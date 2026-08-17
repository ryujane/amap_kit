import 'dart:async';

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

Future<_TapResult> _tapOverlayAtCenter(
  WidgetTester tester, {
  required Object overlay,
  required VoidCallback onOverlayTap,
}) async {
  final Completer<AmapMapController> created = Completer<AmapMapController>();
  final List<AmapMapException> errors = <AmapMapException>[];
  int overlayTaps = 0;
  int mapTaps = 0;
  final Set<Marker> markers = <Marker>{};
  final Set<Polyline> polylines = <Polyline>{};

  void recordTap() {
    overlayTaps += 1;
    onOverlayTap();
  }

  if (overlay is Marker) {
    markers.add(
      Marker(
        markerId: overlay.markerId,
        position: overlay.position,
        onTap: recordTap,
      ),
    );
  } else if (overlay is Polyline) {
    polylines.add(
      Polyline(
        polylineId: overlay.polylineId,
        points: overlay.points,
        color: overlay.color,
        width: overlay.width,
        geodesic: overlay.geodesic,
        zIndex: overlay.zIndex,
        onTap: recordTap,
      ),
    );
  }

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 400,
        height: 600,
        child: AmapMap(
          apiKey: _apiKey,
          privacyStatement: _privacyStatement,
          mapId: _mapId,
          initialCameraPosition: const CameraPosition(
            target: LatLng(30.2741, 120.1551),
            zoom: 16,
          ),
          markers: markers,
          polylines: polylines,
          onMapCreated: created.complete,
          onError: errors.add,
          onTap: (LatLng _) => mapTaps += 1,
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
  await tester.pump(const Duration(seconds: 1));

  final AmapMapController controller = await created.future;
  final Offset center = tester.getCenter(find.byType(AmapMap));
  await tester.tapAt(center);
  await _pumpUntil(
    tester,
    () => overlayTaps > 0 || mapTaps > 0,
    description: 'overlay tap to reach Dart',
  );
  await tester.pumpWidget(const SizedBox.shrink());
  controller.dispose();

  return _TapResult(overlayTaps: overlayTaps, mapTaps: mapTaps);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('marker tap fires its callback and suppresses map tap', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    final _TapResult result = await _tapOverlayAtCenter(
      tester,
      overlay: Marker(
        markerId: const MarkerId('tap-marker'),
        position: const LatLng(30.2741, 120.1551),
      ),
      onOverlayTap: () => tapped = true,
    );

    expect(tapped, isTrue);
    expect(result.overlayTaps, 1);
    expect(result.mapTaps, 0);
  }, skip: _apiKey.isEmpty);

  testWidgets(
    'polyline tap fires its callback and suppresses map tap',
    (WidgetTester tester) async {
      var tapped = false;
      final _TapResult result = await _tapOverlayAtCenter(
        tester,
        overlay: Polyline(
          polylineId: const PolylineId('tap-polyline'),
          points: const <LatLng>[
            LatLng(30.2736, 120.1546),
            LatLng(30.2746, 120.1556),
          ],
          width: 14,
        ),
        onOverlayTap: () => tapped = true,
      );

      expect(tapped, isTrue);
      expect(result.overlayTaps, 1);
      expect(result.mapTaps, 0);
    },
    skip: _apiKey.isEmpty,
  );
}

final class _TapResult {
  const _TapResult({required this.overlayTaps, required this.mapTaps});

  final int overlayTaps;
  final int mapTaps;
}
