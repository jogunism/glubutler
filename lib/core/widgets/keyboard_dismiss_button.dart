import 'package:flutter/material.dart';
import 'package:glu_butler/core/theme/app_theme.dart';

/// Keyboard dismiss button overlay widget
///
/// Creates an overlay with a circular button to dismiss the keyboard.
/// Usage:
/// ```dart
/// final focusNode = FocusNode();
/// OverlayEntry? overlayEntry;
///
/// focusNode.addListener(() {
///   if (focusNode.hasFocus) {
///     overlayEntry = KeyboardDismissButton.show(context, focusNode);
///   } else {
///     KeyboardDismissButton.hide(overlayEntry);
///     overlayEntry = null;
///   }
/// });
/// ```
class KeyboardDismissButton {
  KeyboardDismissButton._();

  /// Show the keyboard dismiss button overlay
  static OverlayEntry show(BuildContext context, FocusNode focusNode) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 0,
        right: 0,
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.only(left: 8, right: 0, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppTheme.secondaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    focusNode.unfocus();
                  },
                  icon: const Icon(
                    Icons.keyboard_hide,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    return overlayEntry;
  }

  /// Hide the keyboard dismiss button overlay
  static void hide(OverlayEntry? overlayEntry) {
    overlayEntry?.remove();
  }
}
