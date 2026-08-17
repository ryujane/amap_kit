import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'amap_kit_map_ios',
    dartOut: 'lib/src/messages.g.dart',
    swiftOut: 'ios/amap_kit_map_ios/Sources/amap_kit_map_ios/MapMessages.g.swift',
    swiftOptions: SwiftOptions(
    )
  ),
)
enum PlatformMapType { normal, satellite }

class PlatformPrivacyStatement {
  /// 隐私权政策是否包含高德开平隐私权政策
  final bool? hasContains;

  /// 隐私权政策是否弹窗展示告知用户
  final bool? hasShow;

  /// 隐私权政策是否已经取得用户同意
  final bool? hasAgree;
  PlatformPrivacyStatement({
    required this.hasContains,
    required this.hasShow,
    required this.hasAgree,
  });
}

/// Pair of double values, such as for an offset or size.
class PlatformDoublePair {
  PlatformDoublePair(this.x, this.y);

  final double x;
  final double y;
}

/// Pigeon equivalent of [BitmapDescriptor]. As there are multiple disjoint
/// types of [BitmapDescriptor], [PlatformBitmap] contains a single field which
/// may hold the pigeon equivalent type of any of them.
class PlatformBitmap {
  PlatformBitmap({required this.bitmap});

  /// One of [PlatformBitmapAssetMap], [PlatformBitmapAsset],
  /// [PlatformBitmapAssetImage], [PlatformBitmapBytesMap],
  /// [PlatformBitmapBytes], or [PlatformBitmapDefaultMarker].
  /// As Pigeon does not currently support data class inheritance, this
  /// approach allows for the different bitmap implementations to be valid
  /// argument and return types of the API methods. See
  /// https://github.com/flutter/flutter/issues/117819.
  final Object bitmap;
}

/// Pigeon equivalent of [DefaultMarker]. See
/// https://developers.google.com/maps/documentation/android-sdk/reference/com/google/android/libraries/maps/model/BitmapDescriptorFactory#defaultMarker(float)
class PlatformBitmapDefaultMarker {
  PlatformBitmapDefaultMarker({this.hue});

  final double? hue;
}

/// Pigeon equivalent of [BytesBitmap]. See
/// https://developers.google.com/maps/documentation/android-sdk/reference/com/google/android/libraries/maps/model/BitmapDescriptorFactory#fromBitmap(android.graphics.Bitmap)
class PlatformBitmapBytes {
  PlatformBitmapBytes({required this.byteData, this.size});

  final Uint8List byteData;
  final PlatformDoublePair? size;
}

/// Pigeon equivalent of [AssetBitmap]. See
/// https://developers.google.com/maps/documentation/android-sdk/reference/com/google/android/libraries/maps/model/BitmapDescriptorFactory#public-static-bitmapdescriptor-fromasset-string-assetname
class PlatformBitmapAsset {
  PlatformBitmapAsset({required this.name, this.pkg});

  final String name;
  final String? pkg;
}

/// Pigeon equivalent of [AssetImageBitmap]. See
/// https://developers.google.com/maps/documentation/android-sdk/reference/com/google/android/libraries/maps/model/BitmapDescriptorFactory#public-static-bitmapdescriptor-fromasset-string-assetname
class PlatformBitmapAssetImage {
  PlatformBitmapAssetImage({
    required this.name,
    required this.scale,
    this.size,
  });
  final String name;
  final double scale;
  final PlatformDoublePair? size;
}

/// Pigeon equivalent of [MapBitmapScaling].
enum PlatformMapBitmapScaling { auto, none }

/// Pigeon equivalent of [AssetMapBitmap]. See
/// https://developers.google.com/maps/documentation/android-sdk/reference/com/google/android/libraries/maps/model/BitmapDescriptorFactory#public-static-bitmapdescriptor-fromasset-string-assetname
class PlatformBitmapAssetMap {
  PlatformBitmapAssetMap({
    required this.assetName,
    required this.bitmapScaling,
    required this.imagePixelRatio,
    this.width,
    this.height,
  });
  final String assetName;
  final PlatformMapBitmapScaling bitmapScaling;
  final double imagePixelRatio;
  final double? width;
  final double? height;
}

