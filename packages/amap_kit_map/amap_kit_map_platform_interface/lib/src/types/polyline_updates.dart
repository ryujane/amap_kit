import 'package:amap_kit_map_platform_interface/src/types/maps_object_updates.dart';
import 'package:amap_kit_map_platform_interface/src/types/polyline.dart';

/// 折线集合的新增、变更和删除差分。
final class PolylineUpdates extends MapsObjectUpdates<Polyline> {
  /// 根据更新前后的折线集合创建差分。
  PolylineUpdates.from(super.previous, super.current)
    : super.from(objectName: 'polyline');

  /// Set of Polylines to be added in this update.
  Set<Polyline> get polylinesToAdd => objectsToAdd;

  /// Set of PolylineIds to be removed in this update.
  Set<PolylineId> get polylineIdsToRemove =>
      objectIdsToRemove.cast<PolylineId>();

  /// Set of Polylines to be changed in this update.
  Set<Polyline> get polylinesToChange => objectsToChange;
}
