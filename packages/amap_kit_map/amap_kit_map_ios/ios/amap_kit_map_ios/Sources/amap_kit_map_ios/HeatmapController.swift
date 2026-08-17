import CoreLocation
import MAMapKit
import UIKit

/// Owns one AMap heatmap tile overlay and applies updates in place, mirroring
/// the Android per-object `HeatmapController`.
final class HeatmapController {
  private unowned let mapView: MAMapView
  private(set) var overlay: MAHeatMapTileOverlay
  private(set) var renderer: MATileOverlayRenderer?
  private(set) var value: PlatformHeatmap

  init(mapView: MAMapView, value: PlatformHeatmap) throws {
    self.mapView = mapView
    self.value = value
    overlay = MAHeatMapTileOverlay()
    try apply(value)
  }

  func update(_ next: PlatformHeatmap) throws {
    try apply(next)
    value = next
  }

  func renderer(for overlay: MAHeatMapTileOverlay) -> MATileOverlayRenderer? {
    guard overlay === self.overlay else { return nil }
    if let renderer { return renderer }
    guard let renderer = MATileOverlayRenderer(tileOverlay: overlay) else { return nil }
    self.renderer = renderer
    return renderer
  }

  func attach() {
    mapView.add(overlay)
  }

  func remove() {
    mapView.remove(overlay)
  }

  private func apply(_ value: PlatformHeatmap) throws {
    guard !value.data.isEmpty else {
      throw amapPigeonError("invalid_heatmap", "Heatmap '\(value.id)' must contain data.")
    }
    if let gradient = value.gradient {
      guard !gradient.colors.isEmpty, gradient.colors.count == gradient.startPoints.count else {
        throw amapPigeonError(
          "invalid_heatmap", "Heatmap gradient colors and start points must have equal lengths.")
      }
    }
    overlay.data = value.data.map {
      let node = MAHeatMapNode()
      node.coordinate = $0.point.coordinate
      node.intensity = Float($0.weight)
      return node
    }
    overlay.opacity = CGFloat(min(max(value.opacity, 0), 1))
    overlay.radius = Int(min(max(value.radius, 10), 200))
    if let gradient = value.gradient {
      overlay.gradient = MAHeatMapGradient(
        color: gradient.colors.map(amapColor),
        andWithStartPoints: gradient.startPoints.map(NSNumber.init(value:)))
    }
    if let renderer {
      renderer.reloadData()
      renderer.setNeedsUpdate()
    }
  }
}
