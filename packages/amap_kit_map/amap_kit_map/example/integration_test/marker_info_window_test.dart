import 'dart:async';
import 'dart:typed_data';

import 'package:amap_kit_map/amap_kit_map.dart';
import 'package:amap_kit_map_example/custom_marker_icon.dart';
import 'package:amap_kit_map_platform_interface/amap_kit_map_platform_interface.dart';
import 'package:flutter/material.dart';
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

const LatLng _center = LatLng(30.2741, 120.1551);

/// 回归测试：点击 marker 后信息窗必须显示，且随后的 marker 更新
/// （图标切换、位置变更）不得关闭信息窗；未选中的 marker 切换图标
/// （视图类型切换且无选中态）不得崩溃。
///
/// 曾因 iOS 每次 marker 变更都移除并重建 annotation，导致选中态与 callout
/// 丢失；Android 原地更新 Marker 对象，因此只有 iOS 触发该缺陷。修复后
/// 视图类型切换依赖 SDK 未类型化的 `selectedAnnotations`/`annotations`
/// （Swift 中为隐式解包可选，空时返回 nil），曾因此在无选中态时崩溃。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'marker info window survives updates and unselected icon switch',
    (WidgetTester tester) async {
      final Completer<AmapMapController> created =
          Completer<AmapMapController>();
      AmapMapController? controller;
      final GlobalKey<_InfoWindowHarnessState> harnessKey = GlobalKey();
      const MarkerId tappedId = MarkerId('tapped-marker');
      const MarkerId untappedId = MarkerId('untapped-marker');

      Future<void> waitForShown(MarkerId id, bool expected) async {
        final Stopwatch stopwatch = Stopwatch()..start();
        while (await controller!.isMarkerInfoWindowShown(id) != expected) {
          if (stopwatch.elapsed > const Duration(seconds: 20)) {
            fail(
              'Timed out waiting for info window of $id shown == $expected.',
            );
          }
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      await tester.pumpWidget(
        _InfoWindowHarness(
          key: harnessKey,
          markers: <Marker>{
            Marker(
              markerId: tappedId,
              position: _center,
              infoWindow: const InfoWindow(title: 'Marker', snippet: 'Info'),
              onTap: () => controller?.showMarkerInfoWindow(tappedId),
            ),
            Marker(
              markerId: untappedId,
              position: const LatLng(30.2741, 120.1581),
              infoWindow: const InfoWindow(title: 'Untapped', snippet: 'Info'),
            ),
          },
          onMapCreated: (AmapMapController value) {
            controller = value;
            created.complete(value);
          },
        ),
      );

      await _pumpUntil(
        tester,
        () => created.isCompleted,
        description: 'native map controller',
      );
      await tester.pump(const Duration(seconds: 1));

      final Offset center = tester.getCenter(find.byType(AmapMap));
      await tester.tapAt(center);
      await waitForShown(tappedId, true);

      // 图标由默认图钉切换为自定义图片：iOS 必须重建 annotation view，
      // 信息窗应随之恢复显示，而不是被更新销毁。
      final Uint8List bytes = await createCustomMarkerIconImage(
        size: const Size(24, 28),
        color: const Color(0xFF1565C0),
      );
      harnessKey.currentState!.updateMarker(
        Marker(
          markerId: tappedId,
          position: _center,
          infoWindow: const InfoWindow(title: 'Marker', snippet: 'Info'),
          onTap: () => controller?.showMarkerInfoWindow(tappedId),
          icon: BitmapDescriptor.bytes(bytes, width: 24, height: 28),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await waitForShown(tappedId, true);

      // 同类型图标下的位置变更走原地更新路径，信息窗同样必须保留。
      harnessKey.currentState!.updateMarker(
        Marker(
          markerId: tappedId,
          position: const LatLng(30.2751, 120.1561),
          infoWindow: const InfoWindow(title: 'Marker', snippet: 'Info'),
          onTap: () => controller?.showMarkerInfoWindow(tappedId),
          icon: BitmapDescriptor.bytes(bytes, width: 24, height: 28),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await waitForShown(tappedId, true);

      // 未选中的 marker 切换图标（视图类型切换且无选中态）：不得崩溃，
      // 也不得显示信息窗。
      harnessKey.currentState!.updateMarker(
        Marker(
          markerId: untappedId,
          position: const LatLng(30.2741, 120.1581),
          infoWindow: const InfoWindow(title: 'Untapped', snippet: 'Info'),
          icon: BitmapDescriptor.bytes(bytes, width: 24, height: 28),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await waitForShown(untappedId, false);

      await tester.pumpWidget(const SizedBox.shrink());
      controller!.dispose();
    },
    skip: _apiKey.isEmpty,
  );
}

class _InfoWindowHarness extends StatefulWidget {
  const _InfoWindowHarness({
    super.key,
    required this.markers,
    required this.onMapCreated,
  });

  final Set<Marker> markers;
  final ValueChanged<AmapMapController> onMapCreated;

  @override
  State<_InfoWindowHarness> createState() => _InfoWindowHarnessState();
}

class _InfoWindowHarnessState extends State<_InfoWindowHarness> {
  late Set<Marker> _markers = widget.markers;

  void updateMarker(Marker marker) {
    setState(() {
      _markers = <Marker>{
        for (final Marker existing in _markers)
          if (existing.markerId == marker.markerId) marker else existing,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 400,
        height: 600,
        child: AmapMap(
          apiKey: _apiKey,
          privacyStatement: _privacyStatement,
          mapId: _mapId,
          initialCameraPosition: const CameraPosition(
            target: _center,
            zoom: 16,
          ),
          markers: _markers,
          onMapCreated: widget.onMapCreated,
        ),
      ),
    );
  }
}

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
