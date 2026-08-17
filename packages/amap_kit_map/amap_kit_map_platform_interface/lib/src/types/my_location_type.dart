/// Behavior of the native user-location blue dot.
///
/// Mirrors AMap's `MyLocationStyle.myLocationType` modes on Android. On iOS the
/// field has no effect; the iOS implementation keeps its own tracking behavior.
enum AmapMyLocationType {
  /// Show the location once without following (`LOCATION_TYPE_SHOW`).
  show,

  /// Follow the location while keeping the map stationary
  /// (`LOCATION_TYPE_LOCATE`).
  locate,

  /// Follow the location with the camera centered (`LOCATION_TYPE_FOLLOW`).
  follow,

  /// Follow the location, rotating the dot with the map
  /// (`LOCATION_TYPE_MAP_ROTATE`).
  mapRotate,

  /// Follow the location, rotating the dot with the heading and centering the
  /// camera (`LOCATION_TYPE_LOCATION_ROTATE`).
  locationRotate,

  /// Rotate the dot with the heading without centering the camera
  /// (`LOCATION_TYPE_LOCATION_ROTATE_NO_CENTER`).
  locationRotateNoCenter,

  /// Follow the location without centering the camera
  /// (`LOCATION_TYPE_FOLLOW_NO_CENTER`).
  followNoCenter,

  /// Rotate the dot with the map without centering the camera
  /// (`LOCATION_TYPE_MAP_ROTATE_NO_CENTER`).
  mapRotateNoCenter,
}
