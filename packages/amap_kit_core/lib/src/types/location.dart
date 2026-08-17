
import 'package:flutter/foundation.dart' show immutable;

/// 表示以角度存储的一对纬度与经度坐标。
@immutable
class LatLng {
  /// 创建地理坐标，并将纬度截断、经度归一化到其标准范围。
  const LatLng(double latitude, double longitude)
    : latitude = latitude < -90 ? -90 : (latitude > 90 ? 90 : latitude),
      longitude = longitude >= -180 && longitude < 180
          ? longitude
          : (longitude + 180) % 360 - 180;

  /// 纬度，范围为 -90 至 90（含边界）。
  final double latitude;

  /// 经度，范围为 -180（含）至 180（不含）。
  final double longitude;

  /// 返回可用于 JSON 编码的坐标列表。
  Object toJson() => <double>[latitude, longitude];

  /// 从 `[latitude, longitude]` 列表创建坐标；空值返回 `null`。
  static LatLng? fromJson(Object? json) {
    if (json == null) {
      return null;
    }
    assert(json is List && json.length == 2);
    final values = json as List<Object?>;
    return LatLng(values[0]! as double, values[1]! as double);
  }

  @override
  String toString() => '$runtimeType($latitude, $longitude)';

  @override
  bool operator ==(Object other) =>
      other is LatLng &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// 表示纬度和经度对齐的矩形区域。
@immutable
class LatLngBounds {
  /// 创建具有指定西南角与东北角的地理边界。
  LatLngBounds({required this.southwest, required this.northeast})
    : assert(southwest.latitude <= northeast.latitude);

  /// 矩形的西南角。
  final LatLng southwest;

  /// 矩形的东北角。
  final LatLng northeast;

  /// 返回可用于 JSON 编码的边界列表。
  Object toJson() => <Object>[southwest.toJson(), northeast.toJson()];

  /// 判断给定坐标是否位于边界内。
  bool contains(LatLng point) =>
      _containsLatitude(point.latitude) && _containsLongitude(point.longitude);

  bool _containsLatitude(double latitude) =>
      southwest.latitude <= latitude && latitude <= northeast.latitude;

  bool _containsLongitude(double longitude) {
    if (southwest.longitude <= northeast.longitude) {
      return southwest.longitude <= longitude &&
          longitude <= northeast.longitude;
    }
    return southwest.longitude <= longitude || longitude <= northeast.longitude;
  }

  /// 从包含两个坐标列表的列表创建边界；空值返回 `null`。
  static LatLngBounds? fromList(Object? json) {
    if (json == null) {
      return null;
    }
    assert(json is List && json.length == 2);
    final values = json as List<Object?>;
    return LatLngBounds(
      southwest: LatLng.fromJson(values[0])!,
      northeast: LatLng.fromJson(values[1])!,
    );
  }

  @override
  String toString() => '$runtimeType($southwest, $northeast)';

  @override
  bool operator ==(Object other) =>
      other is LatLngBounds &&
      other.southwest == southwest &&
      other.northeast == northeast;

  @override
  int get hashCode => Object.hash(southwest, northeast);
}
