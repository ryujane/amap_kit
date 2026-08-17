# amap_kit_map

基于高德原生地图 SDK 的 Flutter 地图组件（支持 Android 与 iOS），提供地图展示、相机控制、强类型覆盖物（Marker、Polyline、Polygon、Circle、Heatmap、TileOverlay、GroundOverlay、聚合）和地图事件。

API 设计参考 [Google Maps for Flutter](https://pub.dev/packages/google_maps_flutter)（`google_maps_flutter`）：沿用其控制器模型、相机更新 API 与覆盖物新增/变更/删除的差分风格，熟悉 Google Maps 插件的开发者可以快速迁移。

| 平台 | 高德 SDK | 版本 |
| --- | --- | --- |
| Android | 3dmap-location-search 合包 | 11.1.001_loc11.1.001_sea9.7.4 |
| iOS | AMap3DMap | 11.2.100 |

## 使用

创建地图前先向用户展示高德隐私政策并取得同意，然后传入 API Key、隐私声明、`mapId` 和初始相机位置：

```dart
AmapMap(
  apiKey: exampleApiKey,
  privacyStatement: const AMapPrivacyStatement(
    hasContains: true,
    hasShow: true,
    hasAgree: true,
  ),
  mapId: 'home-map',
  initialCameraPosition: const CameraPosition(
    target: LatLng(30.2741, 120.1551),
    zoom: 12,
  ),
  markers: const <Marker>{
    Marker(
      markerId: MarkerId('west-lake'),
      position: LatLng(30.2304, 120.1325),
    ),
  },
  onMapCreated: (AmapMapController controller) {
    // 保存 controller，用于后续相机控制。
  },
)
```

地图创建后通过 `AmapMapController` 控制相机、读取可见区域等，不再使用时必须调用 `dispose`：

```dart
controller.animateCamera(const CameraUpdate.zoomBy(1));
controller.moveCamera(CameraUpdate.newLatLng(const LatLng(30.24, 120.14)));
final LatLngBounds visible = await controller.getVisibleRegion();
controller.dispose();
```

## 说明

- 完整示例见 [example](example/README.md)。
