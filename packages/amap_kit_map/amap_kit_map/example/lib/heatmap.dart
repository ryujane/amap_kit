

import 'package:amap_kit_map/amap_kit_map.dart';
import 'package:flutter/material.dart';

import 'example_config.dart';
import 'page.dart';

class HeatmapPage extends MapExampleAppPage {
  const HeatmapPage({super.key})
    : super(const Icon(Icons.local_fire_department), '热力图');

  @override
  Widget build(BuildContext context) => const _HeatmapBody();
}

class _HeatmapBody extends StatefulWidget {
  const _HeatmapBody();

  @override
  State<_HeatmapBody> createState() => _HeatmapBodyState();
}

class _HeatmapBodyState extends State<_HeatmapBody> {
  bool _visible = true;
  bool _strongCenter = false;

  Heatmap get _heatmap => Heatmap(
    heatmapId: const HeatmapId('shenzhen-density'),
    data: <WeightedLatLng>[
      WeightedLatLng(
        const LatLng(22.5431, 114.0579),
        weight: _strongCenter ? 8 : 2,
      ),
      const WeightedLatLng(LatLng(22.5355, 114.0520), weight: 3),
      const WeightedLatLng(LatLng(22.5520, 114.0680), weight: 4),
      const WeightedLatLng(LatLng(22.5480, 114.0410), weight: 2),
    ],
    radius: const HeatmapRadius.fromPixels(32),
    opacity: 0.75,
    visible: _visible,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: AmapMap(
            apiKey: exampleApiKey,
            privacyStatement: examplePrivacyStatement,
            mapId: exampleMapId,
            initialCameraPosition: const CameraPosition(
              target: LatLng(22.5431, 114.0579),
              zoom: 13,
            ),
            heatmaps: <Heatmap>{_heatmap},
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: <Widget>[
            TextButton(
              onPressed: () => setState(() => _visible = !_visible),
              child: Text(_visible ? '隐藏热力图' : '显示热力图'),
            ),
            TextButton(
              onPressed: () => setState(() => _strongCenter = !_strongCenter),
              child: const Text('切换中心权重'),
            ),
          ],
        ),
      ],
    );
  }
}
