import 'package:amap_kit_core/amap_kit_core.dart';
import 'package:amap_kit_map_platform_interface/src/types/maps_object.dart';
import 'package:flutter/material.dart';

/// 唯一标识一个圆形。
@immutable
final class CircleId extends MapsObjectId<Circle> {
  const CircleId(super.value);
}

/// 地图圆形。
@immutable
final class Circle implements MapsObject<Circle> {
  const Circle({
    required this.circleId,
    required this.center,
    required this.radius,
    this.strokeColor = Colors.black,
    this.fillColor = Colors.transparent,
    this.strokeWidth = 10,
    this.visible = true,
    this.zIndex = 0,
    this.isDotted = false,
  }) : assert(radius > 0),
       assert(strokeWidth > 0);

  final CircleId circleId;
  final LatLng center;
  final double radius;
  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;
  final bool visible;

  /// 图层绘制顺序，值越大越靠上。
  ///
  /// 仅在 Android 生效：Android 高德 SDK 原生支持覆盖物层级。iOS 高德 SDK 的
  /// 覆盖物没有层级属性，图层按添加顺序绘制，此值在 iOS 上不生效。
  final double zIndex;

  /// 是否以虚线绘制圆形边框。
  ///
  /// 对应 Android `CircleOptions.dottedLine` 与 iOS `MACircleRenderer.lineDash`；
  /// 两个平台语义一致。
  final bool isDotted;

  @override
  CircleId get mapsId => circleId;

  @override
  Circle clone() => Circle(
    circleId: circleId,
    center: center,
    radius: radius,
    strokeColor: strokeColor,
    fillColor: fillColor,
    strokeWidth: strokeWidth,
    visible: visible,
    zIndex: zIndex,
    isDotted: isDotted,
  );

  @override
  Object toJson() => <String, Object?>{
    'circleId': circleId.value,
    'center': center.toJson(),
    'radius': radius,
    'strokeColor': strokeColor,
    'fillColor': fillColor,
    'strokeWidth': strokeWidth,
    'visible': visible,
    'zIndex': zIndex,
    'isDotted': isDotted,
  };

  @override
  bool operator ==(Object other) =>
      other is Circle &&
      other.circleId == circleId &&
      other.center == center &&
      other.radius == radius &&
      other.strokeColor == strokeColor &&
      other.fillColor == fillColor &&
      other.strokeWidth == strokeWidth &&
      other.visible == visible &&
      other.zIndex == zIndex &&
      other.isDotted == isDotted;
  @override
  int get hashCode => Object.hash(
    circleId,
    center,
    radius,
    strokeColor,
    fillColor,
    strokeWidth,
    visible,
    zIndex,
    isDotted,
  );
}
