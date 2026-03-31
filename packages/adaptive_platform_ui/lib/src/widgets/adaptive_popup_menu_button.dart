import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../platform/platform_info.dart';
import 'ios26/ios26_popup_menu_button.dart';

export 'ios26/ios26_popup_menu_button.dart'
    show
        AdaptivePopupMenuItem,
        AdaptivePopupMenuDivider,
        AdaptivePopupMenuEntry,
        PopupButtonStyle;

/// An adaptive popup menu button that renders platform-specific styles
class AdaptivePopupMenuButton<T> {
  AdaptivePopupMenuButton._();

  /// Creates a text-labeled popup menu button
  static Widget text<T>({
    Key? key,
    required String label,
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<T> entry)
    onSelected,
    Color? tint,
    double height = 32.0,
    bool shrinkWrap = false,
    PopupButtonStyle buttonStyle = PopupButtonStyle.plain,
  }) {
    // iOS 26+ - Use native iOS 26 popup menu button
    if (PlatformInfo.isIOS26OrHigher()) {
      return IOS26PopupMenuButton<T>(
        buttonLabel: label,
        items: items,
        onSelected: onSelected,
        tint: tint,
        height: height,
        shrinkWrap: shrinkWrap,
        buttonStyle: buttonStyle,
      );
    }

    // Android - Use Material PopupMenuButton
    if (PlatformInfo.isAndroid) {
      return _MaterialPopupMenuButton<T>(
        label: label,
        items: items,
        onSelected: onSelected,
        tint: tint,
        height: height,
      );
    }

    // iOS <26 (iOS 18 and below) - Use CupertinoButton with action sheet (iOS fallback)
    return Builder(
      builder: (context) => SizedBox(
        height: height,
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          onPressed: () => _showMenu<T>(context, label, items, onSelected),
          child: Text(label),
        ),
      ),
    );
  }

  /// Creates a popup menu button with a custom child widget
  static Widget widget<T>({
    Key? key,
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<T> entry)
    onSelected,
    Color? tint,
    PopupButtonStyle buttonStyle = PopupButtonStyle.plain,
    required Widget child,
  }) {
    // iOS 26+ - Use gesture detector with native menu
    if (PlatformInfo.isIOS26OrHigher()) {
      return IOS26PopupMenuButton<T>.widget(
        items: items,
        onSelected: onSelected,
        tint: tint,
        buttonStyle: buttonStyle,
        child: child,
      );
    }

    // iOS <26 and Android - Use GestureDetector with action sheet
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => _showMenu<T>(context, null, items, onSelected),
        child: child,
      ),
    );
  }

  /// Creates a round, icon-only popup menu button
  ///
  /// [icon] can be either:
  /// - String (SF Symbol) for iOS 26+
  /// - IconData for iOS <26 and Android
  static Widget icon<T>({
    Key? key,
    required dynamic icon,
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<T> entry)
    onSelected,
    Color? tint,
    double size = 44.0,
    PopupButtonStyle buttonStyle = PopupButtonStyle.glass,
  }) {
    // iOS 26+ - Use native iOS 26 popup menu button (expects String - SF Symbol)
    if (PlatformInfo.isIOS26OrHigher()) {
      return IOS26PopupMenuButton<T>.icon(
        buttonIcon: icon is String ? icon : 'ellipsis.circle',
        items: items,
        onSelected: onSelected,
        tint: tint,
        size: size,
        buttonStyle: buttonStyle,
      );
    }

    // Android - Use Material IconButton with PopupMenu
    if (PlatformInfo.isAndroid) {
      return _MaterialPopupMenuButton<T>.icon(
        icon: icon,
        items: items,
        onSelected: onSelected,
        tint: tint,
        size: size,
      );
    }

    // iOS <26 (iOS 18 and below) - Use icon button with action sheet (iOS fallback)
    return Builder(
      builder: (context) => SizedBox(
        width: size,
        height: size,
        child: CupertinoButton(
          padding: const EdgeInsets.all(4),
          onPressed: () => _showMenu<T>(context, null, items, onSelected),
          child: Icon(icon is IconData ? icon : CupertinoIcons.ellipsis),
        ),
      ),
    );
  }

  static Future<void> _showMenu<T>(
    BuildContext context,
    String? title,
    List<AdaptivePopupMenuEntry> items,
    void Function(int index, AdaptivePopupMenuItem<T> entry) onSelected,
  ) async {
    final int? selected;

    if (PlatformInfo.isAndroid) {
      // Android: centered layer popup dialog
      // Capture colors from the original context before entering dialog.
      // cardColor / colorScheme.surface returns Material 3 seed-generated colors,
      // so we use cardTheme.color (explicitly set by app) and brightness fallback.
      final outerTheme = Theme.of(context);
      final isDark = outerTheme.brightness == Brightness.dark;
      final bgColor = outerTheme.cardTheme.color ??
          (isDark ? const Color(0xFF3A3A55) : Colors.white);
      final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
      final primaryColor = outerTheme.colorScheme.primary;
      final dividerColor =
          isDark ? Colors.grey.shade800 : Colors.grey.shade200;

      selected = await showDialog<int>(
        context: context,
        builder: (ctx) {
          return Dialog(
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    Divider(height: 1, color: dividerColor),
                  ],
                  for (var i = 0; i < items.length; i++)
                    if (items[i] is AdaptivePopupMenuItem<T>) ...[
                      Builder(builder: (ctx2) {
                        final item = items[i] as AdaptivePopupMenuItem<T>;
                        final hasCheckmark = item.icon == 'checkmark';
                        return InkWell(
                          onTap: () => Navigator.of(ctx).pop(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: hasCheckmark
                                        ? primaryColor
                                        : textColor,
                                    fontWeight: hasCheckmark
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                                if (hasCheckmark) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.check,
                                    size: 18,
                                    color: primaryColor,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                      if (i < items.length - 1)
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: dividerColor,
                        ),
                    ],
                ],
              ),
            ),
          );
        },
      );
    } else {
      // iOS: bottom action sheet
      selected = await showCupertinoModalPopup<int>(
        context: context,
        builder: (ctx) {
          return CupertinoActionSheet(
            title: title != null ? Text(title) : null,
            actions: [
              for (var i = 0; i < items.length; i++)
                if (items[i] is AdaptivePopupMenuItem<T>)
                  Builder(builder: (ctx2) {
                    final item = items[i] as AdaptivePopupMenuItem<T>;
                    final hasCheckmark = item.icon == 'checkmark';
                    return CupertinoActionSheetAction(
                      onPressed: () => Navigator.of(ctx).pop(i),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.label),
                          if (hasCheckmark) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              CupertinoIcons.checkmark,
                              size: 18,
                              color: CupertinoColors.activeBlue,
                            ),
                          ],
                        ],
                      ),
                    );
                  })
                else
                  const SizedBox(height: 8),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(),
              isDefaultAction: true,
              child: Text(
                CupertinoLocalizations.of(ctx).cancelButtonLabel,
              ),
            ),
          );
        },
      );
    }

    if (selected != null) {
      final selectedEntry = items[selected];
      if (selectedEntry is AdaptivePopupMenuItem<T>) {
        onSelected(selected, selectedEntry);
      }
    }
  }
}

