package com.github.amapkit.location

import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.amap.api.location.AMapLocation
import com.amap.api.location.AMapLocationClient
import com.amap.api.location.AMapLocationClientOption
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.PluginRegistry

class AmapLocationNativePlugin :
  FlutterPlugin,
  LocationHostApi {
  private var applicationContext: Context? = null
  private var flutterApi: LocationFlutterApi? = null
  private val clients = mutableMapOf<Long, ClientRecord>()
  private val handler by lazy { Handler(Looper.getMainLooper()) }
  private var nextClientId = 1L
  private var configuredPrivacyStatus: NativePrivacyStatus? = null
  private var configuredApiKey: String? = null
  private var hasCreatedClient = false

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = binding.applicationContext
    flutterApi = LocationFlutterApi(binding.binaryMessenger)
    LocationHostApi.setUp(binding.binaryMessenger, this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    disposeAllClients()
    LocationHostApi.setUp(binding.binaryMessenger, null)
    flutterApi = null
    applicationContext = null
  }

  /** Applies a runtime AMap API Key from Dart. Android and iOS use different
   *  keys, so callers pass the platform's own value before creating any client.
   *  When not called, `ensureApiKeyConfigured` falls back to the static
   *  manifest key. A client may already exist only when the same key is
   *  repeated (idempotent no-op); changing the key afterwards is rejected. */
  override fun setApiKey(apiKey: String) {
    val normalizedApiKey = apiKey.trim()
    if (normalizedApiKey.isEmpty()) {
      throw FlutterError("api_key_missing", "高德定位 API Key 不能为空。")
    }
    if (configuredApiKey == normalizedApiKey) {
      return
    }
    if (hasCreatedClient) {
      throw FlutterError(
        "operation_in_progress",
        "必须在创建定位客户端前设置 API Key。",
      )
    }
    AMapLocationClient.setApiKey(normalizedApiKey)
    configuredApiKey = normalizedApiKey
  }

  override fun setPrivacyStatus(status: NativePrivacyStatus) {
    if (configuredPrivacyStatus == status) {
      return
    }
    if (clients.isNotEmpty()) {
      throw FlutterError(
        "operation_in_progress",
        "必须在创建定位客户端前设置隐私状态。",
      )
    }
    val context = requireContext()
    AMapLocationClient.updatePrivacyShow(
      context,
      status.containsAmapPrivacyPolicy,
      status.privacyNoticeShown,
    )
    AMapLocationClient.updatePrivacyAgree(context, status.userAgreed)
    configuredPrivacyStatus = status
  }

  override fun isLocationServiceEnabled(): Boolean {
    val manager =
      requireContext().getSystemService(Context.LOCATION_SERVICE) as LocationManager
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      manager.isLocationEnabled
    } else {
      manager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
        manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }
  }

  override fun createClient(options: NativeLocationOptions): Long {
    ensureApiKeyConfigured()
    configureAndroidGlobals(options.android)
    val id = nextClientId++
    val client = createNativeClient()
    val record = ClientRecord(options, client)
    client.setLocationOption(continuousOptions(options))
    client.setLocationListener { location -> publishContinuous(id, location) }
    clients[id] = record
    hasCreatedClient = true
    return id
  }

  override fun setLocationOption(
    clientId: Long,
    options: NativeLocationOptions,
  ) {
    val record = requireClient(clientId)
    ensureLocationOptionCanBeSet(
      started = record.started,
      oneShotPending = record.pendingOneShot != null,
    )
    configureAndroidGlobals(options.android)
    try {
      record.continuousClient.setLocationOption(continuousOptions(options))
    } catch (error: Throwable) {
      record.continuousClient.setLocationOption(continuousOptions(record.options))
      throw error
    }
    record.options = options
  }

  override fun getCurrentLocation(
    clientId: Long,
    callback: (Result<NativeLocation>) -> Unit,
  ) {
    try {
      ensureCanLocate()
      val record = requireClient(clientId)
      if (record.pendingOneShot != null) {
        callback(
          Result.failure(
            FlutterError("operation_in_progress", "该客户端已有单次定位请求。"),
          ),
        )
        return
      }
      val client = createNativeClient()
      val timeout = Runnable {
        finishOneShot(
          clientId,
          Result.failure(FlutterError("timeout", "单次定位请求超时。")),
        )
      }
      val pending = PendingOneShot(client, callback, timeout)
      record.pendingOneShot = pending
      client.setLocationListener { location ->
        if (location.errorCode == AMapLocation.LOCATION_SUCCESS) {
          finishOneShot(clientId, Result.success(nativeLocation(location)))
        } else {
          finishOneShot(
            clientId,
            Result.failure(
              FlutterError(
                "unknown",
                "高德定位失败，原生错误码 ${location.errorCode}。",
              ),
            ),
          )
        }
      }
      client.setLocationOption(
        locationOptions(record.options).apply {
          isOnceLocation = true
          isOnceLocationLatest = record.options.android?.onceLocationLatest ?: true
        },
      )
      handler.postDelayed(timeout, record.options.timeoutMillis)
      client.startLocation()
    } catch (error: Throwable) {
      callback(Result.failure(error))
    }
  }

  override fun start(clientId: Long) {
    ensureCanLocate()
    val record = requireClient(clientId)
    if (record.started) {
      return
    }
    record.continuousClient.setLocationOption(continuousOptions(record.options))
    record.continuousClient.startLocation()
    record.started = true
  }

  override fun stop(clientId: Long) {
    val record = requireClient(clientId)
    if (!record.started) {
      return
    }
    record.continuousClient.stopLocation()
    record.started = false
  }

  override fun disposeClient(clientId: Long) {
    val record = clients.remove(clientId) ?: return
    record.pendingOneShot?.let { pending ->
      handler.removeCallbacks(pending.timeout)
      pending.client.onDestroy()
      pending.callback(
        Result.failure(FlutterError("client_not_found", "定位客户端已释放。")),
      )
    }
    record.pendingOneShot = null
    record.continuousClient.stopLocation()
    record.continuousClient.onDestroy()
  }

  private fun publishContinuous(clientId: Long, location: AMapLocation) {
    if (clients[clientId]?.started != true) {
      return
    }
    val api = flutterApi ?: return
    if (location.errorCode == AMapLocation.LOCATION_SUCCESS) {
      api.onLocation(clientId, nativeLocation(location)) {}
    } else {
      api.onError(
        clientId,
        NativeLocationErrorCode.UNKNOWN,
        "高德定位失败，原生错误码 ${location.errorCode}。",
      ) {}
    }
  }

  private fun finishOneShot(clientId: Long, result: Result<NativeLocation>) {
    val pending = clients[clientId]?.pendingOneShot ?: return
    clients[clientId]?.pendingOneShot = null
    handler.removeCallbacks(pending.timeout)
    pending.client.stopLocation()
    pending.client.onDestroy()
    pending.callback(result)
  }

  private fun locationOptions(
    options: NativeLocationOptions,
  ): AMapLocationClientOption = AMapLocationClientOption().apply {
    val android = options.android
    android?.locationPurpose?.let {
      setLocationPurpose(
        when (it) {
          NativeAndroidLocationPurpose.SIGN_IN ->
            AMapLocationClientOption.AMapLocationPurpose.SignIn
          NativeAndroidLocationPurpose.TRANSPORT ->
            AMapLocationClientOption.AMapLocationPurpose.Transport
          NativeAndroidLocationPurpose.SPORT ->
            AMapLocationClientOption.AMapLocationPurpose.Sport
        },
      )
    }
    locationMode = when (android?.locationMode) {
      NativeAndroidLocationMode.HIGH_ACCURACY ->
        AMapLocationClientOption.AMapLocationMode.Hight_Accuracy
      NativeAndroidLocationMode.BATTERY_SAVING ->
        AMapLocationClientOption.AMapLocationMode.Battery_Saving
      NativeAndroidLocationMode.DEVICE_SENSORS ->
        AMapLocationClientOption.AMapLocationMode.Device_Sensors
      null -> when (options.accuracy) {
        NativeLocationAccuracy.HIGH ->
          AMapLocationClientOption.AMapLocationMode.Hight_Accuracy
        NativeLocationAccuracy.BALANCED,
        NativeLocationAccuracy.LOW_POWER ->
          AMapLocationClientOption.AMapLocationMode.Battery_Saving
      }
    }
    interval = options.intervalMillis.coerceAtLeast(MIN_INTERVAL_MILLIS)
    httpTimeOut = android?.httpTimeoutMillis ?: options.timeoutMillis
    isNeedAddress = options.needAddress
    if (android != null) {
      setMockEnable(android.mockEnabled)
      setWifiScan(android.wifiScanEnabled)
      setLocationCacheEnable(android.locationCacheEnabled)
      setSensorEnable(android.sensorEnabled)
      setGpsFirst(android.gpsFirst)
      setGpsFirstTimeout(android.gpsFirstTimeoutMillis)
      setBeidouFirst(android.beidouFirst)
      setDeviceModeDistanceFilter(
        android.deviceModeDistanceFilterMeters.toFloat(),
      )
      setGeoLanguage(
        when (android.geoLanguage) {
          NativeAndroidGeoLanguage.SYSTEM ->
            AMapLocationClientOption.GeoLanguage.DEFAULT
          NativeAndroidGeoLanguage.CHINESE ->
            AMapLocationClientOption.GeoLanguage.ZH
          NativeAndroidGeoLanguage.ENGLISH ->
            AMapLocationClientOption.GeoLanguage.EN
        },
      )
      setOffset(android.coordinateOffsetEnabled)
      setSelfStartServiceEnable(android.selfStartServiceEnabled)
      setKillProcess(android.killProcessOnDestroy)
    }
  }

  private fun continuousOptions(
    options: NativeLocationOptions,
  ): AMapLocationClientOption = locationOptions(options).apply {
    isOnceLocation = false
    isOnceLocationLatest = options.android?.onceLocationLatest ?: false
  }

  private fun configureAndroidGlobals(options: NativeAndroidLocationOptions?) {
    val requested = AndroidGlobalOptions(
      protocol = options?.locationProtocol ?: NativeAndroidLocationProtocol.HTTP,
      alwaysScanWifi = options?.alwaysScanWifi ?: true,
    )
    synchronized(AmapLocationNativePlugin::class.java) {
      val configured = processAndroidGlobalOptions
      if (configured != null && configured != requested) {
        throw FlutterError(
          "operation_in_progress",
          "Android 定位协议和始终扫描 Wi-Fi 是进程级参数，创建客户端后不能切换。",
        )
      }
      AMapLocationClientOption.setLocationProtocol(
        when (requested.protocol) {
          NativeAndroidLocationProtocol.HTTP ->
            AMapLocationClientOption.AMapLocationProtocol.HTTP
          NativeAndroidLocationProtocol.HTTPS ->
            AMapLocationClientOption.AMapLocationProtocol.HTTPS
        },
      )
      AMapLocationClientOption.setOpenAlwaysScanWifi(requested.alwaysScanWifi)
      processAndroidGlobalOptions = requested
    }
  }

  private fun nativeLocation(location: AMapLocation): NativeLocation =
    NativeLocation(
      latitude = location.latitude,
      longitude = location.longitude,
      accuracyMeters = location.accuracy.toDouble(),
      timestampMillis = location.time,
      coordinateType = when (location.coordType) {
        AMapLocation.COORD_TYPE_GCJ02 -> NativeCoordinateType.GCJ02
        AMapLocation.COORD_TYPE_WGS84 -> NativeCoordinateType.WGS84
        else -> NativeCoordinateType.UNKNOWN
      },
      address = nativeAddress(location),
    )

  private fun nativeAddress(location: AMapLocation): NativeLocationAddress? {
    val address = NativeLocationAddress(
      formattedAddress = location.address.normalized(),
      country = location.country.normalized(),
      province = location.province.normalized(),
      city = location.city.normalized(),
      district = location.district.normalized(),
      cityCode = location.cityCode.normalized(),
      adCode = location.adCode.normalized(),
      street = location.street.normalized(),
      streetNumber = location.streetNum.normalized(),
      poiName = location.poiName.normalized(),
      aoiName = location.aoiName.normalized(),
    )
    return if (
      listOf(
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
      ).all { it == null }
    ) {
      null
    } else {
      address
    }
  }

  private fun String?.normalized(): String? =
    this?.trim()?.takeIf { it.isNotEmpty() }


  private fun ensureCanLocate() {
    ensureApiKeyConfigured()
  }

  private fun ensureApiKeyConfigured() {
    if (configuredApiKey != null) {
      return
    }
    val context = requireContext()
    val applicationInfo = context.packageManager.getApplicationInfo(
      context.packageName,
      PackageManager.GET_META_DATA,
    )
    val apiKey = applicationInfo.metaData
      ?.getString(AMAP_API_KEY_METADATA)
      ?.trim()
    if (apiKey.isNullOrBlank()) {
      throw FlutterError(
        "api_key_missing",
        "请调用 setApiKey，或在 AndroidManifest.xml 中配置高德定位 API Key。",
      )
    }
    AMapLocationClient.setApiKey(apiKey)
    configuredApiKey = apiKey
  }

  private fun createNativeClient(): AMapLocationClient {
    try {
      return AMapLocationClient(requireContext())
    } catch (error: Throwable) {
      throw FlutterError(
        "sdk_initialization_failed",
        "高德定位 SDK 初始化失败。",
        error.javaClass.simpleName,
      )
    }
  }

  private fun requireClient(clientId: Long): ClientRecord =
    clients[clientId]
      ?: throw FlutterError("client_not_found", "未知或已释放的 clientId。")

  private fun requireContext(): Context =
    applicationContext
      ?: throw FlutterError("unsupported", "Flutter Engine 尚未附着。")

  private fun disposeAllClients() {
    clients.keys.toList().forEach(::disposeClient)
  }

  private data class ClientRecord(
    var options: NativeLocationOptions,
    val continuousClient: AMapLocationClient,
    var started: Boolean = false,
    var pendingOneShot: PendingOneShot? = null,
  )

  private data class PendingOneShot(
    val client: AMapLocationClient,
    val callback: (Result<NativeLocation>) -> Unit,
    val timeout: Runnable,
  )

  private data class AndroidGlobalOptions(
    val protocol: NativeAndroidLocationProtocol,
    val alwaysScanWifi: Boolean,
  )

  private companion object {
    const val AMAP_API_KEY_METADATA = "com.amap.api.v2.apikey"
    const val MIN_INTERVAL_MILLIS = 1000L
    var processAndroidGlobalOptions: AndroidGlobalOptions? = null
  }
}

internal fun ensureLocationOptionCanBeSet(
  started: Boolean,
  oneShotPending: Boolean,
) {
  if (started) {
    throw FlutterError(
      "operation_in_progress",
      "请先停止持续定位，再设置定位参数。",
    )
  }
  if (oneShotPending) {
    throw FlutterError(
      "operation_in_progress",
      "单次定位请求完成前不能设置定位参数。",
    )
  }
}
