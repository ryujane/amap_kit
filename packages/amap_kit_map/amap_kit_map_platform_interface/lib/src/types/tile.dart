import 'package:flutter/foundation.dart';

/// 一张由 [TileProvider] 返回并交给原生地图绘制的瓦片图片。
@immutable
final class Tile {
  /// 创建不可变瓦片描述。
  const Tile(this.width, this.height, this.data)
    : assert(width == -1 || width > 0),
      assert(height == -1 || height > 0);

  /// 图片宽度，单位为像素。
  final int width;

  /// 图片高度，单位为像素。
  final int height;

  /// 原生平台可解码的图片数据；空值表示该坐标没有瓦片。
  final Uint8List? data;

  /// 转换为可序列化结构。
  Object toJson() => <String, Object?>{
    'width': width,
    'height': height,
    'data': data,
  };
}

/// 按地图瓦片坐标异步提供图片。
abstract class TileProvider {
  /// 表示指定坐标不存在瓦片。
  static const Tile noTile = Tile(-1, -1, null);

  /// 返回 `(x, y, zoom)` 对应的瓦片。
  ///
  /// 坐标原点位于 Web Mercator 世界左上角。Android 原生 SDK 可能并发请求
  /// 多张瓦片，因此实现必须能安全处理并发调用。
  Future<Tile> getTile(int x, int y, int zoom);
}
