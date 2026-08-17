// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:amap_kit_map/amap_kit_map.dart';
import 'package:amap_kit_map_platform_interface/amap_kit_map_platform_interface.dart';
import 'package:flutter/material.dart';

import 'custom_marker_icon.dart';
import 'example_config.dart';
import 'page.dart';

/// Page for demonstrating marker clustering support.
class ClusteringPage extends MapExampleAppPage {
  /// Default Constructor.
  const ClusteringPage({super.key}) : super(const Icon(Icons.place), '聚合管理');

  @override
  Widget build(BuildContext context) {
    return const _ClusteringBody();
  }
}

/// Body of the clustering page.
class _ClusteringBody extends StatefulWidget {
  /// Default Constructor.
  const _ClusteringBody();

  @override
  State<StatefulWidget> createState() => _ClusteringBodyState();
}

/// State of the clustering page.
class _ClusteringBodyState extends State<_ClusteringBody> {
  /// Default Constructor.
  _ClusteringBodyState();

  /// Starting point from where markers are added.
  static const LatLng center = LatLng(22.5431, 114.0579);

  /// Initial camera position.
  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(22.5431, 114.0579),
    zoom: 11.0,
  );

  /// Marker offset factor for randomizing marker placing.
  static const double _markerOffsetFactor = 0.05;

  /// Offset for longitude when placing markers to different cluster managers.
  static const double _clusterManagerLongitudeOffset = 0.1;

  /// Maximum amount of cluster managers.
  static const int _clusterManagerMaxCount = 3;

  /// Amount of markers to be added to the cluster manager at once.
  static const int _markersToAddToClusterManagerCount = 10;

  /// Fully visible alpha value.
  static const double _fullyVisibleAlpha = 1.0;

  /// Half visible alpha value.
  static const double _halfVisibleAlpha = 0.5;

  /// 选中标记使用的绿色图钉图标；由 [custom_marker_icon.dart] 绘制。
  BitmapDescriptor _selectedMarkerIcon = BitmapDescriptor.defaultMarker;

  /// Map controller.
  AmapMapController? controller;

  /// Map of clusterManagers with identifier as the key.
  Map<ClusterManagerId, ClusterManager> clusterManagers =
      <ClusterManagerId, ClusterManager>{};

  /// Map of markers with identifier as the key.
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  /// Id of the currently selected marker.
  MarkerId? selectedMarker;

  /// Counter for added cluster manager ids.
  int _clusterManagerIdCounter = 1;

  /// Counter for added markers ids.
  int _markerIdCounter = 1;

  /// Cluster that was tapped most recently.
  Cluster? lastCluster;

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
    this.controller = controller;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onMarkerTapped(MarkerId markerId) {
    final Marker? tappedMarker = markers[markerId];
    if (tappedMarker != null) {
      setState(() {
        final MarkerId? previousMarkerId = selectedMarker;
        if (previousMarkerId != null && markers.containsKey(previousMarkerId)) {
          markers[previousMarkerId] = _copyWithSelectedState(
            markers[previousMarkerId]!,
            false,
          );
        }
        selectedMarker = markerId;
        markers[markerId] = _copyWithSelectedState(tappedMarker, true);
      });
    }
  }

  void _addClusterManager() {
    if (clusterManagers.length == _clusterManagerMaxCount) {
      return;
    }

    final clusterManagerIdVal = 'cluster_manager_id_$_clusterManagerIdCounter';
    _clusterManagerIdCounter++;
    final clusterManagerId = ClusterManagerId(clusterManagerIdVal);

    final clusterManager = ClusterManager(
      clusterManagerId: clusterManagerId,
      onClusterTap: (Cluster cluster) => setState(() {
        lastCluster = cluster;
      }),
    );

    setState(() {
      clusterManagers[clusterManagerId] = clusterManager;
    });
    _addMarkersToCluster(clusterManager);
  }

  void _removeClusterManager(ClusterManager clusterManager) {
    setState(() {
      // Remove markers managed by cluster manager to be removed.
      markers.removeWhere(
        (MarkerId key, Marker marker) =>
            marker.clusterManagerId == clusterManager.clusterManagerId,
      );
      // Remove cluster manager.
      clusterManagers.remove(clusterManager.clusterManagerId);
    });
  }

  void _addMarkersToCluster(ClusterManager clusterManager) {
    for (var i = 0; i < _markersToAddToClusterManagerCount; i++) {
      final markerIdVal =
          '${clusterManager.clusterManagerId.value}_marker_id_$_markerIdCounter';
      _markerIdCounter++;
      final markerId = MarkerId(markerIdVal);

      final int clusterManagerIndex = clusterManagers.values.toList().indexOf(
        clusterManager,
      );

      // Add additional offset to longitude for each cluster manager to space
      // out markers in different cluster managers.
      final double clusterManagerLongitudeOffset =
          clusterManagerIndex * _clusterManagerLongitudeOffset;

      final marker = Marker(
        markerId: markerId,
        clusterManagerId: clusterManager.clusterManagerId,
        position: LatLng(
          center.latitude + _getRandomOffset(),
          center.longitude + _getRandomOffset() + clusterManagerLongitudeOffset,
        ),
        infoWindow: InfoWindow(title: markerIdVal, snippet: '*'),
        onTap: () => _onMarkerTapped(markerId),
      );
      markers[markerId] = marker;
    }
    setState(() {});
  }

  double _getRandomOffset() {
    return (Random().nextDouble() - 0.5) * _markerOffsetFactor;
  }

  void _remove(MarkerId markerId) {
    setState(() {
      if (markers.containsKey(markerId)) {
        markers.remove(markerId);
      }
    });
  }

  void _changeMarkersAlpha() {
    for (final MarkerId markerId in markers.keys) {
      final Marker marker = markers[markerId]!;
      final double current = marker.alpha;
      markers[markerId] = _copyMarkerWith(
        marker,
        alpha: current == _fullyVisibleAlpha
            ? _halfVisibleAlpha
            : _fullyVisibleAlpha,
      );
    }
    setState(() {});
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
  /// [Marker] 实例；回调字段直接透传。
  Marker _copyMarkerWith(
    Marker marker, {
    double? alpha,
    BitmapDescriptor? icon,
  }) {
    return Marker(
      markerId: marker.markerId,
      position: marker.position,
      title: marker.title,
      snippet: marker.snippet,
      draggable: marker.draggable,
      consumeTapEvents: marker.consumeTapEvents,
      alpha: alpha ?? marker.alpha,
      rotation: marker.rotation,
      visible: marker.visible,
      zIndex: marker.zIndex,
      infoWindow: marker.infoWindow,
      clusterManagerId: marker.clusterManagerId,
      icon: icon ?? marker.icon,
      anchor: marker.anchor,
      onTap: marker.onTap,
      onDragStart: marker.onDragStart,
      onDrag: marker.onDrag,
      onDragEnd: marker.onDragEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    final MarkerId? selectedId = selectedMarker;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: AmapMap(
            apiKey: exampleApiKey,
            privacyStatement: examplePrivacyStatement,
            mapId: exampleMapId,
            onMapCreated: _onMapCreated,
            initialCameraPosition: initialCameraPosition,
            markers: Set<Marker>.of(markers.values),
            clusterManagers: Set<ClusterManager>.of(clusterManagers.values),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            TextButton(
              onPressed: clusterManagers.length >= _clusterManagerMaxCount
                  ? null
                  : () => _addClusterManager(),
              child: const Text('添加聚合管理器'),
            ),
            TextButton(
              onPressed: clusterManagers.isEmpty
                  ? null
                  : () => _removeClusterManager(clusterManagers.values.last),
              child: const Text('删除聚合管理器'),
            ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          children: <Widget>[
            for (final MapEntry<ClusterManagerId, ClusterManager> clusterEntry
                in clusterManagers.entries)
              TextButton(
                onPressed: () => _addMarkersToCluster(clusterEntry.value),
                child: Text('向 ${clusterEntry.key.value} 添加标记'),
              ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          children: <Widget>[
            TextButton(
              onPressed: selectedId == null
                  ? null
                  : () {
                      _remove(selectedId);
                      setState(() {
                        selectedMarker = null;
                      });
                    },
              child: const Text('删除选中标记'),
            ),
            TextButton(
              onPressed: markers.isEmpty ? null : () => _changeMarkersAlpha(),
              child: const Text('修改全部标记透明度'),
            ),
          ],
        ),
        if (lastCluster != null)
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              '点击的聚合点包含 ${lastCluster!.count} 个标记，位置：${lastCluster!.position}',
            ),
          ),
      ],
    );
  }
}
