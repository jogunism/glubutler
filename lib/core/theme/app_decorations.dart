import 'package:flutter/material.dart';

/// ThemeExtension for app-wide box decorations and shadows.
/// Usage: Theme.of(context).extension<AppDecorations>()!.card
class AppDecorations extends ThemeExtension<AppDecorations> {
  const AppDecorations({
    required this.card,
    required this.cardElevated,
    required this.glass,
    required this.inputField,
    required this.button,
  });

  /// Standard card decoration (iOS-style grouped list)
  final BoxDecoration card;

  /// Elevated card with shadow
  final BoxDecoration cardElevated;

  /// Glass/blur effect decoration
  final BoxDecoration glass;

  /// Input field decoration
  final BoxDecoration inputField;

  /// Button decoration
  final BoxDecoration button;

  /// Light theme decorations (Glu Sight palette)
  static final light = AppDecorations(
    card: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    cardElevated: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    glass: BoxDecoration(
      color: const Color(0x1A4ECDC4), // Mint/Teal 10%
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0x4D4ECDC4), // Mint/Teal 30%
        width: 1,
      ),
    ),
    inputField: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFFE5E5EA), // Light Gray
        width: 1,
      ),
    ),
    button: BoxDecoration(
      color: const Color(0xFFFF6B6B), // Coral/Salmon (accent)
      borderRadius: BorderRadius.circular(14),
    ),
  );

  /// Dark theme decorations (Glu Sight palette)
  static final dark = AppDecorations(
    card: BoxDecoration(
      color: const Color(0xFF2D2D44), // Lighter Navy
      borderRadius: BorderRadius.circular(12),
    ),
    cardElevated: BoxDecoration(
      color: const Color(0xFF2D2D44),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    glass: BoxDecoration(
      color: const Color(0x264ECDC4), // Mint/Teal 15%
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0x664ECDC4), // Mint/Teal 40%
        width: 1,
      ),
    ),
    inputField: BoxDecoration(
      color: const Color(0xFF2D2D44), // Lighter Navy
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFF3D3D5C), // Navy Border
        width: 1,
      ),
    ),
    button: BoxDecoration(
      color: const Color(0xFF9B8FE4), // Lavender/Purple (dark mode accent)
      borderRadius: BorderRadius.circular(14),
    ),
  );

  @override
  AppDecorations copyWith({
    BoxDecoration? card,
    BoxDecoration? cardElevated,
    BoxDecoration? glass,
    BoxDecoration? inputField,
    BoxDecoration? button,
  }) {
    return AppDecorations(
      card: card ?? this.card,
      cardElevated: cardElevated ?? this.cardElevated,
      glass: glass ?? this.glass,
      inputField: inputField ?? this.inputField,
      button: button ?? this.button,
    );
  }

  @override
  AppDecorations lerp(ThemeExtension<AppDecorations>? other, double t) {
    if (other is! AppDecorations) {
      return this;
    }
    return AppDecorations(
      card: BoxDecoration.lerp(card, other.card, t)!,
      cardElevated: BoxDecoration.lerp(cardElevated, other.cardElevated, t)!,
      glass: BoxDecoration.lerp(glass, other.glass, t)!,
      inputField: BoxDecoration.lerp(inputField, other.inputField, t)!,
      button: BoxDecoration.lerp(button, other.button, t)!,
    );
  }
}

/// Extension method for easy access
extension AppDecorationsExtension on BuildContext {
  AppDecorations get decorations =>
      Theme.of(this).extension<AppDecorations>() ?? AppDecorations.light;
}
