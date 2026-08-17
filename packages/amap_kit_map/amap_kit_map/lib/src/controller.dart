part of '../amap_kit_map.dart';

class AmapMapController {
  AmapMapController._(this._amapMapState, {required this.mapId}) {
    _connectStreams(mapId);
  }

  /// The mapId for this controller
  final int mapId;

  /// List of active stream subscriptions for map events.
  ///
  /// This list keeps track of all event subscriptions created for the map,
  /// including camera movements, marker interactions, and other map events.
  /// These subscriptions should be disposed when the controller is disposed.
  final List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];

  static Future<AmapMapController> _init(
    int id,
    CameraPosition initialCameraPosition,
    _AmapMapState amapMapState,
  ) async {
    await AmapMapsFlutterPlatform.instance.init(id);
    return AmapMapController._(amapMapState, mapId: id);
  }

  final _AmapMapState _amapMapState;

  void _connectStreams(int mapId) {
    if (_amapMapState.widget.onCameraMoveStarted != null) {
      _streamSubscriptions.add(
        AmapMapsFlutterPlatform.instance
            .onCameraMoveStarted(mapId: mapId)
            .listen((_) => _amapMapState.widget.onCameraMoveStarted!()),
      );
    }
    if (_amapMapState.widget.onCameraMove != null) {
      _streamSubscriptions.add(
        AmapMapsFlutterPlatform.instance
            .onCameraMove(mapId: mapId)
            .listen(
              (CameraMoveEvent e) =>
                  _amapMapState.widget.onCameraMove!(e.value),
            ),
      );
    }
    if (_amapMapState.widget.onCameraMoveEnd != null) {
      _streamSubscriptions.add(
        AmapMapsFlutterPlatform.instance
            .onCameraMoveEnd(mapId: mapId)
            .listen(
              (CameraMoveEndEvent e) =>
                  _amapMapState.widget.onCameraMoveEnd!(e.value),
            ),
      );
    }
    _streamSubscriptions.add(
      AmapMapsFlutterPlatform.instance
          .onMarkerTap(mapId: mapId)
          .listen((MarkerTapEvent e) => _amapMapState.onMarkerTap(e.value)),
    );
    _streamSubscriptions.add(
      AmapMapsFlutterPlatform.instance
          .onMarkerDragStart(mapId: mapId)
          .listen(
            (MarkerDragStartEvent e) =>
                _amapMapState.onMarkerDragStart(e.value, e.position),
          ),
    );
    _streamSubscriptions.add(
      AmapMapsFlutterPlatform.instance
          .onMarkerDrag(mapId: mapId)
          .listen(
            (MarkerDragEvent e) =>
                _amapMapState.onMarkerDrag(e.value, e.position),
          ),
    );
    _streamSubscriptions.add(
      AmapMapsFlutterPlatform.instance
          .onMarkerDragEnd(mapId: mapId)
          .listen(
            (MarkerDragEndEvent e) =>
                _amapMapState.onMarkerDragEnd(e.value, e.position),
          ),
    );
    _streamSubscriptions.add(
      AmapMapsFlutterPlatform.instance
          .onInfoWindowTap(mapId: mapId)
          .listen(
            (InfoWindowTapEvent e) => _amapMapState.onInfoWindowTap(e.value),
          ),
    );
    _streamSubscriptions.add(
      AmapMapsFlutterPlatform.instance
          .onPolylineTap(mapId: mapId)
          .listen((PolylineTapEvent e) => _amapMapState.onPolylineTap(e.value)),
    );
    _streamSubscriptions.add(
      AmapMapsFlutterPlatform.instance
          .onTap(mapId: mapId)
          .listen((MapTapEvent e) => _amapMapState.onTap(e.position)),
    );
    _streamSubscriptions.add(
      AmapMapsFlutterPlatform.instance
          .onLongPress(mapId: mapId)
          .listen(
            (MapLongPressEvent e) => _amapMapState.onLongPress(e.position),
          ),
    );
    _streamSubscriptions.add(
      AmapMapsFlutterPlatform.instance
          .onLocationChanged(mapId: mapId)
          .listen(
            (MyLocationChangedEvent e) =>
                _amapMapState.onLocationChanged(e.value),
          ),
    );
    _streamSubscriptions.add(
      AmapMapsFlutterPlatform.instance
          .onClusterTap(mapId: mapId)
          .listen((ClusterTapEvent e) => _amapMapState.onClusterTap(e.value)),
    );
  }

  /// Updates configuration options of the map user interface.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateMapConfiguration(AmapMapConfiguration update) {
    return AmapMapsFlutterPlatform.instance.updateMapConfiguration(
      update,
      mapId: mapId,
    );
  }

  /// Updates marker configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateMarkers(MarkerUpdates markerUpdates) {
    return AmapMapsFlutterPlatform.instance.updateMarkers(
      markerUpdates,
      mapId: mapId,
    );
  }

  /// Updates cluster manager configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateClusterManagers(
    ClusterManagerUpdates clusterManagerUpdates,
  ) {
    return AmapMapsFlutterPlatform.instance.updateClusterManagers(
      clusterManagerUpdates,
      mapId: mapId,
    );
  }

  /// Updates polygon configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updatePolygons(PolygonUpdates polygonUpdates) {
    return AmapMapsFlutterPlatform.instance.updatePolygons(
      polygonUpdates,
      mapId: mapId,
    );
  }

  /// Updates polyline configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updatePolylines(PolylineUpdates polylineUpdates) {
    return AmapMapsFlutterPlatform.instance.updatePolylines(
      polylineUpdates,
      mapId: mapId,
    );
  }

  /// Updates circle configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateCircles(CircleUpdates circleUpdates) {
    return AmapMapsFlutterPlatform.instance.updateCircles(
      circleUpdates,
      mapId: mapId,
    );
  }

  /// Updates Android heatmap configuration.
  Future<void> _updateHeatmaps(HeatmapUpdates heatmapUpdates) {
    return AmapMapsFlutterPlatform.instance.updateHeatmaps(
      heatmapUpdates,
      mapId: mapId,
    );
  }

  /// Syncs the full set of custom tile overlays on the platform map.
  ///
  /// The platform implementation diffs [newTileOverlays] against the state it
  /// already holds, so callers replace rather than incrementally update.
  Future<void> _updateTileOverlays(Set<TileOverlay> newTileOverlays) {
    return AmapMapsFlutterPlatform.instance.updateTileOverlays(
      newTileOverlays: newTileOverlays,
      mapId: mapId,
    );
  }

  Future<void> _updateGroundOverlays(
    GroundOverlayUpdates groundOverlayUpdates,
  ) {
    return AmapMapsFlutterPlatform.instance.updateGroundOverlays(
      groundOverlayUpdates,
      mapId: mapId,
    );
  }

  /// 清除指定瓦片图层缓存，使当前可见瓦片重新向 provider 请求。
  Future<void> clearTileCache(TileOverlayId tileOverlayId) {
    _checkWidgetMountedOrThrow();
    return AmapMapsFlutterPlatform.instance.clearTileCache(
      tileOverlayId,
      mapId: mapId,
    );
  }

  /// Starts an animated change of the map camera position.
  ///
  /// The [duration] parameter specifies the duration of the animation.
  /// If null, the platform will decide the default value.
  ///
  /// The returned [Future] completes after the change has been started on the
  /// platform side.
  Future<void> animateCamera(CameraUpdate cameraUpdate, {Duration? duration}) {
    _checkWidgetMountedOrThrow();
    return AmapMapsFlutterPlatform.instance.animateCameraWithConfiguration(
      cameraUpdate,
      CameraUpdateAnimationConfiguration(duration: duration),
      mapId: mapId,
    );
  }

  /// Changes the map camera position.
  ///
  /// The returned [Future] completes after the change has been made on the
  /// platform side.
  Future<void> moveCamera(CameraUpdate cameraUpdate) {
    _checkWidgetMountedOrThrow();
    return AmapMapsFlutterPlatform.instance.moveCamera(
      cameraUpdate,
      mapId: mapId,
    );
  }

  /// Return [LatLngBounds] defining the region that is visible in a map.
  Future<LatLngBounds> getVisibleRegion() {
    _checkWidgetMountedOrThrow();
    return AmapMapsFlutterPlatform.instance.getVisibleRegion(mapId: mapId);
  }

  /// Programmatically show the Info Window for a [Marker].
  ///
  /// The `markerId` must match one of the markers on the map.
  /// An invalid `markerId` triggers an "Invalid markerId" error.
  ///
  /// * See also:
  ///   * [hideMarkerInfoWindow] to hide the Info Window.
  ///   * [isMarkerInfoWindowShown] to check if the Info Window is showing.
  Future<void> showMarkerInfoWindow(MarkerId markerId) {
    _checkWidgetMountedOrThrow();
    return AmapMapsFlutterPlatform.instance.showMarkerInfoWindow(
      markerId,
      mapId: mapId,
    );
  }

  /// Programmatically hide the Info Window for a [Marker].
  ///
  /// The `markerId` must match one of the markers on the map.
  /// An invalid `markerId` triggers an "Invalid markerId" error.
  ///
  /// * See also:
  ///   * [showMarkerInfoWindow] to show the Info Window.
  ///   * [isMarkerInfoWindowShown] to check if the Info Window is showing.
  Future<void> hideMarkerInfoWindow(MarkerId markerId) {
    _checkWidgetMountedOrThrow();
    return AmapMapsFlutterPlatform.instance.hideMarkerInfoWindow(
      markerId,
      mapId: mapId,
    );
  }

  /// Returns `true` when the [InfoWindow] is showing, `false` otherwise.
  ///
  /// The `markerId` must match one of the markers on the map.
  /// An invalid `markerId` triggers an "Invalid markerId" error.
  ///
  /// * See also:
  ///   * [showMarkerInfoWindow] to show the Info Window.
  ///   * [hideMarkerInfoWindow] to hide the Info Window.
  Future<bool> isMarkerInfoWindowShown(MarkerId markerId) {
    _checkWidgetMountedOrThrow();
    return AmapMapsFlutterPlatform.instance.isMarkerInfoWindowShown(
      markerId,
      mapId: mapId,
    );
  }

  /// Returns the current zoom level of the map
  // Future<double> getZoomLevel() {
  //   _checkWidgetMountedOrThrow();
  //   return AmapMapPlatform.instance.getZoomLevel(mapId: mapId);
  // }

  /// Returns the image bytes of the map
  Future<Uint8List?> takeSnapshot({bool failWithStatus = false}) {
    _checkWidgetMountedOrThrow();
    return AmapMapsFlutterPlatform.instance.takeSnapshot(
      mapId: mapId,
      failWithStatus: failWithStatus,
    );
  }

  void _checkWidgetMountedOrThrow() {
    if (!_amapMapState.mounted) {
      throw StateError(
        'AmapMapController for map ID $mapId was used after '
        'the associated AmapMap widget had already been disposed.',
      );
    }
  }

  /// Disposes of the platform resources
  void dispose() {
    for (final StreamSubscription<dynamic> streamSubscription
        in _streamSubscriptions) {
      streamSubscription.cancel();
    }
    _streamSubscriptions.clear();
    AmapMapsFlutterPlatform.instance.dispose(mapId: mapId);
  }
}
