import CoreLocation
import Foundation
import MAMapKit
import UIKit

/// Maintains every tile overlay belonging to one map instance, mirroring the
/// Android per-object controller pattern.
final class TileOverlaysController {
  private unowned let mapView: MAMapView
  private let callbackApi: MapsCallbackApi
  private var controllers: [String: TileOverlayController] = [:]

  init(mapView: MAMapView, callbackApi: MapsCallbackApi) {
    self.mapView = mapView
    self.callbackApi = callbackApi
  }

  func update(_ updates: PlatformTileOverlayUpdates) throws {
    for value in updates.toAdd {
      try add(value)
    }
    for value in updates.toChange {
      try change(value)
    }
    updates.toRemove.forEach(remove)
  }

  func clearCache(_ id: String) throws {
    guard let controller = controllers[id] else {
      throw amapPigeonError("unknown_tile_overlay", "Unknown tile overlay ID: \(id)")
    }
    controller.renderer?.reloadData()
  }

  func renderer(for overlay: FlutterTileOverlay) -> MATileOverlayRenderer? {
    controllers.values.first(where: { $0.overlay === overlay })?.renderer(for: overlay)
  }

  func dispose() {
    controllers.values.forEach { $0.dispose() }
    controllers.removeAll()
  }

  private func add(_ value: PlatformTileOverlay) throws {
    remove(value.id)
    let controller = try TileOverlayController(
      mapView: mapView, value: value, callbackApi: callbackApi)
    controllers[value.id] = controller
    if value.visible { controller.attach() }
  }

  private func change(_ value: PlatformTileOverlay) throws {
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
    controllers.removeValue(forKey: id)?.dispose()
  }
}

/// Tile overlay whose tiles are provided by the Flutter side over Pigeon.
final class FlutterTileOverlay: MATileOverlay {
  let overlayId: String
  private let callbackApi: MapsCallbackApi
  private let stateLock = NSLock()
  private var active = true
  private var pending: [UUID: PendingTileRequest] = [:]

  init(value: PlatformTileOverlay, callbackApi: MapsCallbackApi) {
    overlayId = value.id
    self.callbackApi = callbackApi
    super.init()
    tileSize = CGSize(width: CGFloat(value.tileSize), height: CGFloat(value.tileSize))
    disableOffScreenTileLoading = true
  }

  required init?(coder: NSCoder) {
    nil
  }

  override func loadTile(
    at path: MATileOverlayPath,
    result: @escaping (Data?, Error?) -> Void
  ) {
    let requestId = UUID()
    let timeout = DispatchWorkItem { [weak self] in
      self?.finish(requestId, data: nil, error: Self.timeoutError)
    }
    stateLock.lock()
    guard active else {
      stateLock.unlock()
      result(nil, Self.cancelledError)
      return
    }
    pending[requestId] = PendingTileRequest(result: result, timeout: timeout)
    stateLock.unlock()
    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 15, execute: timeout)

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      guard self.shouldSend(requestId) else {
        self.finish(requestId, data: nil, error: Self.cancelledError)
        return
      }
      self.callbackApi.getTileOverlayTile(
        tileOverlayId: self.overlayId,
        coordinate: PlatformTileCoordinate(x: Int64(path.x), y: Int64(path.y)),
        zoom: Int64(path.z)
      ) { [weak self] response in
        switch response {
        case .success(let tile):
          self?.finish(requestId, data: tile.data?.data, error: nil)
        case .failure(let error):
          self?.finish(requestId, data: nil, error: error)
        }
      }
    }
  }

  func dispose() {
    stateLock.lock()
    guard active else {
      stateLock.unlock()
      return
    }
    active = false
    let requests = Array(pending.values)
    pending.removeAll()
    stateLock.unlock()
    for request in requests {
      request.timeout.cancel()
      request.result(nil, Self.cancelledError)
    }
  }

  private func shouldSend(_ id: UUID) -> Bool {
    stateLock.lock()
    defer { stateLock.unlock() }
    return active && pending[id] != nil
  }

  private func finish(_ id: UUID, data: Data?, error: Error?) {
    stateLock.lock()
    let request = pending.removeValue(forKey: id)
    stateLock.unlock()
    guard let request else { return }
    request.timeout.cancel()
    request.result(data, error)
  }

  private static let cancelledError = NSError(
    domain: "amap_kit_map.tile_overlay", code: NSUserCancelledError,
    userInfo: [NSLocalizedDescriptionKey: "Tile request was cancelled."])
  private static let timeoutError = NSError(
    domain: "amap_kit_map.tile_overlay", code: NSURLErrorTimedOut,
    userInfo: [NSLocalizedDescriptionKey: "Tile request timed out after 15 seconds."])
}

private struct PendingTileRequest {
  let result: (Data?, Error?) -> Void
  let timeout: DispatchWorkItem
}
