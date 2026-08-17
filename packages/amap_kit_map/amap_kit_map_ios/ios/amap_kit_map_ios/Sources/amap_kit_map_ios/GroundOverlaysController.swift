import CoreLocation
import MAMapKit
import UIKit

/// Maintains every ground overlay belonging to one map instance.
///
/// Ground overlays stay replace-based (no per-object controller) because
/// `MAGroundOverlay` exposes readonly `icon`/`bounds`; this mirrors the Android
/// side, which also has no per-object ground overlay controller.
final class GroundOverlaysController {
  private unowned let mapView: MAMapView
  private let images: MapImageDecoder
  private var entries: [String: GroundOverlayEntry] = [:]

  init(mapView: MAMapView, images: MapImageDecoder) {
    self.mapView = mapView
    self.images = images
  }

  func update(_ updates: PlatformGroundOverlayUpdates) throws {
    updates.toRemove.forEach(remove)
    for value in updates.toChange { try replace(value) }
    for value in updates.toAdd { try replace(value) }
  }

  func renderer(for overlay: MAGroundOverlay) -> MAGroundOverlayRenderer? {
    guard let entry = entries.values.first(where: { $0.overlay === overlay }),
      let renderer = MAGroundOverlayRenderer(groundOverlay: overlay)
    else { return nil }
    renderer.alpha = CGFloat(1 - min(max(entry.transparency, 0), 1))
    return renderer
  }

  func dispose() {
    for entry in entries.values {
      mapView.remove(entry.overlay)
    }
    entries.removeAll()
  }

  private func replace(_ value: PlatformGroundOverlay) throws {
    guard value.zIndex.isFinite else {
      throw amapPigeonError("invalid_argument", "Ground overlay zIndex must be finite.")
    }
    guard value.bearing == 0 else {
      throw amapPigeonError(
        "unsupported",
        "Ground overlay bearing is not supported by the iOS AMap SDK.")
    }
    guard let image = try images.image(for: value.image) else {
      throw amapPigeonError("invalid_ground_overlay", "Ground overlay image is required.")
    }
    let bounds = try coordinateBounds(value, image: image)
    guard let overlay = MAGroundOverlay(bounds: bounds, icon: image) else {
      throw amapPigeonError(
        "invalid_ground_overlay", "Unable to create ground overlay '\(value.id)'.")
    }
    remove(value.id)
    entries[value.id] = GroundOverlayEntry(
      overlay: overlay, transparency: value.transparency)
    if value.visible { mapView.add(overlay) }
  }

  private func coordinateBounds(
    _ value: PlatformGroundOverlay,
    image: UIImage
  ) throws -> MACoordinateBounds {
    if let bounds = value.bounds {
      return MACoordinateBoundsMake(bounds.northeast.coordinate, bounds.southwest.coordinate)
    }
    guard let position = value.position, let width = value.width, width > 0 else {
      throw amapPigeonError(
        "invalid_ground_overlay",
        "Ground overlay '\(value.id)' requires bounds or a position and positive width.")
    }
    let height = value.height ?? width * Double(image.size.height / image.size.width)
    guard height > 0 else {
      throw amapPigeonError("invalid_ground_overlay", "Ground overlay height must be positive.")
    }
    let center = MAMapPointForCoordinate(position.coordinate)
    let metersPerPoint = MAMetersPerMapPointAtLatitude(position.latitude)
    let widthInPoints = width / metersPerPoint
    let heightInPoints = height / metersPerPoint
    let west = center.x - widthInPoints * value.anchor.x
    let north = center.y - heightInPoints * value.anchor.y
    return MACoordinateBoundsMake(
      MACoordinateForMapPoint(MAMapPoint(x: west + widthInPoints, y: north)),
      MACoordinateForMapPoint(MAMapPoint(x: west, y: north + heightInPoints)))
  }

  private func remove(_ id: String) {
    guard let entry = entries.removeValue(forKey: id) else { return }
    mapView.remove(entry.overlay)
  }
}

private struct GroundOverlayEntry {
  let overlay: MAGroundOverlay
  let transparency: Double
}
