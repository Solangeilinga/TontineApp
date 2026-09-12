// lib/widgets/app_logo.dart
import 'package:flutter/material.dart';
import '../config/app_constants.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool white; // version blanche pour fonds colorés

  const AppLogo({super.key, this.size = 80, this.white = false});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConstants.logoPath,
      width: size,
      height: size,
      color: white ? Colors.white : null,
      errorBuilder: (_, __, ___) => _fallbackLogo(),
    );
  }

  // Fallback si logo.png pas encore placé
  Widget _fallbackLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: white
            ? Colors.white.withValues(alpha: 0.15)
            : const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(
        Icons.savings_rounded,
        size: size * 0.55,
        color: white ? Colors.white : const Color(0xFF1B6B3A),
      ),
    );
  }
}
