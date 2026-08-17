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

Future<void> _dragMarkerAtCenter(WidgetTester tester) async {
  final Offset center = tester.getCenter(find.byType(AmapMap));
  final TestGesture gesture = await tester.startGesture(center);
  await tester.pump(const Duration(milliseconds: 700));
  for (int index = 0; index < 4; index++) {
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await gesture.up();
}

Future<AmapMapController> _createMap(
  WidgetTester tester, {
  required Set<Marker> markers,
}) async {
  final Completer<AmapMapController> created = Completer<AmapMapController>();
  final List<AmapMapException> errors = <AmapMapException>[];
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
  await tester.pump(const Duration(seconds: 1));
  return created.future;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('draggable marker reports drag start, update and end', (
    WidgetTester tester,
  ) async {
    final List<LatLng> dragStarts = <LatLng>[];
    final List<LatLng> dragUpdates = <LatLng>[];
    final List<LatLng> dragEnds = <LatLng>[];
    final AmapMapController controller = await _createMap(
      tester,
      markers: <Marker>{
        Marker(
          markerId: const MarkerId('drag-marker'),
          position: const LatLng(30.2741, 120.1551),
          draggable: true,
          onDragStart: dragStarts.add,
          onDrag: dragUpdates.add,
          onDragEnd: dragEnds.add,
        ),
      },
    );

    await _dragMarkerAtCenter(tester);
    await _pumpUntil(
      tester,
      () => dragEnds.isNotEmpty,
      description: 'marker drag end',
    );

    expect(dragStarts, hasLength(1));
    expect(dragUpdates, isNotEmpty);
    expect(dragEnds, hasLength(1));
    expect(dragEnds.single.latitude, isNot(30.2741));
    expect(dragEnds.single.longitude, closeTo(120.1551, 0.01));

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  }, skip: _apiKey.isEmpty);

  testWidgets('non-draggable marker does not report drag events', (
    WidgetTester tester,
  ) async {
    int dragStarts = 0;
    final AmapMapController controller = await _createMap(
      tester,
      markers: <Marker>{
        Marker(
          markerId: const MarkerId('fixed-marker'),
          position: const LatLng(30.2741, 120.1551),
          onDragStart: (LatLng _) => dragStarts += 1,
        ),
      },
    );

    await _dragMarkerAtCenter(tester);
    await tester.pump(const Duration(seconds: 1));

    expect(dragStarts, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  }, skip: _apiKey.isEmpty);
}
