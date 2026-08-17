import CoreLocation
import MAMapKit
import UIKit

/// Owns one Flutter tile overlay and applies updates in place, mirroring the
/// Android per-object `TileOverlayController`.
final class TileOverlayController {
  private unowned let mapView: MAMapView
  private(set) var overlay: FlutterTileOverlay
  private(set) var renderer: MATileOverlayRenderer?
  private(set) var value: PlatformTileOverlay

  init(mapView: MAMapView, value: PlatformTileOverlay, callbackApi: MapsCallbackApi) throws {
    self.mapView = mapView
    self.value = value
    guard value.zIndex.isFinite else {
      throw amapPigeonError("invalid_argument", "Tile overlay zIndex must be finite.")
    }
    overlay = FlutterTileOverlay(value: value, callbackApi: callbackApi)
  }

  func update(_ next: PlatformTileOverlay) throws {
    guard next.zIndex.isFinite else {
      throw amapPigeonError("invalid_argument", "Tile overlay zIndex must be finite.")
    }
    value = next
    overlay.tileSize = CGSize(width: CGFloat(next.tileSize), height: CGFloat(next.tileSize))
  }

  func renderer(for overlay: FlutterTileOverlay) -> MATileOverlayRenderer? {
    guard overlay === self.overlay else { return nil }
    if let renderer { return renderer }
    guard let renderer = MATileOverlayRenderer(tileOverlay: overlay) else { return nil }
    self.renderer = renderer
    return renderer
  }

  func attach() {
    mapView.add(overlay)
  }

  /// Hides the overlay. Unlike [dispose], this keeps the tile overlay active so
  /// a later visibility toggle can re-attach it and resume tile loading.
  func remove() {
    mapView.remove(overlay)
  }

  /// Final teardown: cancels in-flight tile requests and removes the overlay.
  func dispose() {
    overlay.dispose()
    mapView.remove(overlay)
  }
}
