import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Jalyuzichi logosi: tepada karniz, ostida tik (vertikal) pardalar.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.3),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: CustomPaint(painter: _LogoPainter()),
    );
    if (!showName) return mark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(height: 12),
        Text(
          'Jalyuzichi',
          style: TextStyle(
            fontSize: size * 0.3,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// Logoni 100x100 o'lchamda chizadi (ilova belgisi bilan bir xil shakl).
class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.onBrand;
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    // Karniz.
    canvas.drawRRect(
      RRect.fromLTRBR(18, 20, 82, 27, const Radius.circular(3.5)),
      paint,
    );

    // Qiya turgan tik pardalar.
    canvas.skew(math.tan(-12 * math.pi / 180), 0);
    canvas.translate(10, 0);
    for (final x in const [24.0, 38.0, 52.0, 66.0]) {
      canvas.drawRRect(
        RRect.fromLTRBR(x, 31, x + 9, 79, const Radius.circular(4.5)),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}
