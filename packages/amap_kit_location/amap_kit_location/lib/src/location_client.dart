import 'dart:async';

import 'package:amap_kit_location_platform_interface/amap_kit_location_platform_interface.dart';

/// 拥有独立原生资源和事件流的高德定位客户端。
final class AmapLocationClient {
  /// 创建一个惰性初始化的定位客户端。
  ///
  /// 首次定位操作才会创建原生对象。调用方不再需要客户端时必须调用 [dispose]。
  AmapLocationClient({
    AmapLocationOptions options = const AmapLocationOptions(),
  }) : _options = options {
    _validateLocationOptions(options);
  }

  AmapLocationOptions _options;

  /// 该客户端最后一次成功应用的不可变定位配置。
  AmapLocationOptions get options => _options;

  /// 替换该客户端后续定位使用的完整配置。
  ///
  /// 原生客户端尚未创建时仅更新本地配置。原生客户端创建后，只能在持续定位
  /// 已停止且没有单次定位请求时更新；失败时保留原配置。
  Future<void> setLocationOption(AmapLocationOptions options) =>
      _enqueue(() async {
        _ensureActive();
        _validateLocationOptions(options);
        if (_started) {
          throw const AmapLocationOperationInProgressException(
            '请先停止持续定位，再设置定位参数。',
          );
        }
        final Future<int>? idFuture = _clientId;
        if (idFuture != null) {
          final int id = await idFuture;
          _ensureActive();
          await AmapLocationPlatform.instance.setLocationOption(id, options);
        }
        _options = options;
      });

  static void _validateLocationOptions(AmapLocationOptions options) {
    if (options.interval < const Duration(seconds: 1)) {
      throw ArgumentError.value(
        options.interval,
        'options.interval',
        '持续定位间隔不得短于一秒。',
      );
    }
    if (options.timeout < const Duration(seconds: 2)) {
      throw ArgumentError.value(
        options.timeout,
        'options.timeout',
        '单次定位超时不得短于两秒。',
      );
    }
    final AmapLocationAndroidOptions? android = options.android;
    if (android != null) {
      if (android.httpTimeout <= Duration.zero) {
        throw ArgumentError.value(
          android.httpTimeout,
          'options.android.httpTimeout',
          'Android 联网超时必须大于零。',
        );
      }
      if (android.gpsFirstTimeout < const Duration(seconds: 5) ||
          android.gpsFirstTimeout > const Duration(seconds: 30)) {
        throw ArgumentError.value(
          android.gpsFirstTimeout,
          'options.android.gpsFirstTimeout',
          'Android 卫星优先等待时间必须为 5 至 30 秒。',
        );
      }
      if (android.gpsFirst && options.timeout < android.gpsFirstTimeout) {
        throw ArgumentError.value(
          options.timeout,
          'options.timeout',
          '启用 Android 卫星优先时，单次定位超时不得短于卫星优先等待时间。',
        );
      }
      if (!android.deviceModeDistanceFilterMeters.isFinite ||
          android.deviceModeDistanceFilterMeters < 0) {
        throw ArgumentError.value(
          android.deviceModeDistanceFilterMeters,
          'options.android.deviceModeDistanceFilterMeters',
          'Android 最小移动距离必须是非负有限数值。',
        );
      }
    }
    final double? iosDistanceFilter = options.ios?.distanceFilterMeters;
    if (iosDistanceFilter != null &&
        (!iosDistanceFilter.isFinite || iosDistanceFilter < 0)) {
      throw ArgumentError.value(
        iosDistanceFilter,
        'options.ios.distanceFilterMeters',
        'iOS 最小移动距离必须是非负有限数值。',
      );
    }
    final AmapLocationIosAccuracyMode? accuracyMode =
        options.ios?.locationAccuracyMode;
    final String? fullAccuracyPurposeKey = options.ios?.fullAccuracyPurposeKey
        ?.trim();
    if (fullAccuracyPurposeKey != null && fullAccuracyPurposeKey.isEmpty) {
      throw ArgumentError.value(
        options.ios?.fullAccuracyPurposeKey,
        'options.ios.fullAccuracyPurposeKey',
        'iOS 临时精确定位 Purpose Key 不能为空。',
      );
    }
    switch (accuracyMode) {
      case AmapLocationIosAccuracyMode.fullAndReduced:
      case AmapLocationIosAccuracyMode.full:
        if (fullAccuracyPurposeKey == null) {
          throw ArgumentError.value(
            fullAccuracyPurposeKey,
            'options.ios.fullAccuracyPurposeKey',
            '请求 iOS 临时精确定位时必须提供 Purpose Key。',
          );
        }
        break;
      case AmapLocationIosAccuracyMode.reduced:
      case null:
        if (fullAccuracyPurposeKey != null) {
          throw ArgumentError.value(
            fullAccuracyPurposeKey,
            'options.ios.fullAccuracyPurposeKey',
            'Purpose Key 仅能与临时精确定位模式一起使用。',
          );
        }
        break;
    }
  }

