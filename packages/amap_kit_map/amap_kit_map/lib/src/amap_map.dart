part of '../amap_kit_map.dart';

typedef MapCreatedCallback = void Function(AmapMapController controller);

int _nextMapCreationId = 0;

/// Error thrown when an unknown map object ID is provided to a method.
class UnknownMapObjectIdError extends Error {
  /// Creates an assertion error with the provided [message].
  UnknownMapObjectIdError(this.objectType, this.objectId, [this.context]);

  /// The name of the map object whose ID is unknown.
  final String objectType;

  /// The unknown maps object ID.
  final MapsObjectId<Object> objectId;

  /// The context where the error occurred.
  final String? context;

  @override
  String toString() {
    if (context != null) {
      return 'Unknown $objectType ID "${objectId.value}" in $context';
    }
    return 'Unknown $objectType ID "${objectId.value}"';
  }
}

/// 原生 AMap 地图视图。
///
/// 该组件必须放在具有有界尺寸的布局中。通过 [onMapCreated] 获得的控制器必须在
/// 不再使用时调用 [AmapMapController.dispose]；组件卸载时也会进行兜底释放。
final class AmapMap extends StatefulWidget {
  /// 创建地图视图。
  const AmapMap({
    required this.apiKey,
    required this.initialCameraPosition,
    required this.privacyStatement,
    this.onMapCreated,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraMoveEnd,
    this.onTap,
    this.onLongPress,
    this.onLocationChanged,
    this.onError,
    this.mapType = MapType.normal,
    this.compassEnabled = true,
    this.scaleControlsEnabled = true,
    this.trafficEnabled = false,
    this.buildingsEnabled = true,
    this.rotateGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.myLocationEnabled = false,
    this.myLocationStyle,
    this.customMapStyle,
    this.clusterManagers = const <ClusterManager>{},
    this.markers = const <Marker>{},
    this.polylines = const <Polyline>{},
    this.polygons = const <Polygon>{},
    this.circles = const <Circle>{},
    this.multiPointOverlays = const <MultiPointOverlay>{},
    this.heatmaps = const <Heatmap>{},
    this.tileOverlays = const <TileOverlay>{},
    this.groundOverlays = const <GroundOverlay>{},
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
    required this.mapId,
    super.key,
  });

  final String apiKey;
  final AMapPrivacyStatement privacyStatement;
  final String mapId;
  final CameraPosition initialCameraPosition;
  final MapCreatedCallback? onMapCreated;
  final VoidCallback? onCameraMoveStarted;
  final ArgumentCallback<CameraPosition>? onCameraMove;
  final ArgumentCallback<CameraPosition>? onCameraMoveEnd;
  final ArgumentCallback<LatLng>? onTap;
  final ArgumentCallback<LatLng>? onLongPress;

  /// 定位蓝点开启时，设备位置变化的回调。
  ///
  /// 需要 [myLocationEnabled] 为 true 且调用方已获得前台定位权限；原生地图会
  /// 持续上报位置更新。位置仅用于当前地图实例，释放后不再回调。
  final ArgumentCallback<AmapMyLocation>? onLocationChanged;

  final ArgumentCallback<AmapMapException>? onError;
  final MapType mapType;
  final bool compassEnabled;
  final bool scaleControlsEnabled;
  final bool trafficEnabled;
  final bool buildingsEnabled;
  final bool rotateGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool tiltGesturesEnabled;
  final bool zoomGesturesEnabled;

  /// 是否显示并启用高德原生定位蓝点。
  ///
  /// 调用方必须先获得前台定位权限；未授权时平台会返回
  /// [AmapMapLocationPermissionException]。
  final bool myLocationEnabled;

  /// Optional appearance for the native AMap location blue dot.
  final AmapMyLocationStyle? myLocationStyle;

  /// 可选的自定义底图样式
  final AmapCustomMapStyle? customMapStyle;

  /// 管理参与聚合的 Marker 集合；每个 Marker 的管理器 ID 必须在此集合中声明。
  final Set<ClusterManager> clusterManagers;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  final Set<Circle> circles;

  /// 使用共享图标渲染大量点的海量点图层；官方建议每层不超过 100,000 个点。
  final Set<MultiPointOverlay> multiPointOverlays;

  /// Android 热力图图层；iOS 暂不支持。
  final Set<Heatmap> heatmaps;

  /// Android 自定义图片瓦片图层；iOS 暂不支持。
  final Set<TileOverlay> tileOverlays;

  /// Android images fixed to geographical bounds or meter-based dimensions.
  final Set<GroundOverlay> groundOverlays;

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  @override
  State<AmapMap> createState() => _AmapMapState();
}

class _AmapMapState extends State<AmapMap> {
  final int _mapId = _nextMapCreationId++;

  final Completer<AmapMapController> _controller =
      Completer<AmapMapController>();

