// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:amap_kit_map_platform_interface/src/types/types.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// 构建地图 Widget 时的容器配置。
///
/// 作为平台接口 [AmapMapPlatform.buildView] 的参数使用，把 Widget 层面的配置
/// （初始相机、文本方向、手势识别器）聚合在一个不可变对象中，便于以后向同一
/// 方法追加新的配置项而不改变方法签名。地图本身的持续配置见
/// [AmapMapConfiguration]，初始覆盖物见 [MapObjects]。
@immutable
final class MapWidgetConfiguration {
  /// 创建地图 Widget 配置。
  const MapWidgetConfiguration({
    required this.initialCameraPosition,
    required this.apiKey,
    required this.privacyStatement,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
  });

  ///高德开放平台api key配置
  ///
  ///申请key请到高德开放平台官网:https://lbs.amap.com/
  ///
  ///Android平台的key的获取请参考：https://lbs.amap.com/api/poi-sdk-android/develop/create-project/get-key/?sug_index=2
  ///
  ///iOS平台key的获取请参考：https://lbs.amap.com/api/poi-sdk-ios/develop/create-project/get-key/?sug_index=1
  final String apiKey;

  final AMapPrivacyStatement privacyStatement;

  /// 地图初始显示的相机位置。
  final CameraPosition initialCameraPosition;

  /// 添加到 Widget 的手势识别器。
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;
}
