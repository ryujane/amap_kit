import 'dart:ui';

import 'package:amap_kit_core/amap_kit_core.dart';
import 'package:amap_kit_map_platform_interface/src/types/bitmap_descriptor.dart';
import 'package:amap_kit_map_platform_interface/src/types/maps_object.dart';
import 'package:flutter/foundation.dart';

/// 唯一标识一个海量点图层。
@immutable
final class MultiPointOverlayId extends MapsObjectId<MultiPointOverlay> {
  /// 创建海量点图层标识。
  const MultiPointOverlayId(super.value);
}

/// 海量点图层中的一个点；[pointId] 在所属图层内必须稳定唯一。
///
/// 海量点图层建议不超过 100,000 个点（官方建议值）。点本身没有独立的
/// 样式或点击信息；图层内所有点共享图层的图标与锚点。
@immutable
final class MultiPointPoint {
  /// 创建海量点。
  const MultiPointPoint({required this.pointId, required this.latLng});

  /// 图层内稳定且唯一的点标识，用于差分更新与点击事件路由。
  final String pointId;

  /// 点的经纬度。
  final LatLng latLng;

  @override
  bool operator ==(Object other) =>
      other is MultiPointPoint &&
      other.pointId == pointId &&
      other.latLng == latLng;

  @override
  int get hashCode => Object.hash(pointId, latLng);

  @override
  String toString() => 'MultiPointPoint($pointId, $latLng)';
}

/// 用户点击海量点图层中某个点时的回调载荷。
@immutable
final class MultiPointTap {
  /// 创建海量点点击载荷。
  const MultiPointTap({required this.pointId, required this.latLng});

  /// 被点击点的标识。
  final String pointId;

  /// 被点击点的经纬度。
  final LatLng latLng;

  @override
  String toString() => '$runtimeType $pointId $latLng';
}

/// 使用单个共享图标渲染大量相似点的图层。
///
/// 官方 MultiPointOverlay 建议每层不超过 100,000 个点；点数较少时也可
/// 使用普通的 [Marker]。图层的点集通过 [MultiPointOverlayUpdates] 按
/// [MultiPointPoint.pointId] 差分更新。
@immutable
final class MultiPointOverlay implements MapsObject<MultiPointOverlay> {
  /// 创建一个海量点图层。
  ///
  /// [anchor] 是图标上对准 [MultiPointPoint.latLng] 的归一化锚点，
  /// 默认 (0.5, 0.5)。点集会被冻结为不可变列表。
  MultiPointOverlay({
    required this.multiPointOverlayId,
    required List<MultiPointPoint> points,
    this.icon = BitmapDescriptor.defaultMarker,
    this.anchor = const Offset(0.5, 0.5),
    this.visible = true,
    this.onPointTap,
  }) : points = List<MultiPointPoint>.unmodifiable(points),
       assert(points.length <= 100000, '官方建议每层不超过 100,000 个点'),
       assert(
         anchor.dx >= 0 && anchor.dx <= 1 && anchor.dy >= 0 && anchor.dy <= 1,
         'anchor 必须归一化到 0..1',
       );

  /// 当前图层的稳定标识。
  final MultiPointOverlayId multiPointOverlayId;

  /// 图层的点集；点按 [MultiPointPoint.pointId] 保持稳定。
  final List<MultiPointPoint> points;

  /// 图层内所有点共享的图标。
  final BitmapDescriptor icon;

  /// 图标上对准点坐标的归一化锚点。
  final Offset anchor;

  /// 图层是否可见。
  final bool visible;

  /// 用户点击图层内某个点时调用；回调载荷不参与图层相等性判断。
  final void Function(MultiPointTap tap)? onPointTap;

  @override
  MultiPointOverlayId get mapsId => multiPointOverlayId;

  @override
  MultiPointOverlay clone() => MultiPointOverlay(
    multiPointOverlayId: multiPointOverlayId,
    points: List<MultiPointPoint>.unmodifiable(points),
    icon: icon,
    anchor: anchor,
    visible: visible,
    onPointTap: onPointTap,
  );

  /// 计算当前图层相对 [previous] 的增量；无变化时返回 `null`。
  ///
  /// 只有变化的配置字段（图标、锚点、可见性）非空，点集变化按
  /// [MultiPointPoint.pointId] 拆分为新增、变更与删除。
  MultiPointOverlayUpdate? diffFrom(MultiPointOverlay previous) {
    if (previous == this) {
      return null;
    }
    final Map<String, MultiPointPoint> previousPoints =
        <String, MultiPointPoint>{
          for (final MultiPointPoint point in previous.points)
            point.pointId: point,
        };
    final Map<String, MultiPointPoint> currentPoints =
        <String, MultiPointPoint>{
          for (final MultiPointPoint point in points) point.pointId: point,
        };
    final List<MultiPointPoint> pointsToAdd = <MultiPointPoint>[
      for (final MultiPointPoint point in points)
        if (!previousPoints.containsKey(point.pointId)) point,
    ];
    final List<MultiPointPoint> pointsToChange = <MultiPointPoint>[
      for (final MultiPointPoint point in points)
        if (previousPoints[point.pointId]
            case final MultiPointPoint previousPoint
            when previousPoint != point)
          point,
    ];
    final List<String> pointIdsToRemove = <String>[
      for (final String pointId in previousPoints.keys)
        if (!currentPoints.containsKey(pointId)) pointId,
    ];
    return MultiPointOverlayUpdate(
      multiPointOverlayId: multiPointOverlayId,
      icon: icon == previous.icon ? null : icon,
      anchor: anchor == previous.anchor ? null : anchor,
      visible: visible == previous.visible ? null : visible,
      pointsToAdd: pointsToAdd,
      pointsToChange: pointsToChange,
      pointIdsToRemove: pointIdsToRemove,
    );
  }

