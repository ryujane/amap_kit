import 'package:amap_kit_core/amap_kit_core.dart';
import 'package:amap_kit_map_platform_interface/src/types/maps_object.dart';
import 'package:amap_kit_map_platform_interface/src/types/line_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 唯一标识一条折线。
@immutable
final class PolylineId extends MapsObjectId<Polyline> {
  const PolylineId(super.value);
}

/// 地图折线。
@immutable
final class Polyline implements MapsObject<Polyline> {
  Polyline({
    required this.polylineId,
    required List<LatLng> points,
    this.color = Colors.black,
    this.width = 10,
    this.visible = true,
    this.geodesic = false,
    this.zIndex = 0,
    this.isDotted = false,
    this.lineCapType = AmapLineCapType.round,
    this.lineJoinType = AmapLineJoinType.round,
    this.dottedLineType = AmapDottedLineType.square,
    this.onTap,
  }) : points = List<LatLng>.unmodifiable(points),
       assert(points.length >= 2),
       assert(width > 0);

  final PolylineId polylineId;
  final List<LatLng> points;
  final Color color;
  final double width;
  final bool visible;
  final bool geodesic;

  /// 图层绘制顺序，值越大越靠上。
  ///
  /// 仅在 Android 生效：Android 高德 SDK 原生支持覆盖物层级。iOS 高德 SDK 的
  /// 覆盖物没有层级属性，图层按添加顺序绘制，此值在 iOS 上不生效。
  final double zIndex;

  /// 是否以虚线绘制折线。
  ///
  /// 对应 Android `PolylineOptions.dottedLine` 与 iOS `MAPolylineRenderer.lineDash`；
  /// 两个平台语义一致。
  final bool isDotted;

  /// 折线端点的线帽样式，见 [AmapLineCapType]。
  ///
  /// 默认取圆头，以保证 Android 与 iOS 的默认渲染外观一致。
  ///
  /// 限制：Android 高德 SDK 只在创建折线时应用端点样式；对已创建的折线调用
  /// `setOptions` 更新不会重渲染。因此动态修改该字段在 Android 上不生效，需要
  /// 以新的 [Polyline] 对象替换原对象。
  final AmapLineCapType lineCapType;

  /// 折线拐点处的连接样式，见 [AmapLineJoinType]。
  ///
  /// 默认取圆角连接，与原生 SDK 的默认值一致。
  ///
  /// 限制：与 [lineCapType] 相同，Android 上仅创建折线时生效，动态修改不重渲染。
  final AmapLineJoinType lineJoinType;

  /// 折线虚线段的形状，见 [AmapDottedLineType]。
  ///
  /// 目前 Android 与 iOS 实现都未应用该字段：Android 的 `interpretPolylineOptions`
  /// 未下发 `dottedLineType`，iOS 渲染器也未读取它。虚线开合由 [isDotted] 控制。
  final AmapDottedLineType dottedLineType;

  /// 用户点击此折线时调用。
  ///
  /// 回调不参与 [Polyline] 的相等性与差分判断，因此只替换回调不会触发原生
  /// 覆盖物更新。点击是否命中折线由各平台原生 SDK 决定。
  final VoidCallback? onTap;

  @override
  PolylineId get mapsId => polylineId;

  @override
  Polyline clone() => Polyline(
    polylineId: polylineId,
    points: points,
    color: color,
    width: width,
    visible: visible,
    geodesic: geodesic,
    zIndex: zIndex,
    isDotted: isDotted,
    lineCapType: lineCapType,
    lineJoinType: lineJoinType,
    dottedLineType: dottedLineType,
    onTap: onTap,
  );

  @override
  Object toJson() => <String, Object?>{
    'polylineId': polylineId.value,
    'points': points.map((LatLng point) => point.toJson()).toList(),
    'color': color,
    'width': width,
    'visible': visible,
    'geodesic': geodesic,
    'zIndex': zIndex,
    'isDotted': isDotted,
    'lineCapType': lineCapType.name,
    'lineJoinType': lineJoinType.name,
    'dottedLineType': dottedLineType,
  };

  @override
  bool operator ==(Object other) =>
      other is Polyline &&
      other.polylineId == polylineId &&
      listEquals(other.points, points) &&
      other.color == color &&
      other.width == width &&
      other.visible == visible &&
      other.geodesic == geodesic &&
      other.zIndex == zIndex &&
      other.isDotted == isDotted &&
      other.lineCapType == lineCapType &&
      other.lineJoinType == lineJoinType &&
      other.dottedLineType == dottedLineType;
  @override
  int get hashCode => Object.hash(
    polylineId,
    Object.hashAll(points),
    color,
    width,
    visible,
    geodesic,
    zIndex,
    isDotted,
    lineCapType,
    lineJoinType,
    dottedLineType,
  );
}
