import 'package:amap_kit_map_platform_interface/amap_kit_map_platform_interface.dart';

/// 高德开放平台 API Key，通过 `--dart-define=AMAP_API_KEY=<key>` 传入。
const String exampleApiKey = String.fromEnvironment('AMAP_API_KEY');

/// 高德 SDK 合规所需的隐私声明配置。
///
/// 详见高德开放平台合规使用方案：https://lbs.amap.com/news/sdkhgsy
const AMapPrivacyStatement examplePrivacyStatement = AMapPrivacyStatement(
  hasContains: true,
  hasShow: true,
  hasAgree: true,
);

/// 地图实例标识；示例仅创建一张地图，使用空字符串即可。
const String exampleMapId = '';
