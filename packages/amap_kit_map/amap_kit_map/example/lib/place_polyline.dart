// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:amap_kit_map/amap_kit_map.dart';
import 'package:amap_kit_map_platform_interface/amap_kit_map_platform_interface.dart';
import 'package:flutter/material.dart';

import 'example_config.dart';
import 'page.dart';

class PlacePolylinePage extends MapExampleAppPage {
  const PlacePolylinePage({super.key})
    : super(const Icon(Icons.linear_scale), '折线示例');

  @override
  Widget build(BuildContext context) {
    return const PlacePolylineBody();
  }
}

class PlacePolylineBody extends StatefulWidget {
  const PlacePolylineBody({super.key});

  @override
  State<StatefulWidget> createState() => PlacePolylineBodyState();
}

class PlacePolylineBodyState extends State<PlacePolylineBody> {
  PlacePolylineBodyState();

  AmapMapController? controller;
  Map<PolylineId, Polyline> polylines = <PolylineId, Polyline>{};
  int _polylineIdCounter = 0;
  PolylineId? selectedPolyline;

  // Values when toggling polyline color
  int colorsIndex = 0;
  List<Color> colors = <Color>[
    Colors.purple,
    Colors.red,
    Colors.green,
    Colors.pink,
  ];

  // Values when toggling polyline width
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

  void _onPolylineTapped(PolylineId polylineId) {
    setState(() {
      selectedPolyline = polylineId;
    });
  }

  void _remove(PolylineId polylineId) {
    setState(() {
      if (polylines.containsKey(polylineId)) {
        polylines.remove(polylineId);
      }
      selectedPolyline = null;
    });
  }

  void _add() {
    final int polylineCount = polylines.length;

    if (polylineCount == 12) {
      return;
    }

    final polylineIdVal = 'polyline_id_$_polylineIdCounter';
    _polylineIdCounter++;
    final polylineId = PolylineId(polylineIdVal);

    final polyline = Polyline(
      polylineId: polylineId,
      color: Colors.orange,
      width: 5,
      lineJoinType: AmapLineJoinType.miter,
      lineCapType: AmapLineCapType.butt,
      points: _createPoints(),
      onTap: () {
        _onPolylineTapped(polylineId);
      },
    );

    setState(() {
      polylines[polylineId] = polyline;
    });
  }

  void _toggleGeodesic(PolylineId polylineId) {
    final Polyline polyline = polylines[polylineId]!;
    setState(() {
      polylines[polylineId] = _copyPolylineWith(
        polyline,
        geodesic: !polyline.geodesic,
      );
    });
  }

  void _toggleVisible(PolylineId polylineId) {
    final Polyline polyline = polylines[polylineId]!;
    setState(() {
      polylines[polylineId] = _copyPolylineWith(
        polyline,
        visible: !polyline.visible,
      );
    });
  }

  void _changeColor(PolylineId polylineId) {
    final Polyline polyline = polylines[polylineId]!;
    setState(() {
      polylines[polylineId] = _copyPolylineWith(
        polyline,
        color: colors[++colorsIndex % colors.length],
      );
    });
  }

  void _changeWidth(PolylineId polylineId) {
    final Polyline polyline = polylines[polylineId]!;
    setState(() {
      polylines[polylineId] = _copyPolylineWith(
        polyline,
        width: widths[++widthsIndex % widths.length],
      );
    });
  }

  void _toggleDotted(PolylineId polylineId) {
    final Polyline polyline = polylines[polylineId]!;
    setState(() {
      polylines[polylineId] = _copyPolylineWith(
        polyline,
        isDotted: !polyline.isDotted,
      );
    });
  }

  /// 复制 [polyline]，并替换需要变更的字段。
  ///
  /// amap_kit_map 的覆盖物模型没有 `copyWith`，变更字段时需要重建一个不可变的
  /// [Polyline] 实例；回调字段直接透传。
  Polyline _copyPolylineWith(
    Polyline polyline, {
    Color? color,
    double? width,
    bool? visible,
    bool? geodesic,
    bool? isDotted,
  }) {
    return Polyline(
      polylineId: polyline.polylineId,
      points: polyline.points,
      color: color ?? polyline.color,
      width: width ?? polyline.width,
      visible: visible ?? polyline.visible,
      geodesic: geodesic ?? polyline.geodesic,
      zIndex: polyline.zIndex,
      isDotted: isDotted ?? polyline.isDotted,
      // 端点/拐角样式在 Android 上仅创建时生效，复制时保持原值即可。
      lineCapType: polyline.lineCapType,
      lineJoinType: polyline.lineJoinType,
      dottedLineType: polyline.dottedLineType,
      onTap: polyline.onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final PolylineId? selectedId = selectedPolyline;

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
              polylines: Set<Polyline>.of(polylines.values),
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
                      : () => _toggleGeodesic(selectedId),
                  child: const Text('切换大地线'),
                ),
                TextButton(
                  onPressed: (selectedId == null)
                      ? null
                      : () => _changeWidth(selectedId),
                  child: const Text('修改宽度'),
                ),
                TextButton(
                  onPressed: (selectedId == null)
                      ? null
                      : () => _changeColor(selectedId),
                  child: const Text('修改颜色'),
                ),
                TextButton(
                  onPressed: (selectedId == null)
                      ? null
                      : () => _toggleDotted(selectedId),
                  child: const Text('切换虚线'),
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
    final double offset = _polylineIdCounter.ceilToDouble() * 0.05;
    points.add(_createLatLng(22.5516 + offset, 113.9391));
    points.add(_createLatLng(22.5930 + offset, 113.9825));
    points.add(_createLatLng(22.5896 + offset, 114.0639));
    points.add(_createLatLng(22.5653 + offset, 114.1129));
    return points;
  }

  LatLng _createLatLng(double lat, double lng) {
    return LatLng(lat, lng);
  }
}