/// Pigeon equivalent of [BytesMapBitmap]. See
/// https://developers.google.com/maps/documentation/android-sdk/reference/com/google/android/libraries/maps/model/BitmapDescriptorFactory#public-static-bitmapdescriptor-frombitmap-bitmap-image
class PlatformBitmapBytesMap {
  PlatformBitmapBytesMap({
    required this.byteData,
    required this.bitmapScaling,
    required this.imagePixelRatio,
    this.width,
    this.height,
  });
  final Uint8List byteData;
  final PlatformMapBitmapScaling bitmapScaling;
  final double imagePixelRatio;
  final double? width;
  final double? height;
}

/// Pigeon representation of an x,y coordinate.
class PlatformPoint {
  PlatformPoint({required this.x, required this.y});

  final int x;
  final int y;
}

enum PlatformCameraUpdateType {
  cameraPosition,
  latLng,
  latLngBounds,
  zoomBy,
  zoomIn,
  zoomOut,
}

enum PlatformMapEventType {
  cameraMoveStarted,
  cameraMove,
  cameraIdle,
  tap,
  longPress,
  error,
  clusterTap,
  multiPointTap,
  markerTap,
  markerDragStart,
  markerDrag,
  markerDragEnd,
  polylineTap,
}

enum PlatformMapErrorCode {
  privacyNotConfigured,
  apiKeyMissing,
  initializationFailed,
  mapNotFound,
  unsupported,
  unknown,
  locationPermission,
  markerIcon,
}

/// Pigeon equivalent of the InfoWindow class.
class PlatformInfoWindow {
  PlatformInfoWindow({required this.anchor, this.title, this.snippet});

  final String? title;
  final String? snippet;
  final PlatformDoublePair anchor;
}

enum PlatformMarkerIconType { defaultMarker, asset, bytes }

enum PlatformMarkerIconScaling { auto, none }

class PlatformPrivacyStatus {
  PlatformPrivacyStatus({
    required this.privacyNoticeShown,
    required this.containsAmapPrivacyPolicy,
    required this.userAgreed,
  });
  bool privacyNoticeShown;
  bool containsAmapPrivacyPolicy;
  bool userAgreed;
}

class PlatformLatLng {
  PlatformLatLng({required this.latitude, required this.longitude});
  double latitude;
  double longitude;
}

/// The device location as reported by the native AMap map SDK.
class PlatformMyLocation {
  PlatformMyLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.bearing,
    this.timestamp,
  });

  double latitude;
  double longitude;

  /// Horizontal accuracy in meters; null when the SDK cannot report it.
  double? accuracy;

  /// Altitude in meters above the WGS84 ellipsoid.
  double? altitude;

  /// Ground speed in meters per second.
  double? speed;

  /// Direction of travel in degrees clockwise from true north.
  double? bearing;

  /// When the location was measured, in milliseconds since the Unix epoch.
  int? timestamp;
}

class PlatformLatLngBounds {
  PlatformLatLngBounds({required this.southwest, required this.northeast});
  PlatformLatLng southwest;
  PlatformLatLng northeast;
}

class PlatformCameraPosition {
  PlatformCameraPosition({
    required this.target,
    required this.zoom,
    required this.bearing,
    required this.tilt,
  });
  PlatformLatLng target;
  double zoom;
  double bearing;
  double tilt;
}

/// Pigeon representation of a CameraUpdate.
class PlatformCameraUpdate {
  PlatformCameraUpdate({required this.cameraUpdate});

  /// This Object shall be any of the below classes prefixed with
  /// PlatformCameraUpdate. Each such class represents a different type of
  /// camera update, and each holds a different set of data, preventing the
  /// use of a single unified class. Pigeon does not support inheritance, which
  /// prevents a more strict type bound.
  /// See https://github.com/flutter/flutter/issues/117819.
  final Object cameraUpdate;
}

