# amap_kit_location

基于高德原生定位 SDK 的 Flutter 前台定位插件（支持 Android 与 iOS），提供单次定位与持续定位两种独立操作。

平台与 SDK 版本：

| 平台 | 高德 SDK       | 版本       |
| --- |--------------|----------|
| Android | Location     | 11.2.100 |
| iOS | AMapLocation | 2.12.2   |

## 使用

创建客户端前先设置 API Key 与隐私合规状态：

```dart
await AmapLocation.setApiKey('your-amap-key'); // 不调用则回退读取原生静态配置
await AmapLocation.setPrivacyStatus(const AmapLocationPrivacyStatus(
  privacyNoticeShown: true,
  containsAmapPrivacyPolicy: true,
  userAgreed: true,
));
```

单次定位：

```dart
final client = AmapLocationClient();
final AmapLocationResult result = await client.getCurrentLocation();
client.dispose();
```

持续定位：

```dart
final client = AmapLocationClient(
  options: const AmapLocationOptions(interval: Duration(seconds: 2)),
);
client.locations.listen((AmapLocationResult result) {
  // 处理位置更新。
});
await client.start();
// ...
await client.stop();
client.dispose();
```

## 说明

- 应用需自行申请定位权限
