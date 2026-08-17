import 'dart:ui';

import 'package:amap_kit_core/amap_kit_core.dart';
import 'package:amap_kit_map_platform_interface/src/types/bitmap_descriptor.dart';
import 'package:amap_kit_map_platform_interface/src/types/maps_object.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Uniquely identifies a [GroundOverlay] on one map.
@immutable
final class GroundOverlayId extends MapsObjectId<GroundOverlay> {
  /// Creates an immutable ground-overlay identifier.
  const GroundOverlayId(super.value);
}

/// An image fixed to the Earth's surface on an AMap map.
///
/// Ground overlays are intended for one bounded image. Use a tile overlay for
/// imagery that covers a large region. Android supports both bounds placement
/// and position plus meter-based dimensions. Other platforms explicitly
/// report the feature as unsupported until they provide an implementation.
///
/// The image must use [MapBitmapScaling.none], because the native SDK scales
/// the bitmap to its geographical dimensions.
@immutable
final class GroundOverlay implements MapsObject<GroundOverlay> {
  GroundOverlay._({
    required this.groundOverlayId,
    required this.image,
    this.position,
    this.bounds,
    this.width,
    this.height,
    this.anchor = const Offset(0.5, 0.5),
    this.bearing = 0,
    this.transparency = 0,
    this.zIndex = 0,
    this.visible = true,
  }) : assert((position == null) != (bounds == null)),
       assert(position == null || (width != null && width > 0)),
       assert(height == null || height > 0),
       assert(anchor.dx >= 0 && anchor.dx <= 1),
       assert(anchor.dy >= 0 && anchor.dy <= 1),
       assert(bearing >= 0 && bearing < 360),
       assert(transparency >= 0 && transparency <= 1),
       assert(zIndex >= -double.maxFinite && zIndex <= double.maxFinite),
       assert(image.bitmapScaling == MapBitmapScaling.none);

  /// Creates an overlay fitted to [bounds].
  factory GroundOverlay.fromBounds({
    required GroundOverlayId groundOverlayId,
    required MapBitmap image,
    required LatLngBounds bounds,
    Offset anchor = const Offset(0.5, 0.5),
    double bearing = 0,
    double transparency = 0,
    double zIndex = 0,
    bool visible = true,
  }) => GroundOverlay._(
    groundOverlayId: groundOverlayId,
    image: image,
    bounds: bounds,
    anchor: anchor,
    bearing: bearing,
    transparency: transparency,
    zIndex: zIndex,
    visible: visible,
  );

  /// Creates an overlay whose [anchor] is fixed to [position].
  ///
  /// [width] and the optional [height] are measured in meters. When [height]
  /// is omitted, Android preserves the image aspect ratio.
  factory GroundOverlay.fromPosition({
    required GroundOverlayId groundOverlayId,
    required MapBitmap image,
    required LatLng position,
    required double width,
    double? height,
    Offset anchor = const Offset(0.5, 0.5),
    double bearing = 0,
    double transparency = 0,
    double zIndex = 0,
    bool visible = true,
  }) => GroundOverlay._(
    groundOverlayId: groundOverlayId,
    image: image,
    position: position,
    width: width,
    height: height,
    anchor: anchor,
    bearing: bearing,
    transparency: transparency,
    zIndex: zIndex,
    visible: visible,
  );

  /// Stable identifier used by diff updates.
  final GroundOverlayId groundOverlayId;

  /// Application-provided bitmap rendered by the native map SDK.
  final MapBitmap image;

  /// Geographical position to which [anchor] is fixed.
  final LatLng? position;

  /// Bounds containing the complete image.
  final LatLngBounds? bounds;

  /// Width in meters when [position] placement is used.
  final double? width;

  /// Optional height in meters when [position] placement is used.
  final double? height;

  /// Normalized image point fixed to [position].
  final Offset anchor;

  /// Clockwise rotation from true north, in degrees.
  final double bearing;

  /// Image transparency from 0 (opaque) to 1 (fully transparent).
  final double transparency;

  /// Drawing order relative to other native overlays.
  ///
  /// Android only: the Android AMap SDK natively supports overlay z-order, while
  /// the iOS AMap SDK does not — overlays draw in add order and this value has
  /// no effect on iOS.
  final double zIndex;

  /// Whether the overlay is visible.
  final bool visible;

  @override
  GroundOverlayId get mapsId => groundOverlayId;

  /// Returns a copy with replaceable display properties.
  GroundOverlay copyWith({
    double? bearingParam,
    double? transparencyParam,
    double? zIndexParam,
    bool? visibleParam,
  }) => GroundOverlay._(
    groundOverlayId: groundOverlayId,
    image: image,
    position: position,
    bounds: bounds,
    width: width,
    height: height,
    anchor: anchor,
    bearing: bearingParam ?? bearing,
    transparency: transparencyParam ?? transparency,
    zIndex: zIndexParam ?? zIndex,
    visible: visibleParam ?? visible,
  );

  @override
  GroundOverlay clone() => copyWith();

  @override
  Object toJson() => <String, Object?>{
    'groundOverlayId': groundOverlayId.value,
    'image': image.toJson(),
    'position': position?.toJson(),
    'bounds': bounds?.toJson(),
    'width': width,
    'height': height,
    'anchor': <double>[anchor.dx, anchor.dy],
    'bearing': bearing,
    'transparency': transparency,
    'zIndex': zIndex,
    'visible': visible,
  };

  @override
  bool operator ==(Object other) =>
      other is GroundOverlay &&
      other.groundOverlayId == groundOverlayId &&
      other.image == image &&
      other.position == position &&
      other.bounds == bounds &&
      other.width == width &&
      other.height == height &&
      other.anchor == anchor &&
      other.bearing == bearing &&
      other.transparency == transparency &&
      other.zIndex == zIndex &&
      other.visible == visible;

  @override
  int get hashCode => Object.hash(
    groundOverlayId,
    image,
    position,
    bounds,
    width,
    height,
    anchor,
    bearing,
    transparency,
    zIndex,
    visible,
  );
}
