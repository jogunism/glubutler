import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:glu_butler/l10n/app_localizations.dart';

/// Paywall 화면 - RevenueCat UI 사용
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subscription ?? 'Subscription'),
      ),
      body: PaywallView(
        onDismiss: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// RevenueCat Paywall을 모달로 표시
  static Future<PaywallResult> present(BuildContext context) async {
    return await RevenueCatUI.presentPaywall();
  }
}
