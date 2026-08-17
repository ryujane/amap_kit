import 'dart:async';

import 'package:amap_kit_map/amap_kit_map.dart';
import 'package:amap_kit_map_platform_interface/amap_kit_map_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const String _apiKey = String.fromEnvironment('AMAP_API_KEY');

const AMapPrivacyStatement _privacyStatement = AMapPrivacyStatement(
  hasContains: true,
  hasShow: true,
  hasAgree: true,
);

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String description,
}) async {
  final Stopwatch stopwatch = Stopwatch()..start();
  while (!condition()) {
    if (stopwatch.elapsed > const Duration(seconds: 20)) {
      fail('Timed out waiting for $description.');
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('iOS matches Android camera move and end events', (
    WidgetTester tester,
  ) async {
    final Completer<AmapMapController> created = Completer<AmapMapController>();
    final List<CameraPosition> moves = <CameraPosition>[];
    final List<CameraPosition> ends = <CameraPosition>[];
    int starts = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 400,
          height: 600,
          child: AmapMap(
            apiKey: _apiKey,
            privacyStatement: _privacyStatement,
            mapId: '',
            initialCameraPosition: const CameraPosition(
              target: LatLng(30.2741, 120.1551),
              zoom: 12,
            ),
            onMapCreated: created.complete,
            onCameraMoveStarted: () => starts += 1,
            onCameraMove: moves.add,
            onCameraMoveEnd: ends.add,
          ),
        ),
      ),
    );

    await _pumpUntil(
      tester,
      () => created.isCompleted,
      description: 'native map controller',
    );
    final AmapMapController controller = await created.future;
    starts = 0;
    moves.clear();
    ends.clear();

    const LatLng destination = LatLng(30.5, 120.5);
    await controller.animateCamera(
      CameraUpdate.newLatLng(destination),
      duration: const Duration(milliseconds: 300),
    );
    await _pumpUntil(
      tester,
      () => ends.isNotEmpty,
      description: 'camera move end',
    );

    expect(starts, 0, reason: 'Android does not emit a camera-start event.');
    expect(moves, isNotEmpty);
    expect(ends, hasLength(1));
    expect(ends.single.target.latitude, closeTo(destination.latitude, 0.01));
    expect(ends.single.target.longitude, closeTo(destination.longitude, 0.01));

    moves.clear();
    ends.clear();
    const CameraPosition compositeDestination = CameraPosition(
      target: LatLng(30.45, 120.45),
      zoom: 14,
      bearing: 35,
      tilt: 20,
    );
    await controller.animateCamera(
      const CameraUpdate.newCameraPosition(compositeDestination),
    );
    await _pumpUntil(
      tester,
      () => ends.isNotEmpty,
      description: 'default-duration composite camera move end',
    );

    expect(ends, hasLength(1));
    expect(
      ends.single.target.latitude,
      closeTo(compositeDestination.target.latitude, 0.01),
    );
    expect(
      ends.single.target.longitude,
      closeTo(compositeDestination.target.longitude, 0.01),
    );
    expect(ends.single.zoom, closeTo(compositeDestination.zoom, 0.1));
    expect(ends.single.bearing, closeTo(compositeDestination.bearing, 1));
    expect(ends.single.tilt, closeTo(compositeDestination.tilt, 1));

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  }, skip: _apiKey.isEmpty);
}
