import AMapFoundationKit
import Flutter
import MAMapKit
import UIKit

/// Creates independently owned native map views for Flutter platform-view IDs.
final class AmapMapFactory: NSObject, FlutterPlatformViewFactory {
  private let binaryMessenger: FlutterBinaryMessenger
  private let assetLookup: (String, String?) -> String

  init(
    binaryMessenger: FlutterBinaryMessenger,
    assetLookup: @escaping (String, String?) -> String
  ) {
    self.binaryMessenger = binaryMessenger
    self.assetLookup = assetLookup
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    MapsApiSetup.codec
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    guard let creationParams = args as? PlatformMapViewCreationParams else {
      return AmapErrorPlatformView(frame: frame)
    }

    configureSdk(using: creationParams)
    return AmapMapController(
      frame: frame,
      viewIdentifier: viewId,
      binaryMessenger: binaryMessenger,
      assetLookup: assetLookup,
      creationParams: creationParams)
  }

  private func configureSdk(using creationParams: PlatformMapViewCreationParams) {
    let apiKey = creationParams.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    if !apiKey.isEmpty {
      AMapServices.shared().apiKey = apiKey
    }

    let privacy = creationParams.privacyStatement
    if let hasShow = privacy.hasShow, let hasContains = privacy.hasContains {
      MAMapView.updatePrivacyShow(
        hasShow ? .didShow : .notShow,
        privacyInfo: hasContains ? .didContain : .notContain)
    }
    if let hasAgree = privacy.hasAgree {
      MAMapView.updatePrivacyAgree(hasAgree ? .didAgree : .notAgree)
    }
  }
}

private final class AmapMapController: NSObject, FlutterPlatformView, MapsApi, MAMapViewDelegate {
  private let mapId: Int64
  private let binaryMessenger: FlutterBinaryMessenger
  private let mapView: MAMapView
  private let callbackApi: MapsCallbackApi
  private let imageDecoder: MapImageDecoder
  private lazy var clusterController = ClusterController(mapView: mapView)
  private lazy var markersController = MarkersController(
    mapView: mapView, clusters: clusterController, images: imageDecoder)
  private lazy var polylinesController = PolylinesController(mapView: mapView)
  private lazy var polygonsController = PolygonsController(mapView: mapView)
  private lazy var circlesController = CirclesController(mapView: mapView)
  private lazy var groundOverlaysController = GroundOverlaysController(
    mapView: mapView, images: imageDecoder)
  private lazy var heatmapsController = HeatmapsController(mapView: mapView)
  private lazy var tileOverlaysController = TileOverlaysController(
    mapView: mapView, callbackApi: callbackApi)
  private var mapLoaded = false
  private var disposed = false
  private var creationError: Error?
  private var readyCallback: ((Result<Void, Error>) -> Void)?
  private var locationEnabled = false
  private var lastAnnotationTapCoordinate: CLLocationCoordinate2D?
  private var lastAnnotationTapAt: Date?
  private var cameraDisplayLink: CADisplayLink?
  private var cameraDisplayLinkTarget: CameraDisplayLinkTarget?
  private var lastCameraMove: PlatformCameraPosition?
  private var myLocationStyle: PlatformMyLocationStyle?

  init(
    frame: CGRect,
    viewIdentifier: Int64,
    binaryMessenger: FlutterBinaryMessenger,
    assetLookup: @escaping (String, String?) -> String,
    creationParams: PlatformMapViewCreationParams
  ) {
    mapId = viewIdentifier
    self.binaryMessenger = binaryMessenger
    mapView = MAMapView(frame: frame)
    callbackApi = MapsCallbackApi(
      binaryMessenger: binaryMessenger, messageChannelSuffix: viewIdentifier.description)
    imageDecoder = MapImageDecoder(lookupAsset: assetLookup)
    super.init()
    mapView.delegate = self
    MapsApiSetup.setUp(
      binaryMessenger: binaryMessenger,
      api: self,
      messageChannelSuffix: viewIdentifier.description)
    do {
      try applyInitialState(creationParams)
    } catch {
      creationError = error
      rollbackInitialState()
    }
  }

  func view() -> UIView {
    mapView
  }

