import 'dart:async';

import 'package:amap_kit_core/amap_kit_core.dart';
import 'package:amap_kit_location/amap_kit_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakePlatform platform;

  setUp(() {
    platform = _FakePlatform();
    AmapLocationPlatform.instance = platform;
  });

  test('单次定位不启动持续定位', () async {
    final AmapLocationResult result = await AmapLocationClient()
        .getCurrentLocation();

    expect(result.position, const LatLng(30, 120));
    expect(platform.startCount, 0);
  });

  test('start 和 stop 均为幂等操作', () async {
    final AmapLocationClient client = AmapLocationClient();

    await client.start();
    await client.start();
    await client.stop();
    await client.stop();

    expect(platform.startCount, 1);
    expect(platform.stopCount, 1);
    await client.dispose();
  });

  test('原生客户端创建前设置定位参数只覆盖本地配置', () async {
    final AmapLocationClient client = AmapLocationClient();
    const AmapLocationOptions updated = AmapLocationOptions(
      interval: Duration(seconds: 5),
      needAddress: true,
    );

    await client.setLocationOption(updated);
    await client.getCurrentLocation();

    expect(client.options, same(updated));
    expect(platform.createdOptions, same(updated));
    expect(platform.updatedOptions, isNull);
    await client.dispose();
  });

  test('已创建且停止的客户端设置定位参数会更新同一原生实例', () async {
    final AmapLocationClient client = AmapLocationClient();
    await client.getCurrentLocation();
    const AmapLocationOptions updated = AmapLocationOptions(
      accuracy: AmapLocationAccuracy.lowPower,
      interval: Duration(seconds: 6),
    );

    await client.setLocationOption(updated);

    expect(platform.updatedClientId, 1);
    expect(platform.updatedOptions, same(updated));
    expect(client.options, same(updated));
    await client.dispose();
  });

  test('持续定位运行中拒绝设置定位参数', () async {
    final AmapLocationClient client = AmapLocationClient();
    await client.start();

    await expectLater(
      client.setLocationOption(const AmapLocationOptions()),
      throwsA(isA<AmapLocationOperationInProgressException>()),
    );

    expect(platform.updatedOptions, isNull);
    await client.dispose();
  });

  test('原生更新失败时保留旧定位参数', () async {
    const AmapLocationOptions initial = AmapLocationOptions();
    final AmapLocationClient client = AmapLocationClient(options: initial);
    await client.getCurrentLocation();
    platform.updateFailure = const AmapLocationOperationInProgressException();

    await expectLater(
      client.setLocationOption(
        const AmapLocationOptions(interval: Duration(seconds: 7)),
      ),
      throwsA(isA<AmapLocationOperationInProgressException>()),
    );

    expect(client.options, same(initial));
    await client.dispose();
  });

  test('单次定位进行中拒绝设置定位参数', () async {
    final AmapLocationClient client = AmapLocationClient();
    final Completer<AmapLocationResult> locationCompleter =
        Completer<AmapLocationResult>();
    platform.locationCompleter = locationCompleter;
    final Future<AmapLocationResult> location = client.getCurrentLocation();
    await pumpEventQueue();

    await expectLater(
      client.setLocationOption(
        const AmapLocationOptions(interval: Duration(seconds: 8)),
      ),
      throwsA(isA<AmapLocationOperationInProgressException>()),
    );

    locationCompleter.complete(_location(30));
    await location;
    await client.dispose();
  });

  test('设置定位参数只更新目标客户端', () async {
    final AmapLocationClient first = AmapLocationClient();
    final AmapLocationClient second = AmapLocationClient();
    await first.getCurrentLocation();
    await second.getCurrentLocation();
    const AmapLocationOptions updated = AmapLocationOptions(
      interval: Duration(seconds: 9),
    );

    await first.setLocationOption(updated);

    expect(platform.clientOptions[1], same(updated));
    expect(platform.clientOptions[2], same(second.options));
    await first.dispose();
    await second.dispose();
  });

  test('释放后拒绝设置定位参数', () async {
    final AmapLocationClient client = AmapLocationClient();
    await client.dispose();

    await expectLater(
      client.setLocationOption(const AmapLocationOptions()),
      throwsA(isA<AmapLocationDisposedException>()),
    );
  });

  test('多个客户端的持续定位事件互相隔离', () async {
    final AmapLocationClient first = AmapLocationClient();
    final AmapLocationClient second = AmapLocationClient();
    final List<AmapLocationResult> firstValues = <AmapLocationResult>[];
    final List<AmapLocationResult> secondValues = <AmapLocationResult>[];
    final StreamSubscription<AmapLocationResult> firstSubscription = first
        .locations
        .listen(firstValues.add);
    final StreamSubscription<AmapLocationResult> secondSubscription = second
        .locations
        .listen(secondValues.add);

    await first.start();
    await second.start();
    platform.emit(1, _location(31));
    platform.emit(2, _location(32));
    await pumpEventQueue();

    expect(firstValues.single.position.latitude, 31);
    expect(secondValues.single.position.latitude, 32);

    await firstSubscription.cancel();
    await secondSubscription.cancel();
    await first.dispose();
    await second.dispose();
  });

  test('释放会取消订阅、关闭流并阻止迟到事件', () async {
    final AmapLocationClient client = AmapLocationClient();
    final List<AmapLocationResult> values = <AmapLocationResult>[];
    var streamDone = false;
    client.locations.listen(values.add, onDone: () => streamDone = true);
    await client.start();

    await client.dispose();
    platform.emit(1, _location(33));
    await pumpEventQueue();

    expect(values, isEmpty);
    expect(streamDone, isTrue);
    expect(
      client.getCurrentLocation,
      throwsA(isA<AmapLocationDisposedException>()),
    );
    expect(client.start, throwsA(isA<AmapLocationDisposedException>()));
    expect(platform.disposeCount, 1);
  });

  test('API Key、隐私和服务状态入口委托给平台实现', () async {
    const AmapLocationPrivacyStatus privacy = AmapLocationPrivacyStatus(
      privacyNoticeShown: true,
      containsAmapPrivacyPolicy: true,
      userAgreed: true,
    );

    await AmapLocation.setApiKey('  test-api-key  ');
    await AmapLocation.setPrivacyStatus(privacy);

    expect(platform.apiKey, 'test-api-key');
    expect(platform.privacyStatus, same(privacy));
    expect(await AmapLocation.isLocationServiceEnabled(), isTrue);
  });

  test('拒绝空白 API Key，且不会调用平台实现', () async {
    await expectLater(
      AmapLocation.setApiKey(' \n '),
      throwsA(isA<AmapLocationApiKeyException>()),
    );

    expect(platform.apiKey, isNull);
  });

  test('客户端拒绝原生 SDK 不支持的过短时间参数', () {
    expect(
      () => AmapLocationClient(
        options: const AmapLocationOptions(
          interval: Duration(milliseconds: 999),
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => AmapLocationClient(
        options: const AmapLocationOptions(timeout: Duration(seconds: 1)),
      ),
      throwsArgumentError,
    );
  });

  test('完整 Android 定位参数随客户端配置传给平台实现', () async {
    const AmapLocationAndroidOptions android = AmapLocationAndroidOptions(
      locationMode: AmapLocationAndroidMode.deviceSensors,
      protocol: AmapLocationAndroidProtocol.http,
      httpTimeout: Duration(seconds: 12),
      mockEnabled: false,
      wifiScanEnabled: false,
      alwaysScanWifi: false,
      locationCacheEnabled: false,
      onceLocationLatest: false,
      sensorEnabled: true,
      gpsFirst: true,
      gpsFirstTimeout: Duration(seconds: 8),
      beidouFirst: true,
      deviceModeDistanceFilterMeters: 3.5,
      geoLanguage: AmapLocationAndroidGeoLanguage.english,
      locationPurpose: AmapLocationAndroidPurpose.sport,
      coordinateOffsetEnabled: false,
      selfStartServiceEnabled: true,
      killProcessOnDestroy: true,
    );
    final AmapLocationClient client = AmapLocationClient(
      options: const AmapLocationOptions(
        timeout: Duration(seconds: 10),
        needAddress: true,
        android: android,
      ),
    );

    await client.getCurrentLocation();

    expect(platform.createdOptions!.android, same(android));
    expect(platform.createdOptions!.needAddress, isTrue);
    await client.dispose();
  });

  test('拒绝无效 Android 定位参数组合', () {
    expect(
      () => AmapLocationClient(
        options: const AmapLocationOptions(
          android: AmapLocationAndroidOptions(httpTimeout: Duration.zero),
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => AmapLocationClient(
        options: const AmapLocationOptions(
          android: AmapLocationAndroidOptions(
            gpsFirstTimeout: Duration(seconds: 4),
          ),
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => AmapLocationClient(
        options: const AmapLocationOptions(
          android: AmapLocationAndroidOptions(
            deviceModeDistanceFilterMeters: double.nan,
          ),
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => AmapLocationClient(
        options: const AmapLocationOptions(
          android: AmapLocationAndroidOptions(gpsFirst: true),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('完整 iOS 定位参数随客户端配置传给平台实现', () async {
    const AmapLocationIosOptions ios = AmapLocationIosOptions(
      desiredAccuracy: AmapLocationIosDesiredAccuracy.bestForNavigation,
      distanceFilterMeters: 12.5,
      pausesLocationUpdatesAutomatically: true,
      locationAccuracyMode: AmapLocationIosAccuracyMode.fullAndReduced,
      fullAccuracyPurposeKey: 'PreciseLocation',
    );
    final AmapLocationClient client = AmapLocationClient(
      options: const AmapLocationOptions(ios: ios),
    );

    await client.getCurrentLocation();

    expect(platform.createdOptions!.ios, same(ios));
    await client.dispose();
  });

  test('拒绝无效 iOS 距离过滤参数', () {
    expect(
      () => AmapLocationClient(
        options: const AmapLocationOptions(
          ios: AmapLocationIosOptions(distanceFilterMeters: -1),
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => AmapLocationClient(
        options: const AmapLocationOptions(
          ios: AmapLocationIosOptions(distanceFilterMeters: double.infinity),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('校验 iOS 14 临时精确定位参数组合', () {
    expect(
      () => AmapLocationClient(
        options: const AmapLocationOptions(
          ios: AmapLocationIosOptions(
            locationAccuracyMode: AmapLocationIosAccuracyMode.full,
          ),
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => AmapLocationClient(
        options: const AmapLocationOptions(
          ios: AmapLocationIosOptions(
            locationAccuracyMode: AmapLocationIosAccuracyMode.fullAndReduced,
            fullAccuracyPurposeKey: ' ',
          ),
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => AmapLocationClient(
        options: const AmapLocationOptions(
          ios: AmapLocationIosOptions(
            locationAccuracyMode: AmapLocationIosAccuracyMode.reduced,
            fullAccuracyPurposeKey: 'PreciseLocation',
          ),
        ),
      ),
      throwsArgumentError,
    );
  });
}

AmapLocationResult _location(double latitude) => AmapLocationResult(
  position: LatLng(latitude, 120),
  timestamp: DateTime.utc(2026),
  accuracyMeters: 1,
  coordinateType: AmapCoordinateType.gcj02,
);

final class _FakePlatform extends AmapLocationPlatform {
  final Map<int, StreamController<AmapLocationResult>> _controllers =
      <int, StreamController<AmapLocationResult>>{};
  final Map<int, AmapLocationOptions> clientOptions =
      <int, AmapLocationOptions>{};
  int _nextClientId = 1;
  int startCount = 0;
  int stopCount = 0;
  int disposeCount = 0;
  String? apiKey;
  AmapLocationPrivacyStatus? privacyStatus;
  AmapLocationOptions? createdOptions;
  AmapLocationOptions? updatedOptions;
  int? updatedClientId;
  Object? updateFailure;
  Completer<AmapLocationResult>? locationCompleter;

  @override
  Future<void> setApiKey(String apiKey) async {
    this.apiKey = apiKey;
  }

  @override
  Future<void> setPrivacyStatus(AmapLocationPrivacyStatus status) async {
    privacyStatus = status;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<int> createClient(AmapLocationOptions options) async {
    createdOptions = options;
    final int id = _nextClientId++;
    _controllers[id] = StreamController<AmapLocationResult>.broadcast();
    clientOptions[id] = options;
    return id;
  }

  @override
  Future<void> setLocationOption(
    int clientId,
    AmapLocationOptions options,
  ) async {
    final Object? failure = updateFailure;
    if (failure != null) {
      throw failure;
    }
    final Completer<AmapLocationResult>? pendingLocation = locationCompleter;
    if (pendingLocation != null && !pendingLocation.isCompleted) {
      throw const AmapLocationOperationInProgressException(
        '单次定位请求完成前不能设置定位参数。',
      );
    }
    updatedClientId = clientId;
    updatedOptions = options;
    clientOptions[clientId] = options;
  }

  @override
  Future<AmapLocationResult> getCurrentLocation(int clientId) async =>
      locationCompleter?.future ?? _location(30);

  @override
  Stream<AmapLocationResult> locationsForClient(int clientId) =>
      _controllers[clientId]!.stream;

  @override
  Future<void> start(int clientId) async {
    startCount++;
  }

  @override
  Future<void> stop(int clientId) async {
    stopCount++;
  }

  @override
  Future<void> disposeClient(int clientId) async {
    disposeCount++;
    clientOptions.remove(clientId);
    await _controllers.remove(clientId)?.close();
  }

  void emit(int clientId, AmapLocationResult result) {
    _controllers[clientId]?.add(result);
  }
}
