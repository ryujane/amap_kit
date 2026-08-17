import 'dart:ui' show Offset;

import 'package:amap_kit_core/amap_kit_core.dart';
import 'package:test/test.dart';

void main() {
  group('LatLng', () {
    test('相同经纬度相等且拥有相同哈希值', () {
      const first = LatLng(31.2304, 121.4737);
      const second = LatLng(31.2304, 121.4737);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('截断纬度并归一化经度', () {
      expect(const LatLng(95, 190), const LatLng(90, -170));
      expect(const LatLng(-95, -190), const LatLng(-90, 170));
    });

    test('支持列表序列化与反序列化', () {
      expect(const LatLng(31, 121).toJson(), <double>[31, 121]);
      expect(LatLng.fromJson(<double>[31, 121]), const LatLng(31, 121));
      expect(LatLng.fromJson(null), isNull);
    });
  });

  group('LatLngBounds', () {
    test('支持跨日期变更线的包含判断', () {
      final bounds = LatLngBounds(
        southwest: const LatLng(-10, 170),
        northeast: const LatLng(10, -170),
      );

      expect(bounds.contains(const LatLng(0, 175)), isTrue);
      expect(bounds.contains(const LatLng(0, -175)), isTrue);
      expect(bounds.contains(const LatLng(0, 0)), isFalse);
    });

    test('支持列表序列化与反序列化', () {
      final bounds = LatLngBounds(
        southwest: const LatLng(30, 120),
        northeast: const LatLng(32, 122),
      );

      expect(LatLngBounds.fromList(bounds.toJson()), equals(bounds));
      expect(LatLngBounds.fromList(null), isNull);
    });
  });

  group('AMapTools', () {
    group('latLngIsInPolygon', () {
      // 逆时针正方形：西南角 (0,0)，东北角 (2,2)。
      final square = <LatLng>[
        const LatLng(0, 0),
        const LatLng(0, 2),
        const LatLng(2, 2),
        const LatLng(2, 0),
      ];

      test('判断点在多边形内部', () {
        expect(AMapTools.latLngIsInPolygon(const LatLng(1, 1), square), isTrue);
        expect(
          AMapTools.latLngIsInPolygon(const LatLng(3, 1), square),
          isFalse,
        );
      });

      test('不修改传入的顶点列表', () {
        final original = List<LatLng>.of(square);
        AMapTools.latLngIsInPolygon(const LatLng(1, 1), square);

        expect(square, equals(original));
        expect(square.length, 4);
      });

      test('顶点数不足三个时返回 false', () {
        expect(
          AMapTools.latLngIsInPolygon(const LatLng(1, 1), const <LatLng>[
            LatLng(0, 0),
            LatLng(1, 1),
          ]),
          isFalse,
        );
      });
    });

    test('calculateArea 计算矩形面积', () {
      final area = AMapTools.calculateArea(<LatLng>[
        const LatLng(0, 0),
        const LatLng(0, 1),
        const LatLng(1, 1),
        const LatLng(1, 0),
      ]);

      // 赤道附近 1°x1° 区域约 12391 平方公里。
      expect(area, closeTo(12391085347.45, 10.0));
    });

    test('distanceBetween 计算两点距离', () {
      final distance = AMapTools.distanceBetween(
        const LatLng(31.2304, 121.4737),
        const LatLng(31.2304, 121.4737),
      );

      expect(distance, closeTo(0, 0.001));
    });

    test('getVerticalPointOnLine 返回垂足', () {
      final foot = AMapTools.getVerticalPointOnLine(
        const Offset(2, 1),
        const Offset(0, 0),
        const Offset(4, 0),
      );

      expect(foot, const Offset(2, 0));
    });
  });
}
