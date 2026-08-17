import 'dart:async';

import 'package:amap_kit_map_ios/src/messages.g.dart';
import 'package:amap_kit_map_platform_interface/amap_kit_map_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:stream_transform/stream_transform.dart';

/// The platform view type registered by `AmapKitMapIosPlugin` on iOS.
const String _amapMapViewType = 'amap_kit_map/map_ios';

/// The non-test implementation of `_apiProvider`.
MapsApi _productionApiProvider(int mapId) {
  return MapsApi(messageChannelSuffix: mapId.toString());
}

class UnknownMapIDError extends Error {
  /// Creates an assertion error with the provided [mapId] and optional
  /// [message].
  UnknownMapIDError(this.mapId, [this.message]);

  /// The unknown ID.
  final int mapId;

  /// Message describing the assertion error.
  final Object? message;

  @override
  String toString() {
    if (message != null) {
      return 'Unknown map ID $mapId: ${Error.safeToString(message)}';
    }
    return 'Unknown map ID $mapId';
  }
}

class AmapMapsFlutterIOS extends AmapMapsFlutterPlatform {
  AmapMapsFlutterIOS({
    @visibleForTesting MapsApi Function(int mapId)? apiProvider,
  }) : _apiProvider = apiProvider ?? _productionApiProvider;

  /// Registers the iOS implementation of AmapMapPlatform.
  static void registerWith() {
    AmapMapsFlutterPlatform.instance = AmapMapsFlutterIOS();
  }

  final Map<int, MapsApi> _hostMaps = <int, MapsApi>{};

  /// The per-map handlers for callbacks from the host side.
  @visibleForTesting
  final Map<int, HostMapMessageHandler> hostMapHandlers =
      <int, HostMapMessageHandler>{};

  // A method to create MapsApi instances, which can be overridden for testing.
  final MapsApi Function(int mapId) _apiProvider;

  /// Accesses the MapsApi associated to the passed mapId.
  MapsApi _hostApi(int mapId) {
    final MapsApi? api = _hostMaps[mapId];
    if (api == null) {
      throw UnknownMapIDError(mapId);
    }
    return api;
  }

  // Keep a collection of mapId to a map of TileOverlays.
  final Map<int, Map<TileOverlayId, TileOverlay>> _tileOverlays =
      <int, Map<TileOverlayId, TileOverlay>>{};

  /// Returns the handler for [mapId], creating it if it doesn't already exist.
  @visibleForTesting
  HostMapMessageHandler ensureHandlerInitialized(int mapId) {
    HostMapMessageHandler? handler = hostMapHandlers[mapId];
    if (handler == null) {
      handler = HostMapMessageHandler(
        mapId,
        _mapEventStreamController,
        tileOverlayProvider: (TileOverlayId tileOverlayId) {
          final Map<TileOverlayId, TileOverlay>? tileOverlaysForMap =
              _tileOverlays[mapId];
          return tileOverlaysForMap?[tileOverlayId];
        },
      );
      hostMapHandlers[mapId] = handler;
    }
    return handler;
  }

  /// Returns the API instance for [mapId], creating it if it doesn't already
  /// exist.
  @visibleForTesting
  MapsApi ensureApiInitialized(int mapId) {
    MapsApi? api = _hostMaps[mapId];
    if (api == null) {
      api = _apiProvider(mapId);
      _hostMaps[mapId] ??= api;
    }
    return api;
  }

  @override
  Future<void> init(int mapId) async {
    ensureHandlerInitialized(mapId);
    final MapsApi hostApi = ensureApiInitialized(mapId);
    await hostApi.waitForMap();
  }

  @override
  void dispose({required int mapId}) {
    final MapsApi? hostApi = _hostMaps.remove(mapId);
    hostMapHandlers.remove(mapId)?.dispose();
    _tileOverlays.remove(mapId);
    if (hostApi != null) {
      unawaited(hostApi.disposeMap());
    }
  }

  // The controller we need to broadcast the different events coming
  // from handleMethodCall.
  //
  // It is a `broadcast` because multiple controllers will connect to
  // different stream views of this Controller.
  final StreamController<MapEvent<Object?>> _mapEventStreamController =
      StreamController<MapEvent<Object?>>.broadcast();

  // Returns a filtered view of the events in the _controller, by mapId.
  Stream<MapEvent<Object?>> _events(int mapId) => _mapEventStreamController
      .stream
      .where((MapEvent<Object?> event) => event.mapId == mapId);

