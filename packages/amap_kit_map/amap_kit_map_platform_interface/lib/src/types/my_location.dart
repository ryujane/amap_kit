import 'package:amap_kit_core/amap_kit_core.dart';
import 'package:flutter/foundation.dart';

/// 原生 AMap 地图 SDK 上报的设备位置。
///
/// 仅当定位蓝点开启（[AmapMap.myLocationEnabled] 为 true）且调用方已获得前台
/// 定位权限时，地图才会持续上报该事件。各字段在原生 SDK 无法提供对应值时为空。
@immutable
final class AmapMyLocation {
  /// 创建地图定位事件的位置数据。
  const AmapMyLocation({
    required this.position,
    this.accuracyMeters,
    this.altitudeMeters,
    this.speedMetersPerSecond,
    this.bearingDegrees,
    this.timestamp,
  });

  /// 设备坐标。
  final LatLng position;

  /// 以米为单位的水平精度半径；SDK 未报告时为空。
  final double? accuracyMeters;

  /// 相对 WGS84 椭球面的海拔高度，单位米。
  final double? altitudeMeters;

  /// 地面速度，单位米每秒。
  final double? speedMetersPerSecond;

  /// 相对正北顺时针的移动方向，单位度。
  final double? bearingDegrees;

  /// 原生 SDK 测量该位置的时间。
  final DateTime? timestamp;

  @override
  bool operator ==(Object other) =>
      other is AmapMyLocation &&
      other.position == position &&
      other.accuracyMeters == accuracyMeters &&
      other.altitudeMeters == altitudeMeters &&
      other.speedMetersPerSecond == speedMetersPerSecond &&
      other.bearingDegrees == bearingDegrees &&
      other.timestamp == timestamp;

  @override
  int get hashCode => Object.hash(
    position,
    accuracyMeters,
    altitudeMeters,
    speedMetersPerSecond,
    bearingDegrees,
    timestamp,
  );
}
