import 'package:amap_kit_map_platform_interface/src/types/marker.dart';
import 'package:amap_kit_map_platform_interface/src/types/maps_object_updates.dart';

/// 标记集合的新增、变更和删除差分。
final class MarkerUpdates extends MapsObjectUpdates<Marker> {
  /// 根据更新前后的标记集合创建差分。
  MarkerUpdates.from(super.previous, super.current)
    : super.from(objectName: 'marker');

  /// Set of Markers to be added in this update.
  Set<Marker> get markersToAdd => objectsToAdd;

  /// Set of MarkerIds to be removed in this update.
  Set<MarkerId> get markerIdsToRemove => objectIdsToRemove.cast<MarkerId>();

  /// Set of Markers to be changed in this update.
  Set<Marker> get markersToChange => objectsToChange;
}