  @override
  Widget buildView(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    AmapMapConfiguration mapConfiguration = const AmapMapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) {
    final creationParams = PlatformMapViewCreationParams(
      apiKey: widgetConfiguration.apiKey,
      privacyStatement: _platformPrivacyStatementFromAmapPrivacyStatement(
        widgetConfiguration.privacyStatement,
      ),
      initialCameraPosition: _platformCameraPositionFromCameraPosition(
        widgetConfiguration.initialCameraPosition,
      ),
      mapConfiguration: _platformMapConfigurationFromMapConfiguration(
        mapConfiguration,
      ),
      initialCircles: mapObjects.circles
          .map(_platformCircleFromCircle)
          .toList(),
      initialMarkers: mapObjects.markers
          .map(_platformMarkerFromMarker)
          .toList(),
      initialPolygons: mapObjects.polygons
          .map(_platformPolygonFromPolygon)
          .toList(),
      initialPolylines: mapObjects.polylines
          .map(_platformPolylineFromPolyline)
          .toList(),
      initialClusterManagers: mapObjects.clusterManagers
          .map(_platformClusterManagerFromClusterManager)
          .toList(),
      initialHeatmaps: mapObjects.heatmaps
          .map(_platformHeatmapFromHeatmap)
          .toList(),
      initialTileOverlays: mapObjects.tileOverlays
          .map(_platformTileOverlayFromTileOverlay)
          .toList(),
      initialGroundOverlays: mapObjects.groundOverlays
          .map(_platformGroundOverlayFromGroundOverlay)
          .toList(),
    );

    return UiKitView(
      viewType: _amapMapViewType,
      onPlatformViewCreated: onPlatformViewCreated,
      gestureRecognizers: widgetConfiguration.gestureRecognizers,
      creationParams: creationParams,
      creationParamsCodec: MapsApi.pigeonChannelCodec,
    );
  }

  @override
  Future<void> updateMapConfiguration(
    AmapMapConfiguration configuration, {
    required int mapId,
  }) {
    return _hostApi(mapId).updateMapOptions(
      _platformMapConfigurationFromMapConfiguration(configuration),
    );
  }

  @override
  Future<void> moveCamera(CameraUpdate update, {required int mapId}) {
    return _hostApi(
      mapId,
    ).moveCamera(_platformCameraUpdateFromCameraUpdate(update));
  }

  @override
  Future<void> animateCamera(
    CameraUpdate update, {
    required int mapId,
    Duration? duration,
  }) {
    return animateCameraWithConfiguration(
      update,
      const CameraUpdateAnimationConfiguration(),
      mapId: mapId,
    );
  }

  @override
  Future<LatLngBounds> getVisibleRegion({required int mapId}) async {
    return _latLngBoundsFromPlatformLatLngBounds(
      await _hostApi(mapId).getVisibleRegion(),
    );
  }

  @override
  Future<void> animateCameraWithConfiguration(
    CameraUpdate cameraUpdate,
    CameraUpdateAnimationConfiguration configuration, {
    required int mapId,
  }) {
    return _hostApi(mapId).animateCamera(
      _platformCameraUpdateFromCameraUpdate(cameraUpdate),
      configuration.duration?.inMilliseconds,
    );
  }

  @override
  Future<void> showMarkerInfoWindow(MarkerId markerId, {required int mapId}) {
    return _hostApi(mapId).showInfoWindow(markerId.value);
  }

  @override
  Future<void> hideMarkerInfoWindow(MarkerId markerId, {required int mapId}) {
    return _hostApi(mapId).hideInfoWindow(markerId.value);
  }

  @override
  Future<bool> isMarkerInfoWindowShown(
    MarkerId markerId, {
    required int mapId,
  }) {
    return _hostApi(mapId).isInfoWindowShown(markerId.value);
  }

  @override
  Future<Uint8List?> takeSnapshot({
    required int mapId,
    bool failWithStatus = false,
  }) {
    return _hostApi(mapId).takeSnapshot(failWithStatus: failWithStatus);
  }

  @override
  Future<void> updateMarkers(MarkerUpdates updates, {required int mapId}) {
    return _hostApi(
      mapId,
    ).updateMarkers(_platformMarkerUpdatesFromMarkerUpdate(updates));
  }

  @override
  Future<void> updatePolylines(PolylineUpdates updates, {required int mapId}) {
    return _hostApi(
      mapId,
    ).updatePolylines(_platformPolylineUpdatesFromPolylineUpdates(updates));
  }

  @override
  Future<void> updatePolygons(PolygonUpdates updates, {required int mapId}) {
    return _hostApi(
      mapId,
    ).updatePolygons(_platformPolygonUpdatesFromPolygon(updates));
  }

  @override
  Future<void> updateClusterManagers(
    ClusterManagerUpdates updates, {
    required int mapId,
  }) {
    return _hostApi(mapId).updateClusterManagers(
      _platformClusterManagersUpdatesFromClusterUpdates(updates),
    );
  }

  @override
  Future<void> updateCircles(CircleUpdates updates, {required int mapId}) {
    return _hostApi(
      mapId,
    ).updateCircles(_platformCircleUpdatesFromCircleUpdates(updates));
  }

  @override
  Future<void> updateGroundOverlays(
    GroundOverlayUpdates updates, {
    required int mapId,
  }) {
    return _hostApi(mapId).updateGroundOverlays(
      _platformGroundOverlayUpdatesFromGroundOverlayUpdates(updates),
    );
  }

