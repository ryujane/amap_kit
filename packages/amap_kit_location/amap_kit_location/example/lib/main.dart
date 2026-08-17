import 'dart:async';

import 'package:amap_kit_location/amap_kit_location.dart';
import 'package:flutter/material.dart';

const String _apiKey = String.fromEnvironment('AMAP_API_KEY');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LocationExampleApp());
}

class LocationExampleApp extends StatelessWidget {
  const LocationExampleApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: LocationExamplePage());
}

class LocationExamplePage extends StatefulWidget {
  const LocationExamplePage({super.key});

  @override
  State<LocationExamplePage> createState() => _LocationExamplePageState();
}

class _LocationExamplePageState extends State<LocationExamplePage> {
  final TextEditingController _apiKeyController = TextEditingController(
    text: _apiKey,
  );
  AmapLocationClient? _client;
  StreamSubscription<AmapLocationResult>? _locationSubscription;
  String _status = '尚未定位';
  bool _isBusy = false;
  bool _isContinuousLocationRunning = false;
  bool _isApiKeyVisible = false;
  int _continuousUpdateCount = 0;

  @override
  void initState() {
    super.initState();
    AmapLocation.setPrivacyStatus(
      const AmapLocationPrivacyStatus(
        privacyNoticeShown: true,
        containsAmapPrivacyPolicy: true,
        userAgreed: true,
      ),
    );
  }

  Future<void> _locate() async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    try {
      final AmapLocationClient? client = await _prepareClient();
      if (client == null) {
        return;
      }
      final AmapLocationResult result = await client.getCurrentLocation();
      _showResult(result, prefix: '单次定位');
    } on Object catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _startContinuousLocation() async {
    if (_isBusy || _isContinuousLocationRunning) {
      return;
    }
    setState(() => _isBusy = true);
    StreamSubscription<AmapLocationResult>? subscription;
    try {
      final AmapLocationClient? client = await _prepareClient();
      if (client == null) {
        return;
      }

      _continuousUpdateCount = 0;
      subscription = client.locations.listen((AmapLocationResult result) {
        _continuousUpdateCount += 1;
        _showResult(result, prefix: '持续定位 #$_continuousUpdateCount');
      }, onError: (Object error) => _showError(error, prefix: '持续定位错误'));
      _locationSubscription = subscription;
      if (mounted) {
        setState(() => _status = '持续定位已启动，等待位置更新…');
      }
      await client.start();
      if (!mounted) {
        await subscription.cancel();
        await client.stop();
        return;
      }
      setState(() {
        _isContinuousLocationRunning = true;
      });
    } on Object catch (error) {
      await subscription?.cancel();
      _locationSubscription = null;
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _stopContinuousLocation() async {
    if (_isBusy || !_isContinuousLocationRunning) {
      return;
    }
    setState(() => _isBusy = true);
    try {
      await _client?.stop();
      if (mounted) {
        setState(() => _status = '持续定位已停止');
      }
    } on Object catch (error) {
      _showError(error);
    } finally {
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      if (mounted) {
        setState(() {
          _isBusy = false;
          _isContinuousLocationRunning = false;
        });
      }
    }
  }

  Future<AmapLocationClient?> _prepareClient() async {
    final AmapLocationClient? existingClient = _client;
    if (existingClient != null) {
      return existingClient;
    }
    // 权限由调用方（应用）自行请求与校验；未授权时创建或启动定位会抛出
    // AmapLocationPermissionException，由下方错误处理统一展示。
    return _client ??= AmapLocationClient(
      options: const AmapLocationOptions(
        interval: Duration(seconds: 2),
        needAddress: false,
        accuracy: AmapLocationAccuracy.balanced,
        android: AmapLocationAndroidOptions(
          locationMode: AmapLocationAndroidMode.highAccuracy,
        ),
      ),
    );
  }

  void _showResult(AmapLocationResult result, {required String prefix}) {
    if (!mounted) {
      return;
    }
    final String? address = result.address?.formattedAddress;
    setState(() {
      _status = <String>[
        prefix,
        '纬度：${result.position.latitude}',
        '经度：${result.position.longitude}',
        '精度：${result.accuracyMeters.toStringAsFixed(1)} 米',
        '时间：${result.timestamp.toLocal()}',
        if (address != null && address.isNotEmpty) '地址：$address',
      ].join('\n');
    });
  }

  void _showError(Object error, {String prefix = '定位失败'}) {
    if (!mounted) {
      return;
    }
    setState(() => _status = '$prefix：$error');
  }

  Future<void> _disposeLocation() async {
    await _locationSubscription?.cancel();
    await _client?.dispose();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    unawaited(_disposeLocation());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AMap Location')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _apiKeyController,
                obscureText: !_isApiKeyVisible,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: '高德 API Key',
                  helperText: '请输入当前运行平台对应的 Key',
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _isApiKeyVisible = !_isApiKeyVisible),
                    tooltip: _isApiKeyVisible ? '隐藏 API Key' : '显示 API Key',
                    icon: Icon(
                      _isApiKeyVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                textInputAction: TextInputAction.done,
              ),
              FilledButton(
                onPressed: () async {
                  final String apiKey = _apiKeyController.text.trim();
                  await AmapLocation.setApiKey(apiKey);
                },
                child: const Text('设置 apikey'),
              ),
              const SizedBox(height: 24),
              Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  FilledButton(
                    onPressed: _isBusy ? null : _locate,
                    child: const Text('获取当前位置'),
                  ),
                  FilledButton.tonal(
                    onPressed: _isBusy || _isContinuousLocationRunning
                        ? null
                        : _startContinuousLocation,
                    child: const Text('开始持续定位'),
                  ),
                  OutlinedButton(
                    onPressed: _isBusy || !_isContinuousLocationRunning
                        ? null
                        : _stopContinuousLocation,
                    child: const Text('停止持续定位'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
