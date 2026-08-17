// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show immutable, objectRuntimeType;

/// 唯一标识一个指定类型的地图对象。
@immutable
class MapsObjectId<T> {
  /// 创建一个不可变的地图对象标识。
  const MapsObjectId(this.value);

  /// 标识值。
  final String value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MapsObjectId<T> && value == other.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '${objectRuntimeType(this, 'MapsObjectId')}($value)';
}

/// 地图对象的公共接口。
abstract class MapsObject<T> {
  /// 当前对象的类型化标识。
  MapsObjectId<T> get mapsId;

  /// 返回当前对象的副本。
  T clone();

  /// 将当前对象转换为可序列化值。
  Object toJson();
}