  @override
  Future<void> updateHeatmaps(HeatmapUpdates updates, {required int mapId}) {
    return _hostApi(
      mapId,
    ).updateHeatmaps(_platformHeatmapUpdatesFromHeatmapUpdates(updates));
  }

  @override
  Future<void> updateTileOverlays({
    required Set<TileOverlay> newTileOverlays,
    required int mapId,
  }) async {
    final Map<TileOverlayId, TileOverlay>? currentTileOverlays =
        _tileOverlays[mapId];
    final Set<TileOverlay> previousSet = currentTileOverlays != null
        ? currentTileOverlays.values.toSet()
        : <TileOverlay>{};
    final updates = TileOverlayUpdates.from(previousSet, newTileOverlays);
    _tileOverlays[mapId] = keyTileOverlayId(newTileOverlays);
    return _hostApi(mapId).updateTileOverlays(
      _platformTileOverlayUpdatesFromTileOverlayUpdates(updates),
    );
  }

  @override
  Future<void> clearTileCache(
    TileOverlayId tileOverlayId, {
    required int mapId,
  }) {
    return _hostApi(mapId).clearTileCache(tileOverlayId.value);
  }

  @override
  Stream<CameraMoveStartedEvent> onCameraMoveStarted({required int mapId}) {
    return _events(mapId).whereType<CameraMoveStartedEvent>();
  }

  @override
  Stream<CameraMoveEvent> onCameraMove({required int mapId}) {
    return _events(mapId).whereType<CameraMoveEvent>();
  }

  @override
  Stream<CameraMoveEndEvent> onCameraMoveEnd({required int mapId}) {
    return _events(mapId).whereType<CameraMoveEndEvent>();
  }

  @override
  Stream<MarkerTapEvent> onMarkerTap({required int mapId}) {
    return _events(mapId).whereType<MarkerTapEvent>();
  }

  @override
  Stream<InfoWindowTapEvent> onInfoWindowTap({required int mapId}) {
    return _events(mapId).whereType<InfoWindowTapEvent>();
  }

  @override
  Stream<MarkerDragStartEvent> onMarkerDragStart({required int mapId}) {
    return _events(mapId).whereType<MarkerDragStartEvent>();
  }

  @override
  Stream<MarkerDragEvent> onMarkerDrag({required int mapId}) {
    return _events(mapId).whereType<MarkerDragEvent>();
  }

  @override
  Stream<MarkerDragEndEvent> onMarkerDragEnd({required int mapId}) {
    return _events(mapId).whereType<MarkerDragEndEvent>();
  }

  @override
  Stream<PolylineTapEvent> onPolylineTap({required int mapId}) {
    return _events(mapId).whereType<PolylineTapEvent>();
  }

  @override
  Stream<MapTapEvent> onTap({required int mapId}) {
    return _events(mapId).whereType<MapTapEvent>();
  }

  @override
  Stream<MapLongPressEvent> onLongPress({required int mapId}) {
    return _events(mapId).whereType<MapLongPressEvent>();
  }

  @override
  Stream<MyLocationChangedEvent> onLocationChanged({required int mapId}) {
    return _events(mapId).whereType<MyLocationChangedEvent>();
  }

  @override
  Stream<ClusterTapEvent> onClusterTap({required int mapId}) {
    return _events(mapId).whereType<ClusterTapEvent>();
  }

  /// Converts a Pigeon [PlatformCluster] to the corresponding [Cluster].
  static Cluster clusterFromPlatformCluster(PlatformCluster cluster) {
    return Cluster(
      ClusterManagerId(cluster.clusterManagerId),
      cluster.markerIds
          // See comment in messages.dart for why the force unwrap is okay.
          .map((String? markerId) => MarkerId(markerId!))
          .toList(),
      position: _latLngFromPlatformLatLng(cluster.position),
      bounds: _latLngBoundsFromPlatformLatLngBounds(cluster.bounds),
    );
  }

  static PlatformClusterManager _platformClusterManagerFromClusterManager(
    ClusterManager clusterManager,
  ) {
    return PlatformClusterManager(id: clusterManager.clusterManagerId.value);
  }

  static PlatformMarkerUpdates _platformMarkerUpdatesFromMarkerUpdate(
    MarkerUpdates markerUpdates,
  ) {
    return PlatformMarkerUpdates(
      toAdd: markerUpdates.markersToAdd.map(_platformMarkerFromMarker).toList(),
      toChange: markerUpdates.markersToChange
          .map(_platformMarkerFromMarker)
          .toList(),
      toRemove: markerUpdates.markerIdsToRemove
          .map((MarkerId id) => id.value)
          .toList(),
    );
  }

  static PlatformPolygon _platformPolygonFromPolygon(Polygon polygon) {
    final List<PlatformLatLng> points = polygon.points
        .map(_platformLatLngFromLatLng)
        .toList();
    final List<List<PlatformLatLng>> holes = polygon.holes.map((
      List<LatLng> hole,
    ) {
      return hole.map(_platformLatLngFromLatLng).toList();
    }).toList();
    return PlatformPolygon(
      polygonId: polygon.polygonId.value,
      fillColor: polygon.fillColor.toARGB32(),
      points: points,
      holes: holes,
      strokeColor: polygon.strokeColor.toARGB32(),
      strokeWidth: polygon.strokeWidth,
      zIndex: polygon.zIndex,
      visible: polygon.visible,
    );
  }