/// Pigeon equivalent of NewCameraPosition
class PlatformCameraUpdateNewCameraPosition {
  PlatformCameraUpdateNewCameraPosition(this.cameraPosition);
  final PlatformCameraPosition cameraPosition;
}

/// Pigeon equivalent of NewLatLng
class PlatformCameraUpdateNewLatLng {
  PlatformCameraUpdateNewLatLng(this.latLng);
  final PlatformLatLng latLng;
}

/// Pigeon equivalent of NewLatLngBounds
class PlatformCameraUpdateNewLatLngBounds {
  PlatformCameraUpdateNewLatLngBounds(this.bounds, this.padding);
  final PlatformLatLngBounds bounds;
  final double padding;
}

/// Pigeon equivalent of NewLatLngZoom
class PlatformCameraUpdateNewLatLngZoom {
  PlatformCameraUpdateNewLatLngZoom(this.latLng, this.zoom);
  final PlatformLatLng latLng;
  final double zoom;
}

/// Pigeon equivalent of ScrollBy
class PlatformCameraUpdateScrollBy {
  PlatformCameraUpdateScrollBy(this.dx, this.dy);
  final double dx;
  final double dy;
}

/// Pigeon equivalent of ZoomBy
class PlatformCameraUpdateZoomBy {
  PlatformCameraUpdateZoomBy(this.amount, [this.focus]);
  final double amount;
  final PlatformDoublePair? focus;
}

/// Pigeon equivalent of ZoomIn/ZoomOut
class PlatformCameraUpdateZoom {
  PlatformCameraUpdateZoom(this.out);
  final bool out;
}

/// Pigeon equivalent of ZoomTo
class PlatformCameraUpdateZoomTo {
  PlatformCameraUpdateZoomTo(this.zoom);
  final double zoom;
}

class PlatformCustomMapStyle {
  PlatformCustomMapStyle({
    this.styleData,
    this.styleExtraData,
    this.styleTextureData,
    this.styleId,
  });
  Uint8List? styleData;
  Uint8List? styleExtraData;
  Uint8List? styleTextureData;
  String? styleId;
}

class PlatformMapOptions {
  PlatformMapOptions({
    required this.mapType,
    required this.compassEnabled,
    required this.scaleControlsEnabled,
    required this.trafficEnabled,
    required this.buildingsEnabled,
    required this.rotateGesturesEnabled,
    required this.scrollGesturesEnabled,
    required this.tiltGesturesEnabled,
    required this.zoomGesturesEnabled,
    required this.myLocationEnabled,
    required this.mapId,
    this.myLocationStyle,
    this.customMapStyle,
  });
  PlatformMapType? mapType;
  bool? compassEnabled;
  bool? scaleControlsEnabled;
  bool? trafficEnabled;
  bool? buildingsEnabled;
  bool? rotateGesturesEnabled;
  bool? scrollGesturesEnabled;
  bool? tiltGesturesEnabled;
  bool? zoomGesturesEnabled;
  bool? myLocationEnabled;
  final String? mapId;
  PlatformMyLocationStyle? myLocationStyle;
  PlatformCustomMapStyle? customMapStyle;
}

class PlatformMarker {
  PlatformMarker({
    required this.markerId,
    required this.position,
    this.title,
    this.snippet,
    required this.infoWindow,
    this.consumeTapEvents = false,
    this.visible = true,
    this.draggable = false,
    this.flat = false,
    this.alpha = 1.0,
    this.rotation = 0,
    this.zIndex = 0,
    required this.anchor,
    required this.icon,
    this.clusterManagerId,
  });
  final String markerId;
  final PlatformLatLng position;
  final bool consumeTapEvents;
  final String? title;
  final String? snippet;
  final bool visible;
  final bool draggable;
  final PlatformInfoWindow infoWindow;
  final bool flat;
  final double alpha;
  final double rotation;
  final double zIndex;
  final PlatformDoublePair anchor;
  final PlatformBitmap icon;
  final String? clusterManagerId;
}

