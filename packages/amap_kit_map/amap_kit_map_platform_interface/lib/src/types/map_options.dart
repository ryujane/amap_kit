import 'package:amap_kit_map_platform_interface/src/types/map_type.dart';
import 'package:amap_kit_map_platform_interface/src/types/my_location_style.dart';
import 'package:flutter/foundation.dart';

/// 地图视图的持续配置。
///
/// 所有字段均可空：`null` 表示“不修改该项”。这允许把 [diffFrom] 产生的部分更新
/// 直接提交给原生地图（原生端只应用非空字段，空字段保持当前值），也让
/// `const AmapMapConfiguration()` 成为一个不携带任何变更的空配置（[isEmpty]
/// 为 `true`）。
@immutable
final class AmapMapConfiguration {
  /// 创建地图持续配置。
  const AmapMapConfiguration({
    this.mapType,
    this.compassEnabled,
    this.scaleControlsEnabled,
    this.trafficEnabled,
    this.buildingsEnabled,
    this.rotateGesturesEnabled,
    this.scrollGesturesEnabled,
    this.tiltGesturesEnabled,
    this.zoomGesturesEnabled,
    this.myLocationEnabled,
    this.myLocationStyle,
    this.customMapStyle,
    this.mapId,
  });

  final String? mapId;

  /// 底图类型；`null` 表示不修改。
  final MapType? mapType;

  /// 是否显示指南针；`null` 表示不修改。
  final bool? compassEnabled;

  /// 是否显示比例尺控件；`null` 表示不修改。
  final bool? scaleControlsEnabled;

  /// 是否显示实时交通；`null` 表示不修改。
  final bool? trafficEnabled;

  /// 是否显示建筑物；`null` 表示不修改。
  final bool? buildingsEnabled;

  /// 是否启用旋转手势；`null` 表示不修改。
  final bool? rotateGesturesEnabled;

  /// 是否启用平移手势；`null` 表示不修改。
  final bool? scrollGesturesEnabled;

  /// 是否启用倾斜手势；`null` 表示不修改。
  final bool? tiltGesturesEnabled;

  /// 是否启用缩放手势；`null` 表示不修改。
  final bool? zoomGesturesEnabled;

  /// 是否显示并启用高德原生定位蓝点；`null` 表示不修改。
  ///
  /// 启用前调用方必须先获得前台定位权限；平台实现不会替调用方请求权限。
  final bool? myLocationEnabled;

  /// Optional appearance for the native AMap location blue dot.
  final AmapMyLocationStyle? myLocationStyle;

  /// 可选的自定义底图样式。
  ///
  /// 非空时应用 [AmapCustomMapStyle]，置空时恢复 SDK 默认底图样式。
  final AmapCustomMapStyle? customMapStyle;

  /// 与 [previous] 比较后，返回只携带变更字段的部分配置。
  ///
  /// 逐字段比较 `this`（新配置）与 [previous]（旧配置）：值不同的字段在结果中
  /// 携带新值，值相同的字段置为 `null`（表示不修改，原生端保持当前值）。所有
  /// 字段都未变化时 [isEmpty] 为 `true`，调用方可跳过原生更新。
  AmapMapConfiguration diffFrom(AmapMapConfiguration previous) {
    return AmapMapConfiguration(
      mapType: mapType != previous.mapType ? mapType : null,
      compassEnabled: compassEnabled != previous.compassEnabled
          ? compassEnabled
          : null,
      scaleControlsEnabled:
          scaleControlsEnabled != previous.scaleControlsEnabled
          ? scaleControlsEnabled
          : null,
      trafficEnabled: trafficEnabled != previous.trafficEnabled
          ? trafficEnabled
          : null,
      buildingsEnabled: buildingsEnabled != previous.buildingsEnabled
          ? buildingsEnabled
          : null,
      rotateGesturesEnabled:
          rotateGesturesEnabled != previous.rotateGesturesEnabled
          ? rotateGesturesEnabled
          : null,
      scrollGesturesEnabled:
          scrollGesturesEnabled != previous.scrollGesturesEnabled
          ? scrollGesturesEnabled
          : null,
      tiltGesturesEnabled: tiltGesturesEnabled != previous.tiltGesturesEnabled
          ? tiltGesturesEnabled
          : null,
      zoomGesturesEnabled: zoomGesturesEnabled != previous.zoomGesturesEnabled
          ? zoomGesturesEnabled
          : null,
      myLocationEnabled: myLocationEnabled != previous.myLocationEnabled
          ? myLocationEnabled
          : null,
      myLocationStyle: myLocationStyle != previous.myLocationStyle
          ? myLocationStyle
          : null,
      customMapStyle: customMapStyle != previous.customMapStyle
          ? customMapStyle
          : null,
      mapId: mapId != previous.mapId ? mapId : null,
    );
  }

