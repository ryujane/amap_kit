import 'package:amap_kit_map_platform_interface/src/types/maps_object_updates.dart';
import 'package:amap_kit_map_platform_interface/src/types/polygon.dart';

/// 多边形集合的新增、变更和删除差分。
final class PolygonUpdates extends MapsObjectUpdates<Polygon> {
  /// 根据更新前后的多边形集合创建差分。
  PolygonUpdates.from(super.previous, super.current)
    : super.from(objectName: 'polygon');

  /// Set of Polygons to be added in this update.
  Set<Polygon> get polygonsToAdd => objectsToAdd;

  /// Set of PolygonIds to be removed in this update.
  Set<PolygonId> get polygonIdsToRemove => objectIdsToRemove.cast<PolygonId>();

  /// Set of Polygons to be changed in this update.
  Set<Polygon> get polygonsToChange => objectsToChange;
}
