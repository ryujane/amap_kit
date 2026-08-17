// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:amap_kit_map/amap_kit_map.dart';
import 'package:flutter/material.dart';

import 'example_config.dart';
import 'page.dart';

class PlacePolygonPage extends MapExampleAppPage {
  const PlacePolygonPage({super.key})
    : super(const Icon(Icons.linear_scale), '多边形示例');

  @override
  Widget build(BuildContext context) {
    return const PlacePolygonBody();
  }
}

class PlacePolygonBody extends StatefulWidget {
  const PlacePolygonBody({super.key});

  @override
  State<StatefulWidget> createState() => PlacePolygonBodyState();
}

class PlacePolygonBodyState extends State<PlacePolygonBody> {
  PlacePolygonBodyState();

  AmapMapController? controller;
  Map<PolygonId, Polygon> polygons = <PolygonId, Polygon>{};
  Map<PolygonId, double> polygonOffsets = <PolygonId, double>{};
  int _polygonIdCounter = 0;
  PolygonId? selectedPolygon;

  // Values when toggling polygon color
  int strokeColorsIndex = 0;
  int fillColorsIndex = 0;
  List<Color> colors = <Color>[
    Colors.purple,
    Colors.red,
    Colors.green,
    Colors.pink,
  ];

  // Values when toggling polygon width
  int widthsIndex = 0;
  List<double> widths = <double>[50, 20, 5];

