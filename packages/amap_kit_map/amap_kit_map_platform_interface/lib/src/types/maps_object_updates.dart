// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart'
    show immutable, objectRuntimeType, setEquals;

import 'package:amap_kit_map_platform_interface/src/types/maps_object.dart';
import 'package:amap_kit_map_platform_interface/src/types/utils/maps_object.dart';

/// 一组地图对象的新增、变更和删除描述。
@immutable
class MapsObjectUpdates<T extends MapsObject<T>> {
  /// 根据更新前后的对象集合计算差分。
  ///
  /// [objectName] 用于 JSON 字段前缀，例如 `circle` 会生成
  /// `circlesToAdd`、`circlesToChange` 和 `circleIdsToRemove`。
  MapsObjectUpdates.from(
    Set<T> previous,
    Set<T> current, {
    required this.objectName,
  }) {
    final Map<MapsObjectId<T>, T> previousObjects = keyByMapsObjectId(previous);
    final Map<MapsObjectId<T>, T> currentObjects = keyByMapsObjectId(current);

    final Set<MapsObjectId<T>> previousObjectIds = previousObjects.keys.toSet();
    final Set<MapsObjectId<T>> currentObjectIds = currentObjects.keys.toSet();

    T idToCurrentObject(MapsObjectId<T> id) => currentObjects[id]!;

    _objectIdsToRemove = Set<MapsObjectId<T>>.unmodifiable(
      previousObjectIds.difference(currentObjectIds),
    );
    _objectsToAdd = Set<T>.unmodifiable(
      currentObjectIds.difference(previousObjectIds).map(idToCurrentObject),
    );

    bool hasChanged(T currentObject) {
      final T? previousObject = previousObjects[currentObject.mapsId];
      return currentObject != previousObject;
    }

    _objectsToChange = Set<T>.unmodifiable(
      currentObjectIds
          .intersection(previousObjectIds)
          .map(idToCurrentObject)
          .where(hasChanged),
    );
  }

  /// JSON 字段使用的对象名称。
  final String objectName;

  /// 待新增对象。
  Set<T> get objectsToAdd => _objectsToAdd;
  late final Set<T> _objectsToAdd;

  /// 待删除对象的 ID。
  Set<MapsObjectId<T>> get objectIdsToRemove => _objectIdsToRemove;
  late final Set<MapsObjectId<T>> _objectIdsToRemove;

  /// 待变更对象。
  Set<T> get objectsToChange => _objectsToChange;
  late final Set<T> _objectsToChange;

  /// 当且仅当新增、变更、删除全部为空时为 `true`，调用方可用它跳过无变更的原生更新。
  bool get isEmpty =>
      _objectsToAdd.isEmpty &&
      _objectIdsToRemove.isEmpty &&
      _objectsToChange.isEmpty;

  /// 转换为差分 JSON。
  Object toJson() {
    final Map<String, Object> updateMap = <String, Object>{};

    void addIfNonNull(String fieldName, Object? value) {
      if (value != null) {
        updateMap[fieldName] = value;
      }
    }

    addIfNonNull('${objectName}sToAdd', serializeMapsObjectSet(_objectsToAdd));
    addIfNonNull(
      '${objectName}sToChange',
      serializeMapsObjectSet(_objectsToChange),
    );
    addIfNonNull(
      '${objectName}IdsToRemove',
      _objectIdsToRemove.map<String>((MapsObjectId<T> id) => id.value).toList(),
    );

    return updateMap;
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MapsObjectUpdates<T> &&
        setEquals(_objectsToAdd, other._objectsToAdd) &&
        setEquals(_objectIdsToRemove, other._objectIdsToRemove) &&
        setEquals(_objectsToChange, other._objectsToChange);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(_objectsToAdd),
    Object.hashAll(_objectIdsToRemove),
    Object.hashAll(_objectsToChange),
  );

  @override
  String toString() =>
      '${objectRuntimeType(this, 'MapsObjectUpdates')}('
      'add: $objectsToAdd, remove: $objectIdsToRemove, '
      'change: $objectsToChange)';
}
