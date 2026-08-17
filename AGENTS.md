# AMap Flutter Kit Agent 指南

本文档是本仓库所有编码 Agent 的工作约定。任何改动前都必须阅读；它同时说明项目架构与适用于各包的代码规范。

## 项目目标与当前状态

AMap Flutter Kit 提供基于高德原生 SDK、可独立演进的 Flutter 插件产品：

- 地图展示与交互。
- 设备定位。

目标架构为面向 Android 和 iOS 的 Flutter 联邦插件 Pub Workspace，并由 Melos 管理。初期实现可以将 Android 和 iOS 原生代码放在面向应用的包内，但每个产品仍必须拥有独立的平台接口包。下列目录是目标架构；在假设某个包已经存在前，先检查仓库实际状态。

```text
packages/
  amap_kit_core/
  amap_kit_map/amap_kit_map/
  amap_kit_map/amap_kit_map_platform_interface/
  amap_kit_map/amap_kit_map_android/
  amap_kit_map/amap_kit_map_ios/
  amap_kit_location/amap_kit_location/
  amap_kit_location/amap_kit_location_platform_interface/
  amap_kit_location/amap_kit_location_android/
  amap_kit_location/amap_kit_location_ios/
```

各产品必须能独立演进、测试、版本化和发布。不得引入全局共享的 `amap_kit_platform_interface`。

## 包职责与依赖方向

| 包类型 | 职责 | 不得承担 |
| --- | --- | --- |
| 面向应用的包 | 公开 Flutter API、组件、模型、控制器、文档和默认实现选择 | 生成的传输类型或原生集成细节 |
| 产品平台接口包 | 抽象原生契约和测试替身入口 | 依赖具体实现 |
| Android/iOS 实现包 | 原生 SDK 集成、插件注册、平台视图、Pigeon 转换、资源生命周期和错误映射 | 依赖面向应用的包 |
| `amap_kit_core` | 稳定、产品无关的模型和工具 | 原生通道、插件注册、控制器、会话或产品专属类型 |

允许的依赖方向为：面向应用的包 -> 该产品的平台接口 -> core，以及实现包 -> 该产品的平台接口 -> core。面向应用的包可以选择默认平台实现，但实现包不得反向依赖它。跨产品或跨产品平台接口的依赖需要在 `docs/adr/` 中记录 ADR。与其建立错误依赖，不如保留少量重复的辅助代码。

仅当一个类型同时满足以下条件时，才可放入 `amap_kit_core`：至少被两个产品使用、语义完全一致、足够稳定以作为共享公开契约、且不包含原生通道或产品生命周期知识。Core 默认应为纯 Dart 包。

## 不可违背的架构规则

- 公开 API 使用强类型、不可变的 Dart 模型；不得暴露 `Map<String, dynamic>` 或 Pigeon 类型。
- Pigeon 生成的 DTO 必须保持私有，存放于生成源码目录。不得手动修改生成文件：修改 schema 后，使用 `melos run gen:pigeon` 重新生成所有受影响的 Dart、Kotlin、Swift 或 Objective-C 输出，并一并提交。生成文件不参与 `dart format`，其格式由 pigeon 生成器决定。
- 每个原生对象、命令、回调和事件流都必须以显式实例 ID（`mapId`、`clientId` 或 `sessionId`）隔离。事件绝不能跨实例投递。
- 控制器、定位客户端和导航会话必须显式释放。取消订阅、释放原生监听器与对象，并在释放后以强类型错误拒绝调用。
- 将原生失败映射为稳定的强类型 Dart 异常。不支持的能力必须可检测或显式失败，禁止静默无操作。
- 默认不得记录 API Key、精确坐标或个人数据。后台定位和敏感 SDK 初始化必须由调用方显式选择启用。
- 各产品独立遵循语义化版本；不得让不相关产品锁步发布。

## 产品契约

### 地图

`amap_kit_map` 负责 `AmapMap`、`AmapMapController`、相机 API、强类型覆盖物、配置与公开事件。控制器只能在原生视图可用后创建；释放时取消事件订阅并调用原生地图释放。即使 Dart 侧未完成清理，原生地图视图释放时也必须回收资源。

覆盖物 ID 应为不可变强类型；标记、折线、多边形和圆形的更新应使用“新增、变更、删除”的差分模型。Android 和 iOS 实现负责平台视图生命周期与原生监听器清理。必须测试多地图事件隔离、释放行为和覆盖物差分。

