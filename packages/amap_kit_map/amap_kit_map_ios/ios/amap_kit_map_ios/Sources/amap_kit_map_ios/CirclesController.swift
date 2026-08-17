import CoreLocation
import MAMapKit
import UIKit

/// Maintains every circle belonging to one map instance, mirroring the Android
/// per-object controller pattern.
final class CirclesController {
  private unowned let mapView: MAMapView
  private var controllers: [String: CircleController] = [:]

  init(mapView: MAMapView) {
    self.mapView = mapView
  }

  func update(_ updates: PlatformCircleUpdates) throws {
    for value in updates.toAdd {
      try add(value)
    }
    for value in updates.toChange {
      try change(value)
    }
    updates.toRemove.forEach(remove)
  }

  func renderer(for overlay: MACircle) -> MACircleRenderer? {
    controllers.values.first(where: { $0.circle === overlay })?.renderer(for: overlay)
  }

  func dispose() {
    controllers.values.forEach { $0.remove() }
    controllers.removeAll()
  }

  private func add(_ value: PlatformCircle) throws {
    remove(value.circleId)
    let controller = try CircleController(mapView: mapView, value: value)
    controllers[value.circleId] = controller
    if value.visible { controller.attach() }
  }

  private func change(_ value: PlatformCircle) throws {
    guard let controller = controllers[value.circleId] else {
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
