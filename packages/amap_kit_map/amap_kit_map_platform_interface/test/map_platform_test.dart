import 'dart:typed_data';

import 'package:amap_kit_map_platform_interface/amap_kit_map_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  group('CameraUpdate.updateType', () {
    test('每个具体子类都报告正确的类型', () {
      expect(
        CameraUpdate.newCameraPosition(
          const CameraPosition(target: LatLng(22.5, 114.0)),
        ).updateType,
        CameraUpdateType.newCameraPosition,
      );
      expect(
        CameraUpdate.newLatLng(const LatLng(22.5, 114.0)).updateType,
        CameraUpdateType.newLatLng,
      );
      expect(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: const LatLng(22.4, 113.7),
            northeast: const LatLng(22.9, 114.6),
          ),
        ).updateType,
        CameraUpdateType.newLatLngBounds,
      );
      expect(
        const CameraUpdateNewLatLngZoom(LatLng(22.5, 114.0), 11).updateType,
        CameraUpdateType.newLatLngZoom,
      );
      expect(
        const CameraUpdateScrollBy(10, 20).updateType,
        CameraUpdateType.scrollBy,
      );
      expect(CameraUpdate.zoomBy(1).updateType, CameraUpdateType.zoomBy);
      expect(const CameraUpdateZoomTo(16).updateType, CameraUpdateType.zoomTo);
      expect(CameraUpdate.zoomIn().updateType, CameraUpdateType.zoomIn);
      expect(CameraUpdate.zoomOut().updateType, CameraUpdateType.zoomOut);
    });
  });

  test('允许带 MockPlatformInterfaceMixin 的平台替身', () {
    final _MockMapPlatform platform = _MockMapPlatform();
    AmapMapsFlutterPlatform.instance = platform;
    expect(AmapMapsFlutterPlatform.instance, same(platform));
  });

  test('默认实现明确报告未实现', () {
    final _MinimalMapPlatform platform = _MinimalMapPlatform();
    // 基类默认方法未被平台实现覆盖时，命令方法同步抛 UnimplementedError。
    expect(() => platform.init(1), throwsA(isA<UnimplementedError>()));
    expect(() => platform.onTap(mapId: 1), throwsA(isA<UnimplementedError>()));
    expect(
      () => platform.onClusterTap(mapId: 1),
      throwsA(isA<UnimplementedError>()),
    );
    expect(
      () => platform.updateMultiPointOverlays(
        MultiPointOverlayUpdates(),
        mapId: 1,
      ),
      throwsA(isA<UnimplementedError>()),
    );
    expect(
      () => platform.updateHeatmaps(
        HeatmapUpdates.from(<Heatmap>{}, <Heatmap>{}),
        mapId: 1,
      ),
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => platform.clearTileCache(const TileOverlayId('tiles'), mapId: 1),
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => platform.updateGroundOverlays(
        GroundOverlayUpdates.from(<GroundOverlay>{}, <GroundOverlay>{}),
        mapId: 1,
      ),
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => platform.onMarkerTap(mapId: 1),
      throwsA(isA<UnimplementedError>()),
    );
    expect(
      () => platform.onMarkerDragStart(mapId: 1),
      throwsA(isA<UnimplementedError>()),
    );
    expect(
      () => platform.onMarkerDrag(mapId: 1),
      throwsA(isA<UnimplementedError>()),
    );
    expect(
      () => platform.onMarkerDragEnd(mapId: 1),
      throwsA(isA<UnimplementedError>()),
    );
    expect(
      () => platform.onPolylineTap(mapId: 1),
      throwsA(isA<UnimplementedError>()),
    );
    expect(
      () => platform.onLocationChanged(mapId: 1),
      throwsA(isA<UnimplementedError>()),
    );
    // onMultiPointTap 返回 Stream.error，以流错误形式上报未实现。
    expect(
      platform.onMultiPointTap(mapId: 1),
      emitsError(isA<UnimplementedError>()),
    );
  });

  test('覆盖物 ID 按值相等', () {
    expect(const MarkerId('home'), equals(const MarkerId('home')));
    expect(const PolylineId('route'), isNot(equals(const PolylineId('other'))));
    expect(const MarkerId('same'), isNot(equals(const CircleId('same'))));
  });

  test('AmapMyLocation 是不可变值模型', () {
    const AmapMyLocation location = AmapMyLocation(
      position: LatLng(22.5, 114.0),
      accuracyMeters: 12.0,
      timestamp: null,
    );
    expect(
      location,
      equals(
        const AmapMyLocation(
          position: LatLng(22.5, 114.0),
          accuracyMeters: 12.0,
        ),
      ),
    );
    expect(
      location,
      isNot(
        equals(
          const AmapMyLocation(
            position: LatLng(22.6, 114.0),
            accuracyMeters: 12.0,
          ),
        ),
      ),
    );
    expect(location.accuracyMeters, 12.0);
  });

  test('Heatmap 提供兼容 google_maps_flutter 的不可变值模型和差分', () {
    final List<WeightedLatLng> source = <WeightedLatLng>[
      const WeightedLatLng(LatLng(30, 120), weight: 2),
    ];
    final Heatmap heatmap = Heatmap(
      heatmapId: const HeatmapId('density'),
      data: source,
      gradient: HeatmapGradient(const <HeatmapGradientColor>[
        HeatmapGradientColor(Colors.blue, 0),
        HeatmapGradientColor(Colors.red, 1),
      ]),
    );
    source.add(const WeightedLatLng(LatLng(31, 121)));

    expect(heatmap.data, hasLength(1));
    expect(
      () => heatmap.data.add(const WeightedLatLng(LatLng(32, 122))),
      throwsUnsupportedError,
    );
    expect(heatmap.clone(), equals(heatmap));
    expect(heatmap.toJson(), containsPair('heatmapId', 'density'));

    final Heatmap changed = heatmap.copyWith(opacityParam: 0.8);
    final HeatmapUpdates updates = HeatmapUpdates.from(
      <Heatmap>{heatmap},
      <Heatmap>{changed},
    );
    expect(updates.heatmapsToChange, <Heatmap>{changed});
  });

  test('Heatmap 省略 gradient 时序列化为 null，由平台使用默认渐变', () {
    final Heatmap heatmap = Heatmap(
      heatmapId: const HeatmapId('density'),
      data: const <WeightedLatLng>[WeightedLatLng(LatLng(30, 120), weight: 2)],
    );

    expect(heatmap.gradient, isNull);
    expect(heatmap.toJson(), isNot(contains('gradient')));
    expect(
      () => heatmap.toJson(),
      returnsNormally,
      reason: 'gradient 为空必须可正常序列化并交平台兜底',
    );
  });

  test('TileOverlay 按 provider 实例和配置生成差分', () {
    final _TestTileProvider provider = _TestTileProvider();
    final TileOverlay overlay = TileOverlay(
      tileOverlayId: const TileOverlayId('custom'),
      tileProvider: provider,
    );

    expect(overlay.tileSize, 256);
    expect(overlay.visible, isTrue);
    expect(overlay.clone(), equals(overlay));
    expect(overlay.toJson(), containsPair('tileOverlayId', 'custom'));
    expect(TileProvider.noTile.data, isNull);
    expect(TileProvider.noTile.width, -1);

    final TileOverlay changed = overlay.copyWith(zIndexParam: 2);
    final TileOverlayUpdates configurationUpdates = TileOverlayUpdates.from(
      <TileOverlay>{overlay},
      <TileOverlay>{changed},
    );
    expect(configurationUpdates.tileOverlaysToChange, <TileOverlay>{changed});

    final TileOverlay providerChanged = overlay.copyWith(
      tileProviderParam: _TestTileProvider(),
    );
    final TileOverlayUpdates providerUpdates = TileOverlayUpdates.from(
      <TileOverlay>{overlay},
      <TileOverlay>{providerChanged},
    );
    expect(providerUpdates.tileOverlaysToChange, <TileOverlay>{
      providerChanged,
    });
  });

  test('覆盖物实现 MapsObject 的标识、复制和 JSON 契约', () {
    final Marker marker = Marker(
      markerId: const MarkerId('home'),
      position: const LatLng(30, 120),
      title: 'Home',
      visible: false,
      zIndex: 2,
    );

    expect(marker, isA<MapsObject<Marker>>());
    expect(marker.mapsId, equals(marker.markerId));
    expect(marker.clone(), equals(marker));
    expect(marker.toJson(), containsPair('markerId', 'home'));
    expect(marker.toJson(), containsPair('visible', false));
  });

  test('BitmapDescriptor 提供 default、asset 和 bytes 值语义', () {
    expect(BitmapDescriptor.defaultMarker, equals(const DefaultMarker()));
    expect(
      const AssetMapBitmap(
        'assets/pin.png',
        imagePixelRatio: 2,
        width: 24,
        bitmapScaling: MapBitmapScaling.auto,
      ).toJson(),
      equals(<Object>[
        'asset',
        <String, Object?>{
          'assetName': 'assets/pin.png',
          'bitmapScaling': 'auto',
          'imagePixelRatio': 2.0,
          'width': 24.0,
        },
      ]),
    );

    final Uint8List source = Uint8List.fromList(<int>[1, 2, 3]);
    final BytesMapBitmap descriptor = BytesMapBitmap(
      source,
      imagePixelRatio: 3,
      bitmapScaling: MapBitmapScaling.none,
    );
    source[0] = 9;

    expect(descriptor.byteData, orderedEquals(<int>[1, 2, 3]));
    expect(() => descriptor.byteData[0] = 9, throwsUnsupportedError);
    expect(
      descriptor,
      equals(
        BytesMapBitmap(
          Uint8List.fromList(<int>[1, 2, 3]),
          imagePixelRatio: 3,
          bitmapScaling: MapBitmapScaling.none,
        ),
      ),
    );
  });

  test('GroundOverlay 提供强类型图片、两种定位方式和差分', () {
    final MapBitmap image = BytesMapBitmap(
      Uint8List.fromList(<int>[1, 2, 3]),
      bitmapScaling: MapBitmapScaling.none,
    );
    final GroundOverlay boundsOverlay = GroundOverlay.fromBounds(
      groundOverlayId: const GroundOverlayId('floor-plan'),
      image: image,
      bounds: LatLngBounds(
        southwest: const LatLng(30, 120),
        northeast: const LatLng(31, 121),
      ),
    );
    final GroundOverlay positionOverlay = GroundOverlay.fromPosition(
      groundOverlayId: const GroundOverlayId('positioned'),
      image: image,
      position: const LatLng(30.5, 120.5),
      width: 100,
      height: 80,
      bearing: 45,
    );

    expect(boundsOverlay, isA<MapsObject<GroundOverlay>>());
    expect(boundsOverlay.clone(), equals(boundsOverlay));
    expect(
      boundsOverlay.toJson(),
      containsPair('groundOverlayId', 'floor-plan'),
    );
    expect(positionOverlay.width, 100);
    expect(positionOverlay.height, 80);

    final GroundOverlay changed = boundsOverlay.copyWith(
      transparencyParam: 0.5,
      visibleParam: false,
    );
    final GroundOverlayUpdates updates = GroundOverlayUpdates.from(
      <GroundOverlay>{boundsOverlay, positionOverlay},
      <GroundOverlay>{changed},
    );
    expect(updates.groundOverlaysToChange, <GroundOverlay>{changed});
    expect(updates.groundOverlayIdsToRemove, <GroundOverlayId>{
      const GroundOverlayId('positioned'),
    });
  });

  test('GroundOverlay 拒绝自动缩放图片和越界显示参数', () {
    final MapBitmap autoImage = BytesMapBitmap(Uint8List.fromList(<int>[1]));
    final MapBitmap image = BytesMapBitmap(
      Uint8List.fromList(<int>[1]),
      bitmapScaling: MapBitmapScaling.none,
    );
    final LatLngBounds bounds = LatLngBounds(
      southwest: const LatLng(30, 120),
      northeast: const LatLng(31, 121),
    );

    expect(
      () => GroundOverlay.fromBounds(
        groundOverlayId: const GroundOverlayId('auto'),
        image: autoImage,
        bounds: bounds,
      ),
      throwsAssertionError,
    );
    expect(
      () => GroundOverlay.fromPosition(
        groundOverlayId: const GroundOverlayId('width'),
        image: image,
        position: const LatLng(30, 120),
        width: 0,
      ),
      throwsAssertionError,
    );
    expect(
      () => GroundOverlay.fromBounds(
        groundOverlayId: const GroundOverlayId('transparency'),
        image: image,
        bounds: bounds,
        transparency: 1.1,
      ),
      throwsAssertionError,
    );
  });

  test('AmapMyLocationStyle 保留蓝点样式值语义', () {
    const AmapMyLocationStyle style = AmapMyLocationStyle(
      icon: DefaultMarker(),
      anchorU: 0.5,
      anchorV: 1,
      accuracyFillColor: 0x332196f3,
      accuracyStrokeColor: 0xff1565c0,
      accuracyStrokeWidth: 2,
      myLocationType: AmapMyLocationType.locationRotateNoCenter,
      interval: 2000,
      showMyLocation: true,
      zIndex: 5,
      showsAccuracyRing: true,
      showsHeadingIndicator: false,
      enablePulseAnimation: false,
      dotBackgroundColor: 0xffffffff,
      dotFillColor: 0xff1565c0,
    );

    expect(
      style,
      equals(
        const AmapMyLocationStyle(
          icon: DefaultMarker(),
          anchorU: 0.5,
          anchorV: 1,
          accuracyFillColor: 0x332196f3,
          accuracyStrokeColor: 0xff1565c0,
          accuracyStrokeWidth: 2,
          myLocationType: AmapMyLocationType.locationRotateNoCenter,
          interval: 2000,
          showMyLocation: true,
          zIndex: 5,
          showsAccuracyRing: true,
          showsHeadingIndicator: false,
          enablePulseAnimation: false,
          dotBackgroundColor: 0xffffffff,
          dotFillColor: 0xff1565c0,
        ),
      ),
    );
  });

  test('AmapMyLocationType 覆盖全部定位模式', () {
    expect(AmapMyLocationType.values, const <AmapMyLocationType>[
      AmapMyLocationType.show,
      AmapMyLocationType.locate,
      AmapMyLocationType.follow,
      AmapMyLocationType.mapRotate,
      AmapMyLocationType.locationRotate,
      AmapMyLocationType.locationRotateNoCenter,
      AmapMyLocationType.followNoCenter,
      AmapMyLocationType.mapRotateNoCenter,
    ]);
  });

  test('AmapMyLocationStyle 拒绝越界锚点与负刷新间隔', () {
    expect(() => AmapMyLocationStyle(anchorU: 1.5), throwsAssertionError);
    expect(() => AmapMyLocationStyle(anchorV: -0.2), throwsAssertionError);
    expect(() => AmapMyLocationStyle(interval: -1), throwsAssertionError);
  });

  test('AmapCustomMapStyle 冻结样式字节并保留值语义', () {
    final Uint8List styleData = Uint8List.fromList(<int>[1, 2, 3]);
    final AmapCustomMapStyle style = AmapCustomMapStyle(
      styleData: styleData,
      styleExtraData: Uint8List.fromList(<int>[4, 5]),
      styleTextureData: Uint8List.fromList(<int>[6, 7, 8]),
      styleId: 'style-1',
    );
    styleData[0] = 9;

    expect(style.styleData, orderedEquals(<int>[1, 2, 3]));
    expect(() => style.styleData![0] = 9, throwsUnsupportedError);
    expect(style.styleId, 'style-1');
    expect(
      style,
      equals(
        AmapCustomMapStyle(
          styleData: Uint8List.fromList(<int>[1, 2, 3]),
          styleExtraData: Uint8List.fromList(<int>[4, 5]),
          styleTextureData: Uint8List.fromList(<int>[6, 7, 8]),
          styleId: 'style-1',
        ),
      ),
    );
  });

  test('AmapCustomMapStyle 至少需要 styleData 或 styleId', () {
    expect(
      () => AmapCustomMapStyle(styleExtraData: Uint8List.fromList(<int>[1])),
      throwsAssertionError,
    );
    expect(
      AmapCustomMapStyle(styleId: 'style-2'),
      equals(AmapCustomMapStyle(styleId: 'style-2')),
    );
    expect(
      AmapCustomMapStyle(styleData: Uint8List.fromList(<int>[1])).styleData,
      orderedEquals(<int>[1]),
    );
  });

  test('AmapMapConfiguration 携带自定义底图样式', () {
    final AmapCustomMapStyle style = AmapCustomMapStyle(styleId: 'style-1');
    expect(
      const AmapMapConfiguration(customMapStyle: null).customMapStyle,
      isNull,
    );
    expect(
      AmapMapConfiguration(customMapStyle: style).customMapStyle,
      equals(style),
    );
  });

  test('Marker 的 icon 和 anchor 参与复制、JSON 与差分', () {
    final Marker marker = Marker(
      markerId: const MarkerId('icon'),
      position: const LatLng(30, 120),
      icon: const AssetMapBitmap('assets/pin.png'),
      anchor: const Offset(0.5, 1),
    );

    expect(marker.clone(), equals(marker));
    expect(
      marker.toJson(),
      containsPair('anchor', <String, double>{'x': 0.5, 'y': 1}),
    );
    expect(marker.toJson(), containsPair('icon', marker.icon.toJson()));

    final MarkerUpdates updates = MarkerUpdates.from(
      <Marker>{
        const Marker(markerId: MarkerId('icon'), position: LatLng(30, 120)),
      },
      <Marker>{marker},
    );
    expect(updates.objectsToChange, equals(<Marker>{marker}));
  });

  test('Marker 拖拽回调不参与相等性与差分', () {
    final Marker first = Marker(
      markerId: const MarkerId('drag'),
      position: const LatLng(30, 120),
      draggable: true,
      onDragStart: (LatLng _) {},
      onDrag: (LatLng _) {},
      onDragEnd: (LatLng _) {},
    );
    final Marker second = Marker(
      markerId: const MarkerId('drag'),
      position: const LatLng(30, 120),
      draggable: true,
    );

    expect(second, equals(first));
    expect(
      MarkerUpdates.from(<Marker>{first}, <Marker>{second}).objectsToChange,
      isEmpty,
    );
  });

  test('Marker 的信息窗参与克隆、相等与差分', () {
    final Marker withWindow = Marker(
      markerId: const MarkerId('info'),
      position: const LatLng(30, 120),
      infoWindow: const InfoWindow(title: '标题', snippet: '副标题'),
    );

    // clone 保留信息窗内容，onInfoWindowTap 才能拿到 infoWindow.onTap。
    expect(withWindow.clone(), equals(withWindow));
    expect(withWindow.clone().infoWindow.title, '标题');

    // 只改信息窗标题/副标题会产生差分。
    final Marker changedWindow = Marker(
      markerId: const MarkerId('info'),
      position: const LatLng(30, 120),
      infoWindow: const InfoWindow(title: '新标题', snippet: '副标题'),
    );
    expect(
      MarkerUpdates.from(
        <Marker>{withWindow},
        <Marker>{changedWindow},
      ).objectsToChange,
      equals(<Marker>{changedWindow}),
    );

    // 只改信息窗 onTap 不产生差分（回调不参与值语义）。
    final Marker windowWithTap = Marker(
      markerId: const MarkerId('info'),
      position: const LatLng(30, 120),
      infoWindow: InfoWindow(title: '标题', snippet: '副标题', onTap: () {}),
    );
    expect(
      MarkerUpdates.from(
        <Marker>{withWindow},
        <Marker>{windowWithTap},
      ).objectsToChange,
      isEmpty,
    );
  });

  test('聚合管理器按 ID 相等，Marker 保留管理器关联', () {
    const ClusterManagerId managerId = ClusterManagerId('clusters');
    void onClusterTap(Cluster _) {}
    final ClusterManager manager = ClusterManager(
      clusterManagerId: managerId,
      onClusterTap: onClusterTap,
    );
    final Marker marker = const Marker(
      markerId: MarkerId('member'),
      position: LatLng(30, 120),
      clusterManagerId: managerId,
    );

    expect(
      manager,
      equals(ClusterManager(clusterManagerId: managerId, onClusterTap: (_) {})),
    );
    expect(manager.clone(), equals(manager));
    expect(manager.copyWith().onClusterTap, same(onClusterTap));
    expect(manager.toJson(), containsPair('clusterManagerId', 'clusters'));
    expect(marker.clone(), equals(marker));
    expect(marker.toJson(), containsPair('clusterManagerId', 'clusters'));
  });

  test('聚合管理器差分使用稳定的 clusterManagers JSON 字段', () {
    const ClusterManagerId changedId = ClusterManagerId('changed');
    const ClusterManagerId removedId = ClusterManagerId('removed');
    const ClusterManagerId addedId = ClusterManagerId('added');
    const ClusterManager previousChanged = ClusterManager(
      clusterManagerId: changedId,
    );
    const ClusterManager currentChanged = ClusterManager(
      clusterManagerId: changedId,
    );
    final ClusterManagerUpdates updates = ClusterManagerUpdates.from(
      <ClusterManager>{
        previousChanged,
        const ClusterManager(clusterManagerId: removedId),
      },
      <ClusterManager>{
        currentChanged,
        const ClusterManager(clusterManagerId: addedId),
      },
    );

    expect(updates.objectsToAdd.single.clusterManagerId, addedId);
    expect(updates.objectsToChange, isEmpty);
    expect(
      updates.objectIdsToRemove,
      equals(<MapsObjectId<ClusterManager>>{removedId}),
    );
    expect(
      updates.toJson(),
      equals(<String, Object>{
        'clusterManagersToAdd': <Object>[
          const <String, Object>{'clusterManagerId': 'added'},
        ],
        // 三个差分字段始终存在（稳定 JSON 契约），无变更时为空列表。
        'clusterManagersToChange': <Object>[],
        'clusterManagerIdsToRemove': <String>['removed'],
      }),
    );
  });

  test('Cluster 冻结成员列表并暴露数量和边界', () {
    final List<MarkerId> markerIds = <MarkerId>[
      MarkerId('one'),
      MarkerId('two'),
    ];
    final Cluster cluster = Cluster(
      const ClusterManagerId('clusters'),
      markerIds,
      position: const LatLng(30, 120),
      bounds: LatLngBounds(
        southwest: LatLng(29, 119),
        northeast: LatLng(31, 121),
      ),
    );
    markerIds.clear();

    expect(cluster.count, 2);
    expect(cluster.markerIds, hasLength(2));
    expect(cluster.bounds.southwest, const LatLng(29, 119));
    expect(
      () => cluster.markerIds.add(const MarkerId('three')),
      throwsUnsupportedError,
    );
    expect(
      () => cluster.markerIds[0] = const MarkerId('changed'),
      throwsUnsupportedError,
    );
  });

  test('折线和多边形会复制并冻结坐标列表', () {
    final List<LatLng> points = <LatLng>[
      const LatLng(30, 120),
      const LatLng(31, 121),
      const LatLng(32, 122),
    ];
    final Polyline polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: points,
    );
    final Polygon polygon = Polygon(
      polygonId: const PolygonId('area'),
      points: points,
    );

    points.clear();

    expect(polyline.points, hasLength(3));
    expect(polygon.points, hasLength(3));
    expect(
      () => polyline.points.add(const LatLng(33, 123)),
      throwsUnsupportedError,
    );
  });

  test('Marker 和 Polyline 的回调不参与值语义与差分', () {
    void first() {}
    void second() {}
    final Marker marker = Marker(
      markerId: const MarkerId('marker'),
      position: const LatLng(30, 120),
      onTap: first,
    );
    final Polyline polyline = Polyline(
      polylineId: const PolylineId('polyline'),
      points: const <LatLng>[LatLng(30, 120), LatLng(31, 121)],
      onTap: first,
    );

    expect(
      marker,
      equals(
        Marker(
          markerId: const MarkerId('marker'),
          position: const LatLng(30, 120),
          onTap: second,
        ),
      ),
    );
    expect(
      polyline,
      equals(
        Polyline(
          polylineId: const PolylineId('polyline'),
          points: const <LatLng>[LatLng(30, 120), LatLng(31, 121)],
          onTap: second,
        ),
      ),
    );

    expect(marker.clone().onTap, same(first));
    expect(polyline.clone().onTap, same(first));
    expect(
      MarkerUpdates.from(
        <Marker>{marker},
        <Marker>{
          Marker(
            markerId: const MarkerId('marker'),
            position: const LatLng(30, 120),
            onTap: second,
          ),
        },
      ).objectsToChange,
      isEmpty,
    );
    expect(
      PolylineUpdates.from(
        <Polyline>{polyline},
        <Polyline>{
          Polyline(
            polylineId: const PolylineId('polyline'),
            points: const <LatLng>[LatLng(30, 120), LatLng(31, 121)],
            onTap: second,
          ),
        },
      ).objectsToChange,
      isEmpty,
    );
  });

  test('MapsObjectUpdates 计算覆盖物差分并序列化', () {
    const MarkerId unchangedId = MarkerId('unchanged');
    const MarkerId changedId = MarkerId('changed');
    const MarkerId removedId = MarkerId('removed');
    const MarkerId addedId = MarkerId('added');
    const LatLng position = LatLng(30, 120);
    final Marker unchanged = const Marker(
      markerId: unchangedId,
      position: position,
    );
    final Marker previousChanged = const Marker(
      markerId: changedId,
      position: position,
      title: 'before',
    );
    final Marker currentChanged = const Marker(
      markerId: changedId,
      position: position,
      title: 'after',
    );
    final Marker removed = const Marker(
      markerId: removedId,
      position: position,
    );
    final Marker added = const Marker(markerId: addedId, position: position);

    final MarkerUpdates updates = MarkerUpdates.from(
      <Marker>{unchanged, previousChanged, removed},
      <Marker>{unchanged, currentChanged, added},
    );

    expect(updates.objectsToAdd, equals(<Marker>{added}));
    expect(updates.objectsToChange, equals(<Marker>{currentChanged}));
    expect(() => updates.objectsToAdd.clear(), throwsUnsupportedError);
    expect(() => updates.objectIdsToRemove.clear(), throwsUnsupportedError);
    expect(
      updates.objectIdsToRemove,
      equals(<MapsObjectId<Marker>>{removedId}),
    );
    expect(
      updates.toJson(),
      equals(<String, Object>{
        'markersToAdd': <Object>[added.toJson()],
        'markersToChange': <Object>[currentChanged.toJson()],
        'markerIdsToRemove': <String>['removed'],
      }),
    );
  });

  test('海量点图层冻结点集并保留值语义', () {
    final List<MultiPointPoint> points = <MultiPointPoint>[
      const MultiPointPoint(pointId: 'a', latLng: LatLng(30, 120)),
      const MultiPointPoint(pointId: 'b', latLng: LatLng(31, 121)),
    ];
    void onPointTap(MultiPointTap _) {}
    final MultiPointOverlay overlay = MultiPointOverlay(
      multiPointOverlayId: const MultiPointOverlayId('mass'),
      points: points,
      icon: const AssetMapBitmap('assets/pin.png'),
      anchor: const Offset(0.25, 0.75),
      visible: false,
      onPointTap: onPointTap,
    );
    points.clear();

    expect(overlay.points, hasLength(2));
    expect(
      () => overlay.points.add(
        const MultiPointPoint(pointId: 'c', latLng: LatLng(32, 122)),
      ),
      throwsUnsupportedError,
    );
    expect(
      overlay,
      equals(
        MultiPointOverlay(
          multiPointOverlayId: const MultiPointOverlayId('mass'),
          points: const <MultiPointPoint>[
            MultiPointPoint(pointId: 'a', latLng: LatLng(30, 120)),
            MultiPointPoint(pointId: 'b', latLng: LatLng(31, 121)),
          ],
          icon: const AssetMapBitmap('assets/pin.png'),
          anchor: const Offset(0.25, 0.75),
          visible: false,
          onPointTap: (_) {},
        ),
      ),
    );
    expect(overlay.clone(), equals(overlay));
    expect(overlay.toJson(), containsPair('multiPointOverlayId', 'mass'));
    expect(overlay.toJson(), containsPair('visible', false));
    expect(overlay.diffFrom(overlay), isNull, reason: '点集与配置不变时不应产生图层差分');
  });

  test('海量点图层拒绝超过官方建议的点数', () {
    final List<MultiPointPoint> tooMany = <MultiPointPoint>[
      for (int i = 0; i < 100001; i++)
        MultiPointPoint(pointId: 'p$i', latLng: LatLng(30, 120)),
    ];
    expect(
      () => MultiPointOverlay(
        multiPointOverlayId: const MultiPointOverlayId('mass'),
        points: tooMany,
      ),
      throwsAssertionError,
    );
  });

  test('海量点图层差分拆分层级与点级增量', () {
    const MultiPointOverlayId layerId = MultiPointOverlayId('mass');
    MultiPointOverlay layer(List<MultiPointPoint> points) =>
        MultiPointOverlay(multiPointOverlayId: layerId, points: points);
    const List<MultiPointPoint> previousPoints = <MultiPointPoint>[
      MultiPointPoint(pointId: 'a', latLng: LatLng(30, 120)),
      MultiPointPoint(pointId: 'b', latLng: LatLng(31, 121)),
    ];
    const List<MultiPointPoint> currentPoints = <MultiPointPoint>[
      MultiPointPoint(pointId: 'a', latLng: LatLng(30, 120)),
      MultiPointPoint(pointId: 'c', latLng: LatLng(32, 122)),
    ];

    final MultiPointOverlayUpdates updates = MultiPointOverlayUpdates.from(
      <MultiPointOverlay>{layer(previousPoints)},
      <MultiPointOverlay>{layer(currentPoints)},
    );

    expect(updates.layersToAdd, isEmpty);
    expect(updates.layerIdsToRemove, isEmpty);
    expect(updates.layersToChange, hasLength(1));
    final MultiPointOverlayUpdate change = updates.layersToChange.single;
    expect(change.multiPointOverlayId, layerId);
    expect(change.pointsToAdd, <MultiPointPoint>[currentPoints[1]]);
    expect(change.pointIdsToRemove, <String>['b']);
    expect(change.pointsToChange, isEmpty);
    expect(change.icon, isNull);
    expect(change.anchor, isNull);
    expect(change.visible, isNull);
    expect(() => updates.layersToChange.clear(), throwsUnsupportedError);
  });

  test('海量点图层差分识别图层新增、删除与纯配置变更', () {
    const MultiPointOverlayId addedId = MultiPointOverlayId('added');
    const MultiPointOverlayId removedId = MultiPointOverlayId('removed');
    const MultiPointOverlayId changedId = MultiPointOverlayId('changed');
    const List<MultiPointPoint> points = <MultiPointPoint>[
      MultiPointPoint(pointId: 'a', latLng: LatLng(30, 120)),
    ];
    MultiPointOverlay layer(MultiPointOverlayId id, {bool visible = true}) =>
        MultiPointOverlay(
          multiPointOverlayId: id,
          points: points,
          visible: visible,
        );

    final MultiPointOverlayUpdates updates = MultiPointOverlayUpdates.from(
      <MultiPointOverlay>{layer(removedId), layer(changedId)},
      <MultiPointOverlay>{layer(changedId, visible: false), layer(addedId)},
    );

    expect(updates.layersToAdd, <MultiPointOverlay>[layer(addedId)]);
    expect(updates.layerIdsToRemove, <String>['removed']);
    expect(updates.layersToChange, hasLength(1));
    final MultiPointOverlayUpdate change = updates.layersToChange.single;
    expect(change.multiPointOverlayId, changedId);
    expect(change.visible, isFalse);
    expect(change.pointsToAdd, isEmpty);
    expect(change.pointsToChange, isEmpty);
    expect(change.pointIdsToRemove, isEmpty);
  });

  test('海量点图层差分忽略仅回调变化', () {
    const MultiPointOverlayId layerId = MultiPointOverlayId('mass');
    final MultiPointOverlayUpdates updates = MultiPointOverlayUpdates.from(
      <MultiPointOverlay>{
        MultiPointOverlay(
          multiPointOverlayId: layerId,
          points: const <MultiPointPoint>[],
          onPointTap: (_) {},
        ),
      },
      <MultiPointOverlay>{
        MultiPointOverlay(
          multiPointOverlayId: layerId,
          points: const <MultiPointPoint>[],
          onPointTap: (MultiPointTap _) {},
        ),
      },
    );

    expect(updates.layersToAdd, isEmpty);
    expect(updates.layersToChange, isEmpty);
    expect(updates.layerIdsToRemove, isEmpty);
  });

  test('海量点图层差分识别同一点标识的坐标变更', () {
    final MultiPointOverlayUpdates updates = MultiPointOverlayUpdates.from(
      <MultiPointOverlay>{
        MultiPointOverlay(
          multiPointOverlayId: const MultiPointOverlayId('mass'),
          points: const <MultiPointPoint>[
            MultiPointPoint(pointId: 'a', latLng: LatLng(30, 120)),
          ],
        ),
      },
      <MultiPointOverlay>{
        MultiPointOverlay(
          multiPointOverlayId: const MultiPointOverlayId('mass'),
          points: const <MultiPointPoint>[
            MultiPointPoint(pointId: 'a', latLng: LatLng(30.5, 120.5)),
          ],
        ),
      },
    );

    final MultiPointOverlayUpdate change = updates.layersToChange.single;
    expect(change.pointsToChange.single.pointId, 'a');
    expect(change.pointsToAdd, isEmpty);
    expect(change.pointIdsToRemove, isEmpty);
  });

  test('HeatmapGradient supports a transparent low-intensity lead-in', () {
    final HeatmapGradient gradient = HeatmapGradient(
      const <HeatmapGradientColor>[
        HeatmapGradientColor(Colors.blue, 0.2),
        HeatmapGradientColor(Colors.red, 1),
      ],
    );

    expect(gradient.colors.first.startPoint, 0.2);
  });
}

final class _MockMapPlatform extends AmapMapsFlutterPlatform
    with MockPlatformInterfaceMixin {}

final class _MinimalMapPlatform extends AmapMapsFlutterPlatform {}

final class _TestTileProvider extends TileProvider {
  @override
  Future<Tile> getTile(int x, int y, int zoom) async => TileProvider.noTile;
}
