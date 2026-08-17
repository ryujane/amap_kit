import 'package:amap_kit_map_platform_interface/src/events/events.dart';
import 'package:amap_kit_map_platform_interface/src/types/types.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// AMap 地图原生实现的契约和测试替身入口。
///
/// 平台实现必须继承此类，而不是使用 `implements`，这样新增的带默认实现
/// 方法不会破坏已有平台实现。所有地图命令和事件都通过 [mapId] 隔离。
abstract class AmapMapsFlutterPlatform extends PlatformInterface {
  /// 创建平台契约实例。
  AmapMapsFlutterPlatform() : super(token: _token);

  static final Object _token = Object();
  static AmapMapsFlutterPlatform _instance = _UnsupportedAmapMapPlatform();

  /// 当前默认平台实现。
  static AmapMapsFlutterPlatform get instance => _instance;

  /// 设置默认平台实现。
  static set instance(AmapMapsFlutterPlatform value) {
    PlatformInterface.verify(value, _token);
    _instance = value;
  }

  /// 构建平台地图视图。
  ///
  /// 平台实现负责创建 `AndroidView` 或 `UiKitView`，并在视图可以初始化时
  /// 调用 [onPlatformViewCreated]。Widget 层面的配置（初始相机、文本方向、
  /// 手势识别器）由 [widgetConfiguration] 提供，地图持续配置由 [mapConfiguration]
  /// 提供，初始覆盖物由 [mapObjects] 提供，并会在 [init] 中提交到原生地图。
  Widget buildView(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    AmapMapConfiguration mapConfiguration = const AmapMapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) => throw UnimplementedError('buildView() has not been implemented.');

  /// 初始化已经创建的平台地图实例。
  Future<void> init(int mapId) =>
      throw UnimplementedError('init() has not been implemented.');

  /// 更新指定地图持续配置
  Future<void> updateMapConfiguration(
    AmapMapConfiguration configuration, {
    required int mapId,
  }) => throw UnimplementedError(
    'updateMapConfiguration() has not been implemented.',
  );

  /// 立即改变指定地图的相机。
  Future<void> moveCamera(CameraUpdate update, {required int mapId}) =>
      throw UnimplementedError('moveCamera() has not been implemented.');

  /// 动画改变指定地图的相机。
  Future<void> animateCamera(
    CameraUpdate update, {
    required int mapId,
    Duration? duration,
  }) => throw UnimplementedError('animateCamera() has not been implemented.');

  Future<void> animateCameraWithConfiguration(
    CameraUpdate cameraUpdate,
    CameraUpdateAnimationConfiguration configuration, {
    required int mapId,
  }) => throw UnimplementedError(
    'animateCameraWithConfiguration() has not been implemented.',
  );

  /// 返回当前可见区域。
  Future<LatLngBounds> getVisibleRegion({required int mapId}) =>
      throw UnimplementedError('getVisibleRegion() has not been implemented.');

  /// 差分更新指定地图的聚合管理器。
  Future<void> updateClusterManagers(
    ClusterManagerUpdates updates, {
    required int mapId,
  }) => throw UnimplementedError(
    'updateClusterManagers() has not been implemented.',
  );

  /// 差分更新指定地图的标记。
  Future<void> updateMarkers(MarkerUpdates updates, {required int mapId}) =>
      throw UnimplementedError('updateMarkers() has not been implemented.');

  /// 差分更新指定地图的折线。
  Future<void> updatePolylines(PolylineUpdates updates, {required int mapId}) =>
      throw UnimplementedError('updatePolylines() has not been implemented.');

  /// 差分更新指定地图的多边形。
  Future<void> updatePolygons(PolygonUpdates updates, {required int mapId}) =>
      throw UnimplementedError('updatePolygons() has not been implemented.');

  /// 差分更新指定地图的圆形。
  Future<void> updateCircles(CircleUpdates updates, {required int mapId}) =>
      throw UnimplementedError('updateCircles() has not been implemented.');

  /// 差分更新指定地图的热力图。
  ///
  /// 当前仅 Android 实现；未支持的平台必须显式失败。
  Future<void> updateHeatmaps(HeatmapUpdates updates, {required int mapId}) =>
      throw UnsupportedError('Heatmaps are only supported on Android.');

  /// 同步指定地图的自定义瓦片图层全集。
  ///
  /// 平台实现需要对比上一状态计算差分，并缓存当前状态，供后续同步使用；
  /// 调用方直接提供完整集合，不做增量计算。
  Future<void> updateTileOverlays({
    required Set<TileOverlay> newTileOverlays,
    required int mapId,
  }) {
    throw UnimplementedError('updateTileOverlays() has not been implemented.');
  }

  /// Diff-updates ground image overlays on the specified map.
  ///
  /// Currently only Android implements this capability.
  Future<void> updateGroundOverlays(
    GroundOverlayUpdates updates, {
    required int mapId,
  }) =>
      throw UnsupportedError('Ground overlays are only supported on Android.');

  /// 清除指定瓦片图层的原生缓存并重新请求当前可见瓦片。
  Future<void> clearTileCache(
    TileOverlayId tileOverlayId, {
    required int mapId,
  }) => throw UnsupportedError('Tile overlays are only supported on Android.');

