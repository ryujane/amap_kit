import 'package:amap_kit_location_platform_interface/amap_kit_location_platform_interface.dart';

/// 高德定位的进程外部配置与系统能力入口。
abstract final class AmapLocation {
  /// 设置当前平台使用的高德定位 API Key。
  ///
  /// 应用必须在创建任何 [AmapLocationClient] 前调用此方法。Android 与 iOS
  /// 使用不同的 Key，调用方应根据当前平台传入对应值。若未调用，平台实现会
  /// 继续读取 AndroidManifest.xml 或 Info.plist 中的静态配置。
  static Future<void> setApiKey(String apiKey) {
    final String normalizedApiKey = apiKey.trim();
    if (normalizedApiKey.isEmpty) {
      return Future<void>.error(
        const AmapLocationApiKeyException('高德定位 API Key 不能为空。'),
      );
    }
    return AmapLocationPlatform.instance.setApiKey(normalizedApiKey);
  }

  /// 向高德原生 SDK 上报应用当前的隐私合规状态。
  ///
  /// 应用必须在创建任何 [AmapLocationClient] 前调用此方法，并确保状态来自
  /// 应用自己的隐私交互，而不是由插件代替用户作出选择。
  static Future<void> setPrivacyStatus(AmapLocationPrivacyStatus status) =>
      AmapLocationPlatform.instance.setPrivacyStatus(status);

  /// 查询设备的系统定位服务是否开启。
  static Future<bool> isLocationServiceEnabled() =>
      AmapLocationPlatform.instance.isLocationServiceEnabled();
}
