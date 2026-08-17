import 'dart:typed_data';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart'
    show AssetBundleImageKey, AssetImage, ImageConfiguration;
import 'package:flutter/services.dart' show AssetBundle;

/// Controls whether a bitmap is scaled for the device pixel ratio.
enum MapBitmapScaling {
  /// Scale the bitmap to keep its logical size consistent across devices.
  auto,

  /// Use the supplied bitmap pixels without automatic scaling.
  none,
}

/// Describes an image used to render a map marker.
///
/// The descriptor is a value object and is safe to reuse across markers and
/// maps. Asset descriptors resolve their Flutter asset variant before they are
/// sent to a native map implementation; byte descriptors must contain PNG
/// data.
@immutable
sealed class BitmapDescriptor {
  const BitmapDescriptor._();

  /// The default AMap marker image.
  static const BitmapDescriptor defaultMarker = DefaultMarker();

  /// Creates a marker bitmap from a Flutter asset.
  ///
  /// [configuration] is used to resolve the device-appropriate asset variant.
  /// The returned descriptor can be stored in a [Marker] once the future
  /// completes.
  static Future<AssetMapBitmap> asset(
    ImageConfiguration configuration,
    String assetName, {
    AssetBundle? bundle,
    String? package,
    double? width,
    double? height,
    double? imagePixelRatio,
    MapBitmapScaling bitmapScaling = MapBitmapScaling.auto,
  }) async {
    return AssetMapBitmap.create(
      configuration,
      assetName,
      bundle: bundle,
      package: package,
      width: width,
      height: height,
      imagePixelRatio: imagePixelRatio,
      bitmapScaling: bitmapScaling,
    );
  }

  /// Creates a marker bitmap from PNG-encoded bytes.
  static BytesMapBitmap bytes(
    Uint8List byteData, {
    double? imagePixelRatio,
    double? width,
    double? height,
    MapBitmapScaling bitmapScaling = MapBitmapScaling.auto,
  }) {
    return BytesMapBitmap(
      byteData,
      imagePixelRatio: imagePixelRatio,
      width: width,
      height: height,
      bitmapScaling: bitmapScaling,
    );
  }

  /// Serializes the descriptor for model tests and diagnostics.
  Object toJson();
}

/// Describes bitmap data that can be rendered as a map image layer.
///
/// Unlike [DefaultMarker], map bitmaps contain application-provided image
/// data and expose an explicit device-pixel scaling policy.
@immutable
sealed class MapBitmap extends BitmapDescriptor {
  const MapBitmap._() : super._();

  /// Controls whether native code scales the image for device pixel density.
  MapBitmapScaling get bitmapScaling;
}

/// Uses the native default marker image.
@immutable
final class DefaultMarker extends BitmapDescriptor {
  /// Creates a default marker descriptor.
  const DefaultMarker() : super._();

  @override
  Object toJson() => const <Object>['defaultMarker'];

  @override
  bool operator ==(Object other) => other is DefaultMarker;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// A marker bitmap resolved from a Flutter asset.
@immutable
final class AssetMapBitmap extends MapBitmap {
  /// Creates an asset bitmap without resolving density variants.
  const AssetMapBitmap(
    this.assetName, {
    this.bitmapScaling = MapBitmapScaling.auto,
    double? imagePixelRatio,
    this.width,
    this.height,
  }) : imagePixelRatio = imagePixelRatio ?? 1,
       assert(assetName != ''),
       assert(imagePixelRatio == null || imagePixelRatio > 0),
       assert(width == null || width > 0),
       assert(height == null || height > 0),
       assert(
         bitmapScaling != MapBitmapScaling.none || width == null,
         'width cannot be used with MapBitmapScaling.none',
       ),
       assert(
         bitmapScaling != MapBitmapScaling.none || height == null,
         'height cannot be used with MapBitmapScaling.none',
       ),
       super._();

  /// Resolves an asset using Flutter's resolution-aware asset lookup.
  static Future<AssetMapBitmap> create(
    ImageConfiguration configuration,
    String assetName, {
    AssetBundle? bundle,
    String? package,
    double? width,
    double? height,
    double? imagePixelRatio,
    MapBitmapScaling bitmapScaling = MapBitmapScaling.auto,
  }) async {
    assert(assetName != '');
    final AssetImage assetImage = AssetImage(
      assetName,
      bundle: bundle,
      package: package,
    );
    final AssetBundleImageKey key = await assetImage.obtainKey(configuration);
    return AssetMapBitmap(
      key.name,
      bitmapScaling: bitmapScaling,
      imagePixelRatio: imagePixelRatio ?? key.scale,
      width: width,
      height: height,
    );
  }

  /// The resolved Flutter asset key.
  final String assetName;

  /// Bitmap scaling behavior.
  @override
  final MapBitmapScaling bitmapScaling;

  /// Pixel ratio represented by the bitmap.
  final double imagePixelRatio;

  /// Target logical width, if specified.
  final double? width;

  /// Target logical height, if specified.
  final double? height;

  @override
  Object toJson() => <Object>[
    'asset',
    <String, Object?>{
      'assetName': assetName,
      'bitmapScaling': bitmapScaling.name,
      'imagePixelRatio': imagePixelRatio,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    },
  ];

  @override
  bool operator ==(Object other) =>
      other is AssetMapBitmap &&
      other.assetName == assetName &&
      other.bitmapScaling == bitmapScaling &&
      other.imagePixelRatio == imagePixelRatio &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode =>
      Object.hash(assetName, bitmapScaling, imagePixelRatio, width, height);
}

/// A marker bitmap backed by PNG-encoded bytes.
@immutable
final class BytesMapBitmap extends MapBitmap {
  /// Creates a byte-backed marker bitmap.
  BytesMapBitmap(
    Uint8List byteData, {
    this.bitmapScaling = MapBitmapScaling.auto,
    double? imagePixelRatio,
    this.width,
    this.height,
  }) : byteData = Uint8List.fromList(byteData).asUnmodifiableView(),
       imagePixelRatio = imagePixelRatio ?? 1,
       assert(byteData.isNotEmpty),
       assert(imagePixelRatio == null || imagePixelRatio > 0),
       assert(width == null || width > 0),
       assert(height == null || height > 0),
       assert(
         bitmapScaling != MapBitmapScaling.none || width == null,
         'width cannot be used with MapBitmapScaling.none',
       ),
       assert(
         bitmapScaling != MapBitmapScaling.none || height == null,
         'height cannot be used with MapBitmapScaling.none',
       ),
       super._();

  /// PNG-encoded bytes. The returned view cannot be mutated.
  final Uint8List byteData;

  /// Bitmap scaling behavior.
  @override
  final MapBitmapScaling bitmapScaling;

  /// Pixel ratio represented by the bitmap.
  final double imagePixelRatio;

  /// Target logical width, if specified.
  final double? width;

  /// Target logical height, if specified.
  final double? height;

  @override
  Object toJson() => <Object>[
    'bytes',
    <String, Object?>{
      'byteData': byteData,
      'bitmapScaling': bitmapScaling.name,
      'imagePixelRatio': imagePixelRatio,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    },
  ];

  @override
  bool operator ==(Object other) =>
      other is BytesMapBitmap &&
      other.bitmapScaling == bitmapScaling &&
      other.imagePixelRatio == imagePixelRatio &&
      other.width == width &&
      other.height == height &&
      _bytesEqual(other.byteData, byteData);

  @override
  int get hashCode => Object.hash(
    bitmapScaling,
    imagePixelRatio,
    width,
    height,
    Object.hashAll(byteData),
  );
}

bool _bytesEqual(Uint8List first, Uint8List second) {
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}
