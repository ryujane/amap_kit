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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'two maps isolate commands, report overlay failures, and dispose controllers',
    (WidgetTester tester) async {
      final Completer<AmapMapController> primaryCreated =
          Completer<AmapMapController>();
      final Completer<AmapMapController> secondaryCreated =
          Completer<AmapMapController>();
      final List<AmapMapException> errors = <AmapMapException>[];
      final ValueNotifier<Set<Marker>> markers =
          ValueNotifier<Set<Marker>>(<Marker>{
            const Marker(
              markerId: MarkerId('primary'),
              position: LatLng(30.2741, 120.1551),
            ),
          });
      final ValueNotifier<bool> showMaps = ValueNotifier<bool>(true);
      addTearDown(markers.dispose);
      addTearDown(showMaps.dispose);

      void reportError(AmapMapException error) {
        errors.add(error);
      }

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 600,
            height: 400,
            child: ValueListenableBuilder<bool>(
              valueListenable: showMaps,
              builder: (BuildContext context, bool visible, Widget? child) {
                if (!visible) {
                  return const SizedBox.shrink();
                }
                return Row(
                  children: <Widget>[
                    Expanded(
                      child: ValueListenableBuilder<Set<Marker>>(
                        valueListenable: markers,
                        builder:
                            (
                              BuildContext context,
                              Set<Marker> value,
                              Widget? child,
                            ) => AmapMap(
                              apiKey: _apiKey,
                              privacyStatement: _privacyStatement,
                              mapId: _mapId,
                              initialCameraPosition: const CameraPosition(
                                target: LatLng(30.2741, 120.1551),
                                zoom: 12,
                              ),
                              markers: value,
                              polylines: <Polyline>{
                                Polyline(
                                  polylineId: PolylineId('route'),
                                  points: <LatLng>[
                                    LatLng(30.2741, 120.1551),
                                    LatLng(30.2751, 120.1561),
                                  ],
                                ),
                              },
                              polygons: <Polygon>{
                                Polygon(
                                  polygonId: PolygonId('area'),
                                  points: <LatLng>[
                                    LatLng(30.2741, 120.1551),
                                    LatLng(30.2751, 120.1551),
                                    LatLng(30.2741, 120.1561),
                                  ],
                                ),
                              },
                              circles: <Circle>{
                                Circle(
                                  circleId: CircleId('radius'),
                                  center: LatLng(30.2741, 120.1551),
                                  radius: 100,
                                ),
                              },
                              onMapCreated: primaryCreated.complete,
                              onError: reportError,
                            ),
                      ),
                    ),
                    Expanded(
                      child: AmapMap(
                        apiKey: _apiKey,
                        privacyStatement: _privacyStatement,
                        mapId: _mapId,
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(31.2304, 121.4737),
                          zoom: 12,
                        ),
                        markers: <Marker>{
                          const Marker(
                            markerId: MarkerId('secondary'),
                            position: LatLng(31.2304, 121.4737),
                          ),
                        },
                        onMapCreated: secondaryCreated.complete,
                        onError: reportError,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await _pumpUntil(
        tester,
        () =>
            errors.isNotEmpty ||
            (primaryCreated.isCompleted && secondaryCreated.isCompleted),
        description: 'both native map controllers',
      );
      expect(errors, isEmpty);

      final AmapMapController primary = await primaryCreated.future;
      final AmapMapController secondary = await secondaryCreated.future;
      markers.value = <Marker>{
        const Marker(
          markerId: MarkerId('primary'),
          position: LatLng(30.2751, 120.1561),
          title: 'updated',
        ),
      };
      await tester.pump();

      const LatLng primaryTarget = LatLng(30.5, 120.5);
      await primary.moveCamera(CameraUpdate.newLatLng(primaryTarget));
      final LatLngBounds primaryRegion = await primary.getVisibleRegion();
      final LatLngBounds secondaryRegion = await secondary.getVisibleRegion();
      expect(primaryRegion.contains(primaryTarget), isTrue);
      expect(secondaryRegion.contains(primaryTarget), isFalse);
      expect(
        errors,
        isEmpty,
        reason: 'native overlay updates must report failures',
      );

      showMaps.value = false;
      await tester.pump();
      await _pumpUntil(
        tester,
        () => find.byType(AmapMap).evaluate().isEmpty,
        description: 'both map widgets to be removed',
      );
      expect(
        () => primary.moveCamera(CameraUpdate.zoomIn()),
        throwsA(isA<AmapMapDisposedException>()),
      );
      expect(
        () => secondary.moveCamera(CameraUpdate.zoomIn()),
        throwsA(isA<AmapMapDisposedException>()),
      );
    },
    skip: _apiKey.isEmpty,
  );
}
