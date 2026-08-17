import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 用 [Canvas] 绘制一枚高德风格的定位标记图标，返回 PNG 编码字节。
///
/// 供 [BitmapDescriptor.bytes] 使用；[color] 用于标记主体颜色。
Future<Uint8List> createCustomMarkerIconImage({
  required Size size,
  required Color color,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);

  final Paint bodyPaint = Paint()
    ..isAntiAlias = true
    ..color = color;

  // 图钉主体：上半部为圆，下半部为指向下方的三角。
  canvas.drawCircle(
    Offset(size.width / 2, size.height * 0.35),
    size.width * 0.26,
    bodyPaint,
  );
  final Path pointer = Path()
    ..moveTo(size.width * 0.24, size.height * 0.5)
    ..lineTo(size.width * 0.76, size.height * 0.5)
    ..lineTo(size.width * 0.5, size.height * 0.96)
    ..close();
  canvas.drawPath(pointer, bodyPaint);

  // 中心的白色圆点。
  canvas.drawCircle(
    Offset(size.width / 2, size.height * 0.35),
    size.width * 0.12,
    Paint()
      ..isAntiAlias = true
      ..color = Colors.white,
  );

  final ui.Image image = await recorder.endRecording().toImage(
    size.width.toInt(),
    size.height.toInt(),
  );
  final ByteData? byteData = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  return byteData!.buffer.asUint8List();
}
