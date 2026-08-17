import 'package:amap_kit_map_platform_interface/src/types/maps_object_updates.dart';
import 'package:amap_kit_map_platform_interface/src/types/tile_overlay.dart';

/// 一组瓦片图层的新增、变更和删除描述。
final class TileOverlayUpdates extends MapsObjectUpdates<TileOverlay> {
  /// 根据更新前后的瓦片图层集合计算差分。
  TileOverlayUpdates.from(super.previous, super.current)
    : super.from(objectName: 'tileOverlay');

  /// 待新增图层。
  Set<TileOverlay> get tileOverlaysToAdd => objectsToAdd;

  /// 待变更图层。
  Set<TileOverlay> get tileOverlaysToChange => objectsToChange;

  /// 待删除图层 ID。
  Set<TileOverlayId> get tileOverlayIdsToRemove =>
      objectIdsToRemove.cast<TileOverlayId>();
}
