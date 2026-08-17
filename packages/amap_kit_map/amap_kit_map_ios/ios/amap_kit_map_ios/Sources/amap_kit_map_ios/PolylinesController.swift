import CoreLocation
import MAMapKit
import UIKit

/// Maintains every polyline belonging to one map instance, mirroring the
/// Android per-object controller pattern.
final class PolylinesController {
  private unowned let mapView: MAMapView
  private var controllers: [String: PolylineController] = [:]

  init(mapView: MAMapView) {
    self.mapView = mapView
  }

  func update(_ updates: PlatformPolylineUpdates) throws {
    for value in updates.toAdd {
      try add(value)
    }
    for value in updates.toChange {
      try change(value)
    }
    updates.toRemove.forEach(remove)
  }

  func renderer(for overlay: MAPolyline) -> MAPolylineRenderer? {
    controllers.values.first(where: { $0.polyline === overlay })?.renderer(for: overlay)
  }

  func id(at coordinate: CLLocationCoordinate2D) -> String? {
    guard let renderers = mapView.getHittedPolylines(with: coordinate, traverseAll: false),
      let renderer = renderers.first as? MAPolylineRenderer
    else { return nil }
    return controllers.first(where: { $0.value.polyline === renderer.polyline })?.key
  }

  func dispose() {
    controllers.values.forEach { $0.remove() }
    controllers.removeAll()
  }

  private func add(_ value: PlatformPolyline) throws {
    remove(value.polylineId)
    let controller = try PolylineController(mapView: mapView, value: value)
    controllers[value.polylineId] = controller
    if value.visible { controller.attach() }
  }

  private func change(_ value: PlatformPolyline) throws {
    guard let controller = controllers[value.polylineId] else {
      try add(value)
      return
    }
    let wasVisible = controller.value.visible
    try controller.update(value)
    if wasVisible != controller.value.visible {
      if controller.value.visible {
        controller.attach()
      } else {
        controller.remove()
      }
    }
  }

  private func remove(_ id: String) {
    controllers.removeValue(forKey: id)?.remove()
  }
}
