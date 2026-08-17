# amap_kit_map 示例

通过 `--dart-define=AMAP_API_KEY=<key>` 传入高德 API Key 后运行：

```shell
flutter run --dart-define=AMAP_API_KEY=your-amap-key
```

示例包含地图创建与 UI 开关（底图、指南针、比例尺、路况、建筑物、定位蓝点）、相机控制（移动/动画、读取可见区域、事件）、覆盖物绘制（Marker、Polyline、Polygon、Circle、聚合、海量点）、热力图、自定义瓦片和截屏等页面，展示 `AmapMap` 与 `AmapMapController` 的用法。

真机运行前，请在 Android Manifest / iOS Info.plist 中声明权限。
