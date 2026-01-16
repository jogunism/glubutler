import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/widgets/glass_icon.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/l10n/app_localizations.dart';

/// Subscription offer page
class SubscriptionPage extends StatefulWidget {
  final VoidCallback onNext;

  const SubscriptionPage({super.key, required this.onNext});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String _selectedPlan = 'yearly'; // monthly, yearly, lifetime
  bool _isProcessing = false;

  Future<void> _handlePurchase() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // TODO: Implement actual purchase logic
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        widget.onNext();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleRestore() async {
    // TODO: Implement restore purchases
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _handleRedeem() async {
    // TODO: Implement redeem code
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        // Main content with scroll
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              24,
              24,
              180,
            ), // Add bottom padding for buttons
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Title
                Text(
                  l10n.onboardingSubscriptionTitle,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  l10n.onboardingSubscriptionSubtitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary(context),
                    height: 1.4,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 32),

                // Star Icon
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.iconAmber.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const GlassIcon(
                      icon: CupertinoIcons.star_fill,
                      color: AppTheme.iconAmber,
                      size: 72,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Features
                _buildFeatureItem(l10n.onboardingSubscriptionFeature1),
                const SizedBox(height: 12),
                _buildFeatureItem(l10n.onboardingSubscriptionFeature2),
                const SizedBox(height: 12),
                _buildFeatureItem(l10n.onboardingSubscriptionFeature3),
                const SizedBox(height: 12),
                _buildFeatureItem(l10n.onboardingSubscriptionFeature4),

                const SizedBox(height: 32),

                // Plan options
                _buildPlanOption(
                  'monthly',
                  l10n.onboardingSubscriptionMonthly,
                  l10n.onboardingSubscriptionMonthlyPrice,
                ),
                const SizedBox(height: 12),
                _buildPlanOption(
                  'yearly',
                  l10n.onboardingSubscriptionYearly,
                  l10n.onboardingSubscriptionYearlyPrice,
                ),

                const SizedBox(height: 0),

                // Redeem and Restore buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _handleRedeem,
                      child: Text(
                        l10n.onboardingSubscriptionRedeem,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    TextButton(
                      onPressed: _handleRestore,
                      child: Text(
                        l10n.onboardingSubscriptionRestore,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Button positioned at bottom
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Skip button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onNext,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    l10n.onboardingSkip,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 0),

              // Purchase button
              OnboardingPrimaryButton(
                text: l10n.onboardingSubscriptionPurchase,
                onPressed: _handlePurchase,
                isLoading: _isProcessing,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 16,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary(context),
              height: 1.4,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanOption(String planId, String title, String price) {
    final isSelected = _selectedPlan == planId;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = planId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : (isDarkMode ? AppTheme.iosCardDark : AppTheme.iosCardLight),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.divider(context),
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.divider(context),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Plan info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            // Price
            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textPrimary(context),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
