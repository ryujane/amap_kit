import CoreLocation
import MAMapKit
import UIKit

/// Owns one AMap polyline and applies updates to the existing overlay in place,
/// mirroring the Android per-object `PolylineController`.
final class PolylineController {
  private unowned let mapView: MAMapView
  private(set) var polyline: MAPolyline
  private(set) var renderer: MAPolylineRenderer?
  private(set) var value: PlatformPolyline
  private var attached = false

  init(mapView: MAMapView, value: PlatformPolyline) throws {
    self.mapView = mapView
    self.value = value
    polyline = try Self.makePolyline(value)
  }

  func update(_ next: PlatformPolyline) throws {
    guard next.zIndex.isFinite else {
      throw amapPigeonError("invalid_argument", "Polyline zIndex must be finite.")
    }
    guard next.points.count >= 2 else {
      throw amapPigeonError(
        "invalid_argument", "Polyline '\(next.polylineId)' requires at least two points.")
    }
    if next.geodesic != value.geodesic {
      // Geodesic switches the overlay class (MAPolyline vs MAGeodesicPolyline),
      // so the overlay must be rebuilt; the controller object stays the same.
      // Build the replacement first so a failure leaves the current overlay on
      // the map untouched.
      let replacement = try Self.makePolyline(next)
      value = next
      if attached {
        mapView.remove(polyline)
        polyline = replacement
        mapView.add(polyline)
      } else {
        polyline = replacement
      }
      renderer = nil
      return
    }
    value = next
    var coordinates = next.points.map(\.coordinate)
    _ = coordinates.withUnsafeMutableBufferPointer { buffer in
      polyline.setPolylineWithCoordinates(buffer.baseAddress!, count: buffer.count)
    }
    refreshRenderer()
  }

  func renderer(for overlay: MAPolyline) -> MAPolylineRenderer? {
    guard overlay === polyline else { return nil }
    if let renderer { return renderer }
    guard let renderer = MAPolylineRenderer(polyline: overlay) else { return nil }
    applyStyle(renderer)
    self.renderer = renderer
    return renderer
  }

  func attach() {
    mapView.add(polyline)
    attached = true
  }

  func remove() {
    mapView.remove(polyline)
    attached = false
  }

  private static func makePolyline(_ value: PlatformPolyline) throws -> MAPolyline {
    guard value.zIndex.isFinite else {
      throw amapPigeonError("invalid_argument", "Polyline zIndex must be finite.")
    }
    guard value.points.count >= 2 else {
      throw amapPigeonError(
        "invalid_argument", "Polyline '\(value.polylineId)' requires at least two points.")
    }
    var coordinates = value.points.map(\.coordinate)
    let overlay: MAPolyline? = coordinates.withUnsafeMutableBufferPointer { buffer in
      if value.geodesic {
        return MAGeodesicPolyline(coordinates: buffer.baseAddress!, count: UInt(buffer.count))
      }
      return MAPolyline(coordinates: buffer.baseAddress!, count: UInt(buffer.count))
    }
    guard let overlay else {
      throw amapPigeonError(
        "invalid_argument", "Unable to create polyline '\(value.polylineId)'.")
    }
    return overlay
  }

  private func refreshRenderer() {
    guard let renderer else { return }
    applyStyle(renderer)
    renderer.setNeedsUpdate()
  }

  private func applyStyle(_ renderer: MAPolylineRenderer) {
    renderer.strokeColor = amapColor(value.color)
    renderer.lineWidth = CGFloat(value.width)
    renderer.userInteractionEnabled = true
    switch value.lineCapType {
    case .arrow: renderer.lineCapType = kMALineCapArrow
    case .butt: renderer.lineCapType = kMALineCapButt
    case .round: renderer.lineCapType = kMALineCapRound
    case .square: renderer.lineCapType = kMALineCapSquare
    }
    switch value.lineJoinType {
    case .bevel: renderer.lineJoinType = kMALineJoinBevel
    case .miter: renderer.lineJoinType = kMALineJoinMiter
    case .round: renderer.lineJoinType = kMALineJoinRound
    }
    if value.isDotted {
      renderer.lineDashType =
        value.dottedLineType == .circle ? kMALineDashTypeDot : kMALineDashTypeSquare
    } else {
      renderer.lineDashType = kMALineDashTypeNone
    }
  }
}
