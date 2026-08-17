import 'package:amap_kit_location_platform_interface/src/location_types.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// 高德定位插件的平台契约。
abstract class AmapLocationPlatform extends PlatformInterface {
  /// 创建平台实现。
  AmapLocationPlatform() : super(token: _token);

  static final Object _token = Object();
  static AmapLocationPlatform _instance = _UnsupportedAmapLocationPlatform();

  /// 当前平台实现。
  static AmapLocationPlatform get instance => _instance;

  /// 替换当前平台实现。
  static set instance(AmapLocationPlatform value) {
    PlatformInterface.verifyToken(value, _token);
    _instance = value;
  }

  /// 设置当前平台使用的高德定位 API Key。
  ///
  /// 实现必须在创建首个原生定位客户端前完成设置，并拒绝在创建过客户端后切换。
  Future<void> setApiKey(String apiKey) =>
      throw const AmapLocationUnsupportedException();

  /// 向原生 SDK 上报应用的隐私合规状态。
  Future<void> setPrivacyStatus(AmapLocationPrivacyStatus status) =>
      throw const AmapLocationUnsupportedException();

  /// 查询系统定位服务是否开启。
  Future<bool> isLocationServiceEnabled() =>
      throw const AmapLocationUnsupportedException();

  /// 创建原生定位客户端并返回实例 ID。
  Future<int> createClient(AmapLocationOptions options) =>
      throw const AmapLocationUnsupportedException();

  /// 替换指定原生客户端的定位配置。
  ///
  /// 客户端正在持续定位或执行单次定位时，实现必须明确拒绝更新。
  Future<void> setLocationOption(int clientId, AmapLocationOptions options) =>
      throw const AmapLocationUnsupportedException();

  /// 请求一次独立的定位结果。
  Future<AmapLocationResult> getCurrentLocation(int clientId) =>
      throw const AmapLocationUnsupportedException();

  /// 返回只属于指定客户端的持续定位结果流。
  Stream<AmapLocationResult> locationsForClient(int clientId) =>
      Stream<AmapLocationResult>.error(
        const AmapLocationUnsupportedException(),
      );

  /// 启动持续定位；重复调用必须幂等。
  Future<void> start(int clientId) =>
      throw const AmapLocationUnsupportedException();

  /// 停止持续定位；重复调用必须幂等。
  Future<void> stop(int clientId) =>
      throw const AmapLocationUnsupportedException();

  /// 释放原生客户端及其监听器。
  Future<void> disposeClient(int clientId) =>
      throw const AmapLocationUnsupportedException();
}

final class _UnsupportedAmapLocationPlatform extends AmapLocationPlatform {}
