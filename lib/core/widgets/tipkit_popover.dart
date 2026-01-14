import 'package:flutter/material.dart';
import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';

/// iOS TipKit-style popover widget
class TipKitPopover extends StatelessWidget {
  final Offset targetPosition;
  final Size targetSize;
  final AppLocalizations l10n;
  final int steps;
  final String stepsText;
  final double? distanceKm;
  final double waterLiters;
  final bool hasMenstruation;
  final Animation<double> animation;

  const TipKitPopover({
    super.key,
    required this.targetPosition,
    required this.targetSize,
    required this.l10n,
    required this.steps,
    required this.stepsText,
    required this.distanceKm,
    required this.waterLiters,
    required this.hasMenstruation,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    // Calculate popover position (below the target with some padding)
    final popoverTop = targetPosition.dy + targetSize.height + 12;
    final popoverRight =
        screenSize.width - targetPosition.dx - targetSize.width;

    // Base color (without opacity) - using AppTheme colors
    final baseColor = theme.brightness == Brightness.dark
        ? AppTheme.popoverDark
        : AppTheme.popoverLight;

    return Stack(
      children: [
        // Popover content
        Positioned(
          top: popoverTop,
          right: popoverRight,
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              alignment: Alignment.topRight,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 200),
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: 0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(6), // Small radius
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4), // Only shadow below
                        spreadRadius:
                            -4, // Reduce shadow spread to avoid top shadow
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Steps
                        if (steps > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.directions_walk,
                                color: AppTheme.iconGreen,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  distanceKm != null && distanceKm! > 0
                                      ? '${l10n.steps} $stepsText · ${distanceKm!.toStringAsFixed(1)}km'
                                      : '${l10n.steps} $stepsText',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        // Spacing between items
                        if (steps > 0 && (waterLiters > 0 || hasMenstruation))
                          const SizedBox(height: 8),
                        // Water
                        if (waterLiters > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.local_drink,
                                color: AppTheme.iconBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${l10n.waterIntake} ${waterLiters.toStringAsFixed(1)}L',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        // Spacing between items
                        if (waterLiters > 0 && hasMenstruation)
                          const SizedBox(height: 8),
                        // Menstruation
                        if (hasMenstruation)
                          Row(
                            children: [
                              Icon(
                                Icons.local_florist,
                                color: Colors.pink[400],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.menstrualCycle,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Arrow pointing to target (drawn last to be on top of shadow)
        // Position arrow 10px left from the rightmost edge
        Positioned(
          top: popoverTop - 12,
          right: popoverRight + 10, // Move 10px to the left
          child: FadeTransition(
            opacity: animation,
            child: CustomPaint(
              size: const Size(24, 12),
              painter: _ArrowPainter(color: baseColor.withValues(alpha: 0.9)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the arrow pointing to the target
class _ArrowPainter extends CustomPainter {
  final Color color;

  _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0) // Top point
      ..lineTo(0, size.height) // Bottom left
      ..lineTo(size.width, size.height) // Bottom right
      ..close();

    // Draw arrow without shadow
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => oldDelegate.color != color;
}