  static PlatformPolygonUpdates _platformPolygonUpdatesFromPolygon(
    PolygonUpdates polygonUpdates,
  ) {
    return PlatformPolygonUpdates(
      toAdd: polygonUpdates.objectsToAdd
          .map(_platformPolygonFromPolygon)
          .toList(),
      toChange: polygonUpdates.objectsToChange
          .map(_platformPolygonFromPolygon)
          .toList(),
      toRemove: polygonUpdates.polygonIdsToRemove
          .map((PolygonId id) => id.value)
          .toList(),
    );
  }

  static PlatformPolyline _platformPolylineFromPolyline(Polyline polyline) {
    final List<PlatformLatLng> points = polyline.points
        .map(_platformLatLngFromLatLng)
        .toList();
    return PlatformPolyline(
      // The Dart [Polyline] model does not expose `consumeTapEvents`; a tap is
      // claimed by the polyline exactly when an [Polyline.onTap] handler is
      // registered, so that the map does not receive the same tap twice.
      consumesTapEvents: polyline.onTap != null,
      polylineId: polyline.polylineId.value,
      points: points,
      color: polyline.color.toARGB32(),
      width: polyline.width,
      visible: polyline.visible,
      geodesic: polyline.geodesic,
      zIndex: polyline.zIndex,
      isDotted: polyline.isDotted,
      lineCapType: _platformLineCapTypeFromLineCapType(polyline.lineCapType),
      lineJoinType: _platformLineJoinTypeFromLineJoinType(
        polyline.lineJoinType,
      ),
      dottedLineType: _platformDottedLineTypeFromDottedLineType(
        polyline.dottedLineType,
      ),
    );
  }

  static PlatformPolylineUpdates _platformPolylineUpdatesFromPolylineUpdates(
    PolylineUpdates polylineUpdates,
  ) {
    return PlatformPolylineUpdates(
      toAdd: polylineUpdates.polylinesToAdd
          .map(_platformPolylineFromPolyline)
          .toList(),
      toChange: polylineUpdates.polylinesToChange
          .map(_platformPolylineFromPolyline)
          .toList(),
      toRemove: polylineUpdates.polylineIdsToRemove
          .map((PolylineId id) => id.value)
          .toList(),
    );
  }

  static PlatformClusterManagerUpdates
  _platformClusterManagersUpdatesFromClusterUpdates(
    ClusterManagerUpdates updates,
  ) {
    return PlatformClusterManagerUpdates(
      toAdd: updates.clusterManagersToAdd
          .map(_platformClusterManagerFromClusterManager)
          .toList(),
      toChange: updates.clusterManagersToChange
          .map(_platformClusterManagerFromClusterManager)
          .toList(),
      toRemove: updates.clusterManagerIdsToRemove
          .map((ClusterManagerId id) => id.value)
          .toList(),
    );
  }

  static PlatformCircle _platformCircleFromCircle(Circle circle) {
    return PlatformCircle(
      circleId: circle.circleId.value,
      center: _platformLatLngFromLatLng(circle.center),
      radius: circle.radius,
      strokeColor: circle.strokeColor.toARGB32(),
      fillColor: circle.fillColor.toARGB32(),
      strokeWidth: circle.strokeWidth,
      visible: circle.visible,
      zIndex: circle.zIndex,
      isDotted: circle.isDotted,
    );
  }

  static PlatformCircleUpdates _platformCircleUpdatesFromCircleUpdates(
    CircleUpdates circleUpdates,
  ) {
    return PlatformCircleUpdates(
      toAdd: circleUpdates.circlesToAdd.map(_platformCircleFromCircle).toList(),
      toChange: circleUpdates.circlesToChange
          .map(_platformCircleFromCircle)
          .toList(),
      toRemove: circleUpdates.circleIdsToRemove
          .map((CircleId id) => id.value)
          .toList(),
    );
  }

  static PlatformGroundOverlay _platformGroundOverlayFromGroundOverlay(
    GroundOverlay overlay,
  ) {
    return PlatformGroundOverlay(
      id: overlay.groundOverlayId.value,
      image: _platformBitmapFromBitmapDescriptor(overlay.image),
      position: overlay.position == null
          ? null
          : _platformLatLngFromLatLng(overlay.position!),
      bounds: overlay.bounds == null
          ? null
          : _platformLatLngBoundsFromLatLngBounds(overlay.bounds!),
      width: overlay.width,
      height: overlay.height,
      anchor: PlatformDoublePair(x: overlay.anchor.dx, y: overlay.anchor.dy),
      bearing: overlay.bearing,
      transparency: overlay.transparency,
      zIndex: overlay.zIndex,
      visible: overlay.visible,
    );
  }