  func waitForMap(completion: @escaping (Result<Void, Error>) -> Void) {
    if let creationError {
      completion(.failure(creationError))
    } else if disposed {
      completion(.failure(amapPigeonError("map_disposed", "Map \(mapId) has been disposed.")))
    } else if mapLoaded {
      completion(.success(()))
    } else {
      readyCallback = completion
    }
  }

  func updateMapOptions(options: PlatformMapOptions) throws {
    try requireActive()
    if let mapType = options.mapType {
      mapView.mapType = mapType == .satellite ? .satellite : .standard
    }
    if let enabled = options.compassEnabled { mapView.showsCompass = enabled }
    if let enabled = options.scaleControlsEnabled { mapView.showsScale = enabled }
    if let enabled = options.trafficEnabled { mapView.isShowTraffic = enabled }
    if let enabled = options.buildingsEnabled { mapView.isShowsBuildings = enabled }
    if let enabled = options.rotateGesturesEnabled { mapView.isRotateEnabled = enabled }
    if let enabled = options.tiltGesturesEnabled { mapView.isRotateCameraEnabled = enabled }
    if let enabled = options.scrollGesturesEnabled { mapView.isScrollEnabled = enabled }
    if let enabled = options.zoomGesturesEnabled { mapView.isZoomEnabled = enabled }
    if let style = options.customMapStyle {
      updateCustomMapStyle(style)
    }
    if let style = options.myLocationStyle {
      myLocationStyle = style
    }
    if let enabled = options.myLocationEnabled {
      try updateMyLocation(enabled, style: options.myLocationStyle ?? myLocationStyle)
    } else if locationEnabled, let style = options.myLocationStyle {
      try updateMyLocation(true, style: style)
    }
  }

  func moveCamera(update: PlatformCameraUpdate) throws {
    try requireActive()
    applyCameraUpdate(update, animated: false, duration: nil)
  }

  func animateCamera(update: PlatformCameraUpdate, durationMillis: Int64?) throws {
    try requireActive()
    let duration = durationMillis.map { TimeInterval($0) / 1000 }
    applyCameraUpdate(update, animated: true, duration: duration)
  }

  func getVisibleRegion() throws -> PlatformLatLngBounds {
    try requireActive()
    let rect = mapView.visibleMapRect
    let southwest = MACoordinateForMapPoint(
      MAMapPoint(x: MAMapRectGetMinX(rect), y: MAMapRectGetMaxY(rect)))
    let northeast = MACoordinateForMapPoint(
      MAMapPoint(x: MAMapRectGetMaxX(rect), y: MAMapRectGetMinY(rect)))
    return PlatformLatLngBounds(
      southwest: southwest.platform,
      northeast: northeast.platform)
  }

  func updateClusterManagers(updates: PlatformClusterManagerUpdates) throws {
    try requireActive()
    clusterController.updateManagers(updates)
  }

  func updateMarkers(updates: PlatformMarkerUpdates) throws {
    try requireActive()
    try markersController.update(updates)
  }

  func updatePolylines(updates: PlatformPolylineUpdates) throws {
    try requireActive()
    try polylinesController.update(updates)
  }

  func updatePolygons(updates: PlatformPolygonUpdates) throws {
    try requireActive()
    try polygonsController.update(updates)
  }

  func updateCircles(updates: PlatformCircleUpdates) throws {
    try requireActive()
    try circlesController.update(updates)
  }

  func updateGroundOverlays(updates: PlatformGroundOverlayUpdates) throws {
    try requireActive()
    try groundOverlaysController.update(updates)
  }

  func updateHeatmaps(updates: PlatformHeatmapUpdates) throws {
    try requireActive()
    try heatmapsController.update(updates)
  }

  func updateTileOverlays(updates: PlatformTileOverlayUpdates) throws {
    try requireActive()
    try tileOverlaysController.update(updates)
  }

  func clearTileCache(tileOverlayId: String) throws {
    try requireActive()
    try tileOverlaysController.clearCache(tileOverlayId)
  }

  func updateMultiPointOverlays(updates: PlatformMultiPointOverlayUpdates) throws {
    try requireActive()
    throw amapPigeonError(
      "unsupported",
      "Multi-point overlays are not implemented by this iOS renderer.")
  }

  func showInfoWindow(markerId: String) throws {
    try requireActive()
    try markersController.showInfoWindow(markerId)
  }

