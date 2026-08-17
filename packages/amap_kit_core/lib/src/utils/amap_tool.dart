import 'dart:math';
import 'dart:ui';

import 'package:amap_kit_core/src/types/location.dart';

/// 地球半径（米），用于经纬度距离与面积计算。
const double _earthRadius = 6378137.0;

/// 角度转弧度系数。
const double _degToRad = 0.0174532925199432958;

/// 浮点比较的容差。
const double _epsilon = 1e-9;

/// 点在多边形内判断中，与边界求交的奇偶校验基数。
const int _pointElementSize = 2;

class AMapTools {
  ///根据提供的多边形顶点坐标[points]计算多边形的面积
  static double calculateArea(List<LatLng> points) {
    int triangleCount = 3;
    if (points.length < triangleCount) {
      return 0.0;
    }

    double s = 0;
    double metrePerDegree = _earthRadius * _degToRad;
    int count = points.length;
    for (int i = 0; i < count; ++i) {
      LatLng coordPrev = points[i];
      LatLng coordNext = points[((i + 1) % count)];

      double x1 =
          coordPrev.longitude *
          metrePerDegree *
          cos(coordPrev.latitude * _degToRad);
      double y1 = coordPrev.latitude * metrePerDegree;
      double x2 =
          coordNext.longitude *
          metrePerDegree *
          cos(coordNext.latitude * _degToRad);
      double y2 = coordNext.latitude * metrePerDegree;

      s += x1 * y2 - x2 * y1;
    }
    return (s / 2.0).abs();
  }

  /// 判断坐标点[latLng]是否在多边形[latLngList]内
  static bool latLngIsInPolygon(LatLng latLng, List<LatLng> latLngList) {
    bool isInside = false;
    int count = 0;
    double linePoint1x;
    double linePoint1y;
    double linePoint2x = 180;
    double linePoint2y;

    linePoint1x = latLng.longitude;
    linePoint1y = latLng.latitude;
    linePoint2y = latLng.latitude;

    if (latLngList.length < 3) {
      return false;
    }

    // 复制入参，避免向调用方传入的列表追加首点（就地修改副作用）。
    final List<LatLng> polygon = List<LatLng>.of(latLngList);
    if (polygon[0] != (polygon[polygon.length - 1])) {
      polygon.add(polygon[0]);
    }

    for (int i = 0; i < polygon.length - 1; i++) {
      double cx1 = polygon[i].longitude;
      double cy1 = polygon[i].latitude;
      double cx2 = polygon[i + 1].longitude;
      double cy2 = polygon[i + 1].latitude;
      if (_isPointOnLine(linePoint1x, linePoint1y, cx1, cy1, cx2, cy2)) {
        return true;
      }
      if ((cy2 - cy1).abs() < _epsilon) {
        continue;
      }

      if (_isPointOnLine(
        cx1,
        cy1,
        linePoint1x,
        linePoint1y,
        linePoint2x,
        linePoint2y,
      )) {
        if (cy1 > cy2) {
          count++;
        }
      } else if (_isPointOnLine(
        cx2,
        cy2,
        linePoint1x,
        linePoint1y,
        linePoint2x,
        linePoint2y,
      )) {
        if (cy2 > cy1) {
          count++;
        }
      } else if (_isIntersect(
        cx1,
        cy1,
        cx2,
        cy2,
        linePoint1x,
        linePoint1y,
        linePoint2x,
        linePoint2y,
      )) {
        count++;
      }
    }
    if (count % _pointElementSize != 0) {
      isInside = true;
    }

    return isInside;
  }

  static bool _isPointOnLine(
    double px0,
    double py0,
    double px1,
    double py1,
    double px2,
    double py2,
  ) {
    bool flag = false;
    if (((_multiply(px0, py0, px1, py1, px2, py2).abs()) < _epsilon) &&
        ((px0 - px1) * (px0 - px2) <= 0) &&
        ((py0 - py1) * (py0 - py2) <= 0)) {
      flag = true;
    }
    return flag;
  }

  static double _multiply(
    double px0,
    double py0,
    double px1,
    double py1,
    double px2,
    double py2,
  ) {
    return ((px1 - px0) * (py2 - py0) - (px2 - px0) * (py1 - py0));
  }

  static bool _isIntersect(
    double px1,
    double py1,
    double px2,
    double py2,
    double px3,
    double py3,
    double px4,
    double py4,
  ) {
    bool flag = false;
    double d = (px2 - px1) * (py4 - py3) - (py2 - py1) * (px4 - px3);
    if (d != 0) {
      double r = ((py1 - py3) * (px4 - px3) - (px1 - px3) * (py4 - py3)) / d;
      double s = ((py1 - py3) * (px2 - px1) - (px1 - px3) * (py2 - py1)) / d;
      if ((r >= 0) && (r <= 1) && (s >= 0) && (s <= 1)) {
        flag = true;
      }
    }
    return flag;
  }

  /// 获取点到直线上的垂足
  static Offset getVerticalPointOnLine(
    Offset target,
    Offset begin,
    Offset end,
  ) {
    double dx = begin.dx - end.dx;
    double dy = begin.dy - end.dy;
    if (dx.abs() < 0.00000001 && dy.abs() < 0.00000001) {
      return begin;
    }
    double u =
        ((target.dx - begin.dx) * dx + (target.dy - begin.dy) * dy) /
        (dx * dx + dy * dy);
    return Offset((begin.dx + u * dx), (begin.dy + u * dy));
  }

  ///用haversine公式计算经纬度两点间的距离,
  ///注意：这里将地球当做了一个正球体来计算距离，当经纬度跨度较大时，有轻微的距离误差
  static double distanceBetween(LatLng latLng1, LatLng latLng2) {
    //经纬度转换成弧度
    double lat1 = _convertDegreesToRadians(latLng1.latitude);
    double lon1 = _convertDegreesToRadians(latLng1.longitude);
    double lat2 = _convertDegreesToRadians(latLng2.latitude);
    double lon2 = _convertDegreesToRadians(latLng2.longitude);
    //差值
    double detalLat = (lat1 - lat2).abs();
    double detalLon = (lon1 - lon2).abs();
    //h is the great circle distance in radians, great circle
    //就是一个球体上的切面，它的圆心即是球心的一个周长最大的圆。
    double h =
        _haverSin(detalLat) + cos(lat1) * cos(lat2) * _haverSin(detalLon);
    return (2 * _earthRadius * asin(sqrt(h)));
  }

  static double _haverSin(double theta) {
    var v = sin(theta / 2);
    return v * v;
  }

  /// 将角度换算为弧度。
  static double _convertDegreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
