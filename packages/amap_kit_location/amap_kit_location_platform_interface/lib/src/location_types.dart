import 'package:amap_kit_core/amap_kit_core.dart';
import 'package:flutter/foundation.dart';

/// 定位精度与功耗之间的偏好。
enum AmapLocationAccuracy {
  /// 优先获得尽可能精确的位置。
  high,

  /// 在定位精度与功耗之间取得平衡。
  balanced,

  /// 优先降低定位功耗。
  lowPower,
}

/// Android 高德定位 SDK 的定位模式。
enum AmapLocationAndroidMode {
  /// 同时使用网络与卫星定位，并优先返回精度较高的结果。
  highAccuracy,

  /// 仅使用网络定位以降低功耗。
  batterySaving,

  /// 仅使用设备卫星定位，不支持室内定位。
  deviceSensors,
}

/// Android 高德定位 SDK 的联网协议。
///
/// 该设置由原生 SDK 以进程级状态保存，同一进程中的客户端必须使用相同值。
enum AmapLocationAndroidProtocol {
  /// 使用 HTTP。
  http,

  /// 使用 HTTPS。
  https,
}

/// Android 高德定位 SDK 的预设定位场景。
enum AmapLocationAndroidPurpose {
  /// 签到场景，倾向于获取一次更接近真实位置的结果。
  signIn,

  /// 出行场景，适用于室内外切换的持续定位。
  transport,

  /// 运动场景，适用于室内外切换的高精度持续定位。
  sport,
}

/// Android 逆地理信息的语言。
enum AmapLocationAndroidGeoLanguage {
  /// 国内返回中文、国外返回英文。
  system,

  /// 始终返回中文。
  chinese,

  /// 始终返回英文。
  english,
}

/// iOS Core Location 的标准期望精度档位。
///
/// 精度越高通常越耗电，系统会尽力满足但不保证达到所选精度。
enum AmapLocationIosDesiredAccuracy {
  /// 导航场景的最高精度。
  bestForNavigation,

  /// 当前设备可提供的最佳精度。
  best,

  /// 约十米精度。
  nearestTenMeters,

  /// 约百米精度。
  hundredMeters,

  /// 约一公里精度。
  kilometer,

  /// 约三公里精度。
  threeKilometers,
}

/// iOS 14+ 的定位精度授权模式。
enum AmapLocationIosAccuracyMode {
  /// 优先申请临时精确定位，未获得时仍返回降低精度的位置。
  fullAndReduced,

  /// 必须获得临时精确定位，否则定位以原生错误失败。
  full,

  /// 不申请临时精确定位，按当前授权精度返回位置。
  reduced,
}

/// iOS 高德定位管理器参数。
@immutable
final class AmapLocationIosOptions {
  /// 创建 iOS 定位参数。
  const AmapLocationIosOptions({
    this.desiredAccuracy,
    this.distanceFilterMeters,
    this.pausesLocationUpdatesAutomatically = false,
    this.locationAccuracyMode,
    this.fullAccuracyPurposeKey,
  });

  /// 期望定位精度；为空时根据跨平台 [AmapLocationOptions.accuracy] 推导。
  final AmapLocationIosDesiredAccuracy? desiredAccuracy;

  /// 触发持续定位更新的最小移动距离，单位为米。
  ///
  /// 为空时使用 `kCLDistanceFilterNone`，位置发生变化即可更新。
  final double? distanceFilterMeters;

  /// 是否允许 iOS 在判断设备不再移动时自动暂停持续定位。
  final bool pausesLocationUpdatesAutomatically;

  /// iOS 14+ 的定位精度授权策略。
  ///
  /// 选择 [AmapLocationIosAccuracyMode.fullAndReduced] 或
  /// [AmapLocationIosAccuracyMode.full] 时，必须同时提供
  /// [fullAccuracyPurposeKey]。
  final AmapLocationIosAccuracyMode? locationAccuracyMode;

