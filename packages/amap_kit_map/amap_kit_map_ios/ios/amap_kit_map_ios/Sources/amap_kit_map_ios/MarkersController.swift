import MAMapKit
import UIKit

/// Applies marker diffs and routes clustered markers to the map's cluster controller.
final class MarkersController {
  private unowned let mapView: MAMapView
  private let clusters: ClusterController
  private let images: MapImageDecoder
  private var values: [String: PlatformMarker] = [:]
  private var annotations: [String: MapMarkerAnnotation] = [:]
  /// Annotation that was re-added because its view kind changed (default pin vs
  /// custom image); its callout is restored once MAMapView creates the new view.
  private var pendingSelection: MapMarkerAnnotation?

  init(mapView: MAMapView, clusters: ClusterController, images: MapImageDecoder) {
    self.mapView = mapView
    self.clusters = clusters
    self.images = images
  }

  func update(_ updates: PlatformMarkerUpdates) throws {
    for value in updates.toAdd {
      try replace(value)
    }
    for value in updates.toChange where values[value.markerId] != nil {
      try replace(value)
    }
    for markerId in updates.toRemove {
      remove(markerId)
    }
    clusters.completeMarkerUpdates()
  }

  func markerId(for annotation: MAAnnotation) -> String? {
    (annotation as? MapMarkerAnnotation)?.markerId
  }

  func value(for markerId: String) -> PlatformMarker? {
    values[markerId]
  }