  static PlatformGroundOverlayUpdates
  _platformGroundOverlayUpdatesFromGroundOverlayUpdates(
    GroundOverlayUpdates updates,
  ) {
    return PlatformGroundOverlayUpdates(
      toAdd: updates.groundOverlaysToAdd
          .map(_platformGroundOverlayFromGroundOverlay)
          .toList(),
      toChange: updates.groundOverlaysToChange
          .map(_platformGroundOverlayFromGroundOverlay)
          .toList(),
      toRemove: updates.groundOverlayIdsToRemove
          .map((GroundOverlayId id) => id.value)
          .toList(),
    );
  }

  static PlatformHeatmap _platformHeatmapFromHeatmap(Heatmap heatmap) {
    return PlatformHeatmap(
      id: heatmap.heatmapId.value,
      data: heatmap.data
          .map(_platformWeightedLatLngFromWeightedLatLng)
          .toList(),
      gradient: _platformHeatmapGradientFromHeatmapGradient(heatmap.gradient),
      opacity: heatmap.opacity,
      radius: heatmap.radius.radius,
      visible: heatmap.visible,
    );
  }

  static PlatformHeatmapGradient? _platformHeatmapGradientFromHeatmapGradient(
    HeatmapGradient? gradient,
  ) {
    if (gradient == null) {
      return null;
    }
    return PlatformHeatmapGradient(
      colors: gradient.colors
          .map((HeatmapGradientColor c) => c.color.toARGB32())
          .toList(),
      startPoints: gradient.colors
          .map((HeatmapGradientColor c) => c.startPoint)
          .toList(),
    );
  }

  static PlatformHeatmapUpdates _platformHeatmapUpdatesFromHeatmapUpdates(
    HeatmapUpdates updates,
  ) {
    return PlatformHeatmapUpdates(
      toAdd: updates.heatmapsToAdd.map(_platformHeatmapFromHeatmap).toList(),
      toChange: updates.heatmapsToChange
          .map(_platformHeatmapFromHeatmap)
          .toList(),
      toRemove: updates.heatmapIdsToRemove
          .map((HeatmapId id) => id.value)
          .toList(),
    );
  }

  static PlatformTileOverlay _platformTileOverlayFromTileOverlay(
    TileOverlay overlay,
  ) => PlatformTileOverlay(
    id: overlay.tileOverlayId.value,
    tileSize: overlay.tileSize,
    zIndex: overlay.zIndex,
    visible: overlay.visible,
  );

  static PlatformTileOverlayUpdates
  _platformTileOverlayUpdatesFromTileOverlayUpdates(
    TileOverlayUpdates updates,
  ) => PlatformTileOverlayUpdates(
    toAdd: updates.tileOverlaysToAdd
        .map(_platformTileOverlayFromTileOverlay)
        .toList(),
    toChange: updates.tileOverlaysToChange
        .map(_platformTileOverlayFromTileOverlay)
        .toList(),
    toRemove: updates.tileOverlayIdsToRemove
        .map((TileOverlayId id) => id.value)
        .toList(),
  );

  static PlatformCameraUpdate _platformCameraUpdateFromCameraUpdate(
    CameraUpdate update,
  ) {
    switch (update.updateType) {
      case CameraUpdateType.newCameraPosition:
        update as CameraUpdateNewCameraPosition;
        return PlatformCameraUpdate(
          cameraUpdate: PlatformCameraUpdateNewCameraPosition(
            cameraPosition: _platformCameraPositionFromCameraPosition(
              update.position,
            ),
          ),
        );
      case CameraUpdateType.newLatLng:
        update as CameraUpdateNewLatLng;
        return PlatformCameraUpdate(
          cameraUpdate: PlatformCameraUpdateNewLatLng(
            latLng: _platformLatLngFromLatLng(update.target),
          ),
        );
      case CameraUpdateType.newLatLngZoom:
        update as CameraUpdateNewLatLngZoom;
        return PlatformCameraUpdate(
          cameraUpdate: PlatformCameraUpdateNewLatLngZoom(
            latLng: _platformLatLngFromLatLng(update.latLng),
            zoom: update.zoom,
          ),
        );
      case CameraUpdateType.newLatLngBounds:
        update as CameraUpdateNewLatLngBounds;
        return PlatformCameraUpdate(
          cameraUpdate: PlatformCameraUpdateNewLatLngBounds(
            bounds: _platformLatLngBoundsFromLatLngBounds(update.bounds)!,
            padding: update.padding,
          ),
        );
      case CameraUpdateType.zoomTo:
        update as CameraUpdateZoomTo;
        return PlatformCameraUpdate(
          cameraUpdate: PlatformCameraUpdateZoomTo(zoom: update.zoom),
        );
      case CameraUpdateType.zoomBy:
        update as CameraUpdateZoomBy;
        return PlatformCameraUpdate(
          cameraUpdate: PlatformCameraUpdateZoomBy(
            amount: update.amount,
            focus: update.focus == null
                ? null
                : _platformPairFromOffset(update.focus!),
          ),
        );
      case CameraUpdateType.zoomIn:
        update as CameraUpdateZoomIn;
        return PlatformCameraUpdate(
          cameraUpdate: PlatformCameraUpdateZoom(out: false),
        );
      case CameraUpdateType.zoomOut:
        update as CameraUpdateZoomOut;
        return PlatformCameraUpdate(
          cameraUpdate: PlatformCameraUpdateZoom(out: true),
        );
      case CameraUpdateType.scrollBy:
        update as CameraUpdateScrollBy;
        return PlatformCameraUpdate(
          cameraUpdate: PlatformCameraUpdateScrollBy(
            dx: update.dx,
            dy: update.dy,
          ),
        );
    }
  }

