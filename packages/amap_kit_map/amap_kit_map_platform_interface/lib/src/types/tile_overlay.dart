import 'package:amap_kit_map_platform_interface/src/types/maps_object.dart';
import 'package:amap_kit_map_platform_interface/src/types/tile.dart';
import 'package:flutter/foundation.dart';

/// 唯一标识一个瓦片图层。
@immutable
final class TileOverlayId extends MapsObjectId<TileOverlay> {
  /// 创建瓦片图层标识。
  const TileOverlayId(super.value);
}

/// 显示在高德底图之上的自定义图片瓦片集合。
///
/// 当前仅 Android 实现。瓦片坐标遵循 Web Mercator XYZ 规则：缩放级别为
/// `zoom` 时，`x` 从西向东、`y` 从北向南递增。
@immutable
final class TileOverlay implements MapsObject<TileOverlay> {
  /// 创建不可变瓦片图层。
  const TileOverlay({
    required this.tileOverlayId,
    required this.tileProvider,
    this.tileSize = 256,
    this.zIndex = 0,
    this.visible = true,
  }) : assert(tileSize > 0),
       assert(zIndex >= -double.maxFinite && zIndex <= double.maxFinite);

  /// 图层标识。
  final TileOverlayId tileOverlayId;

  /// 按需生成或读取瓦片的 provider。
  final TileProvider tileProvider;

  /// 原生 SDK 请求的正方形瓦片边长，单位为像素。
  final int tileSize;

  /// 图层绘制顺序；值越大越靠上。
  ///
  /// 仅在 Android 生效；iOS 高德 SDK 的覆盖物没有层级属性，按添加顺序绘制。
  final double zIndex;

  /// 是否显示图层。
  final bool visible;

  @override
  TileOverlayId get mapsId => tileOverlayId;

  /// 创建保留未覆盖字段的新瓦片图层。
  TileOverlay copyWith({
    TileProvider? tileProviderParam,
    int? tileSizeParam,
    double? zIndexParam,
    bool? visibleParam,
  }) => TileOverlay(
    tileOverlayId: tileOverlayId,
    tileProvider: tileProviderParam ?? tileProvider,
    tileSize: tileSizeParam ?? tileSize,
    zIndex: zIndexParam ?? zIndex,
    visible: visibleParam ?? visible,
  );

  @override
  TileOverlay clone() => copyWith();

  @override
  Object toJson() => <String, Object>{
    'tileOverlayId': tileOverlayId.value,
    'tileSize': tileSize,
    'zIndex': zIndex,
    'visible': visible,
  };

  @override
  bool operator ==(Object other) =>
      other is TileOverlay &&
      other.tileOverlayId == tileOverlayId &&
      identical(other.tileProvider, tileProvider) &&
      other.tileSize == tileSize &&
      other.zIndex == zIndex &&
      other.visible == visible;

  @override
  int get hashCode => Object.hash(
    tileOverlayId,
    identityHashCode(tileProvider),
    tileSize,
    zIndex,
    visible,
  );
}