  /// 申请临时精确定位时使用的 Purpose Key。
  ///
  /// 该 Key 必须存在于应用 `Info.plist` 的
  /// `NSLocationTemporaryUsageDescriptionDictionary` 字典中。
  final String? fullAccuracyPurposeKey;
}

/// Android 高德定位 SDK 的完整客户端参数。
///
/// 这些参数只在 Android 生效。将非空 Android 配置传给 iOS 会明确报告
/// [AmapLocationUnsupportedException]，调用方应按平台选择是否提供。
@immutable
final class AmapLocationAndroidOptions {
  /// 创建 Android 定位参数。
  ///
  /// [locationPurpose] 会先应用，随后其余显式参数覆盖场景中的冲突值。
  const AmapLocationAndroidOptions({
    this.locationMode,
    this.protocol = AmapLocationAndroidProtocol.https,
    this.httpTimeout = const Duration(seconds: 30),
    this.mockEnabled = true,
    this.needAddress = false,
    this.wifiScanEnabled = true,
    this.alwaysScanWifi = true,
    this.locationCacheEnabled = true,
    this.onceLocationLatest = true,
    this.sensorEnabled = false,
    this.gpsFirst = false,
    this.gpsFirstTimeout = const Duration(seconds: 30),
    this.beidouFirst = false,
    this.deviceModeDistanceFilterMeters = 0,
    this.geoLanguage = AmapLocationAndroidGeoLanguage.system,
    this.locationPurpose,
    this.coordinateOffsetEnabled = true,
    this.selfStartServiceEnabled = false,
    this.killProcessOnDestroy = false,
  });

  /// 原生定位模式；为空时根据跨平台 [AmapLocationOptions.accuracy] 推导。
  final AmapLocationAndroidMode? locationMode;

  /// SDK 联网协议；该值为进程级设置，建议保持 HTTPS。
  final AmapLocationAndroidProtocol protocol;

  /// 网络定位请求超时。
  final Duration httpTimeout;

  /// 是否接受系统模拟位置。
  final bool mockEnabled;

  /// 是否请求逆地理地址信息。
  ///
  /// 请改用跨平台的 [AmapLocationOptions.needAddress]。为了保持 0.1.0
  /// 调用兼容性，该值为 `true` 时仍会在 Android 开启地址解析。
  @Deprecated('Use AmapLocationOptions.needAddress instead.')
  final bool needAddress;

  /// 是否允许 SDK 主动刷新 Wi-Fi。
  final bool wifiScanEnabled;

  /// Wi-Fi 关闭时是否仍尝试扫描。
  ///
  /// 这是进程级参数，且仅在应用具备系统级
  /// `android.permission.WRITE_SECURE_SETTINGS` 权限时有效。
  final bool alwaysScanWifi;

  /// 是否使用高德定位缓存策略。
  final bool locationCacheEnabled;

  /// 首次定位是否等待 Wi-Fi 列表刷新以提高精度。
  final bool onceLocationLatest;

  /// 网络定位时是否使用传感器补充海拔、方向和速度。
  final bool sensorEnabled;

  /// 高精度单次定位是否优先等待卫星定位结果。
  final bool gpsFirst;

  /// 优先等待卫星定位结果的时间，必须为 5 至 30 秒。
  final Duration gpsFirstTimeout;

  /// 是否优先使用北斗卫星定位。
  final bool beidouFirst;

  /// 系统定位自动回调的最小移动距离，单位为米。
  final double deviceModeDistanceFilterMeters;

  /// 逆地理地址信息的语言。
  final AmapLocationAndroidGeoLanguage geoLanguage;

  /// 高德 SDK 的预设定位场景。
  final AmapLocationAndroidPurpose? locationPurpose;

  /// 是否将原始坐标偏移为高德坐标。
  final bool coordinateOffsetEnabled;

  /// 定位服务异常退出后是否允许自行重启。
  ///
  /// 启用可能延长 Android 定位服务生命周期，调用方必须自行满足系统合规要求。
  final bool selfStartServiceEnabled;

  /// 销毁 SDK 客户端时是否允许原生 SDK 杀死所在进程。
  ///
  /// 此选项风险很高，默认关闭；多 Engine 应用不应启用。
  final bool killProcessOnDestroy;
}

