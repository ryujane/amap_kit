import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'amap_kit_location_ios',
    dartOut: 'lib/src/generated/location_messages.g.dart',
    swiftOut:
        'ios/amap_kit_location_ios/Sources/amap_kit_location_ios/LocationMessages.g.swift',
  ),
)
enum NativeLocationAccuracy { high, balanced, lowPower }

enum NativeIosDesiredAccuracy {
  bestForNavigation,
  best,
  nearestTenMeters,
  hundredMeters,
  kilometer,
  threeKilometers,
}

enum NativeIosAccuracyMode { fullAndReduced, full, reduced }

enum NativeCoordinateType { gcj02, wgs84, unknown }

enum NativeLocationErrorCode {
  privacyNotConfigured,
  apiKeyMissing,
  permissionNotDetermined,
  permissionDenied,
  permissionDeniedForever,
  permissionRestricted,
  serviceDisabled,
  timeout,
  sdkInitializationFailed,
  backgroundUnsupported,
  operationInProgress,
  clientNotFound,
  unsupported,
  unknown,
}

class NativePrivacyStatus {
  NativePrivacyStatus({
    required this.privacyNoticeShown,
    required this.containsAmapPrivacyPolicy,
    required this.userAgreed,
  });

  bool privacyNoticeShown;
  bool containsAmapPrivacyPolicy;
  bool userAgreed;
}

class NativeLocationOptions {
  NativeLocationOptions({
    required this.accuracy,
    required this.intervalMillis,
    required this.timeoutMillis,
    required this.needAddress,
    this.ios,
  });

  NativeLocationAccuracy accuracy;
  int intervalMillis;
  int timeoutMillis;
  bool needAddress;
  NativeIosLocationOptions? ios;
}

class NativeIosLocationOptions {
  NativeIosLocationOptions({
    required this.desiredAccuracy,
    required this.distanceFilterMeters,
    required this.pausesLocationUpdatesAutomatically,
    required this.locationAccuracyMode,
    required this.fullAccuracyPurposeKey,
  });

  NativeIosDesiredAccuracy? desiredAccuracy;
  double? distanceFilterMeters;
  bool pausesLocationUpdatesAutomatically;
  NativeIosAccuracyMode? locationAccuracyMode;
  String? fullAccuracyPurposeKey;
}

class NativeLocation {
  NativeLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestampMillis,
    required this.coordinateType,
    this.address,
  });

  double latitude;
  double longitude;
  double accuracyMeters;
  int timestampMillis;
  NativeCoordinateType coordinateType;
  NativeLocationAddress? address;
}

class NativeLocationAddress {
  NativeLocationAddress({
    this.formattedAddress,
    this.country,
    this.province,
    this.city,
    this.district,
    this.cityCode,
    this.adCode,
    this.street,
    this.streetNumber,
    this.poiName,
    this.aoiName,
  });

  String? formattedAddress;
  String? country;
  String? province;
  String? city;
  String? district;
  String? cityCode;
  String? adCode;
  String? street;
  String? streetNumber;
  String? poiName;
  String? aoiName;
}

@HostApi()
abstract class LocationHostApi {
  void setApiKey(String apiKey);
  void setPrivacyStatus(NativePrivacyStatus status);
  bool isLocationServiceEnabled();
  int createClient(NativeLocationOptions options);
  void setLocationOption(int clientId, NativeLocationOptions options);

  @async
  NativeLocation getCurrentLocation(int clientId);

  void start(int clientId);
  void stop(int clientId);
  void disposeClient(int clientId);
}

@FlutterApi()
abstract class LocationFlutterApi {
  void onLocation(int clientId, NativeLocation location);
  void onError(int clientId, NativeLocationErrorCode code, String? message);
}
