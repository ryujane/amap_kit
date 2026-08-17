import 'package:amap_kit_map_platform_interface/src/types/circle.dart';
import 'package:amap_kit_map_platform_interface/src/types/maps_object_updates.dart';

/// 圆形集合的新增、变更和删除差分。
final class CircleUpdates extends MapsObjectUpdates<Circle> {
  /// 根据更新前后的圆形集合创建差分。
  CircleUpdates.from(super.previous, super.current)
    : super.from(objectName: 'circle');

  /// Set of Circles to be added in this update.
  Set<Circle> get circlesToAdd => objectsToAdd;

  /// Set of CircleIds to be removed in this update.
  Set<CircleId> get circleIdsToRemove => objectIdsToRemove.cast<CircleId>();

  /// Set of Circles to be changed in this update.
  Set<Circle> get circlesToChange => objectsToChange;
}