  func hideInfoWindow(markerId: String) throws {
    try requireActive()
    try markersController.hideInfoWindow(markerId)
  }

  func isInfoWindowShown(markerId: String) throws -> Bool {
    try requireActive()
    return try markersController.isInfoWindowShown(markerId)
  }

  func getZoomLevel() throws -> Double {
    try requireActive()
    return Double(mapView.zoomLevel)
  }

  func takeSnapshot(
    failWithStatus: Bool,
    completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void
  ) {
    do {
      try requireActive()
    } catch {
      completion(.failure(error))
      return
    }
    mapView.takeSnapshot(in: mapView.bounds) { [weak self] image, state in
      guard let self, !self.disposed else {
        completion(.failure(amapPigeonError("map_disposed", "Map was disposed during snapshot.")))
        return
      }
      if failWithStatus && state != 1 {
        completion(.failure(amapPigeonError("snapshot_failed", "Map snapshot was incomplete.")))
        return
      }
      guard let data = image?.pngData() else {
        completion(.failure(amapPigeonError("snapshot_failed", "Unable to encode map snapshot.")))
        return
      }
      completion(.success(FlutterStandardTypedData(bytes: data)))
    }
  }

  func disposeMap() throws {
    dispose()
  }

  deinit {
    dispose()
  }

  private func applyInitialState(_ creationParams: PlatformMapViewCreationParams) throws {
    try updateMapOptions(options: creationParams.mapConfiguration)

    let camera = creationParams.initialCameraPosition
    setCameraPosition(camera, animated: false, duration: nil)
    clusterController.updateManagers(
      PlatformClusterManagerUpdates(
        toAdd: creationParams.initialClusterManagers, toChange: [], toRemove: []))
    try markersController.update(
      PlatformMarkerUpdates(toAdd: creationParams.initialMarkers, toChange: [], toRemove: []))
    try polylinesController.update(
      PlatformPolylineUpdates(toAdd: creationParams.initialPolylines, toChange: [], toRemove: []))
    try polygonsController.update(
      PlatformPolygonUpdates(toAdd: creationParams.initialPolygons, toChange: [], toRemove: []))
    try circlesController.update(
      PlatformCircleUpdates(toAdd: creationParams.initialCircles, toChange: [], toRemove: []))
    try groundOverlaysController.update(
      PlatformGroundOverlayUpdates(
        toAdd: creationParams.initialGroundOverlays, toChange: [], toRemove: []))
    try heatmapsController.update(
      PlatformHeatmapUpdates(
        toAdd: creationParams.initialHeatmaps, toChange: [], toRemove: []))
    try tileOverlaysController.update(
      PlatformTileOverlayUpdates(
        toAdd: creationParams.initialTileOverlays, toChange: [], toRemove: []))
  }

  private func requireActive() throws {
    if let creationError { throw creationError }
    if disposed { throw amapPigeonError("map_disposed", "Map \(mapId) has been disposed.") }
  }

  private func rollbackInitialState() {
    mapView.showsUserLocation = false
    mapView.userTrackingMode = .none
    mapView.delegate = nil
    markersController.dispose()
    clusterController.dispose()
    polylinesController.dispose()
    polygonsController.dispose()
    circlesController.dispose()
    groundOverlaysController.dispose()
    heatmapsController.dispose()
    tileOverlaysController.dispose()
    imageDecoder.dispose()
  }

  private func dispose() {
    if disposed { return }
    disposed = true
    let failure = amapPigeonError(
      "map_disposed", "Map \(mapId) was disposed before it became ready.")
    readyCallback?(.failure(failure))
    readyCallback = nil
    mapView.showsUserLocation = false
    mapView.userTrackingMode = .none
    mapView.delegate = nil
    markersController.dispose()
    clusterController.dispose()
    polylinesController.dispose()
    polygonsController.dispose()
    circlesController.dispose()
    groundOverlaysController.dispose()
    heatmapsController.dispose()
    tileOverlaysController.dispose()
    imageDecoder.dispose()
    cameraDisplayLink?.invalidate()
    cameraDisplayLink = nil
    cameraDisplayLinkTarget = nil
    MapsApiSetup.setUp(
      binaryMessenger: binaryMessenger, api: nil, messageChannelSuffix: mapId.description)
  }

