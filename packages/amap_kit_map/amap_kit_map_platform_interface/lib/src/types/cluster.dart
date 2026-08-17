import 'package:flutter/foundation.dart';

import 'package:amap_kit_map_platform_interface/src/types/cluster_manager.dart';
import 'package:amap_kit_map_platform_interface/src/types/coordinates.dart';
import 'package:amap_kit_map_platform_interface/src/types/marker.dart';

/// 一次聚合点点击对应的成员集合和值域。
@immutable
final class Cluster {
  /// 创建一个聚合点描述。
  Cluster(
    this.clusterManagerId,
    List<MarkerId> markerIds, {
    required this.position,
    required this.bounds,
  }) : markerIds = List<MarkerId>.unmodifiable(markerIds);

  /// 产生该聚合点的管理器。
  final ClusterManagerId clusterManagerId;

  /// 聚合点包含的 Marker 标识。
  final List<MarkerId> markerIds;

  /// 聚合点在地图上的位置。
  final LatLng position;

  /// 包含所有成员 Marker 的边界。
  final LatLngBounds bounds;

  /// 聚合点包含的 Marker 数量。
  int get count => markerIds.length;

  @override
  bool operator ==(Object other) =>
      other is Cluster &&
      other.clusterManagerId == clusterManagerId &&
      listEquals(other.markerIds, markerIds) &&
      other.position == position &&
      other.bounds == bounds;

  @override
  int get hashCode => Object.hash(
    clusterManagerId,
    Object.hashAll(markerIds),
    position,
    bounds,
  );
}
