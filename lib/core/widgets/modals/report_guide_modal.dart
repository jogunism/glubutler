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
  /// Returns: true if user confirmed, false if dismissed
  static Future<bool> show(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hideGuide = prefs.getBool(_prefKey) ?? false;

    // 다시 보지 않기 설정되어 있으면 바로 true 반환
    if (hideGuide) {
      return true;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const _ReportGuideSheet(),
    );

    return result ?? false;
  }
}

class _ReportGuideSheet extends StatefulWidget {
  const _ReportGuideSheet();

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

          // 스크롤 가능한 내용
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l10n.reportGuideMessage,
                style: context.textStyles.bodyText.copyWith(
                  height: 1.6,
                  fontSize: 15,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),

          // 하단 고정 영역 (체크박스 + 확인 버튼)
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
            child: Column(
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
            ),
          ),
        ],
      ),
    );
  }
}
