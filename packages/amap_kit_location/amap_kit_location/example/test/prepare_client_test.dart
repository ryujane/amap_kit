import 'dart:async';

import 'package:amap_kit_core/amap_kit_core.dart';
import 'package:amap_kit_location/amap_kit_location.dart';
import 'package:amap_kit_location_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reuses configured privacy status after creating the client', (
    WidgetTester tester,
  ) async {
    final _PrivacyOrderingPlatform platform = _PrivacyOrderingPlatform();
    AmapLocationPlatform.instance = platform;
    await tester.pumpWidget(const LocationExampleApp());

    await tester.enterText(find.byType(TextField), 'test-api-key');
    await tester.tap(find.text('获取当前位置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('获取当前位置'));
    await tester.pumpAndSettle();

    expect(platform.privacyStatusSetCount, 1);
    expect(find.textContaining('单次定位'), findsOneWidget);
    expect(find.textContaining('必须在创建定位客户端前设置隐私状态'), findsNothing);
  });
}

final class _PrivacyOrderingPlatform extends AmapLocationPlatform {
  int privacyStatusSetCount = 0;
  int? _clientId;

  @override
  Future<void> setApiKey(String apiKey) async {}

  @override
  Future<void> setPrivacyStatus(AmapLocationPrivacyStatus status) async {
    privacyStatusSetCount += 1;
    if (_clientId != null) {
      throw StateError('必须在创建定位客户端前设置隐私状态。');
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<int> createClient(AmapLocationOptions options) async {
    _clientId = 1;
    return _clientId!;
  }

  @override
  Future<AmapLocationResult> getCurrentLocation(int clientId) async =>
      AmapLocationResult(
        position: const LatLng(30, 120),
        timestamp: DateTime.utc(2026),
        accuracyMeters: 1,
        coordinateType: AmapCoordinateType.gcj02,
      );

  @override
  Stream<AmapLocationResult> locationsForClient(int clientId) =>
      const Stream<AmapLocationResult>.empty();

  @override
  Future<void> start(int clientId) async {}

  @override
  Future<void> stop(int clientId) async {}

  @override
  Future<void> disposeClient(int clientId) async {
    _clientId = null;
  }
}
