import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:amap_kit_map/amap_kit_map.dart';
import 'package:amap_kit_map_platform_interface/amap_kit_map_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const String _apiKey = String.fromEnvironment('AMAP_API_KEY');

/// 集成测试声明已按高德合规要求处理隐私政策。
const AMapPrivacyStatement _privacyStatement = AMapPrivacyStatement(
  hasContains: true,
  hasShow: true,
  hasAgree: true,
);

/// 测试未使用在线自定义地图样式。
const String _mapId = '';

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String description,
}) async {
  final Stopwatch stopwatch = Stopwatch()..start();
  const Duration timeout = Duration(seconds: 20);
  while (!condition()) {
    if (stopwatch.elapsed > timeout) {
      fail('Timed out waiting for $description.');
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<ui.Image> _decodePng(List<int> bytes) async {
  final ui.Codec codec = await ui.instantiateImageCodec(
    Uint8List.fromList(bytes),
  );
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}

Future<int> _countNearColor(ui.Image image, int target) async {
  final ByteData data = (await image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  ))!;
  final int targetR = (target >> 16) & 0xff;
  final int targetG = (target >> 8) & 0xff;
  final int targetB = target & 0xff;
  int count = 0;
  for (int offset = 0; offset < data.lengthInBytes; offset += 4) {
    final int r = data.getUint8(offset);
    final int g = data.getUint8(offset + 1);
    final int b = data.getUint8(offset + 2);
    if ((r - targetR).abs() <= 24 &&
        (g - targetG).abs() <= 24 &&
        (b - targetB).abs() <= 24) {
      count += 1;
    }
  }
  return count;
}

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'iOS polyline, polygon, and circle render visible colors',
    (WidgetTester tester) async {
      final Completer<AmapMapController> created =
          Completer<AmapMapController>();
      final List<AmapMapException> errors = <AmapMapException>[];
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 400,
            height: 800,
            child: AmapMap(
              apiKey: _apiKey,
              privacyStatement: _privacyStatement,
              mapId: _mapId,
              initialCameraPosition: const CameraPosition(
                target: LatLng(30.2741, 120.1551),
                zoom: 15,
              ),
              polylines: <Polyline>{
                Polyline(
                  polylineId: const PolylineId('visibility-line'),
                  points: const <LatLng>[
                    LatLng(30.2736, 120.1546),
                    LatLng(30.2746, 120.1556),
                  ],
                  color: Color(0xffff00ff),
                  width: 10,
                ),
              },
              polygons: <Polygon>{
                Polygon(
                  polygonId: const PolygonId('visibility-area'),
                  points: const <LatLng>[
                    LatLng(30.2731, 120.1541),
                    LatLng(30.2741, 120.1541),
                    LatLng(30.2741, 120.1551),
                    LatLng(30.2731, 120.1551),
                  ],
                  strokeColor: Color(0xff00ffff),
                  fillColor: Color(0xff00ffff),
                  strokeWidth: 6,
                ),
              },
              circles: <Circle>{
                const Circle(
                  circleId: CircleId('visibility-circle'),
                  center: LatLng(30.2751, 120.1561),
                  radius: 150,
                  strokeColor: Color(0xffffff00),
                  fillColor: Color(0xffffff00),
                  strokeWidth: 6,
                ),
              },
              onMapCreated: created.complete,
              onError: errors.add,
            ),
          ),
        ),
      );

      await _pumpUntil(
        tester,
        () => errors.isNotEmpty || created.isCompleted,
        description: 'native map controller',
      );
      expect(errors, isEmpty);
      await Future<void>.delayed(const Duration(seconds: 4));
      await tester.pump();

      final List<int> screenshot = await binding.takeScreenshot(
        'overlay-visibility',
      );
      final ui.Image image = await _decodePng(screenshot);
      addTearDown(image.dispose);

      final int magenta = await _countNearColor(image, 0xffff00ff);
      final int cyan = await _countNearColor(image, 0xff00ffff);
      final int yellow = await _countNearColor(image, 0xffffff00);

      expect(
        magenta > 200 && cyan > 500 && yellow > 500,
        isTrue,
        reason:
            'overlay pixel counts magenta=$magenta cyan=$cyan yellow=$yellow',
      );
    },
    skip: _apiKey.isEmpty,
  );
}
