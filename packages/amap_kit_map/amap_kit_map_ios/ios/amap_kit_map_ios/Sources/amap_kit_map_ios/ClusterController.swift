import CoreLocation
import MAMapKit
import UIKit

final class MapMarkerAnnotation: MAPointAnnotation {
  let markerId: String

  init(markerId: String, coordinate: CLLocationCoordinate2D) {
    self.markerId = markerId
    super.init()
    self.coordinate = coordinate
  }
}

final class MapClusterAnnotation: MAPointAnnotation {
  let value: PlatformCluster

  init(value: PlatformCluster) {
    self.value = value
    super.init()
    coordinate = value.position.coordinate
  }
}

/// Owns the cluster managers and clustered annotations for one map instance.
final class ClusterController {
  private unowned let mapView: MAMapView
  private var managerIds: Set<String> = []
  private var markers: [String: [String: PlatformMarker]] = [:]
  private var markerOrder: [String: [String]] = [:]
  private var annotations: [MAAnnotation] = []
  private var disposed = false
  private var renderGeneration = 0
  private let renderQueue = DispatchQueue(
    label: "com.github.amapkit.map.cluster", qos: .userInitiated)

  init(mapView: MAMapView) {
    self.mapView = mapView
  }

  func updateManagers(_ updates: PlatformClusterManagerUpdates) {
    guard !disposed else { return }
    // Android intentionally ignores toChange because a manager currently only has an ID.
    for manager in updates.toAdd {
      managerIds.remove(manager.id)
      markers.removeValue(forKey: manager.id)
      managerIds.insert(manager.id)
      markers[manager.id] = [:]
      markerOrder[manager.id] = []
    }
    for id in updates.toRemove {
      managerIds.remove(id)
      markers.removeValue(forKey: id)
      markerOrder.removeValue(forKey: id)
    }
    render()
  }

  func setMarker(_ marker: PlatformMarker) throws {
    guard !disposed, let managerId = marker.clusterManagerId else { return }
    guard managerIds.contains(managerId) else {
      throw amapPigeonError(
        "initialization_failed",
        "Marker references unknown cluster manager '\(managerId)'.")
    }
    let previousManager = managerIds.first {
      markers[$0]?[marker.markerId] != nil
    }
    if let previousManager, previousManager != managerId {
      markers[previousManager]?.removeValue(forKey: marker.markerId)
      markerOrder[previousManager]?.removeAll { $0 == marker.markerId }
    }
    if markers[managerId]?[marker.markerId] == nil {
      markerOrder[managerId, default: []].append(marker.markerId)
    }
    markers[managerId, default: [:]][marker.markerId] = marker
  }

  func removeMarker(_ markerId: String, renderAfterRemoval: Bool = true) {
    guard !disposed else { return }
    var changed = false
    for managerId in managerIds {
      if markers[managerId]?.removeValue(forKey: markerId) != nil {
        markerOrder[managerId]?.removeAll { $0 == markerId }
        changed = true
      }
    }
    if changed && renderAfterRemoval { render() }
  }

  func completeMarkerUpdates() {
    render()
  }

  func onCameraIdle() {
    render()
  }

  func markerAnnotation(withId markerId: String) -> MapMarkerAnnotation? {
    annotations.lazy.compactMap { $0 as? MapMarkerAnnotation }
      .first(where: { $0.markerId == markerId })
  }

  func cluster(for annotation: MAAnnotation) -> PlatformCluster? {
    (annotation as? MapClusterAnnotation)?.value
  }

