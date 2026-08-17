import 'package:amap_kit_map_platform_interface/src/types/circle.dart';
import 'package:amap_kit_map_platform_interface/src/types/cluster_manager.dart';
import 'package:amap_kit_map_platform_interface/src/types/heatmap.dart';
import 'package:amap_kit_map_platform_interface/src/types/ground_overlay.dart';
import 'package:amap_kit_map_platform_interface/src/types/marker.dart';
import 'package:amap_kit_map_platform_interface/src/types/multi_point_overlay.dart';
import 'package:amap_kit_map_platform_interface/src/types/polygon.dart';
import 'package:amap_kit_map_platform_interface/src/types/polyline.dart';
import 'package:amap_kit_map_platform_interface/src/types/tile_overlay.dart';
import 'package:flutter/foundation.dart';

/// 创建地图时携带的初始覆盖物集合。
///
/// 作为平台接口 [AmapMapPlatform.buildView] 的参数使用，把标记、折线、多边形、
/// 圆形、聚合管理器与海量点图层聚合在一个不可变对象中
@immutable
final class MapObjects {
  /// 创建初始覆盖物集合。
  const MapObjects({
    this.markers = const <Marker>{},
    this.polygons = const <Polygon>{},
    this.polylines = const <Polyline>{},
    this.circles = const <Circle>{},
    this.clusterManagers = const <ClusterManager>{},
    this.multiPointOverlays = const <MultiPointOverlay>{},
    this.heatmaps = const <Heatmap>{},
    this.tileOverlays = const <TileOverlay>{},
    this.groundOverlays = const <GroundOverlay>{},
  });

  /// 参与聚合的 Marker 集合。
  final Set<Marker> markers;

  /// 初始多边形集合。
  final Set<Polygon> polygons;

  /// 初始折线集合。
  final Set<Polyline> polylines;

  /// 初始圆形集合。
  final Set<Circle> circles;

  /// 初始聚合管理器集合。
  final Set<ClusterManager> clusterManagers;

  /// 初始海量点图层集合。
  final Set<MultiPointOverlay> multiPointOverlays;

  /// 初始热力图图层集合。
  final Set<Heatmap> heatmaps;

  /// 初始自定义瓦片图层集合。
  final Set<TileOverlay> tileOverlays;

  /// Initial ground-image overlays.
  final Set<GroundOverlay> groundOverlays;
}
