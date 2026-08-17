import 'dart:ui';

import 'package:amap_kit_core/amap_kit_core.dart';
import 'package:amap_kit_map_platform_interface/src/types/bitmap_descriptor.dart';
import 'package:amap_kit_map_platform_interface/src/types/cluster_manager.dart';
import 'package:amap_kit_map_platform_interface/src/types/maps_object.dart';
import 'package:flutter/foundation.dart';

Object _offsetToJson(Offset offset) {
  return <Object>[offset.dx, offset.dy];
}

/// Text labels for a [Marker] info window.
@immutable
class InfoWindow {
  /// Creates an immutable representation of a label on for [Marker].
  const InfoWindow({
    this.title,
    this.snippet,
    this.anchor = const Offset(0.5, 0.0),
    this.onTap,
  });

  /// Text labels specifying that no text is to be displayed.
  static const InfoWindow noText = InfoWindow();

  /// Text displayed in an info window when the user taps the marker.
  ///
  /// A null value means no title.
  final String? title;

  /// Additional text displayed below the [title].
  ///
  /// A null value means no additional text.
  final String? snippet;

  /// The icon image point that will be the anchor of the info window when
  /// displayed.
  ///
  /// The image point is specified in normalized coordinates: An anchor of
  /// (0.0, 0.0) means the top left corner of the image. An anchor
  /// of (1.0, 1.0) means the bottom right corner of the image.
  final Offset anchor;

  /// onTap callback for this [InfoWindow].
  final VoidCallback? onTap;

  /// Creates a new [InfoWindow] object whose values are the same as this instance,
  /// unless overwritten by the specified parameters.
  InfoWindow copyWith({
    String? titleParam,
    String? snippetParam,
    Offset? anchorParam,
    VoidCallback? onTapParam,
  }) {
    return InfoWindow(
      title: titleParam ?? title,
      snippet: snippetParam ?? snippet,
      anchor: anchorParam ?? anchor,
      onTap: onTapParam ?? onTap,
    );
  }

  /// Converts this object to something serializable in JSON.
  Object toJson() {
    final json = <String, Object>{};

    void addIfPresent(String fieldName, Object? value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('title', title);
    addIfPresent('snippet', snippet);
    addIfPresent('anchor', _offsetToJson(anchor));

    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is InfoWindow &&
        title == other.title &&
        snippet == other.snippet &&
        anchor == other.anchor;
  }

  @override
  int get hashCode => Object.hash(title.hashCode, snippet, anchor);

  @override
  String toString() {
    return 'InfoWindow{title: $title, snippet: $snippet, anchor: $anchor}';
  }
}

/// 唯一标识一个标记。
@immutable
final class MarkerId extends MapsObjectId<Marker> {
  /// 创建标记标识。
  const MarkerId(super.value);
}

/// 地图标记。
@immutable
final class Marker implements MapsObject<Marker> {
  /// 创建一个默认样式的地图标记。
  const Marker({
    required this.markerId,
    required this.position,
    this.title,
    this.snippet,
    this.draggable = false,
    this.consumeTapEvents = false,
    this.alpha = 1,
    this.rotation = 0,
    this.visible = true,
    this.zIndex = 0,
    this.infoWindow = InfoWindow.noText,
    this.clusterManagerId,
    this.icon = BitmapDescriptor.defaultMarker,
    this.anchor = const Offset(0.5, 1),
    this.onTap,
    this.onDragStart,
    this.onDrag,
    this.onDragEnd,
  }) : assert(alpha >= 0 && alpha <= 1);

  final MarkerId markerId;
  final LatLng position;
  final String? title;
  final String? snippet;
  final bool draggable;
  final double alpha;
  final double rotation;
  final bool visible;
  final double zIndex;

  final InfoWindow infoWindow;

  /// The image used to render this marker.
  final BitmapDescriptor icon;

  /// The normalized point in the icon that is placed at [position].
  final Offset anchor;

  /// True if the marker icon consumes tap events. If not, the map will perform
  /// default tap handling by centering the map on the marker and displaying its
  /// info window.
  final bool consumeTapEvents;

  /// 可选的聚合管理器标识；为空时 Marker 不参与聚合。
  final ClusterManagerId? clusterManagerId;

  /// 用户点击此标记时调用。
  ///
  /// 回调不参与 [Marker] 的相等性与差分判断，因此只替换回调不会触发原生
  /// 覆盖物更新。参与聚合的 Marker 不会触发此回调，而是走
  /// [ClusterManager.onClusterTap]。
  final VoidCallback? onTap;

  /// 用户开始拖动此标记时调用，参数为原生当前位置。
  ///
  /// 回调不参与 [Marker] 的相等性与差分判断，因此只替换回调不会触发原生
  /// 覆盖物更新。参与聚合的 Marker 不会触发此回调。原生坐标以当前拖拽
  /// 位置为准；Dart 侧 [Marker] 仍是调用方的不可变状态来源。
  final ValueChanged<LatLng>? onDragStart;

  /// 用户拖动此标记过程中调用，参数为原生当前位置。
  ///
  /// 回调不参与 [Marker] 的相等性与差分判断，因此只替换回调不会触发原生
  /// 覆盖物更新。参与聚合的 Marker 不会触发此回调。该回调可能高频触发，
  /// 适合用于位置预览；最终落点请以 [onDragEnd] 为准。
  final ValueChanged<LatLng>? onDrag;

  /// 用户结束拖动此标记时调用，参数为原生最终位置。
  ///
  /// 回调不参与 [Marker] 的相等性与差分判断，因此只替换回调不会触发原生
  /// 覆盖物更新。参与聚合的 Marker 不会触发此回调。拖拽只报告位置，
  /// 调用方需要在此回调中更新自己的 [Marker] 集合以提交新位置。
  final ValueChanged<LatLng>? onDragEnd;

  @override
  MarkerId get mapsId => markerId;

  @override
  Marker clone() => Marker(
    markerId: markerId,
    position: position,
    title: title,
    snippet: snippet,
    visible: visible,
    draggable: draggable,
    alpha: alpha,
    rotation: rotation,
    zIndex: zIndex,
    infoWindow: infoWindow,
    clusterManagerId: clusterManagerId,
    icon: icon,
    anchor: anchor,
    onTap: onTap,
    onDragStart: onDragStart,
    onDrag: onDrag,
    onDragEnd: onDragEnd,
  );

  @override
  Object toJson() => <String, Object?>{
    'markerId': markerId.value,
    'position': position.toJson(),
    'title': title,
    'snippet': snippet,
    'visible': visible,
    'draggable': draggable,
    'alpha': alpha,
    'rotation': rotation,
    'zIndex': zIndex,
    'clusterManagerId': clusterManagerId?.value,
    'icon': icon.toJson(),
    'anchor': <String, double>{'x': anchor.dx, 'y': anchor.dy},
  };

  @override
  bool operator ==(Object other) =>
      other is Marker &&
      other.markerId == markerId &&
      other.position == position &&
      other.title == title &&
      other.snippet == snippet &&
      other.draggable == draggable &&
      other.alpha == alpha &&
      other.rotation == rotation &&
      other.visible == visible &&
      other.zIndex == zIndex &&
      other.infoWindow == infoWindow &&
      other.clusterManagerId == clusterManagerId &&
      other.icon == icon &&
      other.anchor == anchor;

  @override
  int get hashCode => Object.hash(
    markerId,
    position,
    title,
    snippet,
    draggable,
    alpha,
    rotation,
    visible,
    zIndex,
    infoWindow,
    clusterManagerId,
    icon,
    anchor,
  );
}