  func makeView(for annotation: MapClusterAnnotation) -> MAAnnotationView {
    let reuseIdentifier = "amap_kit_map.cluster"
    let view =
      mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
      ?? MAAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
      ?? MAAnnotationView(frame: .zero)
    view.annotation = annotation
    view.frame = CGRect(x: 0, y: 0, width: 46, height: 46)
    view.backgroundColor = UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1)
    view.layer.cornerRadius = 23
    view.layer.borderWidth = 2
    view.layer.borderColor = UIColor.white.cgColor
    if let firstMarkerId = annotation.value.markerIds.first,
      let marker = markers.values.lazy.compactMap({ $0[firstMarkerId] }).first,
      let zIndex = Int(exactly: marker.zIndex.rounded(.towardZero))
    {
      view.zIndex = zIndex
    } else {
      view.zIndex = 0
    }
    let label: UILabel
    if let existing = view.subviews.compactMap({ $0 as? UILabel }).first {
      label = existing
    } else {
      label = UILabel(frame: view.bounds)
      label.textColor = .white
      label.textAlignment = .center
      label.font = .systemFont(ofSize: 14, weight: .semibold)
      label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      view.addSubview(label)
    }
    label.text = String(annotation.value.markerIds.count)
    return view
  }

  func dispose() {
    guard !disposed else { return }
    disposed = true
    renderGeneration += 1
    mapView.removeAnnotations(annotations)
    annotations.removeAll()
    markers.removeAll()
    markerOrder.removeAll()
    managerIds.removeAll()
  }

  private func render() {
    guard !disposed else { return }
    renderGeneration += 1
    let generation = renderGeneration
    let zoom = Double(mapView.zoomLevel)
    let snapshots = managerIds.sorted().map { managerId in
      ClusterManagerSnapshot(
        managerId: managerId,
        markers: markerOrder[managerId, default: []].compactMap {
          markers[managerId]?[$0]
        })
    }
    renderQueue.async { [weak self] in
      let groups = snapshots.flatMap { snapshot in
        DistanceClusterAlgorithm.groups(markers: snapshot.markers, zoom: zoom).map {
          ClusterRenderGroup(managerId: snapshot.managerId, group: $0)
        }
      }
      DispatchQueue.main.async { [weak self] in
        guard let self, !self.disposed, self.renderGeneration == generation else { return }
        self.apply(groups)
      }
    }
  }

  private func apply(_ groups: [ClusterRenderGroup]) {
    if !annotations.isEmpty {
      mapView.removeAnnotations(annotations)
    }
    var next: [MAAnnotation] = []
    for rendered in groups {
      if rendered.group.markers.count >= 4 {
        next.append(
          MapClusterAnnotation(
            value: platformCluster(rendered.managerId, group: rendered.group)))
      } else {
        next.append(
          contentsOf: rendered.group.markers.map {
            let annotation = MapMarkerAnnotation(
              markerId: $0.markerId, coordinate: $0.position.coordinate)
            annotation.title = $0.infoWindow.title ?? $0.title
            annotation.subtitle = $0.infoWindow.snippet ?? $0.snippet
            return annotation
          })
      }
    }
    annotations = next
    if !next.isEmpty { mapView.addAnnotations(next) }
  }

  private func platformCluster(_ managerId: String, group: DistanceClusterGroup) -> PlatformCluster
  {
    let markers = group.markers
    let latitudes = markers.map { $0.position.latitude }
    let longitudes = markers.map { $0.position.longitude }
    let southwest = PlatformLatLng(
      latitude: latitudes.min() ?? 0, longitude: longitudes.min() ?? 0)
    let northeast = PlatformLatLng(
      latitude: latitudes.max() ?? 0, longitude: longitudes.max() ?? 0)
    return PlatformCluster(
      clusterManagerId: managerId,
      markerIds: markers.map(\.markerId),
      position: group.seed.position,
      bounds: PlatformLatLngBounds(southwest: southwest, northeast: northeast))
  }
}

private enum DistanceClusterAlgorithm {
  private static let tileSize = 256.0
  private static let maximumDistance = 100.0

  static func groups(markers: [PlatformMarker], zoom: Double) -> [DistanceClusterGroup] {
    guard !markers.isEmpty else { return [] }
    let items = markers.map { QuadTreeItem(marker: $0, point: point($0)) }
    let tree = MarkerQuadTree(bounds: PointBounds(minX: 0, maxX: 1, minY: 0, maxY: 1))
    for item in items {
      tree.add(item)
    }
    let span = maximumDistance / pow(2, Double(Int(zoom))) / tileSize
    var visited: Set<String> = []
    var clusterForItem: [String: String] = [:]
    var distanceForItem: [String: Double] = [:]
    var membersBySeed: [String: [PlatformMarker]] = [:]
    var resultOrder: [String] = []

    for candidate in items {
      let candidateId = candidate.marker.markerId
      guard !visited.contains(candidateId) else { continue }
      let nearby = tree.search(boundsAround(candidate.point, span: span))
      if nearby.count == 1 {
        resultOrder.append(candidateId)
        membersBySeed[candidateId] = [candidate.marker]
        visited.insert(candidateId)
        distanceForItem[candidateId] = 0
        continue
      }
      resultOrder.append(candidateId)
      membersBySeed[candidateId] = []
      for item in nearby {
        let itemId = item.marker.markerId
        let distance = squaredDistance(item.point, candidate.point)
        if let existing = distanceForItem[itemId], existing < distance { continue }
        if let oldSeed = clusterForItem[itemId] {
          membersBySeed[oldSeed]?.removeAll { $0.markerId == itemId }
        }
        distanceForItem[itemId] = distance
        membersBySeed[candidateId]?.append(item.marker)
        clusterForItem[itemId] = candidateId
      }
      visited.formUnion(nearby.map { $0.marker.markerId })
    }

    let values = Dictionary(uniqueKeysWithValues: markers.map { ($0.markerId, $0) })
    return resultOrder.compactMap { seedId in
      guard let seed = values[seedId], let members = membersBySeed[seedId], !members.isEmpty else {
        return nil
      }
      return DistanceClusterGroup(seed: seed, markers: members)
    }
  }

