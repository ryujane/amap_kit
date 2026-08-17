// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:amap_kit_map/amap_kit_map.dart';
import 'package:amap_kit_map_platform_interface/amap_kit_map_platform_interface.dart';
import 'package:flutter/material.dart';

import 'custom_marker_icon.dart';
import 'example_config.dart';
import 'page.dart';

class PlaceMarkerPage extends MapExampleAppPage {
  const PlaceMarkerPage({super.key}) : super(const Icon(Icons.place), '标记示例');

  @override
  Widget build(BuildContext context) {
    return const _PlaceMarkerBody();
  }
}

class _PlaceMarkerBody extends StatefulWidget {
  const _PlaceMarkerBody();

  @override
  State<StatefulWidget> createState() => _PlaceMarkerBodyState();
}

class _PlaceMarkerBodyState extends State<_PlaceMarkerBody> {
  _PlaceMarkerBodyState();
  static const LatLng center = LatLng(22.5431, 114.0579);

  AmapMapController? controller;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  MarkerId? selectedMarker;
  int _markerIdCounter = 1;
  LatLng? markerPosition;

  /// 选中标记时使用的绿色图钉图标；由 [custom_marker_icon.dart] 绘制。
  BitmapDescriptor _selectedMarkerIcon = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    super.initState();
    unawaited(_buildSelectedMarkerIcon());
  }

  Future<void> _buildSelectedMarkerIcon() async {
    final Uint8List bytes = await createCustomMarkerIconImage(
      size: const Size(48, 56),
      color: Colors.green,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedMarkerIcon = BitmapDescriptor.bytes(
        bytes,
        width: 48,
        height: 56,
      );
    });
  }

  // ignore: use_setters_to_change_properties
  void _onMapCreated(AmapMapController controller) {
    setState(() {
      this.controller = controller;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onMarkerTapped(MarkerId markerId) {
    final Marker? tappedMarker = markers[markerId];
    if (tappedMarker != null) {
      final bool isAlreadySelected = markerId == selectedMarker;
      setState(() {
        if (isAlreadySelected) {
          // 再次点击已选中的标记：关闭信息窗并恢复默认图标。
          selectedMarker = null;
          markers[markerId] = _copyWithSelectedState(tappedMarker, false);
        } else {
          final MarkerId? previousMarkerId = selectedMarker;
          if (previousMarkerId != null &&
              markers.containsKey(previousMarkerId)) {
            markers[previousMarkerId] = _copyWithSelectedState(
              markers[previousMarkerId]!,
              false,
            );
          }
          selectedMarker = markerId;
          markers[markerId] = _copyWithSelectedState(tappedMarker, true);
        }
        markerPosition = null;
      });
    }
  }

  void _onMarkerDrag(MarkerId markerId, LatLng newPosition) {
    setState(() {
      markerPosition = newPosition;
    });
  }

  void _onMarkerDragEnd(MarkerId markerId, LatLng newPosition) {
    final Marker? tappedMarker = markers[markerId];
    if (tappedMarker != null) {
      setState(() {
        markerPosition = null;
      });
      unawaited(
        showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              actions: <Widget>[
                TextButton(
                  child: const Text('确定'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
              content: Padding(
                padding: const EdgeInsets.symmetric(vertical: 66),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('旧位置：${tappedMarker.position}'),
                    Text('新位置：$newPosition'),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
  }

  void _add() {
    final int markerCount = markers.length;

    if (markerCount == 12) {
      return;
    }

    final markerIdVal = 'marker_id_$_markerIdCounter';
    _markerIdCounter++;
    final markerId = MarkerId(markerIdVal);

    final marker = Marker(
      markerId: markerId,
      position: LatLng(
        center.latitude + sin(_markerIdCounter * pi / 6.0) / 20.0,
        center.longitude + cos(_markerIdCounter * pi / 6.0) / 20.0,
      ),
      infoWindow: InfoWindow(title: markerIdVal, snippet: '*'),
      onTap: () => _onMarkerTapped(markerId),
      onDragEnd: (LatLng position) => _onMarkerDragEnd(markerId, position),
      onDrag: (LatLng position) => _onMarkerDrag(markerId, position),
    );

    setState(() {
      markers[markerId] = marker;
    });
  }

  void _remove(MarkerId markerId) {
    setState(() {
      if (markers.containsKey(markerId)) {
        markers.remove(markerId);
      }
      if (markerId == selectedMarker) {
        selectedMarker = null;
      }
    });
  }

  void _changePosition(MarkerId markerId) {
    final Marker marker = markers[markerId]!;
    final LatLng current = marker.position;
    final offset = Offset(
      center.latitude - current.latitude,
      center.longitude - current.longitude,
    );
    setState(() {
      markers[markerId] = _copyMarkerWith(
        marker,
        position: LatLng(
          center.latitude + offset.dy,
          center.longitude + offset.dx,
        ),
      );
    });
  }

  void _changeAnchor(MarkerId markerId) {
    final Marker marker = markers[markerId]!;
    final Offset currentAnchor = marker.anchor;
    final newAnchor = Offset(1.0 - currentAnchor.dy, currentAnchor.dx);
    setState(() {
      markers[markerId] = _copyMarkerWith(marker, anchor: newAnchor);
    });
  }

  void _changeInfoAnchor(MarkerId markerId) {
    final Marker marker = markers[markerId]!;
    final Offset currentAnchor = marker.infoWindow.anchor;
    final newAnchor = Offset(1.0 - currentAnchor.dy, currentAnchor.dx);
    setState(() {
      markers[markerId] = _copyMarkerWith(
        marker,
        infoWindow: marker.infoWindow.copyWith(anchorParam: newAnchor),
      );
    });
  }

  void _toggleDraggable(MarkerId markerId) {
    final Marker marker = markers[markerId]!;
    setState(() {
      markers[markerId] = _copyMarkerWith(marker, draggable: !marker.draggable);
    });
  }

  void _changeInfo(MarkerId markerId) {
    final Marker marker = markers[markerId]!;
    final newSnippet = '${marker.infoWindow.snippet!}*';
    setState(() {
      markers[markerId] = _copyMarkerWith(
        marker,
        infoWindow: marker.infoWindow.copyWith(snippetParam: newSnippet),
      );
    });
  }

  void _changeAlpha(MarkerId markerId) {
    final Marker marker = markers[markerId]!;
    final double current = marker.alpha;
    setState(() {
      markers[markerId] = _copyMarkerWith(
        marker,
        alpha: current < 0.1 ? 1.0 : current * 0.75,
      );
    });
  }

  void _changeRotation(MarkerId markerId) {
    final Marker marker = markers[markerId]!;
    final double current = marker.rotation;
    setState(() {
      markers[markerId] = _copyMarkerWith(
        marker,
        rotation: current == 330.0 ? 0.0 : current + 30.0,
      );
    });
  }

  void _toggleVisible(MarkerId markerId) {
    final Marker marker = markers[markerId]!;
    setState(() {
      markers[markerId] = _copyMarkerWith(marker, visible: !marker.visible);
    });
  }

  void _changeZIndex(MarkerId markerId) {
    final Marker marker = markers[markerId]!;
    final double current = marker.zIndex;
    setState(() {
      markers[markerId] = _copyMarkerWith(
        marker,
        zIndex: current == 12 ? 0 : current + 1,
      );
    });
  }

  void _setMarkerIcon(MarkerId markerId, BitmapDescriptor assetIcon) {
    final Marker? marker = markers[markerId];
    if (marker == null) {
      return;
    }
    setState(() {
      markers[markerId] = _copyMarkerWith(marker, icon: assetIcon);
    });
  }

  Future<BitmapDescriptor> _getMarkerIcon() async {
    const Size canvasSize = Size(48, 56);
    final Uint8List bytes = await createCustomMarkerIconImage(
      size: canvasSize,
      color: Colors.red,
    );
    return BitmapDescriptor.bytes(
      bytes,
      width: canvasSize.width,
      height: canvasSize.height,
    );
  }

  /// Returns selected or unselected state of the given [marker].
  Marker _copyWithSelectedState(Marker marker, bool isSelected) {
    return _copyMarkerWith(
      marker,
      icon: isSelected ? _selectedMarkerIcon : BitmapDescriptor.defaultMarker,
    );
  }

  /// 复制 [marker]，并替换需要变更的字段。
  ///
  /// amap_kit_map 的覆盖物模型没有 `copyWith`，变更字段时需要重建一个不可变的
  /// [Marker] 实例；回调字段直接透传，避免只替换回调却触发原生覆盖物更新。
  Marker _copyMarkerWith(
    Marker marker, {
    LatLng? position,
    bool? draggable,
    double? alpha,
    double? rotation,
    bool? visible,
    double? zIndex,
    BitmapDescriptor? icon,
    Offset? anchor,
    InfoWindow? infoWindow,
  }) {
    return Marker(
      markerId: marker.markerId,
      position: position ?? marker.position,
      title: marker.title,
      snippet: marker.snippet,
      draggable: draggable ?? marker.draggable,
      consumeTapEvents: marker.consumeTapEvents,
      alpha: alpha ?? marker.alpha,
      rotation: rotation ?? marker.rotation,
      visible: visible ?? marker.visible,
      zIndex: zIndex ?? marker.zIndex,
      infoWindow: infoWindow ?? marker.infoWindow,
      clusterManagerId: marker.clusterManagerId,
      icon: icon ?? marker.icon,
      anchor: anchor ?? marker.anchor,
      onTap: marker.onTap,
      onDragStart: marker.onDragStart,
      onDrag: marker.onDrag,
      onDragEnd: marker.onDragEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    final MarkerId? selectedId = selectedMarker;
    return Stack(
      children: <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: AmapMap(
                apiKey: exampleApiKey,
                privacyStatement: examplePrivacyStatement,
                mapId: exampleMapId,
                onMapCreated: _onMapCreated,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(22.5431, 114.0579),
                  zoom: 11.0,
                ),
                markers: Set<Marker>.of(markers.values),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                TextButton(onPressed: _add, child: const Text('添加')),
                TextButton(
                  onPressed: selectedId == null
                      ? null
                      : () => _remove(selectedId),
                  child: const Text('删除'),
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              children: <Widget>[
                TextButton(
                  onPressed: selectedId == null
                      ? null
                      : () => _changeInfo(selectedId),
                  child: const Text('修改信息窗'),
                ),
                TextButton(
                  onPressed: selectedId == null
                      ? null
                      : () => _changeInfoAnchor(selectedId),
                  child: const Text('修改信息窗锚点'),
                ),
                TextButton(
                  onPressed: selectedId == null
                      ? null
                      : () => _changeAlpha(selectedId),
                  child: const Text('修改透明度'),
                ),
                TextButton(
                  onPressed: selectedId == null
                      ? null
                      : () => _changeAnchor(selectedId),
                  child: const Text('修改锚点'),
                ),
                TextButton(
                  onPressed: selectedId == null
                      ? null
                      : () => _toggleDraggable(selectedId),
                  child: const Text('切换可拖动'),
                ),
                TextButton(
                  onPressed: selectedId == null
                      ? null
                      : () => _changePosition(selectedId),
                  child: const Text('修改位置'),
                ),
                TextButton(
                  onPressed: selectedId == null
                      ? null
                      : () => _changeRotation(selectedId),
                  child: const Text('修改旋转'),
                ),
                TextButton(
                  onPressed: selectedId == null
                      ? null
                      : () => _toggleVisible(selectedId),
                  child: const Text('切换可见'),
                ),
                TextButton(
                  onPressed: selectedId == null
                      ? null
                      : () => _changeZIndex(selectedId),
                  child: const Text('修改层级'),
                ),
                TextButton(
                  onPressed: selectedId == null
                      ? null
                      : () {
                          _getMarkerIcon().then((BitmapDescriptor icon) {
                            _setMarkerIcon(selectedId, icon);
                          });
                        },
                  child: const Text('设置图标'),
                ),
              ],
            ),
          ],
        ),
        Visibility(
          visible: markerPosition != null,
          child: Container(
            color: Colors.white70,
            height: 30,
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                if (markerPosition == null)
                  Container()
                else
                  Expanded(child: Text('纬度：${markerPosition!.latitude}')),
                if (markerPosition == null)
                  Container()
                else
                  Expanded(child: Text('经度：${markerPosition!.longitude}')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