  static PlatformInfoWindow _platformInfoWindowFromInfoWindow(
    InfoWindow window,
  ) {
    return PlatformInfoWindow(
      title: window.title,
      snippet: window.snippet,
      anchor: _platformPairFromOffset(window.anchor),
    );
  }

  static PlatformLatLng _platformLatLngFromLatLng(LatLng latLng) {
    return PlatformLatLng(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );
  }

  static PlatformMarker _platformMarkerFromMarker(Marker marker) {
    return PlatformMarker(
      alpha: marker.alpha,
      anchor: _platformPairFromOffset(marker.anchor),
      consumeTapEvents: marker.consumeTapEvents,
      draggable: marker.draggable,
      icon: _platformBitmapFromBitmapDescriptor(marker.icon),
      position: _platformLatLngFromLatLng(marker.position),
      rotation: marker.rotation,
      visible: marker.visible,
      infoWindow: _platformInfoWindowFromInfoWindow(marker.infoWindow),
      zIndex: marker.zIndex,
      markerId: marker.markerId.value,
      clusterManagerId: marker.clusterManagerId?.value,
    );
  }

  static PlatformDoublePair _platformPairFromOffset(Offset offset) {
    return PlatformDoublePair(x: offset.dx, y: offset.dy);
  }
}

@visibleForTesting
class HostMapMessageHandler implements MapsCallbackApi {
  HostMapMessageHandler(
    this.mapId,
    this.streamController, {
    required this.tileOverlayProvider,
  }) {
    MapsCallbackApi.setUp(this, messageChannelSuffix: mapId.toString());
  }

  /// The map ID this handler listens for events from.
  final int mapId;

  /// The controller used to broadcast map events coming from the
  /// host platform.
  final StreamController<MapEvent<Object?>> streamController;

  /// The callback to get a tile overlay for the corresponding map.
  final TileOverlay? Function(TileOverlayId tileOverlayId) tileOverlayProvider;

  /// Removes the handler for native messages.
  void dispose() {
    MapsCallbackApi.setUp(null, messageChannelSuffix: mapId.toString());
  }

  @override
  Future<PlatformTile> getTileOverlayTile(
    String tileOverlayId,
    PlatformTileCoordinate point,
    int zoom,
  ) async {
    final TileOverlay? tileOverlay = tileOverlayProvider(
      TileOverlayId(tileOverlayId),
    );
    final TileProvider? tileProvider = tileOverlay?.tileProvider;
    final Tile tile = tileProvider == null
        ? TileProvider.noTile
        : await tileProvider.getTile(point.x, point.y, zoom);
    return _platformTileFromTile(tile);
  }

  @override
  void onCameraMove(PlatformCameraPosition cameraPosition) {
    streamController.add(
      CameraMoveEvent(
        mapId,
        CameraPosition(
          target: _latLngFromPlatformLatLng(cameraPosition.target),
          bearing: cameraPosition.bearing,
          tilt: cameraPosition.tilt,
          zoom: cameraPosition.zoom,
        ),
      ),
    );
  }

  @override
  void onCameraMoveEnd(PlatformCameraPosition cameraPosition) {
    streamController.add(
      CameraMoveEndEvent(
        mapId,
        CameraPosition(
          target: _latLngFromPlatformLatLng(cameraPosition.target),
          bearing: cameraPosition.bearing,
          tilt: cameraPosition.tilt,
          zoom: cameraPosition.zoom,
        ),
      ),
    );
  }

  @override
  void onClusterTap(PlatformCluster cluster) {
    streamController.add(
      ClusterTapEvent(
        mapId,
        Cluster(
          ClusterManagerId(cluster.clusterManagerId),
          // See comment in messages.dart for why this is force-unwrapped.
          cluster.markerIds.map((String? id) => MarkerId(id!)).toList(),
          position: _latLngFromPlatformLatLng(cluster.position),
          bounds: _latLngBoundsFromPlatformLatLngBounds(cluster.bounds),
        ),
      ),
    );
  }

  @override
  void onInfoWindowTap(String markerId) {
    streamController.add(InfoWindowTapEvent(mapId, MarkerId(markerId)));
  }

  @override
  void onLongPress(PlatformLatLng position) {
    streamController.add(
      MapLongPressEvent(mapId, _latLngFromPlatformLatLng(position)),
    );
  }