  final StreamController<AmapLocationResult> _locations =
      StreamController<AmapLocationResult>.broadcast();
  Future<int>? _clientId;
  StreamSubscription<AmapLocationResult>? _subscription;
  Future<void> _operationTail = Future<void>.value();
  Future<void>? _disposeFuture;
  bool _started = false;
  bool _disposeRequested = false;
  bool _disposed = false;

  /// 持续定位成功结果的广播流。
  ///
  /// 原生失败以强类型 [AmapLocationException] 作为流错误发送。停止定位不会关闭
  /// 此流，释放客户端后流会关闭。
  Stream<AmapLocationResult> get locations => _locations.stream;

  /// 请求一次与持续定位状态相互独立的位置。
  Future<AmapLocationResult> getCurrentLocation() async {
    _ensureActive();
    final int id = await _id();
    _ensureActive();
    return AmapLocationPlatform.instance.getCurrentLocation(id);
  }

  /// 启动持续定位。
  ///
  /// 重复调用是幂等的。
  Future<void> start() => _enqueue(() async {
    _ensureActive();
    if (_started) {
      return;
    }
    final int id = await _id();
    _ensureActive();
    final StreamSubscription<AmapLocationResult> subscription =
        AmapLocationPlatform.instance
            .locationsForClient(id)
            .listen(_locations.add, onError: _locations.addError);
    try {
      await AmapLocationPlatform.instance.start(id);
      _subscription = subscription;
      _started = true;
    } on Object {
      await subscription.cancel();
      rethrow;
    }
  });

  /// 停止持续定位。
  ///
  /// 重复调用是幂等的，结果流保持打开以支持再次启动。
  Future<void> stop() => _enqueue(() async {
    _ensureActive();
    await _stopInternal();
  });

  /// 释放事件订阅和原生定位资源。
  ///
  /// 重复调用返回同一个释放任务。调用开始后，所有新操作都会立即以
  /// [AmapLocationDisposedException] 失败。
  Future<void> dispose() {
    _disposeRequested = true;
    return _disposeFuture ??= _enqueue(() async {
      if (_disposed) {
        return;
      }
      Object? failure;
      StackTrace? failureStack;
      try {
        await _stopInternal();
        final Future<int>? idFuture = _clientId;
        if (idFuture != null) {
          await AmapLocationPlatform.instance.disposeClient(await idFuture);
        }
      } on Object catch (error, stackTrace) {
        failure = error;
        failureStack = stackTrace;
      } finally {
        _disposed = true;
        await _subscription?.cancel();
        _subscription = null;
        await _locations.close();
      }
      if (failure != null) {
        Error.throwWithStackTrace(failure, failureStack!);
      }
    });
  }

  Future<void> _stopInternal() async {
    if (!_started) {
      return;
    }
    final int id = await _clientId!;
    try {
      await AmapLocationPlatform.instance.stop(id);
    } finally {
      await _subscription?.cancel();
      _subscription = null;
      _started = false;
    }
  }

  Future<int> _id() {
    _ensureActive();
    return _clientId ??= AmapLocationPlatform.instance.createClient(_options);
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final Future<T> result = _operationTail.then((_) => operation());
    _operationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  void _ensureActive() {
    if (_disposeRequested || _disposed) {
      throw const AmapLocationDisposedException();
    }
  }
}
