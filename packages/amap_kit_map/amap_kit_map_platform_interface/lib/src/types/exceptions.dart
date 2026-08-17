/// 地图插件异常的稳定基类。
sealed class AmapMapException implements Exception {
  const AmapMapException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => '$runtimeType($code): $message';
}

/// 当前平台不支持所请求的地图能力。
final class AmapMapUnsupportedException extends AmapMapException {
  const AmapMapUnsupportedException([String? message])
    : super('unsupported', message ?? '当前平台不支持该地图能力。');
}

/// 地图 API Key 无效或未配置。
final class AmapMapApiKeyException extends AmapMapException {
  const AmapMapApiKeyException([String? message])
    : super('api_key', message ?? '高德地图 API Key 无效或未配置。');
}

/// 应用尚未完成地图 SDK 所需的隐私合规配置。
final class AmapMapPrivacyException extends AmapMapException {
  const AmapMapPrivacyException([String? message])
    : super('privacy', message ?? '尚未完成高德地图隐私合规配置。');
}

/// 未获得显示地图定位蓝点所需的前台定位权限。
final class AmapMapLocationPermissionException extends AmapMapException {
  const AmapMapLocationPermissionException([String? message])
    : super('location_permission', message ?? '显示定位蓝点前必须获得前台定位权限。');
}

/// Marker bitmap data could not be loaded or decoded by the native map.
final class AmapMapMarkerIconException extends AmapMapException {
  const AmapMapMarkerIconException([String? message])
    : super('marker_icon', message ?? '地图标记图标无法加载或解码。');
}

/// 地图实例已释放，不能再调用控制器。
final class AmapMapDisposedException extends AmapMapException {
  const AmapMapDisposedException() : super('disposed', '地图控制器已释放。');
}

/// 原生地图初始化失败。
final class AmapMapInitializationException extends AmapMapException {
  const AmapMapInitializationException([String? message])
    : super('initialization', message ?? '原生地图初始化失败。');
}

/// 找不到对应的原生地图实例。
final class AmapMapNotFoundException extends AmapMapException {
  const AmapMapNotFoundException([String? message])
    : super('map_not_found', message ?? '找不到指定的地图实例。');
}

/// 未能分类的原生地图错误。
final class AmapMapUnknownException extends AmapMapException {
  const AmapMapUnknownException([String? message])
    : super('unknown', message ?? '高德地图发生未知错误。');
}