  func makeView(for annotation: MapMarkerAnnotation) -> MAAnnotationView? {
    guard let value = values[annotation.markerId] else { return nil }
    let customImage = images.cachedImage(for: value.icon)
    let reuseIdentifier =
      customImage == nil ? "amap_kit_map.marker.pin" : "amap_kit_map.marker.image"
    let view: MAAnnotationView
    if let reused = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) {
      view = reused
    } else if customImage == nil,
      let pin = MAPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
    {
      view = pin
    } else if let imageView = MAAnnotationView(
      annotation: annotation, reuseIdentifier: reuseIdentifier)
    {
      view = imageView
    } else {
      view = MAAnnotationView(frame: .zero)
    }
    view.annotation = annotation
    configure(view, for: value, customImage: customImage)
    return view
  }

  func showInfoWindow(_ markerId: String) throws {
    guard let annotation = annotation(for: markerId) else {
      throw invalidMarkerId("showInfoWindow", markerId: markerId)
    }
    mapView.selectAnnotation(annotation, animated: false)
  }

  func hideInfoWindow(_ markerId: String) throws {
    guard let annotation = annotation(for: markerId) else {
      throw invalidMarkerId("hideInfoWindow", markerId: markerId)
    }
    mapView.deselectAnnotation(annotation, animated: false)
  }

  func isInfoWindowShown(_ markerId: String) throws -> Bool {
    guard let annotation = annotation(for: markerId) else {
      throw invalidMarkerId("isInfoWindowShown", markerId: markerId)
    }
    return isSelected(annotation)
  }

  /// Restores the callout of an annotation re-added with a new view kind.
  /// Forwarded from `mapView(_:didAddAnnotationViews:)` so the annotation view
  /// already exists when the selection is applied.
  func annotationViewsDidAdd(_ views: [MAAnnotationView]) {
    guard let pending = pendingSelection,
      views.contains(where: { ($0.annotation as AnyObject) === pending })
    else { return }
    pendingSelection = nil
    mapView.selectAnnotation(pending, animated: false)
  }

  func dispose() {
    pendingSelection = nil
    mapView.removeAnnotations(Array(annotations.values))
    annotations.removeAll()
    values.removeAll()
  }

  private func replace(_ value: PlatformMarker) throws {
    guard value.zIndex.isFinite,
      Int(exactly: value.zIndex.rounded(.towardZero)) != nil
    else {
      throw amapPigeonError("invalid_argument", "Marker zIndex must fit in a native integer.")
    }
    _ = try images.image(for: value.icon)
    if let managerId = value.clusterManagerId,
      values[value.markerId]?.clusterManagerId == managerId
    {
      values[value.markerId] = value
      try clusters.setMarker(value)
      return
    }
    if value.clusterManagerId == nil, let existing = annotations[value.markerId] {
      values[value.markerId] = value
      updateAnnotation(existing, value)
      let wasOnMap = isOnMap(existing)
      guard value.visible else {
        // Hiding removes the annotation; MAMapView deselects it with the view.
        if wasOnMap { mapView.removeAnnotation(existing) }
        return
      }
      guard wasOnMap else {
        mapView.addAnnotation(existing)
        return
      }
      let customImage = images.cachedImage(for: value.icon)
      if let view = mapView.view(for: existing),
        (customImage == nil) == (view is MAPinAnnotationView)
      {
        // Same view kind: reconfigure in place so the selected annotation and
        // its callout survive the update.
        configure(view, for: value, customImage: customImage)
        return
      }
      // The view kind must change (default pin vs custom image): re-add the
      // same annotation so MAMapView rebuilds its view, then restore the
      // callout once the new view exists.
      let wasSelected = isSelected(existing)
      mapView.removeAnnotation(existing)
      mapView.addAnnotation(existing)
      if wasSelected { pendingSelection = existing }
      return
    }
    remove(value.markerId, removeValue: false)
    values[value.markerId] = value
    if value.clusterManagerId != nil {
      try clusters.setMarker(value)
      return
    }
    let annotation = MapMarkerAnnotation(
      markerId: value.markerId, coordinate: value.position.coordinate)
    annotation.title = value.infoWindow.title ?? value.title
    annotation.subtitle = value.infoWindow.snippet ?? value.snippet
    annotations[value.markerId] = annotation
    if value.visible { mapView.addAnnotation(annotation) }
  }

  private func updateAnnotation(_ annotation: MapMarkerAnnotation, _ value: PlatformMarker) {
    annotation.coordinate = value.position.coordinate
    annotation.title = value.infoWindow.title ?? value.title
    annotation.subtitle = value.infoWindow.snippet ?? value.snippet
  }

  /// The AMap SDK exposes `annotations`/`selectedAnnotations` as untyped
  /// `NSArray`, which Swift imports as implicitly unwrapped optionals that are
  /// nil when the map has no annotations or nothing is selected.
  private func isOnMap(_ annotation: MAAnnotation) -> Bool {
    mapView.annotations?.contains { ($0 as AnyObject) === annotation } ?? false
  }

  private func isSelected(_ annotation: MAAnnotation) -> Bool {
    mapView.selectedAnnotations?.contains { ($0 as AnyObject) === annotation } ?? false
  }

  private func configure(
    _ view: MAAnnotationView,
    for value: PlatformMarker,
    customImage: UIImage?
  ) {
    view.isHidden = !value.visible
    view.isDraggable = value.draggable
    view.alpha = CGFloat(min(max(value.alpha, 0), 1))
    view.transform = CGAffineTransform(rotationAngle: CGFloat(value.rotation * .pi / 180))
    let truncatedZIndex = value.zIndex.rounded(.towardZero)
    guard value.zIndex.isFinite, let zIndex = Int(exactly: truncatedZIndex) else {
      return
    }
    view.zIndex = zIndex
    view.canShowCallout =
      value.infoWindow.title != nil || value.infoWindow.snippet != nil
      || value.title != nil || value.snippet != nil
    view.calloutOffset = CGPoint(
      x: CGFloat(value.infoWindow.anchor.x - 0.5),
      y: CGFloat(value.infoWindow.anchor.y - 0.5))
    if let customImage {
      view.image = customImage
      view.centerOffset = CGPoint(
        x: CGFloat(0.5 - value.anchor.x) * customImage.size.width,
        y: CGFloat(0.5 - value.anchor.y) * customImage.size.height)
    } else {
      if !(view is MAPinAnnotationView) { view.image = nil }
      view.centerOffset = .zero
      if let pin = view as? MAPinAnnotationView {
        pin.pinColor = .red
        if let descriptor = value.icon.bitmap as? PlatformBitmapDefaultMarker,
          let hue = descriptor.hue
        {
          switch hue.truncatingRemainder(dividingBy: 360) {
          case 60..<180: pin.pinColor = .green
          case 180..<330: pin.pinColor = .purple
          default: break
          }
        }
      }
    }
  }

  private func remove(_ markerId: String, removeValue: Bool = true) {
    if let annotation = annotations.removeValue(forKey: markerId) {
      if pendingSelection === annotation { pendingSelection = nil }
      mapView.removeAnnotation(annotation)
    }
    clusters.removeMarker(markerId, renderAfterRemoval: false)
    if removeValue { values.removeValue(forKey: markerId) }
  }

  private func annotation(for markerId: String) -> MapMarkerAnnotation? {
    annotations[markerId] ?? clusters.markerAnnotation(withId: markerId)
  }

  private func invalidMarkerId(_ operation: String, markerId: String) -> PigeonError {
    amapPigeonError(
      "Invalid markerId", "\(operation) called with invalid markerId '\(markerId)'.")
  }
}
