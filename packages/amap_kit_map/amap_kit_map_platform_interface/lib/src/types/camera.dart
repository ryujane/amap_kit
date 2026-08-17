import 'dart:ui';

import 'package:amap_kit_core/amap_kit_core.dart';
import 'package:flutter/foundation.dart';

/// 地图相机的位置。
@immutable
final class CameraPosition {
  /// 创建相机位置。
  const CameraPosition({
    required this.target,
    this.zoom = 10,
    this.bearing = 0,
    this.tilt = 0,
  }) : assert(zoom >= 0),
       assert(tilt >= 0 && tilt <= 90);

  /// 相机注视的经纬度。
  final LatLng target;

  /// 地图缩放等级。
  final double zoom;

  /// 相机朝向，单位为度。
  final double bearing;

  /// 相机倾角，单位为度。
  final double tilt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return other is CameraPosition &&
        bearing == other.bearing &&
        target == other.target &&
        tilt == other.tilt &&
        zoom == other.zoom;
  }

  @override
  int get hashCode => Object.hash(bearing, target, tilt, zoom);

  @override
  String toString() =>
      'CameraPosition(bearing: $bearing, target: $target, tilt: $tilt, zoom: $zoom)';
}

/// Indicates which type of camera update this instance represents.
enum CameraUpdateType {
  /// New position for camera
  newCameraPosition,

  /// New coordinates for camera
  newLatLng,

  /// New coordinates bounding box
  newLatLngBounds,

  /// New coordinate with zoom level
  newLatLngZoom,

  /// Move by a scroll delta
  scrollBy,

  /// Zoom by a relative change
  zoomBy,

  /// Zoom to an absolute level
  zoomTo,

  /// Zoom in
  zoomIn,

  /// Zoom out
  zoomOut,
}

/// 相机变化指令。
sealed class CameraUpdate {
  const CameraUpdate._(this.updateType);

  /// Indicates which type of camera update this instance represents.
  final CameraUpdateType updateType;

  /// 将相机移动到完整的位置。
  const factory CameraUpdate.newCameraPosition(CameraPosition position) =
      CameraUpdateNewCameraPosition;

  /// 将相机移动到指定经纬度，保留其他相机属性。
  const factory CameraUpdate.newLatLng(LatLng target) = CameraUpdateNewLatLng;

  /// 将相机移动到足以展示边界的范围。
  const factory CameraUpdate.newLatLngBounds(
    LatLngBounds bounds, {
    double padding,
  }) = CameraUpdateNewLatLngBounds;

  /// 相对调整缩放等级。
  const factory CameraUpdate.zoomBy(double amount) = CameraUpdateZoomBy;

  /// 增加一级缩放。
  const factory CameraUpdate.zoomIn() = CameraUpdateZoomIn;

  /// 减少一级缩放。
  const factory CameraUpdate.zoomOut() = CameraUpdateZoomOut;
}

/// [CameraUpdate.newCameraPosition] 的值对象。
final class CameraUpdateNewCameraPosition extends CameraUpdate {
  const CameraUpdateNewCameraPosition(this.position)
    : super._(CameraUpdateType.newCameraPosition);
  final CameraPosition position;
}

/// [CameraUpdate.newLatLng] 的值对象。
final class CameraUpdateNewLatLng extends CameraUpdate {
  const CameraUpdateNewLatLng(this.target)
    : super._(CameraUpdateType.newLatLng);
  final LatLng target;
}

/// [CameraUpdate.newLatLngBounds] 的值对象。
final class CameraUpdateNewLatLngBounds extends CameraUpdate {
  const CameraUpdateNewLatLngBounds(this.bounds, {this.padding = 0})
    : assert(padding >= 0),
      super._(CameraUpdateType.newLatLngBounds);
  final LatLngBounds bounds;
  final double padding;
}

/// Defines a camera scroll by a certain delta.
class CameraUpdateScrollBy extends CameraUpdate {
  /// Creates a camera scroll.
  const CameraUpdateScrollBy(this.dx, this.dy)
    : super._(CameraUpdateType.scrollBy);

  /// Scroll delta x.
  final double dx;

  /// Scroll delta y.
  final double dy;
}

/// [CameraUpdate.zoomBy] 的值对象。
final class CameraUpdateZoomBy extends CameraUpdate {
  const CameraUpdateZoomBy(this.amount, [this.focus])
    : super._(CameraUpdateType.zoomBy);
  final double amount;

  /// Optional point around which the zoom is focused.
  final Offset? focus;
}

/// [CameraUpdate.zoomIn] 的值对象。
final class CameraUpdateZoomIn extends CameraUpdate {
  const CameraUpdateZoomIn() : super._(CameraUpdateType.zoomIn);
}

/// [CameraUpdate.zoomOut] 的值对象。
final class CameraUpdateZoomOut extends CameraUpdate {
  const CameraUpdateZoomOut() : super._(CameraUpdateType.zoomOut);
}

/// Defines a camera zoom to an absolute zoom.
class CameraUpdateZoomTo extends CameraUpdate {
  /// Creates a zoom to an absolute zoom level.
  const CameraUpdateZoomTo(this.zoom) : super._(CameraUpdateType.zoomTo);

  /// New zoom level of the camera.
  final double zoom;
}

/// Defines a camera move to new coordinates with a zoom level.
class CameraUpdateNewLatLngZoom extends CameraUpdate {
  /// Creates a camera move with coordinates and zoom level.
  const CameraUpdateNewLatLngZoom(this.latLng, this.zoom)
    : super._(CameraUpdateType.newLatLngZoom);

  /// New coordinates of the camera.
  final LatLng latLng;

  /// New zoom level of the camera.
  final double zoom;
}

/// Defines an animation configuration for camera updates.
@immutable
class CameraUpdateAnimationConfiguration {
  /// Creates a immutable animation configuration for camera updates.
  const CameraUpdateAnimationConfiguration({this.duration});

  /// The duration of the animation.
  ///
  /// If null, the platform will decide the default value.
  final Duration? duration;
}
