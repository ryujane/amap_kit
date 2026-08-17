// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:amap_kit_map_platform_interface/src/types/maps_object.dart';

/// 根据稳定对象 ID 建立对象索引。
Map<MapsObjectId<T>, T> keyByMapsObjectId<T extends MapsObject<T>>(
  Iterable<T> objects,
) {
  return Map<MapsObjectId<T>, T>.fromEntries(
    objects.map(
      (T object) => MapEntry<MapsObjectId<T>, T>(object.mapsId, object.clone()),
    ),
  );
}

/// 序列化对象集合；空集合返回空列表，三个差分字段始终存在（稳定 JSON 契约）。
/// Converts a Set of [MapsObject]s into something serializable in JSON.
Object serializeMapsObjectSet<T>(Set<MapsObject<T>> mapsObjects) {
  return mapsObjects.map<Object>((MapsObject<T> p) => p.toJson()).toList();
}
