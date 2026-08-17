import 'package:amap_kit_location_android/src/generated/location_messages.g.dart';
import 'package:amap_kit_location_android/src/location_handler.dart';
import 'package:amap_kit_location_platform_interface/amap_kit_location_platform_interface.dart';
import 'package:flutter/services.dart';

/// Android 上的高德定位平台实现。
final class AmapLocationAndroid extends AmapLocationPlatform {
  AmapLocationAndroid._({BinaryMessenger? binaryMessenger})
    : _hostApi = LocationHostApi(binaryMessenger: binaryMessenger),
      _binaryMessenger = binaryMessenger;

  final LocationHostApi _hostApi;
  final BinaryMessenger? _binaryMessenger;
  late final LocationHandler _locationHandler = LocationHandler(
    binaryMessenger: _binaryMessenger,
  );

  /// 由 Flutter 自动生成的插件注册器调用。
  static void registerWith() {
    AmapLocationPlatform.instance = AmapLocationAndroid._();
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
      needAddress: _needAddress(options),
      android: _androidOptions(options.android),
    );
  }

  NativeAndroidLocationOptions? _androidOptions(
    AmapLocationAndroidOptions? options,
  ) => options == null
      ? null
      : NativeAndroidLocationOptions(
          locationMode: switch (options.locationMode) {
            AmapLocationAndroidMode.highAccuracy =>
              NativeAndroidLocationMode.highAccuracy,
            AmapLocationAndroidMode.batterySaving =>
              NativeAndroidLocationMode.batterySaving,
            AmapLocationAndroidMode.deviceSensors =>
              NativeAndroidLocationMode.deviceSensors,
            null => null,
          },
          locationProtocol: switch (options.protocol) {
            AmapLocationAndroidProtocol.http =>
              NativeAndroidLocationProtocol.http,
            AmapLocationAndroidProtocol.https =>
              NativeAndroidLocationProtocol.https,
          },
          httpTimeoutMillis: options.httpTimeout.inMilliseconds,
          mockEnabled: options.mockEnabled,
          needAddress: false,
          wifiScanEnabled: options.wifiScanEnabled,
          alwaysScanWifi: options.alwaysScanWifi,
          locationCacheEnabled: options.locationCacheEnabled,
          onceLocationLatest: options.onceLocationLatest,
          sensorEnabled: options.sensorEnabled,
          gpsFirst: options.gpsFirst,
          gpsFirstTimeoutMillis: options.gpsFirstTimeout.inMilliseconds,
          beidouFirst: options.beidouFirst,
          deviceModeDistanceFilterMeters:
              options.deviceModeDistanceFilterMeters,
          geoLanguage: switch (options.geoLanguage) {
            AmapLocationAndroidGeoLanguage.system =>
              NativeAndroidGeoLanguage.system,
            AmapLocationAndroidGeoLanguage.chinese =>
              NativeAndroidGeoLanguage.chinese,
            AmapLocationAndroidGeoLanguage.english =>
              NativeAndroidGeoLanguage.english,
          },
          locationPurpose: switch (options.locationPurpose) {
            AmapLocationAndroidPurpose.signIn =>
              NativeAndroidLocationPurpose.signIn,
            AmapLocationAndroidPurpose.transport =>
              NativeAndroidLocationPurpose.transport,
            AmapLocationAndroidPurpose.sport =>
              NativeAndroidLocationPurpose.sport,
            null => null,
          },
          coordinateOffsetEnabled: options.coordinateOffsetEnabled,
          selfStartServiceEnabled: options.selfStartServiceEnabled,
          killProcessOnDestroy: options.killProcessOnDestroy,
        );

  bool _needAddress(AmapLocationOptions options) {
    if (options.needAddress) {
      return true;
    }
    // ignore: deprecated_member_use
    return options.android?.needAddress ?? false;
  }

  Future<T> _invoke<T>(Future<T> Function() operation) async {
    final LocationHandler handler = _locationHandler;
    try {
      return await operation();
    } on PlatformException catch (error) {
      throw handler.platformException(error);
    }
  }
}
