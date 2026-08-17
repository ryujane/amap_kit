/// 折线端点的线帽样式。
///
/// 对应 Android `PolylineOptions.LineCapType` 与 iOS `MALineCapType`。Android
/// 与 iOS 均支持三种取值，但默认值在各平台可能不同；显式设置可保证跨平台外观一致。
enum AmapLineCapType {
  /// 平头端点，线条在端点处直接截断。
  butt,

  /// 圆头端点，端点处以半圆收尾。
  round,

  /// 方头端点，端点处以方形向外扩展。
  square,
}

enum AmapDottedLineType {
  /// 圆形，。
  circle,

  /// 方形。
  square,
}

/// 折线与多边形拐点处的连接样式。
///
/// 对应 Android `PolylineOptions.LineJoinType` / `PolygonOptions.lineJoinType`
/// 与 iOS `MALineJoinType`。仅影响拐角处的形状，不改变路径本身。
enum AmapLineJoinType {
  /// 斜切连接，拐角处用直线切平。
  bevel,

  /// 尖角连接，拐角处延伸为尖点。
  miter,

  /// 圆角连接，拐角处以圆弧过渡。
  round,
}