/// 应用当前获得的前台定位权限。
enum AmapLocationPermissionStatus {
  /// 用户尚未响应过定位权限请求。
  notDetermined,

  /// 用户拒绝了权限，但系统仍允许再次请求。
  denied,

  /// 用户永久拒绝了权限，需要前往系统设置修改。
  deniedForever,

  /// 权限受到系统或家长控制限制。
  restricted,

  /// 仅获得了粗略位置权限。
  reducedAccuracy,

  /// 已获得精确位置权限。
  fullAccuracy,
}

/// 应用向高德 SDK 上报的隐私合规状态。
@immutable
final class AmapLocationPrivacyStatus {
  /// 创建隐私合规状态。
  const AmapLocationPrivacyStatus({
    required this.privacyNoticeShown,
    required this.containsAmapPrivacyPolicy,
    required this.userAgreed,
  });

  /// 应用是否已经向用户展示隐私说明。
  final bool privacyNoticeShown;

  /// 隐私说明是否包含高德 SDK 隐私政策。
  final bool containsAmapPrivacyPolicy;

  /// 用户是否同意了包含高德条款的隐私说明。
  final bool userAgreed;
}

/// 定位客户端的前台定位配置。
@immutable
final class AmapLocationOptions {
  /// 创建定位配置。
  ///
  /// 持续定位间隔不得短于一秒；单次定位超时不得短于两秒。
  const AmapLocationOptions({
    this.accuracy = AmapLocationAccuracy.high,
    this.interval = const Duration(seconds: 2),
    this.timeout = const Duration(seconds: 15),
    this.needAddress = false,
    this.android,
    this.ios,
  });

  /// 定位精度与功耗偏好。
  final AmapLocationAccuracy accuracy;

  /// 持续定位结果的期望间隔。
  final Duration interval;

  /// 单次定位的最大等待时间。
  ///
  /// iOS 开启 [needAddress] 时，该值也作为逆地理请求超时。
  final Duration timeout;

  /// 是否请求逆地理地址信息。
  ///
  /// 开启后 Android 与 iOS 都会联网解析地址，并通过
  /// [AmapLocationResult.address] 返回。解析失败时位置仍可能成功，而地址为空。
  final bool needAddress;

  /// Android 专属的高德 SDK 参数。
  ///
  /// 为空时保持插件 0.1.0 的默认行为。
  final AmapLocationAndroidOptions? android;

  /// iOS 专属的高德 SDK 参数。
  ///
  /// 为空时保持插件默认行为。
  final AmapLocationIosOptions? ios;
}

/// 定位 SDK 返回的结构化逆地理地址。
@immutable
final class AmapLocationAddress {
  /// 创建逆地理地址。
  const AmapLocationAddress({
    this.formattedAddress,
    this.country,
    this.province,
    this.city,
    this.district,
    this.cityCode,
    this.adCode,
    this.street,
    this.streetNumber,
    this.poiName,
    this.aoiName,
  });

  /// 可直接展示的格式化地址。
  final String? formattedAddress;

  /// 国家或地区。
  final String? country;

  /// 省或直辖市。
  final String? province;

  /// 城市。
  final String? city;

  /// 区县。
  final String? district;

  /// 高德城市编码。
  final String? cityCode;

  /// 高德行政区编码。
  final String? adCode;

  /// 街道名称。
  final String? street;

  /// 门牌号。
  final String? streetNumber;

  /// 兴趣点名称。
  final String? poiName;

  /// 所属兴趣区域名称。
  final String? aoiName;
}

/// 一次成功的定位结果。
@immutable
final class AmapLocationResult {
  /// 创建定位结果。
  const AmapLocationResult({
    required this.position,
    required this.timestamp,
    required this.accuracyMeters,
    this.coordinateType,
    this.address,
  });

  /// 设备位置。
  final LatLng position;

  /// 原生 SDK 生成该结果的时间。
  final DateTime timestamp;

  /// 以米为单位的水平精度半径。
  final double accuracyMeters;