  Map<MarkerId, Marker> _markers = <MarkerId, Marker>{};
  Map<PolygonId, Polygon> _polygons = <PolygonId, Polygon>{};
  Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};
  Map<CircleId, Circle> _circles = <CircleId, Circle>{};
  Map<ClusterManagerId, ClusterManager> _clusterManagers =
      <ClusterManagerId, ClusterManager>{};
  Map<HeatmapId, Heatmap> _heatmaps = <HeatmapId, Heatmap>{};
  Map<GroundOverlayId, GroundOverlay> _groundOverlays =
      <GroundOverlayId, GroundOverlay>{};
  late AmapMapConfiguration _mapConfiguration;

  @override
  void initState() {
    super.initState();
    _mapConfiguration = _configurationFromMapWidget(widget);
    _clusterManagers = keyByClusterManagerId(widget.clusterManagers);
    _markers = keyByMarkerId(widget.markers);
    _polygons = keyByPolygonId(widget.polygons);
    _polylines = keyByPolylineId(widget.polylines);
    _circles = keyByCircleId(widget.circles);
    _heatmaps = keyByHeatmapId(widget.heatmaps);
    _groundOverlays = keyByGroundOverlayId(widget.groundOverlays);
  }

  @override
  Widget build(BuildContext context) {
    return AmapMapsFlutterPlatform.instance.buildView(
      _mapId,
      onPlatformViewCreated,
      widgetConfiguration: MapWidgetConfiguration(
        initialCameraPosition: widget.initialCameraPosition,
        apiKey: widget.apiKey,
        privacyStatement: widget.privacyStatement,
        gestureRecognizers: widget.gestureRecognizers,
      ),
      mapObjects: MapObjects(
        markers: widget.markers,
        polygons: widget.polygons,
        polylines: widget.polylines,
        circles: widget.circles,
        clusterManagers: widget.clusterManagers,
        heatmaps: widget.heatmaps,
        tileOverlays: widget.tileOverlays,
        groundOverlays: widget.groundOverlays,
      ),
      mapConfiguration: _mapConfiguration,
    );
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  void didUpdateWidget(AmapMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    _refreshStateFromWidget();
  }

  Future<void> _disposeController() async {
    final AmapMapController controller = await _controller.future;
    controller.dispose();
  }

  Future<void> _refreshStateFromWidget() async {
    final AmapMapController controller = await _controller.future;
    if (!mounted) {
      return;
    }
    _updateOptions(controller);
    _updateClusterManagers(controller);
    _updateMarkers(controller);
    _updatePolygons(controller);
    _updatePolylines(controller);
    _updateCircles(controller);
    _updateHeatmaps(controller);
    _updateTileOverlays(controller);
    _updateGroundOverlays(controller);
  }

  void _updateOptions(AmapMapController controller) {
    final AmapMapConfiguration newConfig = _configurationFromMapWidget(widget);
    final AmapMapConfiguration updates = newConfig.diffFrom(_mapConfiguration);
    if (updates.isEmpty) {
      return;
    }
    unawaited(controller._updateMapConfiguration(updates));
    _mapConfiguration = newConfig;
  }

  void _updateMarkers(AmapMapController controller) {
    final MarkerUpdates updates = MarkerUpdates.from(
      _markers.values.toSet(),
      widget.markers,
    );
    if (!updates.isEmpty) {
      unawaited(controller._updateMarkers(updates));
    }
    _markers = keyByMarkerId(widget.markers);
  }

  void _updateClusterManagers(AmapMapController controller) {
    final ClusterManagerUpdates updates = ClusterManagerUpdates.from(
      _clusterManagers.values.toSet(),
      widget.clusterManagers,
    );
    if (!updates.isEmpty) {
      unawaited(controller._updateClusterManagers(updates));
    }
    _clusterManagers = keyByClusterManagerId(widget.clusterManagers);
  }

  void _updatePolygons(AmapMapController controller) {
    final PolygonUpdates updates = PolygonUpdates.from(
      _polygons.values.toSet(),
      widget.polygons,
    );
    if (!updates.isEmpty) {
      unawaited(controller._updatePolygons(updates));
    }
    _polygons = keyByPolygonId(widget.polygons);
  }

  void _updatePolylines(AmapMapController controller) {
    final PolylineUpdates updates = PolylineUpdates.from(
      _polylines.values.toSet(),
      widget.polylines,
    );
    if (!updates.isEmpty) {
      unawaited(controller._updatePolylines(updates));
    }
    _polylines = keyByPolylineId(widget.polylines);
  }

  void _updateCircles(AmapMapController controller) {
    final CircleUpdates updates = CircleUpdates.from(
      _circles.values.toSet(),
      widget.circles,
    );
    if (!updates.isEmpty) {
      unawaited(controller._updateCircles(updates));
    }
    _circles = keyByCircleId(widget.circles);
  }

  void _updateHeatmaps(AmapMapController controller) {
    unawaited(
      controller._updateHeatmaps(
        HeatmapUpdates.from(_heatmaps.values.toSet(), widget.heatmaps),
      ),
    );
    _heatmaps = keyByHeatmapId(widget.heatmaps);
  }

  void _updateTileOverlays(AmapMapController controller) {
    unawaited(controller._updateTileOverlays(widget.tileOverlays));
  }

  void _updateGroundOverlays(AmapMapController controller) {
    unawaited(
      controller._updateGroundOverlays(
        GroundOverlayUpdates.from(
          _groundOverlays.values.toSet(),
          widget.groundOverlays,
        ),
      ),
    );
    _groundOverlays = keyByGroundOverlayId(widget.groundOverlays);
  }

  Future<void> onPlatformViewCreated(int id) async {
    final AmapMapController controller = await AmapMapController._init(
      id,
      widget.initialCameraPosition,
      this,
    );
    _controller.complete(controller);
    if (mounted) {
      _updateTileOverlays(controller);
      final MapCreatedCallback? onMapCreated = widget.onMapCreated;
      if (onMapCreated != null) {
        onMapCreated(controller);
      }
    }
  }

  void onMarkerTap(MarkerId markerId) {
    final Marker? marker = _markers[markerId];
    if (marker == null) {
      throw UnknownMapObjectIdError('marker', markerId, 'onTap');
    }
    final VoidCallback? onTap = marker.onTap;
    if (onTap != null) {
      onTap();
    }
  }

  void onMarkerDragStart(MarkerId markerId, LatLng position) {
    final Marker? marker = _markers[markerId];
    if (marker == null) {
      throw UnknownMapObjectIdError('marker', markerId, 'onDragStart');
    }
    final ValueChanged<LatLng>? onDragStart = marker.onDragStart;
    if (onDragStart != null) {
      onDragStart(position);
    }
  }

  void onMarkerDrag(MarkerId markerId, LatLng position) {
    final Marker? marker = _markers[markerId];
    if (marker == null) {
      throw UnknownMapObjectIdError('marker', markerId, 'onDrag');
    }
    final ValueChanged<LatLng>? onDrag = marker.onDrag;
    if (onDrag != null) {
      onDrag(position);
    }
  }

  void onMarkerDragEnd(MarkerId markerId, LatLng position) {
    final Marker? marker = _markers[markerId];
    if (marker == null) {
      throw UnknownMapObjectIdError('marker', markerId, 'onDragEnd');
    }
    final ValueChanged<LatLng>? onDragEnd = marker.onDragEnd;
    if (onDragEnd != null) {
      onDragEnd(position);
    }
  }

  void onPolylineTap(PolylineId polylineId) {
    final Polyline? polyline = _polylines[polylineId];
    if (polyline == null) {
      throw UnknownMapObjectIdError('polyline', polylineId, 'onTap');
    }
    final VoidCallback? onTap = polyline.onTap;
    if (onTap != null) {
      onTap();
    }
  }

  void onInfoWindowTap(MarkerId markerId) {
    final Marker? marker = _markers[markerId];
    if (marker == null) {
      throw UnknownMapObjectIdError('marker', markerId, 'InfoWindow onTap');
    }
    final VoidCallback? onTap = marker.infoWindow.onTap;
    if (onTap != null) {
      onTap();
    }
  }

  void onTap(LatLng position) {
    final ArgumentCallback<LatLng>? onTap = widget.onTap;
    if (onTap != null) {
      onTap(position);
    }
  }

  void onLongPress(LatLng position) {
    final ArgumentCallback<LatLng>? onLongPress = widget.onLongPress;
    if (onLongPress != null) {
      onLongPress(position);
    }
  }

  void onLocationChanged(AmapMyLocation location) {
    final ArgumentCallback<AmapMyLocation>? onLocationChanged =
        widget.onLocationChanged;
    if (onLocationChanged != null) {
      onLocationChanged(location);
    }
  }

  void onClusterTap(Cluster cluster) {
    final ClusterManager? clusterManager =
        _clusterManagers[cluster.clusterManagerId];
    if (clusterManager == null) {
      throw UnknownMapObjectIdError(
        'clusterManager',
        cluster.clusterManagerId,
        'onClusterTap',
      );
    }
    final ArgumentCallback<Cluster>? onClusterTap = clusterManager.onClusterTap;
    if (onClusterTap != null) {
      onClusterTap(cluster);
    }
  }
}

AmapMapConfiguration _configurationFromMapWidget(AmapMap map) {
  return AmapMapConfiguration(
    mapType: map.mapType,
    compassEnabled: map.compassEnabled,
    scaleControlsEnabled: map.scaleControlsEnabled,
    trafficEnabled: map.trafficEnabled,
    buildingsEnabled: map.buildingsEnabled,
    rotateGesturesEnabled: map.rotateGesturesEnabled,
    scrollGesturesEnabled: map.scrollGesturesEnabled,
    tiltGesturesEnabled: map.tiltGesturesEnabled,
    zoomGesturesEnabled: map.zoomGesturesEnabled,
    myLocationEnabled: map.myLocationEnabled,
    myLocationStyle: map.myLocationStyle,
    customMapStyle: map.customMapStyle,
    mapId: map.mapId,
  );
}
