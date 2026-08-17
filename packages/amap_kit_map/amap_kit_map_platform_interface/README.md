# amap_kit_map_platform_interface

`amap_kit_map` 的平台契约包：定义地图平台接口、强类型模型（覆盖物、相机、位图等）、事件流和异常，并提供测试替身入口。平台实现必须按 `mapId` 隔离所有命令、事件和原生资源。

应用应依赖 `amap_kit_map`，不要直接使用本包；Pigeon 生成代码只属于 Android/iOS 实现包。