/// Pigeon equivalent of `MyLocationStyle.myLocationType`.
///
/// Member order mirrors AMap's `MyLocationStyle.LOCATION_TYPE_*` constants so
/// the ordinal encoding stays in sync: `show`(0), `locate`(1), `follow`(2),
/// `mapRotate`(3), `locationRotate`(4), `locationRotateNoCenter`(5),
/// `followNoCenter`(6), `mapRotateNoCenter`(7).
enum PlatformMyLocationType {
  show,
  locate,
  follow,
  mapRotate,
  locationRotate,
  locationRotateNoCenter,
  followNoCenter,
  mapRotateNoCenter,
}

/// Pigeon equivalent of AMap's
/// `com.amap.api.maps.model.MyLocationStyle` location-dot appearance.
class PlatformMyLocationStyle {
  PlatformMyLocationStyle({
    this.icon,
    this.anchorU,
    this.anchorV,
    this.radiusFillColor,
    this.strokeColor,
    this.strokeWidth,
    this.myLocationType,
    this.interval,
    this.showMyLocation,
    this.zIndex,
  });

  /// Custom location-dot icon (`myLocationIcon`).
  PlatformBitmap? icon;

  /// Location-dot anchor U coordinate in [0, 1] (`anchor`).
  double? anchorU;

  /// Location-dot anchor V coordinate in [0, 1] (`anchor`).
  double? anchorV;

  /// Accuracy-circle fill color as an ARGB integer (`radiusFillColor`).
  int? radiusFillColor;

  /// Accuracy-circle stroke color as an ARGB integer (`strokeColor`).
  int? strokeColor;

  /// Accuracy-circle stroke width in the SDK's display units (`strokeWidth`).
  double? strokeWidth;

  /// Location-dot behavior and tracking mode (`myLocationType`).
  PlatformMyLocationType? myLocationType;

  /// Location refresh interval in milliseconds (`interval`).
  int? interval;

  /// Whether the location dot is shown (`showMyLocation`).
  bool? showMyLocation;

  /// Location-dot z-index (`zIndex`).
  int? zIndex;
}

class PlatformClusterManager {
  PlatformClusterManager({required this.id});
  String id;
}

class PlatformClusterManagerUpdates {
  PlatformClusterManagerUpdates({
    required this.toAdd,
    required this.toChange,
    required this.toRemove,
  });
  List<PlatformClusterManager> toAdd;
  List<PlatformClusterManager> toChange;
  List<String> toRemove;
}

enum PlatformLineCapType { butt, round, square, arrow }

enum PlatformLineJoinType { bevel, miter, round }

enum PlatformDottedLineType { square, circle }

class PlatformPolyline {
  PlatformPolyline({
    required this.polylineId,
    required this.points,
    required this.color,
    required this.width,
    required this.visible,
    required this.geodesic,
    required this.zIndex,
    this.isDotted = false,
    required this.consumesTapEvents,
    this.lineCapType = PlatformLineCapType.round,
    this.lineJoinType = PlatformLineJoinType.round,
    this.dottedLineType = PlatformDottedLineType.square,
  });
  final bool consumesTapEvents;
  final String polylineId;
  final List<PlatformLatLng> points;
  final int color;
  final double width;
  final bool visible;
  final bool geodesic;
  final double zIndex;
  final bool isDotted;
  final PlatformLineCapType lineCapType;
  final PlatformLineJoinType lineJoinType;
  final PlatformDottedLineType dottedLineType;
}