  @override
  void onMarkerDrag(String markerId, PlatformLatLng position) {
    streamController.add(
      MarkerDragEvent(
        mapId,
        _latLngFromPlatformLatLng(position),
        MarkerId(markerId),
      ),
    );
  }

  @override
  void onMarkerDragEnd(String markerId, PlatformLatLng position) {
    streamController.add(
      MarkerDragEndEvent(
        mapId,
        _latLngFromPlatformLatLng(position),
        MarkerId(markerId),
      ),
    );
  }

  @override
  void onMarkerDragStart(String markerId, PlatformLatLng position) {
    streamController.add(
      MarkerDragStartEvent(
        mapId,
        _latLngFromPlatformLatLng(position),
        MarkerId(markerId),
      ),
    );
  }

  @override
  void onMarkerTap(String markerId) {
    streamController.add(MarkerTapEvent(mapId, MarkerId(markerId)));
  }

  @override
  void onMyLocationChange(PlatformMyLocation location) {
    streamController.add(
      MyLocationChangedEvent(
        mapId,
        AmapMyLocation(
          position: LatLng(location.latitude, location.longitude),
          accuracyMeters: location.accuracy,
          altitudeMeters: location.altitude,
          speedMetersPerSecond: location.speed,
          bearingDegrees: location.bearing,
          timestamp: location.timestamp == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(location.timestamp!),
        ),
      ),
    );
  }

  @override
  void onPolygonTap(String polygonId) {
    // TODO: implement onPolygonTap
  }

  @override
  void onPolylineTap(String polylineId) {
    streamController.add(PolylineTapEvent(mapId, PolylineId(polylineId)));
  }

  @override
  void onTap(PlatformLatLng position) {
    streamController.add(
      MapTapEvent(mapId, _latLngFromPlatformLatLng(position)),
    );
  }
}

PlatformCameraPosition _platformCameraPositionFromCameraPosition(
  CameraPosition position,
) {
  return PlatformCameraPosition(
    bearing: position.bearing,
    target: _platformLatLngFromLatLng(position.target),
    tilt: position.tilt,
    zoom: position.zoom,
  );
}

PlatformLatLng _platformLatLngFromLatLng(LatLng latLng) {
  return PlatformLatLng(latitude: latLng.latitude, longitude: latLng.longitude);
}

LatLng _latLngFromPlatformLatLng(PlatformLatLng latLng) {
  return LatLng(latLng.latitude, latLng.longitude);
}

LatLngBounds _latLngBoundsFromPlatformLatLngBounds(
  PlatformLatLngBounds bounds,
) {
  return LatLngBounds(
    southwest: _latLngFromPlatformLatLng(bounds.southwest),
    northeast: _latLngFromPlatformLatLng(bounds.northeast),
  );
}

PlatformPrivacyStatement _platformPrivacyStatementFromAmapPrivacyStatement(
  AMapPrivacyStatement statement,
) {
  return PlatformPrivacyStatement(
    hasContains: statement.hasContains,
    hasShow: statement.hasShow,
    hasAgree: statement.hasAgree,
  );
}

PlatformWeightedLatLng _platformWeightedLatLngFromWeightedLatLng(
  WeightedLatLng weightedLatLng,
) {
  return PlatformWeightedLatLng(
    point: _platformLatLngFromLatLng(weightedLatLng.point),
    weight: weightedLatLng.weight,
  );
}

PlatformTile _platformTileFromTile(Tile tile) {
  return PlatformTile(width: tile.width, height: tile.height, data: tile.data);
}

PlatformMapOptions _platformMapConfigurationFromMapConfiguration(
  AmapMapConfiguration config,
) {
  return PlatformMapOptions(
    compassEnabled: config.compassEnabled,
    mapType: _platformMapTypeFromMapType(config.mapType),
    scaleControlsEnabled: config.scaleControlsEnabled,
    rotateGesturesEnabled: config.rotateGesturesEnabled,
    scrollGesturesEnabled: config.scrollGesturesEnabled,
    tiltGesturesEnabled: config.tiltGesturesEnabled,
    zoomGesturesEnabled: config.zoomGesturesEnabled,
    myLocationEnabled: config.myLocationEnabled,
    myLocationStyle: _platformMyLocationStyleFromMyLocationStyle(
      config.myLocationStyle,
    ),
    customMapStyle: _platformCustomMapStyleFromCustomMapStyle(
      config.customMapStyle,
    ),
    trafficEnabled: config.trafficEnabled,
    buildingsEnabled: config.buildingsEnabled,
    mapId: config.mapId,
  );
}

PlatformLatLngBounds? _platformLatLngBoundsFromLatLngBounds(
  LatLngBounds? bounds,
) {
  if (bounds == null) {
    return null;
  }
  return PlatformLatLngBounds(
    northeast: _platformLatLngFromLatLng(bounds.northeast),
    southwest: _platformLatLngFromLatLng(bounds.southwest),
  );
}

