// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:amap_kit_map/amap_kit_map.dart';
import 'package:amap_kit_map_platform_interface/amap_kit_map_platform_interface.dart';
import 'package:flutter/material.dart';

import 'example_config.dart';
import 'page.dart';

class MoveCameraPage extends MapExampleAppPage {
  const MoveCameraPage({super.key}) : super(const Icon(Icons.map), '相机控制');

  @override
  Widget build(BuildContext context) {
    return const MoveCamera();
  }
}

class MoveCamera extends StatefulWidget {
  const MoveCamera({super.key});
  @override
  State createState() => MoveCameraState();
}

class MoveCameraState extends State<MoveCamera> {
  AmapMapController? mapController;

  // ignore: use_setters_to_change_properties
  void _onMapCreated(AmapMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // 地图占页面大块区域。
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AmapMap(
              apiKey: exampleApiKey,
              privacyStatement: examplePrivacyStatement,
              mapId: exampleMapId,
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(22.5431, 114.0579),
              ),
            ),
          ),
        ),
        // 操作按钮用 Wrap 整齐排布，超宽自动换行，不再横向滚动。
        Flexible(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: <Widget>[
                TextButton(
                  onPressed: () async {
                    await mapController?.moveCamera(
                      CameraUpdate.newCameraPosition(
                        const CameraPosition(
                          bearing: 270.0,
                          target: LatLng(22.5431, 114.0579),
                          tilt: 30.0,
                          zoom: 17.0,
                        ),
                      ),
                    );
                  },
                  child: const Text('新相机位置'),
                ),
                TextButton(
                  onPressed: () async {
                    await mapController?.moveCamera(
                      CameraUpdate.newLatLng(const LatLng(22.5187, 113.9503)),
                    );
                  },
                  child: const Text('新经纬度'),
                ),
                TextButton(
                  onPressed: () async {
                    await mapController?.moveCamera(
                      CameraUpdate.newLatLngBounds(
                        LatLngBounds(
                          southwest: const LatLng(22.400, 113.730),
                          northeast: const LatLng(22.870, 114.620),
                        ),
                        padding: 10.0,
                      ),
                    );
                  },
                  child: const Text('缩放到边界'),
                ),
                TextButton(
                  onPressed: () async {
                    await mapController?.moveCamera(
                      CameraUpdateNewLatLngZoom(
                        const LatLng(22.5926, 114.3127),
                        11.0,
                      ),
                    );
                  },
                  child: const Text('经纬度+缩放'),
                ),
                TextButton(
                  onPressed: () async {
                    await mapController?.moveCamera(
                      CameraUpdateScrollBy(150.0, -225.0),
                    );
                  },
                  child: const Text('平移'),
                ),
                TextButton(
                  onPressed: () async {
                    await mapController?.moveCamera(
                      CameraUpdateZoomBy(-0.5, const Offset(30.0, 20.0)),
                    );
                  },
                  child: const Text('聚焦缩放'),
                ),
                TextButton(
                  onPressed: () async {
                    await mapController?.moveCamera(CameraUpdate.zoomBy(-0.5));
                  },
                  child: const Text('相对缩放'),
                ),
                TextButton(
                  onPressed: () async {
                    await mapController?.moveCamera(CameraUpdate.zoomIn());
                  },
                  child: const Text('放大'),
                ),
                TextButton(
                  onPressed: () async {
                    await mapController?.moveCamera(CameraUpdate.zoomOut());
                  },
                  child: const Text('缩小'),
                ),
                TextButton(
                  onPressed: () async {
                    await mapController?.moveCamera(CameraUpdateZoomTo(16.0));
                  },
                  child: const Text('缩放到级别'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
