import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/generated/location_messages.g.dart',
    kotlinOptions: KotlinOptions(package: 'com.github.amapkit.location'),
    kotlinOut:
        'android/src/main/kotlin/com/github/amapkit/location/LocationMessages.g.kt',
  ),
)
enum NativeLocationAccuracy { high, balanced, lowPower }

enum NativeAndroidLocationMode { highAccuracy, batterySaving, deviceSensors }

enum NativeAndroidLocationProtocol { http, https }

enum NativeAndroidLocationPurpose { signIn, transport, sport }

enum NativeAndroidGeoLanguage { system, chinese, english }

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
    this.android,
  });

  NativeLocationAccuracy accuracy;
  int intervalMillis;
  int timeoutMillis;
  bool needAddress;
  NativeAndroidLocationOptions? android;
}

class NativeAndroidLocationOptions {
  NativeAndroidLocationOptions({
    required this.locationMode,
    required this.locationProtocol,
    required this.httpTimeoutMillis,
    required this.mockEnabled,
    required this.needAddress,
    required this.wifiScanEnabled,
    required this.alwaysScanWifi,
    required this.locationCacheEnabled,
    required this.onceLocationLatest,
    required this.sensorEnabled,
    required this.gpsFirst,
    required this.gpsFirstTimeoutMillis,
    required this.beidouFirst,
    required this.deviceModeDistanceFilterMeters,
    required this.geoLanguage,
    required this.locationPurpose,
    required this.coordinateOffsetEnabled,
    required this.selfStartServiceEnabled,
    required this.killProcessOnDestroy,
  });

  NativeAndroidLocationMode? locationMode;
  NativeAndroidLocationProtocol locationProtocol;
  int httpTimeoutMillis;
  bool mockEnabled;
  bool needAddress;
  bool wifiScanEnabled;
  bool alwaysScanWifi;
  bool locationCacheEnabled;
  bool onceLocationLatest;
  bool sensorEnabled;
  bool gpsFirst;
  int gpsFirstTimeoutMillis;
  bool beidouFirst;
  double deviceModeDistanceFilterMeters;
  NativeAndroidGeoLanguage geoLanguage;
  NativeAndroidLocationPurpose? locationPurpose;
  bool coordinateOffsetEnabled;
  bool selfStartServiceEnabled;
  bool killProcessOnDestroy;
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
