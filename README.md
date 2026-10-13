# AMap Flutter Kit

高德地图 Flutter 插件集合。


- [`amap_kit_map`](packages/amap_kit_map/amap_kit_map/README.md)：支持 Android 与 iOS 的地图展示、相机控制、覆盖物和地图事件。
- [`amap_kit_location`](packages/amap_kit_location/amap_kit_location/README.md)：支持 Android 与 iOS 的定位



## 持续集成

[CI](.github/workflows/ci.yml) 在 Pull Request、`main` 推送及手动触发时运行。
固定使用 Flutter 3.47.5 / Java 17；新提交会取消同一分支的旧运行。

- Dart：全仓格式检查（排除 Pigeon 生成文件）、静态分析、有实际测试文件的 Workspace 包测试、Pigeon 重新生成差异检查。
- Android：地图与定位分别编译示例 debug APK，再运行各自实现包的 Kotlin 单元测试。Flutter 构建负责生成未入库的 Gradle wrapper。
- iOS：地图与定位分别在 macOS 上编译无签名设备版本，避免依赖高德 SDK 的模拟器架构支持。
- 架构：检查 core、平台接口及平台实现的 Workspace 依赖方向；依据 `tool/ci/native_sdks.yaml` 审计原生 SDK 声明变更。

本地可执行：

```bash
flutter pub get
dart run tool/ci/check_workspace.dart
dart run tool/ci/test_workspace.dart
flutter analyze --no-pub
dart run melos run gen:pigeon
```

SDK 审计记录当前声明，不代表不同平台版本号必须一致。当前 Android 地图使用组合 SDK、定位使用独立 SDK；iOS 地图 SDK 尚未锁定版本，因此 iOS 构建仍可能受上游更新影响。SDK 升级时应同时审查声明和审计文件。

CI 不需要 API Key 或签名证书，不执行真机定位/地图集成测试，也不自动发布 pub.dev。发布继续遵循 AGENTS.md 中的 Melos 流程。原生编译成功不代表权限流程与设备视觉行为已验证。
