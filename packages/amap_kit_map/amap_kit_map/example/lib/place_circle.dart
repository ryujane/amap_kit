// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:amap_kit_map/amap_kit_map.dart';
import 'package:flutter/material.dart';

import 'example_config.dart';
import 'page.dart';

class PlaceCirclePage extends MapExampleAppPage {
  const PlaceCirclePage({super.key})
    : super(const Icon(Icons.linear_scale), '圆形示例');

  @override
  Widget build(BuildContext context) {
    return const PlaceCircleBody();
  }
}

class PlaceCircleBody extends StatefulWidget {
  const PlaceCircleBody({super.key});

  @override
  State<StatefulWidget> createState() => PlaceCircleBodyState();
}

class PlaceCircleBodyState extends State<PlaceCircleBody> {
  PlaceCircleBodyState();

  AmapMapController? controller;
  Map<CircleId, Circle> circles = <CircleId, Circle>{};
  int _circleIdCounter = 1;
  CircleId? selectedCircle;

  // Values when toggling circle color
  int fillColorsIndex = 0;
  int strokeColorsIndex = 0;
  List<Color> colors = <Color>[
    Colors.purple,
    Colors.red,
    Colors.green,
    Colors.pink,
  ];

  // Values when toggling circle stroke width
  int widthsIndex = 0;
  List<double> widths = <double>[10, 20, 5];

  // ignore: use_setters_to_change_properties
  void _onMapCreated(AmapMapController controller) {
    this.controller = controller;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _remove(CircleId circleId) {
    setState(() {
      if (circles.containsKey(circleId)) {
        circles.remove(circleId);
      }
      if (circleId == selectedCircle) {
        selectedCircle = null;
      }
    });
  }

  void _add() {
    final int circleCount = circles.length;

    if (circleCount == 12) {
      return;
    }

    final circleIdVal = 'circle_id_$_circleIdCounter';
    _circleIdCounter++;
    final circleId = CircleId(circleIdVal);

    final circle = Circle(
      circleId: circleId,
      strokeColor: Colors.orange,
      fillColor: Colors.green,
      strokeWidth: 5,
      center: _createCenter(),
      radius: 50000,
    );

    setState(() {
      circles[circleId] = circle;
      // 圆形不支持点击选中，操作按钮作用于最新添加的圆形。
      selectedCircle = circleId;
    });
  }

  void _toggleVisible(CircleId circleId) {
    final Circle circle = circles[circleId]!;
    setState(() {
      circles[circleId] = _copyCircleWith(circle, visible: !circle.visible);
    });
  }

  void _changeFillColor(CircleId circleId) {
    final Circle circle = circles[circleId]!;
    setState(() {
      circles[circleId] = _copyCircleWith(
        circle,
        fillColor: colors[++fillColorsIndex % colors.length],
      );
    });
  }

  void _changeStrokeColor(CircleId circleId) {
    final Circle circle = circles[circleId]!;
    setState(() {
      circles[circleId] = _copyCircleWith(
        circle,
        strokeColor: colors[++strokeColorsIndex % colors.length],
      );
    });
  }

  void _changeStrokeWidth(CircleId circleId) {
    final Circle circle = circles[circleId]!;
    setState(() {
      circles[circleId] = _copyCircleWith(
        circle,
        strokeWidth: widths[++widthsIndex % widths.length],
      );
    });
  }

  /// 复制 [circle]，并替换需要变更的字段。
  ///
  /// amap_kit_map 的覆盖物模型没有 `copyWith`，变更字段时需要重建一个不可变的
  /// [Circle] 实例。
  Circle _copyCircleWith(
    Circle circle, {
    Color? strokeColor,
    Color? fillColor,
    double? strokeWidth,
    bool? visible,
  }) {
    return Circle(
      circleId: circle.circleId,
      center: circle.center,
      radius: circle.radius,
      strokeColor: strokeColor ?? circle.strokeColor,
      fillColor: fillColor ?? circle.fillColor,
      strokeWidth: strokeWidth ?? circle.strokeWidth,
      visible: visible ?? circle.visible,
      zIndex: circle.zIndex,
      isDotted: circle.isDotted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final CircleId? selectedId = selectedCircle;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // 地图占页面大块区域。
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AmapMap(
              apiKey: exampleApiKey,
              privacyStatement: examplePrivacyStatement,
              mapId: exampleMapId,
              initialCameraPosition: const CameraPosition(
                target: LatLng(22.5410, 114.0579),
                zoom: 9.0,
              ),
              circles: Set<Circle>.of(circles.values),
              onMapCreated: _onMapCreated,
            ),
          ),
        ),
        // 操作按钮用 Wrap 整齐排布。
        Flexible(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: <Widget>[
                TextButton(onPressed: _add, child: const Text('添加')),
                TextButton(
                  onPressed: (selectedId == null)
                      ? null
                      : () => _remove(selectedId),
                  child: const Text('删除'),
                ),
                TextButton(
                  onPressed: (selectedId == null)
                      ? null
                      : () => _toggleVisible(selectedId),
                  child: const Text('切换可见'),
                ),
                TextButton(
                  onPressed: (selectedId == null)
                      ? null
                      : () => _changeStrokeWidth(selectedId),
                  child: const Text('修改描边宽度'),
                ),
                TextButton(
                  onPressed: (selectedId == null)
                      ? null
                      : () => _changeStrokeColor(selectedId),
                  child: const Text('修改描边颜色'),
                ),
                TextButton(
                  onPressed: (selectedId == null)
                      ? null
                      : () => _changeFillColor(selectedId),
                  child: const Text('修改填充颜色'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LatLng _createCenter() {
    final double offset = _circleIdCounter.ceilToDouble() * 0.05;
    return _createLatLng(22.5410 + offset, 114.0579);
  }

  LatLng _createLatLng(double lat, double lng) {
    return LatLng(lat, lng);
  }
}
