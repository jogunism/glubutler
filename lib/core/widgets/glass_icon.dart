import 'dart:ui';
import 'package:flutter/material.dart';

class GlassIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const GlassIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular((size + 8) * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.4 : 0.25),
            color.withValues(alpha: isDark ? 0.2 : 0.15),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular((size + 8) * 0.3),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Center(
            child: Icon(
              icon,
              color: color,
              size: size * 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
