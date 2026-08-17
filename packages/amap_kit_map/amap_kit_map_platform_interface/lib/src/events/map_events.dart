import 'package:amap_kit_map_platform_interface/amap_kit_map_platform_interface.dart';
import 'package:amap_kit_map_platform_interface/src/types/types.dart';

class MapEvent<T> {
  const MapEvent(this.mapId, this.value);
  final int mapId;
  final T value;
}

/// 相机开始移动。
final class CameraMoveStartedEvent extends MapEvent<void> {
  const CameraMoveStartedEvent(int mapId) : super(mapId, null);
}

/// A `MapEvent` associated to a `position`.
class _PositionedMapEvent<T> extends MapEvent<T> {
  /// Build a Positioned MapEvent, that relates a mapId and a position with a value.
  ///
  /// The `mapId` is the id of the map that triggered the event.
  /// `value` may be `null` in events that don't transport any meaningful data.
  _PositionedMapEvent(int mapId, this.position, T value) : super(mapId, value);

  /// The position where this event happened.
  final LatLng position;
}

/// 相机位置变化。
final class CameraMoveEvent extends MapEvent<CameraPosition> {
  const CameraMoveEvent(super.mapId, super.position);
}

/// 相机停止移动。
final class CameraMoveEndEvent extends MapEvent<CameraPosition> {
  const CameraMoveEndEvent(super.mapId, super.position);
}

/// 用户点击地图。
final class MapTapEvent extends _PositionedMapEvent<void> {
  MapTapEvent(int mapId, LatLng position) : super(mapId, position, null);
}

/// 设备位置变化。
final class MyLocationChangedEvent extends MapEvent<AmapMyLocation> {
  /// 创建位置变化事件。
  const MyLocationChangedEvent(super.mapId, super.location);
}

/// 用户长按地图。
final class MapLongPressEvent extends _PositionedMapEvent<void> {
  MapLongPressEvent(int mapId, LatLng position) : super(mapId, position, null);
}

/// 原生地图初始化或运行时错误。
final class MapErrorEvent extends MapEvent<AmapMapException> {
  const MapErrorEvent(super.mapId, super.error);
}

/// 用户点击聚合点。
final class ClusterTapEvent extends MapEvent<Cluster> {
  /// 创建聚合点点击事件。
  const ClusterTapEvent(super.mapId, super.cluster);
}

/// 用户点击海量点图层中的某个点。
final class MultiPointTapEvent extends MapEvent<MultiPointTap> {
  /// 创建海量点点击事件。
  MultiPointTapEvent(int mapId, this.overlayId, this.tap) : super(mapId, tap);

  /// 被点击点所属的图层标识。
  final MultiPointOverlayId overlayId;

  /// 被点击点的标识与坐标。
  final MultiPointTap tap;
}

/// 用户点击标记。
final class MarkerTapEvent extends MapEvent<MarkerId> {
  /// 创建标记点击事件。
  const MarkerTapEvent(super.mapId, super.markerId);
}

/// 用户开始拖动标记。
final class MarkerDragStartEvent extends _PositionedMapEvent<MarkerId> {
  /// 创建标记开始拖拽事件。
  MarkerDragStartEvent(super.mapId, super.position, super.markerId);
}

/// 用户拖动标记过程中位置发生变化。
final class MarkerDragEvent extends _PositionedMapEvent<MarkerId> {
  /// 创建标记拖拽中事件。
  MarkerDragEvent(super.mapId, super.position, super.markerId);
}

/// 用户结束拖动标记。
final class MarkerDragEndEvent extends _PositionedMapEvent<MarkerId> {
  /// 创建标记拖拽结束事件。
  MarkerDragEndEvent(super.mapId, super.position, super.markerId);
}

/// 用户点击折线。
final class PolylineTapEvent extends MapEvent<PolylineId> {
  /// 创建折线点击事件。
  const PolylineTapEvent(super.mapId, super.polylineId);
}

/// An event fired when an [InfoWindow] is tapped.
class InfoWindowTapEvent extends MapEvent<MarkerId> {
  /// Build an InfoWindowTap Event triggered from the map represented by `mapId`.
  ///
  /// The `value` of this event is a [MarkerId] object that represents the tapped InfoWindow.
  InfoWindowTapEvent(super.mapId, super.markerId);
}

/// An event fired when a [Polygon] is tapped.
class PolygonTapEvent extends MapEvent<PolygonId> {
  /// Build an PolygonTap Event triggered from the map represented by `mapId`.
  ///
  /// The `value` of this event is a [PolygonId] object that represents the tapped Polygon.
  PolygonTapEvent(super.mapId, super.polygonId);
}
