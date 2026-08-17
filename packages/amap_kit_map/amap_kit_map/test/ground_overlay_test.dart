import 'dart:async';

import 'package:amap_kit_map/amap_kit_map.dart';
import 'package:amap_kit_map_platform_interface/amap_kit_map_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  testWidgets('AmapMap submits initial and diff-updated ground overlays', (
    WidgetTester tester,
  ) async {
    final _GroundOverlayPlatform platform = _GroundOverlayPlatform();
    AmapMapsFlutterPlatform.instance = platform;
    final MapBitmap image = BytesMapBitmap(
      Uint8List.fromList(<int>[1, 2, 3]),
      bitmapScaling: MapBitmapScaling.none,
    );
    final GroundOverlay initial = GroundOverlay.fromBounds(
      groundOverlayId: const GroundOverlayId('floor'),
      image: image,
      bounds: LatLngBounds(
        southwest: const LatLng(30, 120),
        northeast: const LatLng(31, 121),
      ),
    );

    await tester.pumpWidget(_testApp(<GroundOverlay>{initial}));
    await tester.pump();

    expect(platform.initialGroundOverlays, <GroundOverlay>{initial});

    final GroundOverlay changed = initial.copyWith(
      transparencyParam: 0.5,
      visibleParam: false,
    );
    await tester.pumpWidget(_testApp(<GroundOverlay>{changed}));
    await tester.pump();

    expect(platform.updates, hasLength(1));
    expect(platform.updates.single.$1, 0);
    expect(platform.updates.single.$2.groundOverlaysToChange, <GroundOverlay>{
      changed,
    });

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(platform.disposedMapIds, <int>[0]);
  });
}

Widget _testApp(Set<GroundOverlay> overlays) {
  return MaterialApp(
    home: SizedBox(
      width: 300,
      height: 300,
      child: AmapMap(
        apiKey: 'test-key',
        mapId: 'test-map',
        privacyStatement: const AMapPrivacyStatement(
          hasContains: true,
          hasShow: true,
          hasAgree: true,
        ),
        initialCameraPosition: const CameraPosition(target: LatLng(30, 120)),
        groundOverlays: overlays,
      ),
    ),
  );
}

final class _GroundOverlayPlatform extends AmapMapsFlutterPlatform
    with MockPlatformInterfaceMixin {
  Set<GroundOverlay> initialGroundOverlays = <GroundOverlay>{};
  final List<(int, GroundOverlayUpdates)> updates =
      <(int, GroundOverlayUpdates)>[];
  final List<int> disposedMapIds = <int>[];
  final Set<int> _created = <int>{};

  @override
  Widget buildView(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    AmapMapConfiguration mapConfiguration = const AmapMapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) {
    initialGroundOverlays = mapObjects.groundOverlays;
    if (_created.add(creationId)) {
      scheduleMicrotask(() => onPlatformViewCreated(creationId));
    }
    return const SizedBox.expand();
  }

  @override
  Future<void> init(int mapId) async {}

  @override
  Future<void> updateGroundOverlays(
    GroundOverlayUpdates groundOverlayUpdates, {
    required int mapId,
  }) async {
    updates.add((mapId, groundOverlayUpdates));
  }

  @override
  Future<void> updateHeatmaps(
    HeatmapUpdates heatmapUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateTileOverlays({
    required Set<TileOverlay> newTileOverlays,
    required int mapId,
  }) async {}

  @override
  Stream<MarkerTapEvent> onMarkerTap({required int mapId}) =>
      const Stream<MarkerTapEvent>.empty();

  @override
  Stream<MyLocationChangedEvent> onLocationChanged({required int mapId}) =>
      const Stream<MyLocationChangedEvent>.empty();

  @override
  Stream<MarkerDragStartEvent> onMarkerDragStart({required int mapId}) =>
      const Stream<MarkerDragStartEvent>.empty();

  @override
  Stream<MarkerDragEvent> onMarkerDrag({required int mapId}) =>
      const Stream<MarkerDragEvent>.empty();

  @override
  Stream<MarkerDragEndEvent> onMarkerDragEnd({required int mapId}) =>
      const Stream<MarkerDragEndEvent>.empty();

  @override
  Stream<InfoWindowTapEvent> onInfoWindowTap({required int mapId}) =>
      const Stream<InfoWindowTapEvent>.empty();

  @override
  Stream<PolylineTapEvent> onPolylineTap({required int mapId}) =>
      const Stream<PolylineTapEvent>.empty();

  @override
  Stream<MapTapEvent> onTap({required int mapId}) =>
      const Stream<MapTapEvent>.empty();

  @override
  Stream<MapLongPressEvent> onLongPress({required int mapId}) =>
      const Stream<MapLongPressEvent>.empty();

  @override
  Stream<ClusterTapEvent> onClusterTap({required int mapId}) =>
      const Stream<ClusterTapEvent>.empty();

  @override
  void dispose({required int mapId}) {
    disposedMapIds.add(mapId);
  }
}
