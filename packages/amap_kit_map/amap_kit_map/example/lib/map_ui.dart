// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:amap_kit_map/amap_kit_map.dart';
import 'package:amap_kit_map_platform_interface/amap_kit_map_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'example_config.dart';
import 'page.dart';

/// 深圳市行政区域，用于演示相机缩放到指定区域。
final LatLngBounds shenzhenBounds = LatLngBounds(
  southwest: const LatLng(22.400, 113.730),
  northeast: const LatLng(22.870, 114.620),
);

class MapUiPage extends MapExampleAppPage {
  const MapUiPage({super.key}) : super(const Icon(Icons.map), '用户界面');

  @override
  Widget build(BuildContext context) {
    return const MapUiBody();
  }
}

class MapUiBody extends StatefulWidget {
  const MapUiBody({super.key});

  @override
  State<MapUiBody> createState() => MapUiBodyState();
}

class MapUiBodyState extends State<MapUiBody> {
  MapUiBodyState();

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(22.54, 114.06),
    zoom: 11.0,
  );

  CameraPosition _position = _kInitialPosition;
  bool _isMapCreated = false;
  bool _isMoving = false;
  bool _compassEnabled = true;
  bool _scaleControlsEnabled = true;
  bool _buildingsEnabled = true;
  MapType _mapType = MapType.normal;
  bool _rotateGesturesEnabled = true;
  bool _scrollGesturesEnabled = true;
  bool _tiltGesturesEnabled = true;
  bool _zoomGesturesEnabled = true;

  /// 显示高德原生定位蓝点；启用前必须先获得前台定位权限，否则平台返回
  /// [AmapMapLocationPermissionException]。
  bool _myLocationEnabled = false;
  bool _myTrafficEnabled = false;
  bool _fitsShenzhen = false;

  /// 定位蓝点开启后，最近一次上报的设备位置；关闭蓝点或未收到更新时为空。
  AmapMyLocation? _myLocation;

  /// 最近一次查询到的定位权限状态，显示在界面上便于诊断。
  PermissionStatus? _locationPermissionStatus;

  /// 请求定位权限时抛出的异常；正常为空，出现时显示在界面上。
  Object? _locationPermissionError;
  AmapMapException? _mapError;
  late AmapMapController _controller;

  @override
  void initState() {
    super.initState();
    // 进入页面即查询并请求前台定位权限，授权后自动显示定位蓝点。
    _refreshLocationPermission();
  }

  /// 查询当前定位权限状态并显示；未授权时自动请求一次，再刷新显示最终状态。
  Future<void> _refreshLocationPermission() async {
    PermissionStatus current;
    try {
      current = await Permission.locationWhenInUse.status;
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _locationPermissionError = e;
      });
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _locationPermissionStatus = current;
    });
    if (!current.isGranted) {
      await _requestLocationPermission(silent: true);
    }
    PermissionStatus after;
    try {
      after = await Permission.locationWhenInUse.status;
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _locationPermissionError = e;
      });
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _locationPermissionStatus = after;
    });
  }

  /// 请求前台定位权限；授权后开启定位蓝点。
  ///
  /// [silent] 为 true（进入页面自动请求）时，拒绝仅保持蓝点关闭，不打断
  /// 用户；可点击"开启定位蓝点"按钮重试并看到具体原因与去设置入口。
  Future<void> _requestLocationPermission({bool silent = false}) async {
    PermissionStatus status;
    try {
      status = await Permission.locationWhenInUse.request();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _locationPermissionError = e;
      });
      return;
    }
    if (!mounted) {
      return;
    }
    if (status.isGranted) {
      setState(() {
        _myLocationEnabled = true;
      });
      return;
    }
    if (silent) {
      return;
    }
    // iOS 上请求被拒后系统不再弹框，必须由用户去系统设置开启；
    // Android 上永久拒绝后同样只能去设置。这里按状态给出可操作提示。
    final String reason = switch (status) {
      PermissionStatus.permanentlyDenied => '定位权限已被永久拒绝，请在系统设置中开启后重试。',
      PermissionStatus.restricted => '定位权限被系统限制（如家长控制），无法显示定位蓝点。',
      PermissionStatus.denied => '未获得定位权限，无法显示定位蓝点。',
      _ => '无法获取定位权限（$status）。',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reason),
        action: SnackBarAction(
          label: '去设置',
          onPressed: () {
            openAppSettings();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _compassToggler() {
    return TextButton(
      child: Text('${_compassEnabled ? '关闭' : '开启'}指南针'),
      onPressed: () {
        setState(() {
          _compassEnabled = !_compassEnabled;
        });
      },
    );
  }

  Widget _scaleControlsToggler() {
    return TextButton(
      child: Text('${_scaleControlsEnabled ? '关闭' : '开启'}比例尺'),
      onPressed: () {
        setState(() {
          _scaleControlsEnabled = !_scaleControlsEnabled;
        });
      },
    );
  }

  Widget _buildingsToggler() {
    return TextButton(
      child: Text('${_buildingsEnabled ? '关闭' : '开启'}建筑物'),
      onPressed: () {
        setState(() {
          _buildingsEnabled = !_buildingsEnabled;
        });
      },
    );
  }

  Widget _mapTypeCycler() {
    final MapType nextType =
        MapType.values[(_mapType.index + 1) % MapType.values.length];
    return TextButton(
      child: Text('切换底图类型：$nextType'),
      onPressed: () {
        setState(() {
          _mapType = nextType;
        });
      },
    );
  }

  Widget _rotateToggler() {
    return TextButton(
      child: Text('${_rotateGesturesEnabled ? '关闭' : '开启'}旋转手势'),
      onPressed: () {
        setState(() {
          _rotateGesturesEnabled = !_rotateGesturesEnabled;
        });
      },
    );
  }

  Widget _scrollToggler() {
    return TextButton(
      child: Text('${_scrollGesturesEnabled ? '关闭' : '开启'}平移手势'),
      onPressed: () {
        setState(() {
          _scrollGesturesEnabled = !_scrollGesturesEnabled;
        });
      },
    );
  }

  Widget _tiltToggler() {
    return TextButton(
      child: Text('${_tiltGesturesEnabled ? '关闭' : '开启'}倾斜手势'),
      onPressed: () {
        setState(() {
          _tiltGesturesEnabled = !_tiltGesturesEnabled;
        });
      },
    );
  }

  Widget _zoomToggler() {
    return TextButton(
      child: Text('${_zoomGesturesEnabled ? '关闭' : '开启'}缩放手势'),
      onPressed: () {
        setState(() {
          _zoomGesturesEnabled = !_zoomGesturesEnabled;
        });
      },
    );
  }

  Widget _myLocationToggler() {
    return TextButton(
      child: Text('${_myLocationEnabled ? '关闭' : '开启'}定位蓝点'),
      onPressed: () async {
        if (_myLocationEnabled) {
          setState(() {
            _myLocationEnabled = false;
            _myLocation = null;
          });
          return;
        }
        // 重新请求前台定位权限；被拒时提示原因并提供去设置入口。
        await _requestLocationPermission();
      },
    );
  }

  Widget _myTrafficToggler() {
    return TextButton(
      child: Text('${_myTrafficEnabled ? '关闭' : '开启'}实时路况'),
      onPressed: () {
        setState(() {
          _myTrafficEnabled = !_myTrafficEnabled;
        });
      },
    );
  }

  /// 在“缩放到深圳区域”与“回退到初始视野”之间切换。
  Widget _shenzhenBoundsToggler() {
    return TextButton(
      child: Text(_fitsShenzhen ? '回到初始视野' : '缩放到深圳区域'),
      onPressed: () async {
        _fitsShenzhen = !_fitsShenzhen;
        setState(() {});
        final CameraUpdate update = _fitsShenzhen
            ? CameraUpdate.newLatLngBounds(shenzhenBounds, padding: 32)
            : CameraUpdate.newCameraPosition(_kInitialPosition);
        await _controller.moveCamera(update);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final amapMap = AmapMap(
      apiKey: exampleApiKey,
      privacyStatement: examplePrivacyStatement,
      mapId: exampleMapId,
      onMapCreated: onMapCreated,
      initialCameraPosition: _kInitialPosition,
      compassEnabled: _compassEnabled,
      scaleControlsEnabled: _scaleControlsEnabled,
      buildingsEnabled: _buildingsEnabled,
      mapType: _mapType,
      rotateGesturesEnabled: _rotateGesturesEnabled,
      scrollGesturesEnabled: _scrollGesturesEnabled,
      tiltGesturesEnabled: _tiltGesturesEnabled,
      zoomGesturesEnabled: _zoomGesturesEnabled,
      myLocationEnabled: _myLocationEnabled,
      onLocationChanged: _onMyLocationChanged,
      trafficEnabled: _myTrafficEnabled,
      onCameraMoveStarted: _onCameraMoveStarted,
      onCameraMove: _updateCameraPosition,
      onCameraMoveEnd: _onCameraMoveEnd,
      onError: _onMapError,
    );

    final columnChildren = <Widget>[
      // 地图预览放大到全宽并占更高区域。
      Padding(
        padding: const EdgeInsets.all(10.0),
        child: SizedBox(width: double.infinity, height: 280, child: amapMap),
      ),
    ];

    if (_isMapCreated) {
      columnChildren.add(
        Expanded(
          child: ListView(
            children: <Widget>[
              if (_mapError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '地图错误：$_mapError',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Text('相机朝向：${_position.bearing}'),
              Text(
                '相机目标：${_position.target.latitude.toStringAsFixed(4)},'
                '${_position.target.longitude.toStringAsFixed(4)}',
              ),
              Text('缩放等级：${_position.zoom}'),
              Text('倾斜角度：${_position.tilt}'),
              Text(_isMoving ? '（相机移动中）' : '（相机静止）'),
              _compassToggler(),
              _scaleControlsToggler(),
              _buildingsToggler(),
              _mapTypeCycler(),
              _rotateToggler(),
              _scrollToggler(),
              _tiltToggler(),
              _zoomToggler(),
              _myLocationToggler(),
              Text('定位权限：${_locationPermissionStatus ?? '查询中…'}'),
              if (_locationPermissionError != null)
                Text(
                  '权限请求异常：$_locationPermissionError',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              if (_myLocation != null)
                Text(
                  '最近定位：${_myLocation!.position.latitude.toStringAsFixed(6)},'
                  '${_myLocation!.position.longitude.toStringAsFixed(6)}'
                  '${_myLocation!.accuracyMeters != null ? '，精度 ${_myLocation!.accuracyMeters!.toStringAsFixed(1)} 米' : ''}',
                ),
              _myTrafficToggler(),
              _shenzhenBoundsToggler(),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: columnChildren,
    );
  }

  void _onCameraMoveStarted() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isMoving = true;
    });
  }

  void _onCameraMoveEnd(CameraPosition position) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isMoving = false;
    });
  }

  void _updateCameraPosition(CameraPosition position) {
    if (!mounted) {
      return;
    }
    setState(() {
      _position = position;
    });
  }

  void _onMyLocationChanged(AmapMyLocation location) {
    if (!mounted) {
      return;
    }
    setState(() {
      _myLocation = location;
    });
  }

  void _onMapError(AmapMapException error) {
    if (!mounted) {
      return;
    }
    setState(() {
      _mapError = error;
    });
  }

  void onMapCreated(AmapMapController controller) {
    setState(() {
      _controller = controller;
      _isMapCreated = true;
    });
  }
}
