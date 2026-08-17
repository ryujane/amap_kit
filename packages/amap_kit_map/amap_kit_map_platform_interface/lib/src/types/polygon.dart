import 'package:amap_kit_core/amap_kit_core.dart';
import 'package:amap_kit_map_platform_interface/src/types/maps_object.dart';
import 'package:amap_kit_map_platform_interface/src/types/line_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 唯一标识一个多边形。
@immutable
final class PolygonId extends MapsObjectId<Polygon> {
  const PolygonId(super.value);
}

/// 地图多边形。
@immutable
final class Polygon implements MapsObject<Polygon> {
  Polygon({
    required this.polygonId,
    required List<LatLng> points,
    List<List<LatLng>> holes = const <List<LatLng>>[],
    this.strokeColor = Colors.black,
    this.fillColor = Colors.black,
    this.strokeWidth = 10,
    this.visible = true,
    this.zIndex = 0,
    this.lineJoinType = AmapLineJoinType.round,
  }) : points = List<LatLng>.unmodifiable(points),
       holes = List<List<LatLng>>.unmodifiable(
         holes.map((List<LatLng> hole) => List<LatLng>.unmodifiable(hole)),
       ),
       assert(points.length >= 3),
       assert(strokeWidth > 0),
       assert(holes.every((List<LatLng> hole) => hole.length >= 3));

  final PolygonId polygonId;
  final List<LatLng> points;

  /// 多边形内部挖空的孔洞，每个孔洞是一个按顺序连接的闭合同环。
  ///
  /// 对应 Android `PolygonOptions.addHoles` 与 iOS `MAPolygon.interiorPolygons`。
  /// 孔洞必须包含至少 3 个点；不参与填充颜色绘制，但会保留边框样式。
  final List<List<LatLng>> holes;

  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;
  final bool visible;

  /// 图层绘制顺序，值越大越靠上。
  ///
  /// 仅在 Android 生效：Android 高德 SDK 原生支持覆盖物层级。iOS 高德 SDK 的
  /// 覆盖物没有层级属性，图层按添加顺序绘制，此值在 iOS 上不生效。
  final double zIndex;

  /// 多边形边线拐点处的连接样式，见 [AmapLineJoinType]。
  ///
  /// 默认取圆角连接，与原生 SDK 的默认值一致。
  final AmapLineJoinType lineJoinType;

  @override
  PolygonId get mapsId => polygonId;

  @override
  Polygon clone() => Polygon(
    polygonId: polygonId,
    points: points,
    holes: holes,
    strokeColor: strokeColor,
    fillColor: fillColor,
    strokeWidth: strokeWidth,
    visible: visible,
    zIndex: zIndex,
    lineJoinType: lineJoinType,
  );

  @override
  Object toJson() => <String, Object?>{
    'polygonId': polygonId.value,
    'points': points.map((LatLng point) => point.toJson()).toList(),
    'holes': holes
        .map(
          (List<LatLng> hole) =>
              hole.map((LatLng point) => point.toJson()).toList(),
        )
        .toList(),
    'strokeColor': strokeColor,
    'fillColor': fillColor,
    'strokeWidth': strokeWidth,
    'visible': visible,
    'zIndex': zIndex,
    'lineJoinType': lineJoinType.name,
  };

  @override
  bool operator ==(Object other) =>
      other is Polygon &&
      other.polygonId == polygonId &&
      listEquals(other.points, points) &&
      _listEqualsNested(other.holes, holes) &&
      other.strokeColor == strokeColor &&
      other.fillColor == fillColor &&
      other.strokeWidth == strokeWidth &&
      other.visible == visible &&
      other.zIndex == zIndex &&
      other.lineJoinType == lineJoinType;
  @override
  int get hashCode => Object.hash(
    polygonId,
    Object.hashAll(points),
    Object.hashAll(holes.map((List<LatLng> hole) => Object.hashAll(hole))),
    strokeColor,
    fillColor,
    strokeWidth,
    visible,
    zIndex,
    lineJoinType,
  );
}

bool _listEqualsNested(List<List<LatLng>> first, List<List<LatLng>> second) {
  if (first.length != second.length) {
    return false;
  }
  for (int i = 0; i < first.length; i++) {
    if (!listEquals(first[i], second[i])) {
      return false;
    }
  }
  return true;
}
