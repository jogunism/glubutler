import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';

/// 레포트 안내 Bottom Sheet 모달
///
/// 처음 레포트 생성 시 표시되는 안내 모달입니다.
/// "다시 보지 않기" 체크박스를 제공하여 사용자가 선택할 수 있습니다.
class ReportGuideModal {
  static const String _prefKey = 'hide_report_guide';

  /// 레포트 안내 모달 표시
  ///
  /// [context]: BuildContext
  /// [infoMode]: true이면 닫기 버튼만 표시, false이면 체크박스+확인 버튼 표시
  /// Returns: true if user confirmed, false if dismissed
  static Future<bool> show(BuildContext context, {bool infoMode = false}) async {
    // info 모드가 아닐 때만 "다시 보지 않기" 설정 확인
    if (!infoMode) {
      final prefs = await SharedPreferences.getInstance();
      final hideGuide = prefs.getBool(_prefKey) ?? false;

      // 다시 보지 않기 설정되어 있으면 바로 true 반환
      if (hideGuide) {
        return true;
      }
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => _ReportGuideSheet(infoMode: infoMode),
    );

    return result ?? false;
  }
}

class _ReportGuideSheet extends StatefulWidget {
  const _ReportGuideSheet({this.infoMode = false});

  final bool infoMode;

  @override
  State<_ReportGuideSheet> createState() => _ReportGuideSheetState();
}

class _ReportGuideSheetState extends State<_ReportGuideSheet> {
  bool _doNotShowAgain = false;

  Future<void> _onConfirm() async {
    if (_doNotShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(ReportGuideModal._prefKey, true);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _onClose() {
    Navigator.of(context).pop(false);
  }

  Widget _buildConfirmSection(AppLocalizations l10n, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 다시 보지 않기 체크박스
        GestureDetector(
          onTap: () {
            setState(() {
              _doNotShowAgain = !_doNotShowAgain;
            });
          },
          child: Padding(
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.2,
                  child: CupertinoCheckbox(
                    value: _doNotShowAgain,
                    onChanged: (value) {
                      setState(() {
                        _doNotShowAgain = value ?? false;
                      });
                    },
                    activeColor: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.doNotShowAgain,
                  style: context.textStyles.bodyText.copyWith(
                    fontSize: 14,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 확인 버튼
        SizedBox(
          width: double.infinity,
          height: 50,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(12),
            onPressed: _onConfirm,
            child: Text(
              l10n.confirm,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageContent(BuildContext context, AppLocalizations l10n) {
    // 메시지를 줄바꿈으로 분리
    final lines = l10n.reportGuideMessage.split('\n\n');
    final items = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('•')) {
        // Bullet point 항목
        final text = line.substring(1).trim();
        items.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: context.textStyles.bodyText.copyWith(
                  fontSize: 15,
                  height: 1.6,
                  decoration: TextDecoration.none,
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: context.textStyles.bodyText.copyWith(
                    fontSize: 15,
                    height: 1.6,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (line.startsWith('※')) {
        // 개인정보 안내
        final text = line.substring(1).trim();
        items.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '※ ',
                style: context.textStyles.bodyText.copyWith(
                  fontSize: 15,
                  height: 1.6,
                  decoration: TextDecoration.none,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.accentRedColorDarkMode
                      : AppTheme.primaryColor,
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: context.textStyles.bodyText.copyWith(
                    fontSize: 15,
                    height: 1.6,
                    decoration: TextDecoration.none,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.accentRedColorDarkMode
                        : AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // 항목 간 간격
      if (i < lines.length - 1) {
        items.add(const SizedBox(height: 16));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final bottomPadding = mediaQuery.viewInsets.bottom;

    return Container(
      height: screenHeight * 0.75,
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 드래그 핸들
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: context.colors.divider,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
          ),

          // 타이틀
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Stack(
              children: [
                // 닫기 버튼 (info 모드일 때만, 왼쪽 상단)
                if (widget.infoMode)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: _onClose,
                      child: Text(
                        l10n.close,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textSecondary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                // 타이틀 (중앙 정렬)
                Center(
                  child: Text(
                    l10n.reportGuideTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 스크롤 가능한 내용
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildMessageContent(context, l10n),
            ),
          ),

          // 하단 고정 영역 (체크박스 + 확인 버튼, info 모드일 때는 표시 안 함)
          if (!widget.infoMode)
            Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
              decoration: BoxDecoration(
                color: context.colors.background,
                border: Border(
                  top: BorderSide(
                    color: context.colors.divider,
                    width: 0.5,
                  ),
                ),
              ),
              child: _buildConfirmSection(l10n, context),
            ),
        ],
      ),
    );
  }
}
