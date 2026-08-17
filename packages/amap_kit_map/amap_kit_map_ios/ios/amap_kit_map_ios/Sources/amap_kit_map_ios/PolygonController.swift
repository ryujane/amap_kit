import CoreLocation
import MAMapKit
import UIKit

/// Owns one AMap polygon and applies updates to the existing overlay in place,
/// mirroring the Android per-object `PolygonController`.
final class PolygonController {
  private unowned let mapView: MAMapView
  private(set) var polygon: MAPolygon
  private(set) var renderer: MAPolygonRenderer?
  private(set) var value: PlatformPolygon

  init(mapView: MAMapView, value: PlatformPolygon) throws {
    self.mapView = mapView
    self.value = value
    guard value.zIndex.isFinite else {
      throw amapPigeonError("invalid_argument", "Polygon zIndex must be finite.")
    }
    polygon = try Self.makePolygon(points: value.points, description: "Polygon '\(value.polygonId)'")
    polygon.hollowShapes = try value.holes.map {
      try Self.makePolygon(points: $0, description: "Polygon hole")
    }
  }

  func update(_ next: PlatformPolygon) throws {
    guard next.zIndex.isFinite else {
      throw amapPigeonError("invalid_argument", "Polygon zIndex must be finite.")
    }
    guard next.points.count >= 3 else {
      throw amapPigeonError(
        "invalid_argument", "Polygon '\(next.polygonId)' requires at least three points.")
    }
    // Validate and build everything before mutating the live overlay so a
    // failed update leaves no half-applied state.
    let holes = try next.holes.map {
      try Self.makePolygon(points: $0, description: "Polygon hole")
    }
    value = next
    var coordinates = next.points.map(\.coordinate)
    _ = coordinates.withUnsafeMutableBufferPointer { buffer in
      polygon.setPolygonWithCoordinates(buffer.baseAddress!, count: buffer.count)
    }
    polygon.hollowShapes = holes
    refreshRenderer()
  }

  func renderer(for overlay: MAPolygon) -> MAPolygonRenderer? {
    guard overlay === polygon else { return nil }
    if let renderer { return renderer }
    guard let renderer = MAPolygonRenderer(polygon: overlay) else { return nil }
    applyStyle(renderer)
    self.renderer = renderer
    return renderer
  }

  func attach() {
    mapView.add(polygon)
  }

  func remove() {
    mapView.remove(polygon)
  }

  private static func makePolygon(points: [PlatformLatLng], description: String) throws -> MAPolygon {
    guard points.count >= 3 else {
      throw amapPigeonError("invalid_argument", "\(description) requires at least three points.")
    }
    var coordinates = points.map(\.coordinate)
    guard
      let polygon = coordinates.withUnsafeMutableBufferPointer({ buffer in
        MAPolygon(coordinates: buffer.baseAddress!, count: UInt(buffer.count))
      })
    else {
      throw amapPigeonError("invalid_argument", "Unable to create \(description.lowercased()).")
    }
    return polygon
  }

  private func refreshRenderer() {
    guard let renderer else { return }
    applyStyle(renderer)
    renderer.setNeedsUpdate()
  }

  private func applyStyle(_ renderer: MAPolygonRenderer) {
    renderer.strokeColor = amapColor(value.strokeColor)
    renderer.fillColor = amapColor(value.fillColor)
    renderer.lineWidth = CGFloat(value.strokeWidth)
    switch value.lineJoinType {
    case .bevel: renderer.lineJoinType = kMALineJoinBevel
    case .miter: renderer.lineJoinType = kMALineJoinMiter
    case .round: renderer.lineJoinType = kMALineJoinRound
    }
  }
}
