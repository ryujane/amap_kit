import 'package:amap_kit_core/amap_kit_core.dart';
import 'package:amap_kit_map_platform_interface/src/types/maps_object.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 唯一标识一个热力图图层。
@immutable
final class HeatmapId extends MapsObjectId<Heatmap> {
  /// 创建热力图标识。
  const HeatmapId(super.value);
}

/// 带权重的热力图坐标点。
@immutable
final class WeightedLatLng {
  /// 创建带权重坐标点。
  const WeightedLatLng(this.point, {this.weight = 1.0})
    : assert(weight > 0),
      assert(weight < double.infinity);

  /// 地理坐标。
  final LatLng point;

  /// 对热力强度的贡献权重，必须为有限正数。
  final double weight;

  /// 转换为可序列化结构。
  Object toJson() => <String, Object>{
    'point': point.toJson(),
    'weight': weight,
  };


  @override
  String toString() {
    return '${objectRuntimeType(this, 'WeightedLatLng')}($point, $weight)';
  }

  @override
  bool operator ==(Object other) =>
      other is WeightedLatLng && other.point == point && other.weight == weight;

  @override
  int get hashCode => Object.hash(point, weight);
}

/// 热力渐变中的一个颜色起点。
@immutable
final class HeatmapGradientColor {
  /// 创建颜色起点；[startPoint] 必须位于 0 到 1。
  const HeatmapGradientColor(this.color, this.startPoint)
    : assert(startPoint >= 0 && startPoint <= 1),
      assert(startPoint < double.infinity);

  /// 此区间使用的颜色。
  final Color color;

  /// 颜色在归一化热力强度中的起点。
  final double startPoint;

  @override
  bool operator ==(Object other) =>
      other is HeatmapGradientColor &&
      other.color == color &&
      other.startPoint == startPoint;

  @override
  int get hashCode => Object.hash(color, startPoint);
}


@immutable
final class HeatmapGradient {
  /// Creates a heatmap gradient with strictly increasing color start points.
  ///
  /// A first start point above zero fades low intensities in from transparent.
  HeatmapGradient(List<HeatmapGradientColor> colors)
    : assert(colors.isNotEmpty),
      assert(_strictlyIncreasing(colors)),
      colors = List<HeatmapGradientColor>.unmodifiable(colors);

  /// 渐变颜色及其起点。
  final List<HeatmapGradientColor> colors;

  static bool _strictlyIncreasing(List<HeatmapGradientColor> colors) {
    for (var index = 1; index < colors.length; index++) {
      if (colors[index - 1].startPoint >= colors[index].startPoint) {
        return false;
      }
    }
    return true;
  }
  Object toJson() {
    final json = <String, Object>{};

    void addIfPresent(String fieldName, Object? value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('colors', colors.map((HeatmapGradientColor e) => e.color.toARGB32()).toList());
    addIfPresent('startPoints', colors.map((HeatmapGradientColor e) => e.startPoint).toList());
    return json;
  }
  @override
  bool operator ==(Object other) =>
      other is HeatmapGradient && listEquals(other.colors, colors);

  @override
  int get hashCode => Object.hashAll(colors);
}

/// 热力点影响半径的跨平台封装。
@immutable
final class HeatmapRadius {
  /// 使用屏幕像素创建半径。
  const HeatmapRadius.fromPixels(this.radius)
    : assert(radius >= 10 && radius <= 50);

  /// 屏幕像素半径。
  final int radius;

  @override
  bool operator ==(Object other) =>
      other is HeatmapRadius && other.radius == radius;

  @override
  int get hashCode => radius.hashCode;
}

/// 在地图上绘制的 Android 热力图图层。
///
/// 当前仅 Android 实现；其他平台调用更新接口时会显式报告不支持。
@immutable
final class Heatmap implements MapsObject<Heatmap> {
  /// 创建不可变热力图。
  Heatmap({
    required this.heatmapId,
    required List<WeightedLatLng> data,
    this.opacity = 0.6,
    this.radius = const HeatmapRadius.fromPixels(12),
    this.visible = true,
    this.gradient,
  }) : assert(opacity >= 0 && opacity <= 1),
       data = List<WeightedLatLng>.unmodifiable(data);

  /// 图层标识。
  final HeatmapId heatmapId;

  /// 热力数据；为空时保留声明状态但不创建原生图层。
  final List<WeightedLatLng> data;

  /// 热力颜色渐变。
  ///
  /// 为空时使用平台默认渐变：Android 使用
  /// `HeatmapTileProvider.DEFAULT_GRADIENT`。
  final HeatmapGradient? gradient;

  /// 图层不透明度，范围为 0 到 1。
  final double opacity;

  /// 热力点影响半径。
  final HeatmapRadius radius;

  /// 是否显示图层。
  final bool visible;

  @override
  HeatmapId get mapsId => heatmapId;

  /// 创建保留未覆盖字段的新热力图。
  Heatmap copyWith({
    List<WeightedLatLng>? dataParam,
    HeatmapGradient? gradientParam,
    double? opacityParam,
    HeatmapRadius? radiusParam,
    bool? visibleParam,
  }) => Heatmap(
    heatmapId: heatmapId,
    data: dataParam ?? data,
    gradient: gradientParam ?? gradient,
    opacity: opacityParam ?? opacity,
    radius: radiusParam ?? radius,
    visible: visibleParam ?? visible,
  );

  @override
  Heatmap clone() => copyWith(dataParam: List<WeightedLatLng>.of(data));

  @override
  Object toJson() => <String, Object>{
    'heatmapId': heatmapId.value,
    'data': data.map((WeightedLatLng value) => value.toJson()).toList(),
    'gradient': ?gradient?.toJson(),
    'opacity': opacity,
    'radius': radius.radius,
    'visible': visible,
  };

  @override
  bool operator ==(Object other) =>
      other is Heatmap &&
      other.heatmapId == heatmapId &&
      listEquals(other.data, data) &&
      other.gradient == gradient &&
      other.opacity == opacity &&
      other.radius == radius &&
      other.visible == visible;

  @override
  int get hashCode => Object.hash(
    heatmapId,
    Object.hashAll(data),
    gradient,
    opacity,
    radius,
    visible,
  );
}
