import 'package:amap_kit_map_platform_interface/src/types/bitmap_descriptor.dart';
import 'package:amap_kit_map_platform_interface/src/types/my_location_type.dart';
import 'package:flutter/foundation.dart';

/// Configures the native AMap user-location blue dot.
///
/// Colors use Flutter's ARGB integer representation. A null field keeps the
/// platform SDK default. The bitmap is resolved through the same asset/PNG
/// pipeline as [Marker.icon].
@immutable
final class AmapMyLocationStyle {
  /// Creates an optional native blue-dot style.
  const AmapMyLocationStyle({
    this.icon,
    this.anchorU,
    this.anchorV,
    this.accuracyFillColor,
    this.accuracyStrokeColor,
    this.accuracyStrokeWidth,
    this.myLocationType,
    this.interval,
    this.showMyLocation,
    this.zIndex,
    this.showsAccuracyRing,
    this.showsHeadingIndicator,
    this.enablePulseAnimation,
    this.dotBackgroundColor,
    this.dotFillColor,
  }) : assert(accuracyStrokeWidth == null || accuracyStrokeWidth >= 0),
       assert(anchorU == null || (anchorU >= 0 && anchorU <= 1)),
       assert(anchorV == null || (anchorV >= 0 && anchorV <= 1)),
       assert(interval == null || interval >= 0);

  /// Optional custom blue-dot bitmap.
  final BitmapDescriptor? icon;

  /// Location-dot anchor U coordinate in [0, 1]
  /// (`MyLocationStyle.anchor`).
  ///
  /// Supported by Android. iOS has no equivalent, so this field has no effect
  /// there.
  final double? anchorU;

  /// Location-dot anchor V coordinate in [0, 1]
  /// (`MyLocationStyle.anchor`).
  ///
  /// Supported by Android. iOS has no equivalent, so this field has no effect
  /// there.
  final double? anchorV;

  /// Accuracy-circle fill color as an ARGB integer.
  ///
  /// Supported by Android and iOS.
  final int? accuracyFillColor;

  /// Accuracy-circle stroke color as an ARGB integer.
  ///
  /// Supported by Android and iOS.
  final int? accuracyStrokeColor;

  /// Accuracy-circle stroke width in the native SDK's display units.
  ///
  /// Supported by Android and iOS.
  final double? accuracyStrokeWidth;

  /// Blue-dot tracking behavior; see [AmapMyLocationType].
  ///
  /// Supported by Android. iOS keeps its own tracking behavior, so this field
  /// has no effect there.
  final AmapMyLocationType? myLocationType;

  /// Location refresh interval in milliseconds (`MyLocationStyle.interval`).
  ///
  /// Supported by Android. iOS has no equivalent, so this field has no effect
  /// there.
  final int? interval;

  /// Whether the location dot is shown (`MyLocationStyle.showMyLocation`).
  ///
  /// Supported by Android. iOS has no equivalent, so this field has no effect
  /// there.
  final bool? showMyLocation;

  /// Location-dot z-index (`MyLocationStyle.zIndex`).
  ///
  /// Supported by Android. iOS has no equivalent, so this field has no effect
  /// there.
  final int? zIndex;

  /// Whether iOS renders the accuracy circle.
  ///
  /// Android's AMap SDK has no separate accuracy-circle visibility switch, so
  /// this field has no effect there.
  final bool? showsAccuracyRing;

  /// Whether the location marker displays a heading indicator.
  ///
  /// On Android this selects the SDK's rotating or non-rotating location mode.
  final bool? showsHeadingIndicator;

  /// Whether iOS animates the inner blue-dot pulse.
  ///
  /// Android's AMap SDK has no equivalent, so this field has no effect there.
  final bool? enablePulseAnimation;

  /// iOS location-dot background color as an ARGB integer.
  ///
  /// Android's AMap SDK has no equivalent, so this field has no effect there.
  final int? dotBackgroundColor;

  /// iOS location-dot fill color as an ARGB integer.
  ///
  /// Android's AMap SDK has no equivalent, so this field has no effect there.
  final int? dotFillColor;

  @override
  bool operator ==(Object other) =>
      other is AmapMyLocationStyle &&
      other.icon == icon &&
      other.anchorU == anchorU &&
      other.anchorV == anchorV &&
      other.accuracyFillColor == accuracyFillColor &&
      other.accuracyStrokeColor == accuracyStrokeColor &&
      other.accuracyStrokeWidth == accuracyStrokeWidth &&
      other.myLocationType == myLocationType &&
      other.interval == interval &&
      other.showMyLocation == showMyLocation &&
      other.zIndex == zIndex &&
      other.showsAccuracyRing == showsAccuracyRing &&
      other.showsHeadingIndicator == showsHeadingIndicator &&
      other.enablePulseAnimation == enablePulseAnimation &&
      other.dotBackgroundColor == dotBackgroundColor &&
      other.dotFillColor == dotFillColor;

  @override
  int get hashCode => Object.hash(
    icon,
    anchorU,
    anchorV,
    accuracyFillColor,
    accuracyStrokeColor,
    accuracyStrokeWidth,
    myLocationType,
    interval,
    showMyLocation,
    zIndex,
    showsAccuracyRing,
    showsHeadingIndicator,
    enablePulseAnimation,
    dotBackgroundColor,
    dotFillColor,
  );
}
