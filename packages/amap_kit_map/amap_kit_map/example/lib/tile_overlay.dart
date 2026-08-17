// ignore_for_file: public_member_api_docs

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:amap_kit_map/amap_kit_map.dart';
import 'package:flutter/material.dart';

import 'example_config.dart';
import 'page.dart';

class TileOverlayPage extends MapExampleAppPage {
  const TileOverlayPage({super.key})
    : super(const Icon(Icons.grid_on), '自定义瓦片');

  @override
  Widget build(BuildContext context) => const _TileOverlayBody();
}

class _TileOverlayBody extends StatefulWidget {
  const _TileOverlayBody();

  @override
  State<_TileOverlayBody> createState() => _TileOverlayBodyState();
}

class _TileOverlayBodyState extends State<_TileOverlayBody> {
  static const TileOverlayId _overlayId = TileOverlayId('coordinate-grid');

  late final TileProvider _blueProvider = _CoordinateTileProvider(Colors.blue);
  late final TileProvider _orangeProvider = _CoordinateTileProvider(
    Colors.deepOrange,
  );
  AmapMapController? _controller;
  bool _visible = true;
  bool _orange = false;

  @override
  Widget build(BuildContext context) {
    final TileOverlay overlay = TileOverlay(
      tileOverlayId: _overlayId,
      tileProvider: _orange ? _orangeProvider : _blueProvider,
      zIndex: 1,
      visible: _visible,
    );
    return Column(
      children: <Widget>[
        Expanded(
          child: AmapMap(
            apiKey: exampleApiKey,
            privacyStatement: examplePrivacyStatement,
            mapId: exampleMapId,
            initialCameraPosition: const CameraPosition(
              target: LatLng(22.5431, 114.0579),
              zoom: 11,
            ),
            tileOverlays: <TileOverlay>{overlay},
            onMapCreated: (AmapMapController controller) {
              _controller = controller;
            },
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: <Widget>[
            TextButton(
              onPressed: () => setState(() => _visible = !_visible),
              child: Text(_visible ? '隐藏瓦片' : '显示瓦片'),
            ),
            TextButton(
              onPressed: () => setState(() => _orange = !_orange),
              child: const Text('替换 Provider'),
            ),
            TextButton(
              onPressed: () => _controller?.clearTileCache(_overlayId),
              child: const Text('清除缓存'),
            ),
          ],
        ),
      ],
    );
  }
}

final class _CoordinateTileProvider extends TileProvider {
  _CoordinateTileProvider(this.color);

  final Color color;

  @override
  Future<Tile> getTile(int x, int y, int zoom) async {
    const int size = 256;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint background = Paint()..color = color.withValues(alpha: 0.12);
    final Paint border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(const Rect.fromLTWH(0.0, 0.0, 256.0, 256.0), background);
    canvas.drawRect(const Rect.fromLTWH(1.5, 1.5, 253, 253), border);
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: 'z=$zoom\nx=$x\ny=$y',
        style: TextStyle(color: color, fontSize: 28),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, const Offset(18.0, 18.0));
    final ui.Image image = await recorder.endRecording().toImage(size, size);
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    if (data == null) return TileProvider.noTile;
    final Uint8List bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    return Tile(size, size, bytes);
  }
}
