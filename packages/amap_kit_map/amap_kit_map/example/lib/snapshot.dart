// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:typed_data';

import 'package:amap_kit_map/amap_kit_map.dart';
import 'package:flutter/material.dart';

import 'example_config.dart';
import 'page.dart';

const CameraPosition _kInitialPosition = CameraPosition(
  target: LatLng(22.5410, 114.0579),
  zoom: 11.0,
);

class SnapshotPage extends MapExampleAppPage {
  const SnapshotPage({super.key}) : super(const Icon(Icons.camera_alt), '地图截图');

  @override
  Widget build(BuildContext context) {
    return _SnapshotBody();
  }
}

class _SnapshotBody extends StatefulWidget {
  @override
  _SnapshotBodyState createState() => _SnapshotBodyState();
}

class _SnapshotBodyState extends State<_SnapshotBody> {
  AmapMapController? _mapController;
  Uint8List? _imageBytes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // 地图放大，占上半块区域。
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AmapMap(
              apiKey: exampleApiKey,
              privacyStatement: examplePrivacyStatement,
              mapId: exampleMapId,
              onMapCreated: onMapCreated,
              initialCameraPosition: _kInitialPosition,
            ),
          ),
        ),
        TextButton(
          child: const Text('截图'),
          onPressed: () async {
            final Uint8List? imageBytes = await _mapController?.takeSnapshot();
            setState(() {
              _imageBytes = imageBytes;
            });
          },
        ),
        // 截图预览，占下半块区域。
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(color: Colors.blueGrey[50]),
              child: _imageBytes != null ? Image.memory(_imageBytes!) : null,
            ),
          ),
        ),
      ],
    );
  }

  // ignore: use_setters_to_change_properties
  void onMapCreated(AmapMapController controller) {
    _mapController = controller;
  }
}