class PlatformPolygon {
  PlatformPolygon({
    required this.polygonId,
    required this.points,
    this.holes = const [],
    required this.strokeColor,
    required this.fillColor,
    required this.strokeWidth,
    required this.visible,
    required this.zIndex,
    this.lineJoinType = PlatformLineJoinType.round,
  });
  String polygonId;
  List<PlatformLatLng> points;
  List<List<PlatformLatLng>> holes;
  int strokeColor;
  int fillColor;
  double strokeWidth;
  bool visible;
  double zIndex;
  PlatformLineJoinType lineJoinType;
}

class PlatformCircle {
  PlatformCircle({
    required this.circleId,
    required this.center,
    required this.radius,
    required this.strokeColor,
    required this.fillColor,
    required this.strokeWidth,
    required this.visible,
    required this.zIndex,
    this.isDotted = false,
  });
  String circleId;
  PlatformLatLng center;
  double radius;
  int strokeColor;
  int fillColor;
  double strokeWidth;
  bool visible;
  double zIndex;
  bool isDotted;
}

class PlatformGroundOverlay {
  PlatformGroundOverlay({
    required this.id,
    required this.image,
    required this.anchor,
    required this.bearing,
    required this.transparency,
    required this.zIndex,
    required this.visible,
    this.position,
    this.bounds,
    this.width,
    this.height,
  });
  String id;
  PlatformBitmap image;
  PlatformLatLng? position;
  PlatformLatLngBounds? bounds;
  double? width;
  double? height;
  PlatformDoublePair anchor;
  double bearing;
  double transparency;
  double zIndex;
  bool visible;
}

class PlatformMarkerUpdates {
  PlatformMarkerUpdates({
    required this.toAdd,
    required this.toChange,
    required this.toRemove,
  });
  List<PlatformMarker> toAdd;
  List<PlatformMarker> toChange;
  List<String> toRemove;
}

class PlatformPolylineUpdates {
  PlatformPolylineUpdates({
    required this.toAdd,
    required this.toChange,
    required this.toRemove,
  });
  List<PlatformPolyline> toAdd;
  List<PlatformPolyline> toChange;
  List<String> toRemove;
}

class PlatformPolygonUpdates {
  PlatformPolygonUpdates({
    required this.toAdd,
    required this.toChange,
    required this.toRemove,
  });
  List<PlatformPolygon> toAdd;
  List<PlatformPolygon> toChange;
  List<String> toRemove;
}

class PlatformCircleUpdates {
  PlatformCircleUpdates({
    required this.toAdd,
    required this.toChange,
    required this.toRemove,
  });
  List<PlatformCircle> toAdd;
  List<PlatformCircle> toChange;
  List<String> toRemove;
}

class PlatformGroundOverlayUpdates {
  PlatformGroundOverlayUpdates({
    required this.toAdd,
    required this.toChange,
    required this.toRemove,
  });
  List<PlatformGroundOverlay> toAdd;
  List<PlatformGroundOverlay> toChange;
  List<String> toRemove;
}

class PlatformWeightedLatLng {
  PlatformWeightedLatLng({
    required this.point,
    required this.weight,
  });
  PlatformLatLng point;
  double weight;
}

class PlatformHeatmapGradient {
  PlatformHeatmapGradient({
    required this.colors,
    required this.startPoints,
  });

  final List<int> colors;
  final List<double> startPoints;
}

class PlatformHeatmap {
  PlatformHeatmap({
    required this.id,
    required this.data,
    this.gradient,
    required this.opacity,
    required this.radius,
    required this.visible,
  });
  String id;
  List<PlatformWeightedLatLng> data;
  final PlatformHeatmapGradient? gradient;
  double opacity;
  int radius;
  bool visible;
}

class PlatformHeatmapUpdates {
  PlatformHeatmapUpdates({
    required this.toAdd,
    required this.toChange,
    required this.toRemove,
  });
  List<PlatformHeatmap> toAdd;
  List<PlatformHeatmap> toChange;
  List<String> toRemove;
}

class PlatformTile {
  PlatformTile({required this.width, required this.height, this.data});
  int width;
  int height;
  Uint8List? data;
}

class PlatformTileCoordinate {
  PlatformTileCoordinate({required this.x, required this.y});
  int x;
  int y;
}