  // ignore: use_setters_to_change_properties
  void _onMapCreated(AmapMapController controller) {
    this.controller = controller;
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 依次选中下一个多边形。
  ///
  /// amap_kit_map 当前不支持多边形点击事件，因此通过按钮切换需要修改的多边形。
  void _selectNextPolygon() {
    if (polygons.isEmpty) {
      return;
    }
    final List<PolygonId> ids = polygons.keys.toList();
    final int currentIndex = selectedPolygon == null
        ? -1
        : ids.indexOf(selectedPolygon!);
    setState(() {
      selectedPolygon = ids[(currentIndex + 1) % ids.length];
    });
  }

  void _remove(PolygonId polygonId) {
    setState(() {
      if (polygons.containsKey(polygonId)) {
        polygons.remove(polygonId);
      }
      selectedPolygon = null;
    });
  }

  void _add() {
    final int polygonCount = polygons.length;

    if (polygonCount == 12) {
      return;
    }

    final polygonIdVal = 'polygon_id_$_polygonIdCounter';
    final polygonId = PolygonId(polygonIdVal);

    final polygon = Polygon(
      polygonId: polygonId,
      strokeColor: Colors.orange,
      strokeWidth: 5,
      fillColor: Colors.green,
      points: _createPoints(),
    );

    setState(() {
      polygons[polygonId] = polygon;
      polygonOffsets[polygonId] = _polygonIdCounter.ceilToDouble();
      // increment _polygonIdCounter to have unique polygon id each time
      _polygonIdCounter++;
    });
  }

  void _toggleVisible(PolygonId polygonId) {
    final Polygon polygon = polygons[polygonId]!;
    setState(() {
      polygons[polygonId] = _copyPolygonWith(
        polygon,
        visible: !polygon.visible,
      );
    });
  }

  void _changeStrokeColor(PolygonId polygonId) {
    final Polygon polygon = polygons[polygonId]!;
    setState(() {
      polygons[polygonId] = _copyPolygonWith(
        polygon,
        strokeColor: colors[++strokeColorsIndex % colors.length],
      );
    });
  }

  void _changeFillColor(PolygonId polygonId) {
    final Polygon polygon = polygons[polygonId]!;
    setState(() {
      polygons[polygonId] = _copyPolygonWith(
        polygon,
        fillColor: colors[++fillColorsIndex % colors.length],
      );
    });
  }

  void _changeWidth(PolygonId polygonId) {
    final Polygon polygon = polygons[polygonId]!;
    setState(() {
      polygons[polygonId] = _copyPolygonWith(
        polygon,
        strokeWidth: widths[++widthsIndex % widths.length],
      );
    });
  }

  void _addHoles(PolygonId polygonId) {
    final Polygon polygon = polygons[polygonId]!;
    setState(() {
      polygons[polygonId] = _copyPolygonWith(
        polygon,
        holes: _createHoles(polygonId),
      );
    });
  }

  void _removeHoles(PolygonId polygonId) {
    final Polygon polygon = polygons[polygonId]!;
    setState(() {
      polygons[polygonId] = _copyPolygonWith(
        polygon,
        holes: const <List<LatLng>>[],
      );
    });
  }

  /// 复制 [polygon]，并替换需要变更的字段。
  ///
  /// amap_kit_map 的覆盖物模型没有 `copyWith`，变更字段时需要重建一个不可变的
  /// [Polygon] 实例。
  Polygon _copyPolygonWith(
    Polygon polygon, {
    List<List<LatLng>>? holes,
    Color? strokeColor,
    Color? fillColor,
    double? strokeWidth,
    bool? visible,
  }) {
    return Polygon(
      polygonId: polygon.polygonId,
      points: polygon.points,
      holes: holes ?? polygon.holes,
      strokeColor: strokeColor ?? polygon.strokeColor,
      fillColor: fillColor ?? polygon.fillColor,
      strokeWidth: strokeWidth ?? polygon.strokeWidth,
      visible: visible ?? polygon.visible,
      zIndex: polygon.zIndex,
      lineJoinType: polygon.lineJoinType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final PolygonId? selectedId = selectedPolygon;
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
                zoom: 10.0,
              ),
              polygons: Set<Polygon>.of(polygons.values),
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
                  onPressed: _selectNextPolygon,
                  child: const Text('选中下一个多边形'),
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
                      : (polygons[selectedId]!.holes.isNotEmpty
                            ? null
                            : () => _addHoles(selectedId)),
                  child: const Text('添加孔洞'),
                ),
                TextButton(
                  onPressed: (selectedId == null)
                      ? null
                      : (polygons[selectedId]!.holes.isEmpty
                            ? null
                            : () => _removeHoles(selectedId)),
                  child: const Text('移除孔洞'),
                ),
                TextButton(
                  onPressed: (selectedId == null)
                      ? null
                      : () => _changeWidth(selectedId),
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

  List<LatLng> _createPoints() {
    final points = <LatLng>[];
    final double offset = _polygonIdCounter.ceilToDouble() * 0.05;
    points.add(_createLatLng(22.5395 + offset, 113.9434));
    points.add(_createLatLng(22.6634 + offset, 113.9314));
    points.add(_createLatLng(22.6551 + offset, 114.2535));
    points.add(_createLatLng(22.5731 + offset, 114.2129));
    return points;
  }

  List<List<LatLng>> _createHoles(PolygonId polygonId) {
    final holes = <List<LatLng>>[];
    final double offset = polygonOffsets[polygonId]! * 0.05;

    final hole1 = <LatLng>[];
    hole1.add(_createLatLng(22.5795 + offset, 113.9714));
    hole1.add(_createLatLng(22.5934 + offset, 113.9614));
    hole1.add(_createLatLng(22.5951 + offset, 114.0135));
    hole1.add(_createLatLng(22.5831 + offset, 114.0229));
    holes.add(hole1);

    final hole2 = <LatLng>[];
    hole2.add(_createLatLng(22.6195 + offset, 114.1314));
    hole2.add(_createLatLng(22.6334 + offset, 114.1214));
    hole2.add(_createLatLng(22.6351 + offset, 114.1735));
    hole2.add(_createLatLng(22.6231 + offset, 114.1829));
    holes.add(hole2);

    return holes;
  }

  LatLng _createLatLng(double lat, double lng) {
    return LatLng(lat, lng);
  }
}