/// Material implementation of popup menu button for Android
class _MaterialPopupMenuButton<T> extends StatefulWidget {
  const _MaterialPopupMenuButton({
    required this.label,
    required this.items,
    required this.onSelected,
    this.tint,
    this.height = 32.0,
  }) : icon = null,
       size = null;

  const _MaterialPopupMenuButton.icon({
    required this.icon,
    required this.items,
    required this.onSelected,
    this.tint,
    this.size = 44.0,
  }) : label = null,
       height = null;

  final String? label;
  final dynamic icon; // IconData for Android
  final List<AdaptivePopupMenuEntry> items;
  final void Function(int index, AdaptivePopupMenuItem<T> entry) onSelected;
  final Color? tint;
  final double? height;
  final double? size;

  bool get isIconButton => icon != null;

  @override
  State<_MaterialPopupMenuButton<T>> createState() =>
      _MaterialPopupMenuButtonState<T>();
}

class _MaterialPopupMenuButtonState<T>
    extends State<_MaterialPopupMenuButton<T>> {
  @override
  Widget build(BuildContext context) {
    final menuItems = <PopupMenuEntry<int>>[];

    for (var i = 0; i < widget.items.length; i++) {
      if (widget.items[i] is AdaptivePopupMenuDivider) {
        menuItems.add(const PopupMenuDivider());
      } else if (widget.items[i] is AdaptivePopupMenuItem<T>) {
        final item = widget.items[i] as AdaptivePopupMenuItem<T>;
        menuItems.add(
          PopupMenuItem<int>(
            value: i,
            enabled: item.enabled,
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon is IconData
                        ? item.icon as IconData
                        : Icons.circle,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(child: Text(item.label)),
              ],
            ),
          ),
        );
      }
    }

    if (widget.isIconButton) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: PopupMenuButton<int>(
          icon: Icon(
            widget.icon is IconData ? widget.icon as IconData : Icons.more_vert,
            color: widget.tint,
          ),
          itemBuilder: (context) => menuItems,
          onSelected: (index) {
            final selectedEntry = widget.items[index];
            if (selectedEntry is AdaptivePopupMenuItem<T>) {
              widget.onSelected(index, selectedEntry);
            }
          },
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: TextButton(
        onPressed: () {},
        child: PopupMenuButton<int>(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label ?? ''),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
          itemBuilder: (context) => menuItems,
          onSelected: (index) {
            final selectedEntry = widget.items[index];
            if (selectedEntry is AdaptivePopupMenuItem<T>) {
              widget.onSelected(index, selectedEntry);
            }
          },
        ),
      ),
    );
  }
}