  /// 当且仅当所有字段均为 `null`（不携带任何要应用的变更）时为 `true`。
  bool get isEmpty =>
      mapId == null &&
      mapType == null &&
      compassEnabled == null &&
      scaleControlsEnabled == null &&
      trafficEnabled == null &&
      buildingsEnabled == null &&
      rotateGesturesEnabled == null &&
      scrollGesturesEnabled == null &&
      tiltGesturesEnabled == null &&
      zoomGesturesEnabled == null &&
      myLocationEnabled == null &&
      myLocationStyle == null &&
      customMapStyle == null;
}

/// 高德自定义地图样式（GeoHUB 样式）的强类型模型。
///
/// 样式文件在控制台的地图自定义平台发布后获得：
/// [离线样式] 包含 `style.data`（必选）、`style_extra.data` 与 `textures.zip`
/// （可选），以字节提供；[在线样式] 通过 [styleId] 设置，但纹理仍须本地提供。
/// 若同时设置 [styleId] 与 [styleData]，原生 SDK 优先拉取在线样式，失败后回退
/// 到离线样式。纹理能力需要高德开放平台开通对应权限。字节字段在构造时被复制并
/// 冻结，模型是安全的值对象，可跨地图复用。
@immutable
final class AmapCustomMapStyle {
  /// 创建自定义地图样式。
  ///
  /// [styleData]（`style.data` 字节）与 [styleId]（在线样式 ID）至少提供其一；
  /// 仅设置 [styleExtraData] 或 [styleTextureData] 而没有主样式时会在调试模式
  /// 抛出 [AssertionError]。
  AmapCustomMapStyle({
    Uint8List? styleData,
    Uint8List? styleExtraData,
    Uint8List? styleTextureData,
    this.styleId,
  }) : assert(
         styleData != null || styleId != null,
         'AmapCustomMapStyle 必须提供 styleData 或 styleId。',
       ),
       styleData = styleData == null
           ? null
           : Uint8List.fromList(styleData).asUnmodifiableView(),
       styleExtraData = styleExtraData == null
           ? null
           : Uint8List.fromList(styleExtraData).asUnmodifiableView(),
       styleTextureData = styleTextureData == null
           ? null
           : Uint8List.fromList(styleTextureData).asUnmodifiableView();

  /// `style.data` 的具体样式配置字节。返回的视图不可修改。
  final Uint8List? styleData;

  /// `style_extra.data` 的扩展内容字节（如网格背景色）。返回的视图不可修改。
  final Uint8List? styleExtraData;

  /// `textures.zip` 的纹理图片字节。返回的视图不可修改。
  final Uint8List? styleTextureData;

  /// 控制台发布的在线样式 ID。
  final String? styleId;

  @override
  bool operator ==(Object other) =>
      other is AmapCustomMapStyle &&
      other.styleId == styleId &&
      listEquals(other.styleData, styleData) &&
      listEquals(other.styleExtraData, styleExtraData) &&
      listEquals(other.styleTextureData, styleTextureData);

  @override
  int get hashCode => Object.hash(
    styleId,
    Object.hashAll(styleData ?? const <int>[]),
    Object.hashAll(styleExtraData ?? const <int>[]),
    Object.hashAll(styleTextureData ?? const <int>[]),
  );
}