  @override
  Object toJson() => <String, Object?>{
    'multiPointOverlayId': multiPointOverlayId.value,
    'points': points
        .map(
          (MultiPointPoint point) => <String, Object?>{
            'pointId': point.pointId,
            'latLng': point.latLng.toJson(),
          },
        )
        .toList(growable: false),
    'icon': icon.toJson(),
    'anchor': <String, double>{'x': anchor.dx, 'y': anchor.dy},
    'visible': visible,
  };

  @override
  bool operator ==(Object other) =>
      other is MultiPointOverlay &&
      other.multiPointOverlayId == multiPointOverlayId &&
      listEquals(other.points, points) &&
      other.icon == icon &&
      other.anchor == anchor &&
      other.visible == visible;

  @override
  int get hashCode => Object.hash(
    multiPointOverlayId,
    Object.hashAll(points),
    icon,
    anchor,
    visible,
  );
}

/// 单个海量点图层的配置与点集增量。
///
/// 可空的配置字段表示该配置未变化；点集增量按点标识拆分。
@immutable
final class MultiPointOverlayUpdate {
  /// 创建图层增量。
  MultiPointOverlayUpdate({
    required this.multiPointOverlayId,
    this.icon,
    this.anchor,
    this.visible,
    List<MultiPointPoint> pointsToAdd = const <MultiPointPoint>[],
    List<MultiPointPoint> pointsToChange = const <MultiPointPoint>[],
    List<String> pointIdsToRemove = const <String>[],
  }) : pointsToAdd = List<MultiPointPoint>.unmodifiable(pointsToAdd),
       pointsToChange = List<MultiPointPoint>.unmodifiable(pointsToChange),
       pointIdsToRemove = List<String>.unmodifiable(pointIdsToRemove);

  /// 目标图层的标识。
  final MultiPointOverlayId multiPointOverlayId;

  /// 变更后的图标；为空表示未变化。
  final BitmapDescriptor? icon;

  /// 变更后的锚点；为空表示未变化。
  final Offset? anchor;

  /// 变更后的可见性；为空表示未变化。
  final bool? visible;

  /// 待新增的点。
  final List<MultiPointPoint> pointsToAdd;

  /// 待变更（同一点标识、新坐标）的点。
  final List<MultiPointPoint> pointsToChange;

  /// 待删除的点标识。
  final List<String> pointIdsToRemove;
}

/// 海量点图层集合的新增、变更和删除差分。
@immutable
final class MultiPointOverlayUpdates {
  /// 创建一个空差分。
  MultiPointOverlayUpdates({
    List<MultiPointOverlay> layersToAdd = const <MultiPointOverlay>[],
    List<MultiPointOverlayUpdate> layersToChange =
        const <MultiPointOverlayUpdate>[],
    List<String> layerIdsToRemove = const <String>[],
  }) : layersToAdd = List<MultiPointOverlay>.unmodifiable(layersToAdd),
       layersToChange = List<MultiPointOverlayUpdate>.unmodifiable(
         layersToChange,
       ),
       layerIdsToRemove = List<String>.unmodifiable(layerIdsToRemove);

  /// 待新增的图层，携带完整点集。
  final List<MultiPointOverlay> layersToAdd;

  /// 待变更图层的配置与点级增量。
  final List<MultiPointOverlayUpdate> layersToChange;

  /// 待删除图层的标识。
  final List<String> layerIdsToRemove;

  /// 根据更新前后的图层集合计算差分。
  ///
  /// 新增图层携带完整点集；变更图层通过 [MultiPointOverlay.diffFrom]
  /// 计算配置与点级增量；仅配置或点集之一变化都会触发图层变更。
  factory MultiPointOverlayUpdates.from(
    Set<MultiPointOverlay> previous,
    Set<MultiPointOverlay> current,
  ) {
    final Map<MultiPointOverlayId, MultiPointOverlay> previousLayers =
        <MultiPointOverlayId, MultiPointOverlay>{
          for (final MultiPointOverlay layer in previous)
            layer.multiPointOverlayId: layer,
        };
    final Map<MultiPointOverlayId, MultiPointOverlay> currentLayers =
        <MultiPointOverlayId, MultiPointOverlay>{
          for (final MultiPointOverlay layer in current)
            layer.multiPointOverlayId: layer,
        };
    final List<MultiPointOverlay> layersToAdd = <MultiPointOverlay>[
      for (final MultiPointOverlayId id in currentLayers.keys)
        if (!previousLayers.containsKey(id)) currentLayers[id]!,
    ];
    final List<String> layerIdsToRemove = <String>[
      for (final MultiPointOverlayId id in previousLayers.keys)
        if (!currentLayers.containsKey(id)) id.value,
    ];
    final List<MultiPointOverlayUpdate> layersToChange =
        <MultiPointOverlayUpdate>[];
    for (final MultiPointOverlayId id in currentLayers.keys) {
      final MultiPointOverlay? previousLayer = previousLayers[id];
      if (previousLayer == null) {
        continue;
      }
      final MultiPointOverlayUpdate? update = currentLayers[id]!.diffFrom(
        previousLayer,
      );
      if (update != null) {
        layersToChange.add(update);
      }
    }
    return MultiPointOverlayUpdates(
      layersToAdd: layersToAdd,
      layersToChange: layersToChange,
      layerIdsToRemove: layerIdsToRemove,
    );
  }
}