  /// 原生 SDK 能够明确报告时使用的坐标系。
  final AmapCoordinateType? coordinateType;

  /// 请求逆地理信息且原生 SDK 成功解析时返回的地址。
  final AmapLocationAddress? address;
}

/// 定位插件公开错误的基类。
sealed class AmapLocationException implements Exception {
  /// 创建定位错误。
  const AmapLocationException(this.code, this.message);

  /// 稳定的机器可读错误码。
  final String code;

  /// 面向开发者的错误说明。
  final String message;

  @override
  String toString() => '$runtimeType($code): $message';
}

/// 当前平台不支持请求的定位能力。
final class AmapLocationUnsupportedException extends AmapLocationException {
  /// 创建不支持能力错误。
  const AmapLocationUnsupportedException([String? message])
    : super('unsupported', message ?? '当前平台不支持该定位能力。');
}

/// 应用尚未正确上报隐私合规状态。
final class AmapLocationPrivacyException extends AmapLocationException {
  /// 创建隐私合规错误。
  const AmapLocationPrivacyException([String? message])
    : super('privacy_not_configured', message ?? '请在创建定位客户端前上报隐私合规状态。');
}

/// 应用未配置有效的高德 API Key。
final class AmapLocationApiKeyException extends AmapLocationException {
  /// 创建 API Key 错误。
  const AmapLocationApiKeyException([String? message])
    : super('api_key_missing', message ?? '应用未配置有效的高德定位 API Key。');
}

/// 当前定位权限不足。
final class AmapLocationPermissionException extends AmapLocationException {
  /// 创建权限错误。
  AmapLocationPermissionException(this.status, [String? message])
    : super('permission_${status.name}', message ?? '当前定位权限不足：${status.name}。');

  /// 导致操作失败的权限状态。
  final AmapLocationPermissionStatus status;
}

/// 系统定位服务已关闭。
final class AmapLocationServiceDisabledException extends AmapLocationException {
  /// 创建系统服务关闭错误。
  const AmapLocationServiceDisabledException([String? message])
    : super('service_disabled', message ?? '系统定位服务已关闭。');
}

/// 单次定位请求超时。
final class AmapLocationTimeoutException extends AmapLocationException {
  /// 创建定位超时错误。
  const AmapLocationTimeoutException([String? message])
    : super('timeout', message ?? '定位请求超时。');
}

/// 原生高德定位 SDK 初始化失败。
final class AmapLocationInitializationException extends AmapLocationException {
  /// 创建初始化错误。
  const AmapLocationInitializationException([String? message])
    : super('sdk_initialization_failed', message ?? '高德定位 SDK 初始化失败。');
}

/// 当前版本不支持后台定位。
final class AmapLocationBackgroundUnsupportedException
    extends AmapLocationException {
  /// 创建后台定位不支持错误。
  const AmapLocationBackgroundUnsupportedException([String? message])
    : super('background_unsupported', message ?? '当前版本不支持后台定位。');
}

/// 当前客户端已经存在互斥的定位操作。
final class AmapLocationOperationInProgressException
    extends AmapLocationException {
  /// 创建操作冲突错误。
  const AmapLocationOperationInProgressException([String? message])
    : super('operation_in_progress', message ?? '定位客户端已有操作正在进行。');
}

/// 定位客户端已经释放。
final class AmapLocationDisposedException extends AmapLocationException {
  /// 创建已释放错误。
  const AmapLocationDisposedException() : super('disposed', '定位客户端已释放。');
}

/// 原生端找不到指定的定位客户端。
final class AmapLocationClientNotFoundException extends AmapLocationException {
  /// 创建客户端不存在错误。
  const AmapLocationClientNotFoundException([String? message])
    : super('client_not_found', message ?? '原生定位客户端不存在或已经释放。');
}

/// 无法归类的原生定位错误。
final class AmapLocationUnknownException extends AmapLocationException {
  /// 创建未知定位错误。
  const AmapLocationUnknownException([String? message])
    : super('unknown', message ?? '发生未知定位错误。');
}
