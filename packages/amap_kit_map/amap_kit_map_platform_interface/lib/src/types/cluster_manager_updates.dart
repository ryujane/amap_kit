import 'package:amap_kit_map_platform_interface/src/types/cluster_manager.dart';
import 'package:amap_kit_map_platform_interface/src/types/maps_object_updates.dart';

/// 聚合管理器的新增、变更和删除差分。
final class ClusterManagerUpdates extends MapsObjectUpdates<ClusterManager> {
  /// 根据更新前后的聚合管理器集合计算差分。
  ClusterManagerUpdates.from(super.previous, super.current)
    : super.from(objectName: 'clusterManager');

  /// Set of Clusters to be added in this update.
  Set<ClusterManager> get clusterManagersToAdd => objectsToAdd;

  /// Set of ClusterManagerIds to be removed in this update.
  Set<ClusterManagerId> get clusterManagerIdsToRemove =>
      objectIdsToRemove.cast<ClusterManagerId>();

  /// Set of Clusters to be changed in this update.
  Set<ClusterManager> get clusterManagersToChange => objectsToChange;
}
