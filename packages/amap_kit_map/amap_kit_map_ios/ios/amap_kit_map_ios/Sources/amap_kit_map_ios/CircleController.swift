import CoreLocation
import MAMapKit
import UIKit

/// Owns one AMap circle and applies updates to the existing overlay in place,
/// mirroring the Android per-object `CircleController`.
final class CircleController {
  private unowned let mapView: MAMapView
  private(set) var circle: MACircle
  private(set) var renderer: MACircleRenderer?
  private(set) var value: PlatformCircle

  init(mapView: MAMapView, value: PlatformCircle) throws {
    self.mapView = mapView
    self.value = value
    try Self.validate(value)
    guard let circle = MACircle(center: value.center.coordinate, radius: value.radius) else {
      throw amapPigeonError("invalid_argument", "Unable to create circle '\(value.circleId)'.")
    }
    self.circle = circle
  }

  func update(_ next: PlatformCircle) throws {
    try Self.validate(next)
    value = next
    circle.setCircleWithCenterCoordinate(next.center.coordinate, radius: next.radius)
    refreshRenderer()
  }

  func renderer(for overlay: MACircle) -> MACircleRenderer? {
    guard overlay === circle else { return nil }
    if let renderer { return renderer }
    guard let renderer = MACircleRenderer(circle: overlay) else { return nil }
    applyStyle(renderer)
    self.renderer = renderer
    return renderer
  }

  func attach() {
    mapView.add(circle)
  }

  func remove() {
    mapView.remove(circle)
  }

  private static func validate(_ value: PlatformCircle) throws {
    guard value.zIndex.isFinite else {
      throw amapPigeonError("invalid_argument", "Circle zIndex must be finite.")
    }
    guard value.radius > 0 else {
      throw amapPigeonError("invalid_argument", "Circle radius must be greater than zero.")
    }
  }

  private func refreshRenderer() {
    guard let renderer else { return }
    applyStyle(renderer)
    renderer.setNeedsUpdate()
  }

  private func applyStyle(_ renderer: MACircleRenderer) {
    renderer.strokeColor = amapColor(value.strokeColor)
    renderer.fillColor = amapColor(value.fillColor)
    renderer.lineWidth = CGFloat(value.strokeWidth)
    renderer.lineDashType = value.isDotted ? kMALineDashTypeSquare : kMALineDashTypeNone
  }
}
