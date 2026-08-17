import CoreLocation
import MAMapKit
import UIKit

/// Maintains every heatmap belonging to one map instance, mirroring the
/// Android per-object controller pattern.
final class HeatmapsController {
  private unowned let mapView: MAMapView
  private var controllers: [String: HeatmapController] = [:]

  init(mapView: MAMapView) {
    self.mapView = mapView
  }

  func update(_ updates: PlatformHeatmapUpdates) throws {
    for value in updates.toAdd {
      try add(value)
    }
    for value in updates.toChange {
      try change(value)
    }
    updates.toRemove.forEach(remove)
  }

  func renderer(for overlay: MAHeatMapTileOverlay) -> MATileOverlayRenderer? {
    controllers.values.first(where: { $0.overlay === overlay })?.renderer(for: overlay)
  }

  func dispose() {
    controllers.values.forEach { $0.remove() }
    controllers.removeAll()
  }

  private func add(_ value: PlatformHeatmap) throws {
    remove(value.id)
    let controller = try HeatmapController(mapView: mapView, value: value)
    controllers[value.id] = controller
    if value.visible { controller.attach() }
  }

  private func change(_ value: PlatformHeatmap) throws {
    guard let controller = controllers[value.id] else {
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