PlatformMyLocationStyle? _platformMyLocationStyleFromMyLocationStyle(
  AmapMyLocationStyle? style,
) {
  if (style == null) {
    return null;
  }
  return PlatformMyLocationStyle(
    icon: _platformBitmapFromBitmapDescriptor(style.icon),
    anchorU: style.anchorU,
    anchorV: style.anchorV,
    radiusFillColor: style.accuracyFillColor,
    strokeColor: style.accuracyStrokeColor,
    strokeWidth: style.accuracyStrokeWidth,
    myLocationType: _platformMyLocationTypeFromMyLocationType(
      style.myLocationType,
    ),
    interval: style.interval,
    showMyLocation: style.showMyLocation,
    zIndex: style.zIndex,
  );
}

PlatformCustomMapStyle? _platformCustomMapStyleFromCustomMapStyle(
  AmapCustomMapStyle? style,
) {
  if (style == null) {
    return null;
  }
  return PlatformCustomMapStyle(
    styleData: style.styleData,
    styleExtraData: style.styleExtraData,
    styleTextureData: style.styleTextureData,
    styleId: style.styleId,
  );
}

PlatformMyLocationType? _platformMyLocationTypeFromMyLocationType(
  AmapMyLocationType? type,
) {
  switch (type) {
    case null:
      return null;
    case AmapMyLocationType.show:
      return PlatformMyLocationType.show;
    case AmapMyLocationType.locate:
      return PlatformMyLocationType.locate;
    case AmapMyLocationType.follow:
      return PlatformMyLocationType.follow;
    case AmapMyLocationType.mapRotate:
      return PlatformMyLocationType.mapRotate;
    case AmapMyLocationType.locationRotate:
      return PlatformMyLocationType.locationRotate;
    case AmapMyLocationType.locationRotateNoCenter:
      return PlatformMyLocationType.locationRotateNoCenter;
    case AmapMyLocationType.followNoCenter:
      return PlatformMyLocationType.followNoCenter;
    case AmapMyLocationType.mapRotateNoCenter:
      return PlatformMyLocationType.mapRotateNoCenter;
  }
}

PlatformBitmap _platformBitmapFromBitmapDescriptor(
  BitmapDescriptor? descriptor,
) {
  return switch (descriptor) {
    DefaultMarker() => PlatformBitmap(bitmap: PlatformBitmapDefaultMarker()),
    AssetMapBitmap(
      :final assetName,
      :final bitmapScaling,
      :final imagePixelRatio,
      :final width,
      :final height,
    ) =>
      PlatformBitmap(
        bitmap: PlatformBitmapAssetMap(
          assetName: assetName,
          bitmapScaling: _platformMapBitmapScalingFromMapBitmapScaling(
            bitmapScaling,
          ),
          imagePixelRatio: imagePixelRatio,
          width: width,
          height: height,
        ),
      ),
    BytesMapBitmap(
      :final byteData,
      :final bitmapScaling,
      :final imagePixelRatio,
      :final width,
      :final height,
    ) =>
      PlatformBitmap(
        bitmap: PlatformBitmapBytesMap(
          byteData: byteData,
          bitmapScaling: _platformMapBitmapScalingFromMapBitmapScaling(
            bitmapScaling,
          ),
          imagePixelRatio: imagePixelRatio,
          width: width,
          height: height,
        ),
      ),
    // TODO: Handle this case.
    null => throw UnimplementedError(),
  };
}

PlatformMapBitmapScaling _platformMapBitmapScalingFromMapBitmapScaling(
  MapBitmapScaling scaling,
) {
  switch (scaling) {
    case MapBitmapScaling.auto:
      return PlatformMapBitmapScaling.auto;
    case MapBitmapScaling.none:
      return PlatformMapBitmapScaling.none;
  }
}

PlatformLineCapType _platformLineCapTypeFromLineCapType(AmapLineCapType type) {
  switch (type) {
    case AmapLineCapType.butt:
      return PlatformLineCapType.butt;
    case AmapLineCapType.round:
      return PlatformLineCapType.round;
    case AmapLineCapType.square:
      return PlatformLineCapType.square;
  }
}

PlatformLineJoinType _platformLineJoinTypeFromLineJoinType(
  AmapLineJoinType type,
) {
  switch (type) {
    case AmapLineJoinType.bevel:
      return PlatformLineJoinType.bevel;
    case AmapLineJoinType.miter:
      return PlatformLineJoinType.miter;
    case AmapLineJoinType.round:
      return PlatformLineJoinType.round;
  }
}

PlatformDottedLineType _platformDottedLineTypeFromDottedLineType(
  AmapDottedLineType type,
) {
  switch (type) {
    case AmapDottedLineType.circle:
      return PlatformDottedLineType.circle;
    case AmapDottedLineType.square:
      return PlatformDottedLineType.square;
  }
}

PlatformMapType? _platformMapTypeFromMapType(MapType? type) {
  switch (type) {
    case null:
      return null;
    case MapType.normal:
      return PlatformMapType.normal;
    case MapType.satellite:
      return PlatformMapType.satellite;
  }
}
