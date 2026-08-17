import 'package:amap_kit_map_platform_interface/src/types/callbacks.dart';
import 'package:flutter/foundation.dart';

import 'package:amap_kit_map_platform_interface/src/types/cluster.dart';
import 'package:amap_kit_map_platform_interface/src/types/maps_object.dart';

/// 唯一标识一个聚合管理器。
@immutable
final class ClusterManagerId extends MapsObjectId<ClusterManager> {
  /// 创建一个聚合管理器标识。
  const ClusterManagerId(super.value);
}

/// 处理一组共享 [clusterManagerId] 的 Marker 聚合。
@immutable
final class ClusterManager implements MapsObject<ClusterManager> {
  /// 创建一个聚合管理器。
  const ClusterManager({required this.clusterManagerId, this.onClusterTap});

  /// 当前管理器的稳定标识。
  final ClusterManagerId clusterManagerId;

  /// 用户点击聚合点时调用。
  final ArgumentCallback<Cluster>? onClusterTap;

  @override
  ClusterManagerId get mapsId => clusterManagerId;

  @override
  ClusterManager clone() => ClusterManager(
    clusterManagerId: clusterManagerId,
    onClusterTap: onClusterTap,
  );

  /// 复制管理器，并可替换聚合点点击回调。
  ClusterManager copyWith({
    void Function(Cluster cluster)? onClusterTapParam,
  }) => ClusterManager(
    clusterManagerId: clusterManagerId,
    onClusterTap: onClusterTapParam ?? onClusterTap,
  );

  @override
  Object toJson() => <String, Object>{
    'clusterManagerId': clusterManagerId.value,
  };

  @override
  bool operator ==(Object other) =>
      other is ClusterManager && other.clusterManagerId == clusterManagerId;

  @override
  int get hashCode => clusterManagerId.hashCode;
}