  private func cameraPosition() -> PlatformCameraPosition {
    PlatformCameraPosition(
      target: mapView.centerCoordinate.platform,
      zoom: Double(mapView.zoomLevel),
      bearing: Double(mapView.rotationDegree),
      tilt: Double(mapView.cameraDegree))
  }

  private func setCameraPosition(
    _ position: PlatformCameraPosition,
    animated: Bool,
    duration: TimeInterval?
  ) {
    guard let status = mapView.getMapStatus() else {
      mapView.setCenter(position.target.coordinate, animated: animated)
      mapView.setZoomLevel(CGFloat(position.zoom), animated: animated)
      mapView.rotationDegree = CGFloat(position.bearing)
      mapView.cameraDegree = CGFloat(position.tilt)
      return
    }
    status.centerCoordinate = position.target.coordinate
    status.zoomLevel = CGFloat(position.zoom)
    status.rotationDegree = CGFloat(position.bearing)
    status.cameraDegree = CGFloat(position.tilt)
    applyMapStatus(status, animated: animated, duration: duration)
  }

  private func applyCameraUpdate(
    _ update: PlatformCameraUpdate,
    animated: Bool,
    duration: TimeInterval?
  ) {
    switch update.cameraUpdate {
    case let value as PlatformCameraUpdateNewCameraPosition:
      setCameraPosition(value.cameraPosition, animated: animated, duration: duration)
    case let value as PlatformCameraUpdateNewLatLng:
      setCenter(value.latLng.coordinate, animated: animated, duration: duration)
    case let value as PlatformCameraUpdateNewLatLngBounds:
      let padding = CGFloat(value.padding)
      mapView.setVisibleMapRect(
        mapRect(for: value.bounds),
        edgePadding: UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding),
        animated: animated,
        duration: duration ?? 0.25)
    case let value as PlatformCameraUpdateNewLatLngZoom:
      let position = PlatformCameraPosition(
        target: value.latLng, zoom: value.zoom,
        bearing: Double(mapView.rotationDegree), tilt: Double(mapView.cameraDegree))
      setCameraPosition(position, animated: animated, duration: duration)
    case let value as PlatformCameraUpdateScrollBy:
      let center = CGPoint(x: mapView.bounds.midX + value.dx, y: mapView.bounds.midY + value.dy)
      setCenter(
        mapView.convert(center, toCoordinateFrom: mapView), animated: animated, duration: duration)
    case let value as PlatformCameraUpdateZoomBy:
      if let focus = value.focus {
        mapView.setZoomLevel(
          CGFloat(Double(mapView.zoomLevel) + value.amount),
          atPivot: CGPoint(x: focus.x, y: focus.y),
          animated: animated)
      } else {
        setZoom(Double(mapView.zoomLevel) + value.amount, animated: animated, duration: duration)
      }
    case let value as PlatformCameraUpdateZoom:
      setZoom(
        Double(mapView.zoomLevel) + (value.out ? -1 : 1), animated: animated, duration: duration)
    case let value as PlatformCameraUpdateZoomTo:
      setZoom(value.zoom, animated: animated, duration: duration)
    default:
      break
    }
  }

  private func setCenter(
    _ coordinate: CLLocationCoordinate2D,
    animated: Bool,
    duration: TimeInterval?
  ) {
    guard let status = mapView.getMapStatus() else {
      mapView.setCenter(coordinate, animated: animated)
      return
    }
    status.centerCoordinate = coordinate
    applyMapStatus(status, animated: animated, duration: duration)
  }

  private func setZoom(_ zoom: Double, animated: Bool, duration: TimeInterval?) {
    guard let status = mapView.getMapStatus() else {
      mapView.setZoomLevel(CGFloat(zoom), animated: animated)
      return
    }
    status.zoomLevel = CGFloat(zoom)
    applyMapStatus(status, animated: animated, duration: duration)
  }

  private func applyMapStatus(
    _ status: MAMapStatus,
    animated: Bool,
    duration: TimeInterval?
  ) {
    if let duration {
      mapView.setMapStatus(status, animated: animated, duration: duration)
    } else {
      mapView.setMapStatus(status, animated: animated)
    }
  }

  private func mapRect(for bounds: PlatformLatLngBounds) -> MAMapRect {
    let southwest = MAMapPointForCoordinate(bounds.southwest.coordinate)
    let northeast = MAMapPointForCoordinate(bounds.northeast.coordinate)
    var width = northeast.x - southwest.x
    if width < 0 { width += MAMapSizeWorld.width }
    return MAMapRectMake(southwest.x, northeast.y, width, southwest.y - northeast.y)
  }

  private func updateCustomMapStyle(_ style: PlatformCustomMapStyle) {
    let options = MAMapCustomStyleOptions()
    options.styleId = style.styleId
    options.styleData = style.styleData?.data
    options.styleExtraData = style.styleExtraData?.data
    options.styleTextureData = style.styleTextureData?.data
    mapView.setCustomMapStyleOptions(options)
    mapView.customMapStyleEnabled = true
  }

  private func updateMyLocation(_ enabled: Bool, style: PlatformMyLocationStyle?) throws {
    guard enabled else {
      locationEnabled = false
      mapView.showsUserLocation = false
      mapView.userTrackingMode = .none
      return
    }
    let status = CLLocationManager().authorizationStatus
    guard status == .authorizedAlways || status == .authorizedWhenInUse else {
      throw amapPigeonError("location_permission", "Foreground location permission is required.")
    }
    locationEnabled = true
    guard style?.showMyLocation != false else {
      mapView.showsUserLocation = false
      mapView.userTrackingMode = .none
      return
    }
    let representation = MAUserLocationRepresentation()
    representation.image = try imageDecoder.image(for: style?.icon)
    if let color = style?.radiusFillColor { representation.fillColor = amapColor(color) }
    if let color = style?.strokeColor { representation.strokeColor = amapColor(color) }
    if let width = style?.strokeWidth { representation.lineWidth = CGFloat(width) }
    mapView.update(representation)
    switch style?.myLocationType {
    case .follow, .locate, .followNoCenter:
      mapView.userTrackingMode = .follow
    case .mapRotate, .locationRotate, .locationRotateNoCenter, .mapRotateNoCenter:
      mapView.userTrackingMode = .followWithHeading
    default:
      mapView.userTrackingMode = .none
    }
    mapView.showsUserLocation = true
  }
    
    func mapViewDidFinishLoadingMap(_ mapView: MAMapView!) {
        
    }

  func mapInitComplete(_ mapView: MAMapView!) {
    guard !disposed else { return }
    mapLoaded = true
    readyCallback?(.success(()))
    readyCallback = nil
  }

  func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
    if annotation is MAUserLocation { return nil }
    if let cluster = annotation as? MapClusterAnnotation {
      return clusterController.makeView(for: cluster)
    }
    guard let marker = annotation as? MapMarkerAnnotation else { return nil }
    return markersController.makeView(for: marker)
  }

  func mapView(_ mapView: MAMapView!, didAddAnnotationViews views: [Any]) {
    guard !disposed else { return }
    markersController.annotationViewsDidAdd(views.compactMap { $0 as? MAAnnotationView })
  }

  func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
    if let ground = overlay as? MAGroundOverlay {
      return groundOverlaysController.renderer(for: ground)
    }
    if let heatmap = overlay as? MAHeatMapTileOverlay {
      return heatmapsController.renderer(for: heatmap)
    }
    if let tile = overlay as? FlutterTileOverlay {
      return tileOverlaysController.renderer(for: tile)
    }
    if let polyline = overlay as? MAPolyline { return polylinesController.renderer(for: polyline) }
    if let polygon = overlay as? MAPolygon { return polygonsController.renderer(for: polygon) }
    if let circle = overlay as? MACircle { return circlesController.renderer(for: circle) }
    return nil
  }

  func mapView(_ mapView: MAMapView!, regionWillChangeAnimated animated: Bool) {
    guard !disposed else { return }
    cameraDisplayLink?.invalidate()
    lastCameraMove = nil
    let target = CameraDisplayLinkTarget { [weak self] in self?.emitCameraMove() }
    let displayLink = CADisplayLink(
      target: target, selector: #selector(CameraDisplayLinkTarget.tick))
    displayLink.add(to: .main, forMode: .common)
    cameraDisplayLinkTarget = target
    cameraDisplayLink = displayLink
  }

  func mapView(_ mapView: MAMapView!, regionDidChangeAnimated animated: Bool) {
    guard !disposed else { return }
    cameraDisplayLink?.invalidate()
    cameraDisplayLink = nil
    cameraDisplayLinkTarget = nil
    clusterController.onCameraIdle()
    let position = cameraPosition()
    if lastCameraMove != position {
      callbackApi.onCameraMove(cameraPosition: position) { _ in }
    }
    lastCameraMove = position
    callbackApi.onCameraMoveEnd(cameraPosition: position) { _ in }
  }

  @objc private func emitCameraMove() {
    guard !disposed else { return }
    let position = cameraPosition()
    guard position != lastCameraMove else { return }
    lastCameraMove = position
    callbackApi.onCameraMove(cameraPosition: position) { _ in }
  }

  func mapView(_ mapView: MAMapView!, didAnnotationViewTapped view: MAAnnotationView!) {
    guard !disposed, let annotation = view.annotation else { return }
    if let cluster = clusterController.cluster(for: annotation) {
      callbackApi.onClusterTap(cluster: cluster) { _ in }
      return
    }
    guard let markerId = markersController.markerId(for: annotation)
    else { return }
    callbackApi.onMarkerTap(markerId: markerId) { _ in }
  }

  func mapView(_ mapView: MAMapView!, didAnnotationViewCalloutTapped view: MAAnnotationView!) {
    guard let annotation = view.annotation,
      let markerId = markersController.markerId(for: annotation)
    else { return }
    callbackApi.onInfoWindowTap(markerId: markerId) { _ in }
  }

  func mapView(
    _ mapView: MAMapView!,
    annotationView view: MAAnnotationView!,
    didChange newState: MAAnnotationViewDragState,
    fromOldState oldState: MAAnnotationViewDragState
  ) {
    guard let point = view.annotation as? MapMarkerAnnotation,
      let markerId = markersController.markerId(for: point)
    else { return }
    switch newState {
    case .starting:
      callbackApi.onMarkerDragStart(markerId: markerId, position: point.coordinate.platform) { _ in
      }
    case .dragging:
      callbackApi.onMarkerDrag(markerId: markerId, position: point.coordinate.platform) { _ in }
    case .ending, .canceling:
      callbackApi.onMarkerDragEnd(markerId: markerId, position: point.coordinate.platform) { _ in }
    case .none where oldState == .dragging || oldState == .starting:
      callbackApi.onMarkerDragEnd(markerId: markerId, position: point.coordinate.platform) { _ in }
    default:
      break
    }
  }

  func mapView(_ mapView: MAMapView!, didSingleTappedAt coordinate: CLLocationCoordinate2D) {
    guard !disposed else { return }
    if let polylineId = polylinesController.id(at: coordinate) {
      callbackApi.onPolylineTap(polylineId: polylineId) { _ in }
      return
    }
    callbackApi.onTap(position: coordinate.platform) { _ in }
  }

  func mapView(_ mapView: MAMapView!, didLongPressedAt coordinate: CLLocationCoordinate2D) {
    guard !disposed else { return }
    callbackApi.onLongPress(position: coordinate.platform) { _ in }
  }

  func mapView(
    _ mapView: MAMapView!,
    didUpdate userLocation: MAUserLocation!,
    updatingLocation: Bool
  ) {
    guard !disposed, locationEnabled, updatingLocation,
      let location = userLocation?.location
    else { return }
    callbackApi.onMyLocationChange(
      location: PlatformMyLocation(
        latitude: location.coordinate.latitude,
        longitude: location.coordinate.longitude,
        accuracy: location.horizontalAccuracy >= 0 ? location.horizontalAccuracy : nil,
        altitude: location.verticalAccuracy >= 0 ? location.altitude : nil,
        speed: location.speed >= 0 ? location.speed : nil,
        bearing: location.course >= 0 ? location.course : nil,
        timestamp: Int64(location.timestamp.timeIntervalSince1970 * 1000)))
    { _ in }
  }
}

private final class CameraDisplayLinkTarget: NSObject {
  private let handler: () -> Void

  init(handler: @escaping () -> Void) {
    self.handler = handler
  }

  @objc func tick() {
    handler()
  }
}

private final class AmapErrorPlatformView: NSObject, FlutterPlatformView {
  private let contentView: UIView

  init(frame: CGRect) {
    contentView = UIView(frame: frame)
    super.init()
  }

  func view() -> UIView {
    contentView
  }
}