  /// 差分更新指定地图的海量点图层。
  ///
  /// 新增图层携带完整点集；变更图层携带配置与点级增量。
  Future<void> updateMultiPointOverlays(
    MultiPointOverlayUpdates updates, {
    required int mapId,
  }) => throw UnimplementedError(
    'updateMultiPointOverlays() has not been implemented.',
  );

  /// Programmatically show the Info Window for a [Marker].
  ///
  /// The `markerId` must match one of the markers on the map.
  /// An invalid `markerId` triggers an "Invalid markerId" error.
  ///
  /// * See also:
  ///   * [hideMarkerInfoWindow] to hide the Info Window.
  ///   * [isMarkerInfoWindowShown] to check if the Info Window is showing.
  Future<void> showMarkerInfoWindow(MarkerId markerId, {required int mapId}) {
    throw UnimplementedError(
      'showMarkerInfoWindow() has not been implemented.',
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
  Future<void> hideMarkerInfoWindow(MarkerId markerId, {required int mapId}) {
    throw UnimplementedError(
      'hideMarkerInfoWindow() has not been implemented.',
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
  Future<bool> isMarkerInfoWindowShown(
    MarkerId markerId, {
    required int mapId,
  }) {
    throw UnimplementedError(
      'isMarkerInfoWindowShown() has not been implemented.',
    );
  }

  /// Returns the image bytes of the map.
  ///
  /// Returns null if a snapshot cannot be created.
  Future<Uint8List?> takeSnapshot({
    required int mapId,
    bool failWithStatus = false,
  }) {
    throw UnimplementedError('takeSnapshot() has not been implemented.');
  }

  /// 返回相机开始移动事件。
  Stream<CameraMoveStartedEvent> onCameraMoveStarted({required int mapId}) {
    throw UnimplementedError('onCameraMoveStarted() has not been implemented.');
  }

  /// 返回相机位置变化事件。
  Stream<CameraMoveEndEvent> onCameraMoveEnd({required int mapId}) {
    throw UnimplementedError('onCameraMove() has not been implemented.');
  }

  /// 返回相机位置变化事件。
  Stream<CameraMoveEvent> onCameraMove({required int mapId}) {
    throw UnimplementedError('onCameraMove() has not been implemented.');
  }

  /// 返回地图点击事件。
  Stream<MapTapEvent> onTap({required int mapId}) {
    throw UnimplementedError('onTap() has not been implemented.');
  }

  /// 返回地图长按事件。
  Stream<MapLongPressEvent> onLongPress({required int mapId}) {
    throw UnimplementedError('onLongPress() has not been implemented.');
  }

  /// 返回设备位置变化事件。
  ///
  /// 仅当定位蓝点开启且调用方已获得前台定位权限时，平台才会持续上报位置。
  Stream<MyLocationChangedEvent> onLocationChanged({required int mapId}) {
    throw UnimplementedError('onLocationChanged() has not been implemented.');
  }

  /// An [InfoWindow] has been tapped.
  Stream<InfoWindowTapEvent> onInfoWindowTap({required int mapId}) {
    throw UnimplementedError('onInfoWindowTap() has not been implemented.');
  }

  /// 返回原生地图错误事件。
  Stream<MapErrorEvent> onError({required int mapId}) {
    throw UnimplementedError('onError() has not been implemented.');
  }

  /// 返回聚合点点击事件。
  Stream<ClusterTapEvent> onClusterTap({required int mapId}) {
    throw UnimplementedError('onClusterTap() has not been implemented.');
  }

  /// 返回海量点图层点击事件。
  Stream<MultiPointTapEvent> onMultiPointTap({required int mapId}) =>
      Stream<MultiPointTapEvent>.error(
        UnimplementedError('onMultiPointTap() has not been implemented.'),
      );

  /// 返回标记点击事件。
  Stream<MarkerTapEvent> onMarkerTap({required int mapId}) {
    throw UnimplementedError('onMarkerTap() has not been implemented.');
  }

  /// 返回标记开始拖拽事件。
  Stream<MarkerDragStartEvent> onMarkerDragStart({required int mapId}) {
    throw UnimplementedError('onMarkerDragStart() has not been implemented.');
  }

  /// 返回标记拖拽中的位置变化事件。
  Stream<MarkerDragEvent> onMarkerDrag({required int mapId}) {
    throw UnimplementedError('onMarkerDrag() has not been implemented.');
  }

  /// 返回标记拖拽结束事件。
  Stream<MarkerDragEndEvent> onMarkerDragEnd({required int mapId}) {
    throw UnimplementedError('onMarkerDragEnd() has not been implemented.');
  }

  /// 返回折线点击事件。
  Stream<PolylineTapEvent> onPolylineTap({required int mapId}) {
    throw UnimplementedError('onPolylineTap() has not been implemented.');
  }

  /// 释放指定地图的原生资源和事件监听器。
  void dispose({required int mapId}) =>
      throw UnimplementedError('dispose() has not been implemented.');
}

final class _UnsupportedAmapMapPlatform extends AmapMapsFlutterPlatform {}