class PlatformTileOverlay {
  PlatformTileOverlay({
    required this.id,
    required this.tileSize,
    required this.zIndex,
    required this.visible,
  });
  String id;
  int tileSize;
  double zIndex;
  bool visible;
}

class PlatformTileOverlayUpdates {
  PlatformTileOverlayUpdates({
    required this.toAdd,
    required this.toChange,
    required this.toRemove,
  });
  List<PlatformTileOverlay> toAdd;
  List<PlatformTileOverlay> toChange;
  List<String> toRemove;
}

class PlatformCluster {
  PlatformCluster({
    required this.clusterManagerId,
    required this.markerIds,
    required this.position,
    required this.bounds,
  });
  String clusterManagerId;
  List<String> markerIds;
  PlatformLatLng position;
  PlatformLatLngBounds bounds;
}

class PlatformMultiPointPoint {
  PlatformMultiPointPoint({required this.id, required this.latLng});
  String id;
  PlatformLatLng latLng;
}

class PlatformMultiPointOverlay {
  PlatformMultiPointOverlay({
    required this.id,
    required this.anchorU,
    required this.anchorV,
    required this.visible,
    required this.points,
    this.icon,
  });
  String id;
  PlatformBitmap? icon;
  double anchorU;
  double anchorV;
  bool visible;
  List<PlatformMultiPointPoint> points;
}

class PlatformMultiPointOverlayUpdate {
  PlatformMultiPointOverlayUpdate({
    required this.id,
    this.icon,
    this.anchorU,
    this.anchorV,
    this.visible,
    this.pointsToAdd = const [],
    this.pointsToChange = const [],
    this.pointIdsToRemove = const [],
  });
  String id;
  PlatformBitmap? icon;
  double? anchorU;
  double? anchorV;
  bool? visible;
  List<PlatformMultiPointPoint> pointsToAdd;
  List<PlatformMultiPointPoint> pointsToChange;
  List<String> pointIdsToRemove;
}

class PlatformMultiPointOverlayUpdates {
  PlatformMultiPointOverlayUpdates({
    required this.layersToAdd,
    required this.layersToChange,
    required this.layerIdsToRemove,
  });
  List<PlatformMultiPointOverlay> layersToAdd;
  List<PlatformMultiPointOverlayUpdate> layersToChange;
  List<String> layerIdsToRemove;
}

class PlatformMultiPointTap {
  PlatformMultiPointTap({
    required this.overlayId,
    required this.pointId,
    required this.latLng,
  });
  String overlayId;
  String pointId;
  PlatformLatLng latLng;
}

class PlatformOverlayTap {
  PlatformOverlayTap({required this.overlayId});
  String overlayId;
}

class PlatformMarkerDrag {
  PlatformMarkerDrag({required this.markerId, required this.position});
  String markerId;
  PlatformLatLng position;
}

class PlatformMapEvent {
  PlatformMapEvent({
    required this.type,
    this.cameraPosition,
    this.position,
    this.errorCode,
    this.errorMessage,
    this.cluster,
    this.multiPointTap,
    this.overlayTap,
    this.markerDrag,
  });
  PlatformMapEventType type;
  PlatformCameraPosition? cameraPosition;
  PlatformLatLng? position;
  PlatformMapErrorCode? errorCode;
  String? errorMessage;
  PlatformCluster? cluster;
  PlatformMultiPointTap? multiPointTap;
  PlatformOverlayTap? overlayTap;
  PlatformMarkerDrag? markerDrag;
}

