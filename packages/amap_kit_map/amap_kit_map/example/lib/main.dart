import './page.dart';
import 'package:flutter/material.dart';

import 'animate_camera.dart';
import 'clustering.dart';
import 'heatmap.dart';
import 'map_ui.dart';
import 'move_camera.dart';
import 'place_circle.dart';
import 'place_marker.dart';
import 'place_polygon.dart';
import 'place_polyline.dart';
import 'snapshot.dart';
import 'tile_overlay.dart';

final List<MapExampleAppPage> _allPages = <MapExampleAppPage>[
  const MapUiPage(),
  const MoveCameraPage(),
  const AnimateCameraPage(),
  const PlaceMarkerPage(),
  const PlaceCirclePage(),
  const PlacePolygonPage(),
  const PlacePolylinePage(),
  const ClusteringPage(),
  const HeatmapPage(),
  const TileOverlayPage(),
  const SnapshotPage(),
];

class Demos extends StatelessWidget {
  const Demos({super.key});

  void _pushPage(BuildContext context, MapExampleAppPage page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(page.title)),
          body: page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('高德地图示例')),
      body: ListView.builder(
        itemCount: _allPages.length,
        itemBuilder: (_, int index) => ListTile(
          leading: _allPages[index].leading,
          title: Text(_allPages[index].title),
          onTap: () => _pushPage(context, _allPages[index]),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(home: Demos()));
}
