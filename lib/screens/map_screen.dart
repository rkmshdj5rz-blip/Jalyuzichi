import 'package:flutter/material.dart';

import '../theme.dart';

/// Xaritadan manzil tanlash. Hozircha namuna: haqiqiy xarita
/// (Google yoki Yandex) keyingi bosqichda ulanadi.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Xaritadan belgilash')),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _MapPainter(dark: dark)),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_on_rounded,
                  size: 52, color: AppColors.brandDark),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Xarita keyingi bosqichda ulanadi. Hozircha namuna.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SafeArea(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Shu manzilni tanlash'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = dark ? const Color(0xFF1E2228) : const Color(0xFFEAF0E6));
    final road = Paint()
      ..color = dark ? const Color(0xFF2E343C) : Colors.white
      ..strokeWidth = 14;
    for (double x = -40; x < size.width; x += 110) {
      canvas.drawLine(Offset(x, 0), Offset(x + 60, size.height), road);
    }
    for (double y = 30; y < size.height; y += 130) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 40), road);
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.dark != dark;
}
