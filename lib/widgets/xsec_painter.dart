import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/forecast_models.dart';

class XSectionPainter extends CustomPainter {
  final ForecastResult res;
  final bool isLight;

  XSectionPainter({required this.res, required this.isLight});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fg = isLight ? const Color(0xFF18181B) : const Color(0xFFF4F4F6);
    final muted = isLight
        ? const Color(0x52000000)
        : const Color(0x52FFFFFF);
    final gridColor = isLight
        ? const Color(0x14000000)
        : const Color(0x14FFFFFF);

    const double padL = 38;
    const double padR = 16;
    const double padT = 16;
    const double padB = 26;
    final plotW = w - padL - padR;
    final plotH = h - padT - padB;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final textStyle = TextStyle(
      color: muted,
      fontSize: 10,
      fontFamily: 'monospace',
    );

    void drawText(String text, double x, double y) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x, y));
    }

    for (int alt = 0; alt <= 12; alt += 3) {
      final y = padT + plotH - (alt / 12.0) * plotH;
      canvas.drawLine(Offset(padL, y), Offset(padL + plotW, y), gridPaint);
      drawText('${alt}km', 4, y - 6);
    }

    for (final d in [-300, -150, 0, 150, 300]) {
      final x = padL + ((d + 300) / 600.0) * plotW;
      canvas.drawLine(Offset(x, padT), Offset(x, padT + plotH), gridPaint);
      final label = d == 0 ? '0km' : (d > 0 ? '+$d' : '$d');
      drawText(label, x - 14, h - 17);
    }

    final aodAlpha = isLight
        ? math.min(0.18, res.aod * 0.35)
        : math.min(0.14, res.aod * 0.28);
    final aodPaint = Paint()
      ..color = (isLight ? Colors.black : Colors.white).withValues(alpha: aodAlpha);
    final aodH = (1.8 / 12.0) * plotH;
    canvas.drawRect(
      Rect.fromLTWH(padL, padT + plotH - aodH, plotW, aodH),
      aodPaint,
    );

    void drawCloudBand(double altKm, double thicknessKm, int coverPct, double alpha) {
      final cloudPaint = Paint()
        ..color = (isLight ? const Color(0xFF18181B) : const Color(0xFFF4F4F6))
            .withValues(alpha: alpha);
      final count = math.max(2, (coverPct / 12.0).round());
      for (int i = 0; i < count; i++) {
        final cx = padL + ((i + 0.6) / count) * plotW * 0.85 + (res.quality * 17) % 25;
        final cy = padT + plotH - (altKm / 12.0) * plotH;
        final rx = (plotW / count) * 0.42;
        final ry = (thicknessKm / 12.0) * plotH;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
          cloudPaint,
        );
      }
    }

    drawCloudBand(8.2, 1.1, res.hcc, 0.36);
    drawCloudBand(4.4, 0.9, res.mcc, 0.24);
    drawCloudBand(1.4, 0.6, res.lcc, 0.18);

    final rayPaint = Paint()
      ..color = fg
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final p0 = Offset(padL + plotW, padT + plotH - (0.5 / 12.0) * plotH);
    final p1 = Offset(padL + plotW * 0.5, padT + plotH - (7.8 / 12.0) * plotH);
    final p2 = Offset(padL + plotW * 0.12, padT + plotH - (10.5 / 12.0) * plotH);

    _drawDashedLine(canvas, p0, p1, rayPaint, 5, 4);
    _drawDashedLine(canvas, p1, p2, rayPaint, 5, 4);

    final observerPaint = Paint()..color = fg;
    canvas.drawCircle(
      Offset(padL + plotW * 0.5, padT + plotH),
      3.5,
      observerPaint,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashLen,
    double gapLen,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final total = math.sqrt(dx * dx + dy * dy);
    if (total == 0) return;
    final ux = dx / total;
    final uy = dy / total;

    double dist = 0;
    while (dist < total) {
      final segEnd = math.min(dist + dashLen, total);
      canvas.drawLine(
        Offset(start.dx + ux * dist, start.dy + uy * dist),
        Offset(start.dx + ux * segEnd, start.dy + uy * segEnd),
        paint,
      );
      dist += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant XSectionPainter oldDelegate) =>
      oldDelegate.res != res || oldDelegate.isLight != isLight;
}