/// Information passed to the platform view creation.
class PlatformMapViewCreationParams {
  PlatformMapViewCreationParams({
    required this.apiKey,
    required this.privacyStatement,
    required this.initialCameraPosition,
    required this.mapConfiguration,
    required this.initialCircles,
    required this.initialMarkers,
    required this.initialPolygons,
    required this.initialPolylines,
    required this.initialClusterManagers,
    required this.initialHeatmaps,
    required this.initialTileOverlays,
    required this.initialGroundOverlays,
  });
  final String apiKey;
  final PlatformPrivacyStatement privacyStatement;
  final PlatformCameraPosition initialCameraPosition;
  final PlatformMapOptions mapConfiguration;
  final List<PlatformCircle> initialCircles;
  final List<PlatformMarker> initialMarkers;
  final List<PlatformPolygon> initialPolygons;
  final List<PlatformPolyline> initialPolylines;
  final List<PlatformClusterManager> initialClusterManagers;
  List<PlatformHeatmap> initialHeatmaps;
  List<PlatformTileOverlay> initialTileOverlays;
  List<PlatformGroundOverlay> initialGroundOverlays;
}

@HostApi()
abstract class MapsApi {
  @async
  void waitForMap();
  void updateMapOptions(PlatformMapOptions options);
  void moveCamera(PlatformCameraUpdate update);
  void animateCamera(PlatformCameraUpdate update, int? durationMillis);
  PlatformLatLngBounds getVisibleRegion();
  void updateClusterManagers(PlatformClusterManagerUpdates updates);
  void updateMarkers(PlatformMarkerUpdates updates);
  void updatePolylines(PlatformPolylineUpdates updates);
  void updatePolygons(PlatformPolygonUpdates updates);
  void updateCircles(PlatformCircleUpdates updates);
  void updateGroundOverlays(PlatformGroundOverlayUpdates updates);
  void updateHeatmaps(PlatformHeatmapUpdates updates);
  void updateTileOverlays(PlatformTileOverlayUpdates updates);
  void clearTileCache(String tileOverlayId);
  void updateMultiPointOverlays(PlatformMultiPointOverlayUpdates updates);

  /// Show the info window for the marker with the given ID.
  void showInfoWindow(String markerId);

  /// Hide the info window for the marker with the given ID.
  void hideInfoWindow(String markerId);

  /// Returns true if the marker with the given ID is currently displaying its
  /// info window.
  bool isInfoWindowShown(String markerId);

  /// Gets the current map zoom level.
  double getZoomLevel();
  @async
  Uint8List takeSnapshot({bool failWithStatus = false});
  void disposeMap();
}

@FlutterApi()
abstract class MapsCallbackApi {
  /// Called when the map camera moves.
  void onCameraMove(PlatformCameraPosition cameraPosition);

  /// Called when the map camera moves end.
  void onCameraMoveEnd(PlatformCameraPosition cameraPosition);

  /// Called when the map, not a specifc map object, is tapped.
  void onTap(PlatformLatLng position);

  /// Called by the native tile worker to obtain one image tile.
  @async
  PlatformTile getTileOverlayTile(
    String tileOverlayId,
    PlatformTileCoordinate coordinate,
    int zoom,
  );

  /// Called when the map, not a specifc map object, is long pressed.
  void onLongPress(PlatformLatLng position);

  /// Called when a marker is tapped.
  void onMarkerTap(String markerId);

  /// Called when a marker drag starts.
  void onMarkerDragStart(String markerId, PlatformLatLng position);

  /// Called when a marker drag updates.
  void onMarkerDrag(String markerId, PlatformLatLng position);

  /// Called when a marker drag ends.
  void onMarkerDragEnd(String markerId, PlatformLatLng position);

  /// Called when a marker's info window is tapped.
  void onInfoWindowTap(String markerId);

  /// Called when a marker cluster is tapped.
  void onClusterTap(PlatformCluster cluster);

  /// Called when a polygon is tapped.
  void onPolygonTap(String polygonId);

  /// Called when a polyline is tapped.
  void onPolylineTap(String polylineId);

  /// Called when the user's location changes while the location layer is
  /// enabled.
  void onMyLocationChange(PlatformMyLocation location);
}

@HostApi()
abstract class MapsPlatformViewApi {
  // This is never actually called.
  void createView(PlatformMapViewCreationParams? type);
}
