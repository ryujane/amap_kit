import 'dart:async';

import 'package:amap_kit_core/amap_kit_core.dart';
import 'package:amap_kit_location_ios/src/generated/location_messages.g.dart';
import 'package:amap_kit_location_platform_interface/amap_kit_location_platform_interface.dart';
import 'package:flutter/services.dart';

final class LocationHandler implements LocationFlutterApi {
  LocationHandler({BinaryMessenger? binaryMessenger})
    : _binaryMessenger = binaryMessenger {
    LocationFlutterApi.setUp(this, binaryMessenger: binaryMessenger);
  }

  final BinaryMessenger? _binaryMessenger;
  final Map<int, StreamController<AmapLocationResult>> _controllers =
      <int, StreamController<AmapLocationResult>>{};
  bool _disposed = false;

  Stream<AmapLocationResult> locationsForClient(int clientId) {
    if (_disposed) {
      throw const AmapLocationDisposedException();
    }
    return (_controllers[clientId] ??=
            StreamController<AmapLocationResult>.broadcast())
        .stream;
  }

  Future<void> closeClient(int clientId) async {
    await _controllers.remove(clientId)?.close();
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    LocationFlutterApi.setUp(null, binaryMessenger: _binaryMessenger);
    final List<StreamController<AmapLocationResult>> controllers = _controllers
        .values
        .toList(growable: false);
    _controllers.clear();
    await Future.wait<void>(
      controllers.map((StreamController<AmapLocationResult> controller) {
        return controller.close();
      }),
    );
  }

  @override
  void onLocation(int clientId, NativeLocation location) {
    if (_disposed) {
      return;
    }
    _controllers[clientId]?.add(result(location));
  }

  @override
  void onError(int clientId, NativeLocationErrorCode code, String? message) {
    if (_disposed) {
      return;
    }
    _controllers[clientId]?.addError(exception(code, message));
  }

  AmapLocationResult result(NativeLocation value) => AmapLocationResult(
    position: LatLng(value.latitude, value.longitude),
    timestamp: DateTime.fromMillisecondsSinceEpoch(value.timestampMillis),
    accuracyMeters: value.accuracyMeters,
    coordinateType: switch (value.coordinateType) {
      NativeCoordinateType.gcj02 => AmapCoordinateType.gcj02,
      NativeCoordinateType.wgs84 => AmapCoordinateType.wgs84,
      NativeCoordinateType.unknown => null,
    },
    address: _address(value.address),
  );

  AmapLocationException platformException(PlatformException error) {
    final NativeLocationErrorCode? code = NativeLocationErrorCode.values
        .cast<NativeLocationErrorCode?>()
        .firstWhere(
          (NativeLocationErrorCode? value) =>
              value?.name == _camelCase(error.code),
          orElse: () => null,
        );
    return exception(code ?? NativeLocationErrorCode.unknown, error.message);
  }

  AmapLocationException exception(
    NativeLocationErrorCode code,
    String? message,
  ) => switch (code) {
    NativeLocationErrorCode.privacyNotConfigured =>
      AmapLocationPrivacyException(message),
    NativeLocationErrorCode.apiKeyMissing => AmapLocationApiKeyException(
      message,
    ),
    NativeLocationErrorCode.permissionNotDetermined =>
      AmapLocationPermissionException(
        AmapLocationPermissionStatus.notDetermined,
        message,
      ),
    NativeLocationErrorCode.permissionDenied => AmapLocationPermissionException(
      AmapLocationPermissionStatus.denied,
      message,
    ),
    NativeLocationErrorCode.permissionDeniedForever =>
      AmapLocationPermissionException(
        AmapLocationPermissionStatus.deniedForever,
        message,
      ),
    NativeLocationErrorCode.permissionRestricted =>
      AmapLocationPermissionException(
        AmapLocationPermissionStatus.restricted,
        message,
      ),
    NativeLocationErrorCode.serviceDisabled =>
      AmapLocationServiceDisabledException(message),
    NativeLocationErrorCode.timeout => AmapLocationTimeoutException(message),
    NativeLocationErrorCode.sdkInitializationFailed =>
      AmapLocationInitializationException(message),
    NativeLocationErrorCode.backgroundUnsupported =>
      AmapLocationBackgroundUnsupportedException(message),
    NativeLocationErrorCode.operationInProgress =>
      AmapLocationOperationInProgressException(message),
    NativeLocationErrorCode.clientNotFound =>
      AmapLocationClientNotFoundException(message),
    NativeLocationErrorCode.unsupported => AmapLocationUnsupportedException(
      message,
    ),
    NativeLocationErrorCode.unknown => AmapLocationUnknownException(message),
  };

  AmapLocationAddress? _address(NativeLocationAddress? value) => value == null
      ? null
      : AmapLocationAddress(
          formattedAddress: value.formattedAddress,
          country: value.country,
          province: value.province,
          city: value.city,
          district: value.district,
          cityCode: value.cityCode,
          adCode: value.adCode,
          street: value.street,
          streetNumber: value.streetNumber,
          poiName: value.poiName,
          aoiName: value.aoiName,
        );

  String _camelCase(String value) {
    final List<String> parts = value.toLowerCase().split('_');
    return parts.first +
        parts.skip(1).map((String part) {
          return part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}';
        }).join();
  }
}