### 定位

`amap_kit_location` 使用显式的 `AmapLocationClient` 实例。单次定位与持续定位是两个独立操作。每个客户端拥有 `clientId`；重复调用 `start`/`stop` 的行为必须确定且文档化。释放时必须移除原生监听器、阻止迟到事件、按文档关闭或终止流，并使后续调用以强类型“已释放”错误失败。

公开错误必须区分权限状态、系统定位服务关闭、超时、原生初始化失败和不支持后台模式。后台定位必须显式启用，并文档化所需权限、系统指示与生命周期行为。

## 变更流程

修改代码前，阅读目标包的 `pubspec.yaml`、根目录 README，以及存在时的 `CONTRIBUTING.md`；并阅读 `docs/` 下的适用文档：`core-package.md`、`map-plugin.md`、`location-plugin.md`、`navigation-plugin.md`。涉及依赖、生成代码、CI、版本或发布时，还必须阅读 `engineering-governance.md`。

修改公开 API 时，使用不可变强类型模型，补充 Dart 文档和测试，更新包的 changelog，评估 SemVer 影响；除非已授权破坏性变更，否则保持源代码兼容。修改平台接口时，优先提供带默认实现的向后兼容方法；同步更新 fake、Android、iOS、测试、实例隔离和不支持平台说明。

修改原生代码时，验证释放和平台视图销毁时的清理，并阻止取消或释放后的迟到回调。适用时先运行不依赖原生 SDK 的单元测试，再运行受影响平台的设备集成测试。

## Workspace、发布与验证

- 使用仓库已有的 Pub Workspace 和 Melos 配置；不得自行猜测命令语法或版本约束。
- 原生 SDK 版本必须由单一来源审计，并校验 Gradle 与 CocoaPods 声明一致。升级 SDK 时记录系统版本、权限/隐私、行为、二进制体积和迁移影响。
- 每个产品按需具备模型/单元测试、平台接口测试、带 fake 平台的面向应用包测试，以及 Android/iOS 设备集成测试。
- 完成前，格式化代码，使用 `flutter_lints` 进行分析，运行相关测试，校验依赖与生成文件新鲜度；必要时更新公开文档、changelog 和版本元数据。
- 变更包的 CI 应覆盖格式化、分析、单元测试、依赖规则、生成代码新鲜度、原生 SDK 版本校验、Android 编译，以及 CI 可用时的 iOS 编译。根 Workspace 包不得发布。

## Flutter 与 Dart 代码规范

- 优先使用简洁、声明式的组合，而非继承。组件保持不可变，并区分组件临时状态与应用状态。
- 类型使用 `PascalCase`，成员使用 `camelCase`，文件使用 `snake_case`。避免含义不明的缩写，函数保持单一职责。
- 使用健全的空安全。除非不变量已被保证，否则避免 `!`。异步操作使用 `async`/`await`，事件序列使用 `Stream`。
- 优先使用 `const` 构造函数和不可变字段。仅在提升可读性时使用模式匹配、switch 表达式、records 和箭头函数。
- 使用具体异常审慎处理失败，禁止静默失败。使用 `dart:developer` 的 `log`，不要使用 `print`。
- 公开 API 使用 `///` 文档注释。说明“为什么”而非复述代码，从面向用户的完整句子开始，并说明平台差异和生命周期要求。
- 正确使用 `Expanded`、`Flexible`、`Wrap`、滚动组件和基于 builder 的列表。支持字体缩放，文本对比度至少为 4.5:1，并提供有意义的语义标签。
- 优先使用 package import。保持 `analysis_options.yaml` 与 `flutter_lints` 一致，包括 `avoid_print`、`prefer_single_quotes` 和 `always_use_package_imports`。
- 使用可用的 Dart/Flutter 格式化工具格式化修改过的 Dart 代码；适用时执行安全的自动修复，随后运行 linter/analyzer。

## 完成检查清单

- 包的归属与依赖方向正确。
- 公开契约强类型化、有文档、有测试，并符合 SemVer。
- 生命周期、实例路由和迟到回调行为均已覆盖。
- Android 和 iOS 均已实现，或显式报告不支持。
- 受影响的生成源码、公开文档、changelog 和版本元数据已更新。
- 格式化、分析和相关测试均已通过。
