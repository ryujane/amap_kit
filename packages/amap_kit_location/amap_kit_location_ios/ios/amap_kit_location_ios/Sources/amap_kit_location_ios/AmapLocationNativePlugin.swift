import AMapFoundationKit
import AMapLocationKit
import CoreLocation
import Flutter

public final class AmapLocationNativePlugin: NSObject, FlutterPlugin, LocationHostApi,
  AMapLocationManagerDelegate, CLLocationManagerDelegate
{
  private var clients: [Int64: ClientRecord] = [:]
  private var clientIdsByManager: [ObjectIdentifier: Int64] = [:]
  private var fullAccuracyPurposeKeysByManager: [ObjectIdentifier: String] = [:]
  private var nextClientId: Int64 = 1
  private var flutterApi: LocationFlutterApi?
  private var configuredPrivacyStatus: NativePrivacyStatus?
  private var configuredApiKey: String?
  private var hasCreatedClient = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = AmapLocationNativePlugin()
    instance.flutterApi = LocationFlutterApi(binaryMessenger: registrar.messenger())
    LocationHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  deinit {
    disposeAllClients()
  }

  /// Applies a runtime AMap API Key from Dart. Android and iOS use different
  /// keys, so callers pass the platform's own value before creating any client.
  /// When not called, `configureApiKey` falls back to the static Info.plist
  /// `AMapApiKey`. A client may already exist only when the same key is
  /// repeated (idempotent no-op); changing the key afterwards is rejected.
  func setApiKey(apiKey: String) throws {
    let normalizedApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalizedApiKey.isEmpty else {
      throw error("api_key_missing", "高德定位 API Key 不能为空。")
    }
    if configuredApiKey == normalizedApiKey {
      return
    }
    if hasCreatedClient {
      throw error(
        "operation_in_progress",
        "必须在创建定位客户端前设置 API Key。"
      )
    }
    AMapServices.shared().apiKey = normalizedApiKey
    configuredApiKey = normalizedApiKey
  }

  func setPrivacyStatus(status: NativePrivacyStatus) throws {
    if configuredPrivacyStatus == status {
      return
    }
    if !clients.isEmpty {
      throw error(
        "operation_in_progress",
        "必须在创建定位客户端前设置隐私状态。"
      )
    }
    AMapLocationManager.updatePrivacyShow(
      status.privacyNoticeShown ? .didShow : .notShow,
      privacyInfo: status.containsAmapPrivacyPolicy ? .didContain : .notContain
    )
    AMapLocationManager.updatePrivacyAgree(
      status.userAgreed ? .didAgree : .notAgree
    )
    configuredPrivacyStatus = status
  }

  func isLocationServiceEnabled() throws -> Bool {
    CLLocationManager.locationServicesEnabled()
  }

  func createClient(options: NativeLocationOptions) throws -> Int64 {
    try configureApiKey()
    let manager = AMapLocationManager()
    try configure(manager, options: options)
    manager.delegate = self
    let clientId = nextClientId
    nextClientId += 1
    let record = ClientRecord(options: options, manager: manager)
    clients[clientId] = record
    clientIdsByManager[ObjectIdentifier(manager)] = clientId
    hasCreatedClient = true
    return clientId
  }

  func setLocationOption(
    clientId: Int64,
    options: NativeLocationOptions
  ) throws {
    let record = try client(clientId)
    guard !record.started else {
      throw error(
        "operation_in_progress",
        "请先停止持续定位，再设置定位参数。"
      )
    }
    guard record.oneShotManager == nil else {
      throw error(
        "operation_in_progress",
        "单次定位请求完成前不能设置定位参数。"
      )
    }
    do {
      try configure(record.manager, options: options)
    } catch {
      try? configure(record.manager, options: record.options)
      throw error
    }
    record.options = options
    record.lastPublishedMillis = 0
  }

  func getCurrentLocation(
    clientId: Int64,
    completion: @escaping (Result<NativeLocation, Error>) -> Void
  ) {
    do {
      try ensureCanLocate()
      let record = try client(clientId)
      guard record.oneShotManager == nil else {
        completion(
          .failure(
            error(
              "operation_in_progress",
              "该客户端已有单次定位请求。"
            )
          )
        )
        return
      }
      let manager = AMapLocationManager()
      try configure(manager, options: record.options)
      manager.delegate = self
      record.oneShotManager = manager
      record.oneShotCompletion = completion
      let accepted = manager.requestLocation(
        withReGeocode: record.options.needAddress
      ) { [weak self] location, reGeocode, nativeError in
        guard let self else { return }
        guard let current = self.clients[clientId],
          current.oneShotManager === manager
        else {
          return
        }
        current.oneShotManager = nil
        current.oneShotCompletion = nil
        self.fullAccuracyPurposeKeysByManager.removeValue(
          forKey: ObjectIdentifier(manager)
        )
        manager.delegate = nil
        if let location {
          completion(
            .success(self.nativeLocation(location, reGeocode: reGeocode))
          )
        } else if let nativeError {
          completion(.failure(self.mapLocationError(nativeError)))
        } else {
          completion(
            .failure(
              self.error("unknown", "单次定位没有返回位置或错误。")
            )
          )
        }
      }
      if !accepted {
        record.oneShotManager = nil
        record.oneShotCompletion = nil
        fullAccuracyPurposeKeysByManager.removeValue(
          forKey: ObjectIdentifier(manager)
        )
        manager.delegate = nil
        completion(
          .failure(
            error("sdk_initialization_failed", "高德 SDK 拒绝了单次定位请求。")
          )
        )
      }
    } catch {
      completion(.failure(error))
    }
  }

  func start(clientId: Int64) throws {
    try ensureCanLocate()
    let record = try client(clientId)
    guard !record.started else { return }
    try configure(record.manager, options: record.options)
    record.manager.startUpdatingLocation()
    record.started = true
  }

  func stop(clientId: Int64) throws {
    let record = try client(clientId)
    guard record.started else { return }
    record.manager.stopUpdatingLocation()
    record.started = false
  }

  func disposeClient(clientId: Int64) throws {
    guard let record = clients.removeValue(forKey: clientId) else { return }
    clientIdsByManager.removeValue(forKey: ObjectIdentifier(record.manager))
    fullAccuracyPurposeKeysByManager.removeValue(
      forKey: ObjectIdentifier(record.manager)
    )
    record.manager.stopUpdatingLocation()
    record.manager.delegate = nil
    if let oneShotManager = record.oneShotManager {
      fullAccuracyPurposeKeysByManager.removeValue(
        forKey: ObjectIdentifier(oneShotManager)
      )
      oneShotManager.stopUpdatingLocation()
      oneShotManager.delegate = nil
      record.oneShotCompletion?(
        .failure(error("client_not_found", "定位客户端已释放。"))
      )
    }
    record.oneShotManager = nil
    record.oneShotCompletion = nil
  }

  public func amapLocationManager(
    _ manager: AMapLocationManager!,
    didUpdate location: CLLocation!,
    reGeocode: AMapLocationReGeocode!
  ) {
    guard let manager, let location,
      let clientId = clientIdsByManager[ObjectIdentifier(manager)],
      let record = clients[clientId], record.started
    else {
      return
    }
    let timestampMillis = Int64(location.timestamp.timeIntervalSince1970 * 1000)
    if timestampMillis - record.lastPublishedMillis < record.options.intervalMillis {
      return
    }
    record.lastPublishedMillis = timestampMillis
    flutterApi?.onLocation(
      clientId: clientId,
      location: nativeLocation(location, reGeocode: reGeocode)
    ) { _ in }
  }

  public func amapLocationManager(
    _ manager: AMapLocationManager!,
    didFailWithError nativeError: Error!
  ) {
    guard let manager, let nativeError,
      let clientId = clientIdsByManager[ObjectIdentifier(manager)],
      clients[clientId]?.started == true
    else {
      return
    }
    let mapped = mapLocationError(nativeError)
    let pigeonError = mapped as? PigeonError
    let code: NativeLocationErrorCode =
      pigeonError?.code == "timeout" ? .timeout : .unknown
    flutterApi?.onError(
      clientId: clientId,
      code: code,
      message: pigeonError?.message ?? "高德持续定位失败。"
    ) { _ in }
  }

  public func amapLocationManager(
    _ manager: AMapLocationManager!,
    doRequireLocationAuth locationManager: CLLocationManager!
  ) {
    locationManager.requestWhenInUseAuthorization()
  }

  public func amapLocationManager(
    _ manager: AMapLocationManager!,
    doRequireTemporaryFullAccuracyAuth locationManager: CLLocationManager!,
    completion: ((Error?) -> Void)!
  ) {
    guard let manager, let locationManager, let completion else { return }
    guard #available(iOS 14.0, *) else {
      completion(
        NSError(
          domain: "com.amap.kit.location",
          code: 2,
          userInfo: [
            NSLocalizedDescriptionKey:
              "临时精确定位需要 iOS 14 或更高版本。"
          ]
        )
      )
      return
    }
    guard
      let purposeKey =
        fullAccuracyPurposeKeysByManager[ObjectIdentifier(manager)]
    else {
      completion(
        NSError(
          domain: "com.amap.kit.location",
          code: 1,
          userInfo: [
            NSLocalizedDescriptionKey:
              "未配置临时精确定位 fullAccuracyPurposeKey。"
          ]
        )
      )
      return
    }
    // 校验 Info.plist 的 NSLocationTemporaryUsageDescriptionDictionary 是否包含
    // 该 purposeKey；缺失时打日志提示并返回错误，避免无效请求挂起 SDK。
    let temporaryDictionary = Bundle.main.object(
      forInfoDictionaryKey: "NSLocationTemporaryUsageDescriptionDictionary"
    ) as? [String: Any]
    guard temporaryDictionary?[purposeKey] != nil else {
      NSLog(
        "[AMapLocationKit] 要在 iOS 14 及以上版本使用精确定位，Info.plist 的"
          + " NSLocationTemporaryUsageDescriptionDictionary 必须包含"
          + " fullAccuracyPurposeKey：\(purposeKey)。"
      )
      completion(
        NSError(
          domain: "com.amap.kit.location",
          code: 3,
          userInfo: [
            NSLocalizedDescriptionKey:
              "Info.plist 缺少临时精确定位 purposeKey 配置。"
          ]
        )
      )
      return
    }
    locationManager.requestTemporaryFullAccuracyAuthorization(
      withPurposeKey: purposeKey
    ) { nativeError in
      completion(nativeError)
    }
  }

  private func configure(
    _ manager: AMapLocationManager,
    options: NativeLocationOptions
  ) throws {
    if let desiredAccuracy = options.ios?.desiredAccuracy {
      manager.desiredAccuracy = switch desiredAccuracy {
      case .bestForNavigation:
        kCLLocationAccuracyBestForNavigation
      case .best:
        kCLLocationAccuracyBest
      case .nearestTenMeters:
        kCLLocationAccuracyNearestTenMeters
      case .hundredMeters:
        kCLLocationAccuracyHundredMeters
      case .kilometer:
        kCLLocationAccuracyKilometer
      case .threeKilometers:
        kCLLocationAccuracyThreeKilometers
      }
    } else {
      manager.desiredAccuracy = switch options.accuracy {
      case .high:
        kCLLocationAccuracyBest
      case .balanced:
        kCLLocationAccuracyHundredMeters
      case .lowPower:
        kCLLocationAccuracyKilometer
      }
    }
    manager.distanceFilter =
      options.ios?.distanceFilterMeters ?? kCLDistanceFilterNone
    manager.pausesLocationUpdatesAutomatically =
      options.ios?.pausesLocationUpdatesAutomatically ?? false
    let managerIdentifier = ObjectIdentifier(manager)
    let fullAccuracyPurposeKey = normalized(
      options.ios?.fullAccuracyPurposeKey
    )
    if let accuracyMode = options.ios?.locationAccuracyMode {
      guard #available(iOS 14.0, *) else {
        throw error(
          "unsupported",
          "locationAccuracyMode 和 fullAccuracyPurposeKey 需要 iOS 14 或更高版本。"
        )
      }
      switch accuracyMode {
      case .fullAndReduced, .full:
        guard fullAccuracyPurposeKey != nil else {
          throw error(
            "sdk_initialization_failed",
            "请求临时精确定位时必须提供 fullAccuracyPurposeKey。"
          )
        }
      case .reduced:
        guard fullAccuracyPurposeKey == nil else {
          throw error(
            "sdk_initialization_failed",
            "降低精度模式不能配置 fullAccuracyPurposeKey。"
          )
        }
      }
      // The SDK's Objective-C enum cases are not exposed as Swift members.
      manager.locationAccuracyMode = switch accuracyMode {
      case .fullAndReduced:
        AMapLocationAccuracyMode(rawValue: 0)!
      case .full:
        AMapLocationAccuracyMode(rawValue: 1)!
      case .reduced:
        AMapLocationAccuracyMode(rawValue: 2)!
      }
      if let purposeKey = fullAccuracyPurposeKey {
        fullAccuracyPurposeKeysByManager[managerIdentifier] = purposeKey
      } else {
        fullAccuracyPurposeKeysByManager.removeValue(forKey: managerIdentifier)
      }
    } else {
      guard fullAccuracyPurposeKey == nil else {
        throw error(
          "sdk_initialization_failed",
          "fullAccuracyPurposeKey 必须与临时精确定位模式同时配置。"
        )
      }
      fullAccuracyPurposeKeysByManager.removeValue(forKey: managerIdentifier)
    }
    manager.locationTimeout = max(2, Int(options.timeoutMillis / 1000))
    manager.reGeocodeTimeout = max(2, Int(options.timeoutMillis / 1000))
    manager.locatingWithReGeocode = options.needAddress
    manager.allowsBackgroundLocationUpdates = false
  }

  private func nativeLocation(
    _ location: CLLocation,
    reGeocode: AMapLocationReGeocode? = nil
  ) -> NativeLocation {
    NativeLocation(
      latitude: location.coordinate.latitude,
      longitude: location.coordinate.longitude,
      accuracyMeters: location.horizontalAccuracy,
      timestampMillis: Int64(location.timestamp.timeIntervalSince1970 * 1000),
      coordinateType: .unknown,
      address: nativeAddress(reGeocode)
    )
  }

  private func nativeAddress(
    _ reGeocode: AMapLocationReGeocode?
  ) -> NativeLocationAddress? {
    guard let reGeocode else { return nil }
    let address = NativeLocationAddress(
      formattedAddress: normalized(reGeocode.formattedAddress),
      country: normalized(reGeocode.country),
      province: normalized(reGeocode.province),
      city: normalized(reGeocode.city),
      district: normalized(reGeocode.district),
      cityCode: normalized(reGeocode.citycode),
      adCode: normalized(reGeocode.adcode),
      street: normalized(reGeocode.street),
      streetNumber: normalized(reGeocode.number),
      poiName: normalized(reGeocode.value(forKey: "POIName") as? String),
      aoiName: normalized(reGeocode.value(forKey: "AOIName") as? String)
    )
    let values = [
      address.formattedAddress,
      address.country,
      address.province,
      address.city,
      address.district,
      address.cityCode,
      address.adCode,
      address.street,
      address.streetNumber,
      address.poiName,
      address.aoiName,
    ]
    return values.allSatisfy { $0 == nil } ? nil : address
  }

  private func normalized(_ value: String?) -> String? {
    guard let value else { return nil }
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  /// 定位前的唯一前置：确保高德 API Key 已配置。
  /// 权限、隐私合规与定位服务状态均不再由插件校验，直接交给高德 SDK，
  /// 其错误经 [mapLocationError] 返回给 Flutter 端。
  private func ensureCanLocate() throws {
    try configureApiKey()
  }

  private func configureApiKey() throws {
    if configuredApiKey != nil {
      return
    }
    guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "AMapApiKey")
      as? String,
      !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      throw error(
        "api_key_missing",
        "请调用 setApiKey，或在 Info.plist 中配置 AMapApiKey。"
      )
    }
    let normalizedApiKey = apiKey.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    AMapServices.shared().apiKey = normalizedApiKey
    configuredApiKey = normalizedApiKey
  }

  private func client(_ clientId: Int64) throws -> ClientRecord {
    guard let record = clients[clientId] else {
      throw error("client_not_found", "未知或已释放的 clientId。")
    }
    return record
  }

  private func mapLocationError(_ nativeError: Error) -> Error {
    let nsError = nativeError as NSError
    if nsError.code == AMapLocationErrorCode.timeOut.rawValue {
      return error("timeout", "单次定位请求超时。")
    }
    // 将高德 SDK 的错误描述与原生错误码原样透传给 Flutter 端，便于诊断。
    return error(
      "unknown",
      "高德定位失败：\(nsError.localizedDescription)（原生错误码 \(nsError.code)）。"
    )
  }

  private func error(_ code: String, _ message: String) -> PigeonError {
    PigeonError(code: code, message: message, details: nil)
  }

  private func disposeAllClients() {
    for clientId in Array(clients.keys) {
      try? disposeClient(clientId: clientId)
    }
  }
}

private final class ClientRecord {
  init(options: NativeLocationOptions, manager: AMapLocationManager) {
    self.options = options
    self.manager = manager
  }

  var options: NativeLocationOptions
  let manager: AMapLocationManager
  var started = false
  var lastPublishedMillis: Int64 = 0
  var oneShotManager: AMapLocationManager?
  var oneShotCompletion: ((Result<NativeLocation, Error>) -> Void)?
}
