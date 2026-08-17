import 'package:amap_kit_location_ios/src/generated/location_messages.g.dart';
import 'package:amap_kit_location_ios/src/location_handler.dart';
import 'package:amap_kit_location_platform_interface/amap_kit_location_platform_interface.dart';
import 'package:flutter/services.dart';

/// iOS 上的高德定位平台实现。
final class AmapLocationIos extends AmapLocationPlatform {
  AmapLocationIos._({BinaryMessenger? binaryMessenger})
    : _hostApi = LocationHostApi(binaryMessenger: binaryMessenger),
      _binaryMessenger = binaryMessenger;

  final LocationHostApi _hostApi;
  final BinaryMessenger? _binaryMessenger;
  late final LocationHandler _locationHandler = LocationHandler(
    binaryMessenger: _binaryMessenger,
  );

  /// 由 Flutter 自动生成的插件注册器调用。
  static void registerWith() {
    AmapLocationPlatform.instance = AmapLocationIos._();
  }

  @override
  Future<void> setApiKey(String apiKey) =>
      _invoke(() => _hostApi.setApiKey(apiKey));

  @override
  Future<void> setPrivacyStatus(AmapLocationPrivacyStatus status) => _invoke(
    () => _hostApi.setPrivacyStatus(
      NativePrivacyStatus(
        privacyNoticeShown: status.privacyNoticeShown,
        containsAmapPrivacyPolicy: status.containsAmapPrivacyPolicy,
        userAgreed: status.userAgreed,
      ),
    ),
  );

  @override
  Future<bool> isLocationServiceEnabled() =>
      _invoke(_hostApi.isLocationServiceEnabled);

  @override
  Future<int> createClient(AmapLocationOptions options) {
    return _invoke(() => _hostApi.createClient(_nativeOptions(options)));
  }

  @override
  Future<void> setLocationOption(int clientId, AmapLocationOptions options) =>
      _invoke(
        () => _hostApi.setLocationOption(clientId, _nativeOptions(options)),
      );

  @override
  Future<AmapLocationResult> getCurrentLocation(int clientId) async =>
      _locationHandler.result(
        await _invoke(() => _hostApi.getCurrentLocation(clientId)),
      );

  @override
  Stream<AmapLocationResult> locationsForClient(int clientId) =>
      _locationHandler.locationsForClient(clientId);

  @override
  Future<void> start(int clientId) => _invoke(() => _hostApi.start(clientId));

  @override
  Future<void> stop(int clientId) => _invoke(() => _hostApi.stop(clientId));

  @override
  Future<void> disposeClient(int clientId) async {
    try {
      await _invoke(() => _hostApi.disposeClient(clientId));
    } finally {
      await _locationHandler.closeClient(clientId);
    }
  }

  NativeLocationOptions _nativeOptions(AmapLocationOptions options) {
    return NativeLocationOptions(
      accuracy: switch (options.accuracy) {
        AmapLocationAccuracy.high => NativeLocationAccuracy.high,
        AmapLocationAccuracy.balanced => NativeLocationAccuracy.balanced,
        AmapLocationAccuracy.lowPower => NativeLocationAccuracy.lowPower,
      },
      intervalMillis: options.interval.inMilliseconds,
      timeoutMillis: options.timeout.inMilliseconds,
      needAddress: options.needAddress,
      ios: _iosOptions(options.ios),
    );
  }

  NativeIosLocationOptions? _iosOptions(AmapLocationIosOptions? options) =>
      options == null
      ? null
      : NativeIosLocationOptions(
          desiredAccuracy: switch (options.desiredAccuracy) {
            AmapLocationIosDesiredAccuracy.bestForNavigation =>
              NativeIosDesiredAccuracy.bestForNavigation,
            AmapLocationIosDesiredAccuracy.best =>
              NativeIosDesiredAccuracy.best,
            AmapLocationIosDesiredAccuracy.nearestTenMeters =>
              NativeIosDesiredAccuracy.nearestTenMeters,
            AmapLocationIosDesiredAccuracy.hundredMeters =>
              NativeIosDesiredAccuracy.hundredMeters,
            AmapLocationIosDesiredAccuracy.kilometer =>
              NativeIosDesiredAccuracy.kilometer,
            AmapLocationIosDesiredAccuracy.threeKilometers =>
              NativeIosDesiredAccuracy.threeKilometers,
            null => null,
          },
          distanceFilterMeters: options.distanceFilterMeters,
          pausesLocationUpdatesAutomatically:
              options.pausesLocationUpdatesAutomatically,
          locationAccuracyMode: switch (options.locationAccuracyMode) {
            AmapLocationIosAccuracyMode.fullAndReduced =>
              NativeIosAccuracyMode.fullAndReduced,
            AmapLocationIosAccuracyMode.full => NativeIosAccuracyMode.full,
            AmapLocationIosAccuracyMode.reduced =>
              NativeIosAccuracyMode.reduced,
            null => null,
          },
          fullAccuracyPurposeKey: options.fullAccuracyPurposeKey?.trim(),
        );

  Future<T> _invoke<T>(Future<T> Function() operation) async {
    final LocationHandler handler = _locationHandler;
    try {
      return await operation();
    } on PlatformException catch (error) {
      throw handler.platformException(error);
    }
  }
}