  private static func boundsAround(_ point: ProjectedPoint, span: Double) -> PointBounds {
    let halfSpan = span / 2
    return PointBounds(
      minX: point.x - halfSpan,
      maxX: point.x + halfSpan,
      minY: point.y - halfSpan,
      maxY: point.y + halfSpan)
  }

  private static func point(_ marker: PlatformMarker) -> ProjectedPoint {
    let sine = sin(marker.position.latitude * .pi / 180)
    return ProjectedPoint(
      x: (marker.position.longitude + 180) / 360,
      y: 0.5 - log((1 + sine) / (1 - sine)) / (4 * .pi))
  }

  private static func squaredDistance(_ first: ProjectedPoint, _ second: ProjectedPoint) -> Double {
    let x = first.x - second.x
    let y = first.y - second.y
    return x * x + y * y
  }
}

private struct ClusterManagerSnapshot {
  let managerId: String
  let markers: [PlatformMarker]
}

private struct ClusterRenderGroup {
  let managerId: String
  let group: DistanceClusterGroup
}

private struct DistanceClusterGroup {
  let seed: PlatformMarker
  let markers: [PlatformMarker]
}

private struct QuadTreeItem {
  let marker: PlatformMarker
  let point: ProjectedPoint
}

private struct PointBounds {
  let minX: Double
  let maxX: Double
  let minY: Double
  let maxY: Double

  var midX: Double { (minX + maxX) / 2 }
  var midY: Double { (minY + maxY) / 2 }

  func contains(_ point: ProjectedPoint) -> Bool {
    point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY
  }

  func contains(_ bounds: PointBounds) -> Bool {
    bounds.minX >= minX && bounds.maxX <= maxX
      && bounds.minY >= minY && bounds.maxY <= maxY
  }

  func intersects(_ bounds: PointBounds) -> Bool {
    minX < bounds.maxX && bounds.minX < maxX
      && minY < bounds.maxY && bounds.minY < maxY
  }
}

private final class MarkerQuadTree {
  private static let maximumElements = 50
  private static let maximumDepth = 40

  private let bounds: PointBounds
  private let depth: Int
  private var items: [QuadTreeItem] = []
  private var children: [MarkerQuadTree]?

  init(bounds: PointBounds, depth: Int = 0) {
    self.bounds = bounds
    self.depth = depth
  }

  func add(_ item: QuadTreeItem) {
    guard bounds.contains(item.point) else { return }
    insert(item)
  }

  func search(_ searchBounds: PointBounds) -> [QuadTreeItem] {
    var results: [QuadTreeItem] = []
    search(searchBounds, results: &results)
    return results
  }

  private func insert(_ item: QuadTreeItem) {
    if let children {
      child(for: item.point, children: children).insert(item)
      return
    }
    items.append(item)
    if items.count > Self.maximumElements, depth < Self.maximumDepth {
      split()
    }
  }

  private func split() {
    children = [
      child(minX: bounds.minX, maxX: bounds.midX, minY: bounds.minY, maxY: bounds.midY),
      child(minX: bounds.midX, maxX: bounds.maxX, minY: bounds.minY, maxY: bounds.midY),
      child(minX: bounds.minX, maxX: bounds.midX, minY: bounds.midY, maxY: bounds.maxY),
      child(minX: bounds.midX, maxX: bounds.maxX, minY: bounds.midY, maxY: bounds.maxY),
    ]
    let itemsToReinsert = items
    items.removeAll()
    for item in itemsToReinsert {
      insert(item)
    }
  }

  private func child(
    minX: Double,
    maxX: Double,
    minY: Double,
    maxY: Double
  ) -> MarkerQuadTree {
    MarkerQuadTree(
      bounds: PointBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY),
      depth: depth + 1)
  }

  private func child(
    for point: ProjectedPoint,
    children: [MarkerQuadTree]
  ) -> MarkerQuadTree {
    switch (point.y < bounds.midY, point.x < bounds.midX) {
    case (true, true): children[0]
    case (true, false): children[1]
    case (false, true): children[2]
    case (false, false): children[3]
    }
  }

  private func search(_ searchBounds: PointBounds, results: inout [QuadTreeItem]) {
    guard bounds.intersects(searchBounds) else { return }
    if let children {
      for child in children {
        child.search(searchBounds, results: &results)
      }
      return
    }
    if searchBounds.contains(bounds) {
      results.append(contentsOf: items)
    } else {
      results.append(contentsOf: items.filter { searchBounds.contains($0.point) })
    }
  }
}

private struct ProjectedPoint {
  let x: Double
  let y: Double
}
