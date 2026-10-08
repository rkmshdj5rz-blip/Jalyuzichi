import 'package:flutter/material.dart';

import '../theme.dart';

/// Vaqtinchalik logo. Haqiqiy logo tayyor bo'lgach shu vidjet almashtiriladi.
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
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandLight, AppColors.brandDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.3),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Icon(Icons.blinds_rounded,
          color: AppColors.onBrand, size: size * 0.55),
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
