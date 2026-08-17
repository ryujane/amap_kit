import 'package:amap_kit_map_platform_interface/src/types/heatmap.dart';
import 'package:amap_kit_map_platform_interface/src/types/maps_object_updates.dart';

/// 热力图集合的新增、变更和删除差分。
final class HeatmapUpdates extends MapsObjectUpdates<Heatmap> {
  /// 根据更新前后的热力图集合创建差分。
  HeatmapUpdates.from(super.previous, super.current)
    : super.from(objectName: 'heatmap');

  /// 待新增热力图。
  Set<Heatmap> get heatmapsToAdd => objectsToAdd;

  /// 待删除热力图 ID。
  Set<HeatmapId> get heatmapIdsToRemove => objectIdsToRemove.cast<HeatmapId>();

  /// 待变更热力图。
  Set<Heatmap> get heatmapsToChange => objectsToChange;
}
