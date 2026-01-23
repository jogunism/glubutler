import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/widgets/glass_icon.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/subscription_service.dart';

/// Subscription offer page
class SubscriptionPage extends StatefulWidget {
  final VoidCallback onNext;

  const SubscriptionPage({super.key, required this.onNext});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  Offering? _currentOffering;
  Package? _selectedPackage;
  bool _isLoadingOfferings = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _isLoadingOfferings = true;
    });

    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      if (current != null && current.availablePackages.isNotEmpty) {
        setState(() {
          _currentOffering = current;
          // Default to yearly package
          _selectedPackage = current.availablePackages.firstWhere(
            (pkg) =>
                pkg.packageType == PackageType.annual ||
                pkg.identifier.contains('yearly'),
            orElse: () => current.availablePackages.first,
          );
          _isLoadingOfferings = false;
        });
      } else {
        setState(() {
          _isLoadingOfferings = false;
        });
      }
    } catch (e) {
      debugPrint('[Onboarding Subscription] Error loading offerings: $e');
      setState(() {
        _isLoadingOfferings = false;
      });
    }
  }

  Future<void> _handlePurchase() async {
    if (_selectedPackage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await Purchases.purchasePackage(_selectedPackage!);

      // Check if user has active entitlement
      final isPremium = result.customerInfo.entitlements.active.isNotEmpty;

      if (isPremium && mounted) {
        final settings = context.read<SettingsService>();
        await settings.setProStatus(true);

        if (mounted) {
          // Wait a bit before moving to next page
          await Future.delayed(const Duration(milliseconds: 500));
          widget.onNext();
        }
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        final errorMessage = e.toString();
        // Don't show error if user cancelled
        if (!errorMessage.contains('cancel') &&
            !errorMessage.contains('abort')) {
          final l10n = AppLocalizations.of(context)!;
          _showErrorAlert(l10n.purchaseErrorMessage);
        }
      }
    }
  }

  Future<void> _handleRestore() async {
    final l10n = AppLocalizations.of(context)!;

    // Show loading dialog
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(radius: 16),
                const SizedBox(height: 16),
                Text(
                  l10n.restoringPurchases,
                  style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Restore purchases
      await SubscriptionService.restorePurchases();

      // Check if premium is active
      final isPremium = await SubscriptionService.isPremiumActive();

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        if (isPremium) {
          final settings = context.read<SettingsService>();
          await settings.setProStatus(true);

          // Wait a bit before moving to next page
          await Future.delayed(const Duration(milliseconds: 500));
          widget.onNext();
        } else {
          _showErrorAlert(l10n.restoreNotFoundMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorAlert(l10n.restoreErrorMessage);
      }
    }
  }

  void _showErrorAlert(String message) {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.notice),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Future<void> _handleRedeem() async {
  //   // TODO: Implement redeem code
  //   await Future.delayed(const Duration(milliseconds: 500));
  // }

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

                const SizedBox(height: 32),

                // Plan options - dynamic from offerings
                if (_isLoadingOfferings)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CupertinoActivityIndicator(),
                    ),
                  )
                else if (_currentOffering != null)
                  for (final package in _currentOffering!.availablePackages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPlanOptionFromPackage(package),
                    ),

                const SizedBox(height: 0),

                // Restore button (Redeem commented out)
                Center(
                  child: TextButton(
                    onPressed: _handleRestore,
                    child: Text(
                      l10n.restorePurchases,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     TextButton(
                //       onPressed: _handleRedeem,
                //       child: Text(
                //         l10n.onboardingSubscriptionRedeem,
                //         style: const TextStyle(
                //           fontSize: 15,
                //           fontWeight: FontWeight.w500,
                //           color: AppTheme.primaryColor,
                //           letterSpacing: -0.3,
                //         ),
                //       ),
                //     ),
                //     const SizedBox(width: 24),
                //     TextButton(
                //       onPressed: _handleRestore,
                //       child: Text(
                //         l10n.onboardingSubscriptionRestore,
                //         style: const TextStyle(
                //           fontSize: 15,
                //           fontWeight: FontWeight.w500,
                //           color: AppTheme.primaryColor,
                //           letterSpacing: -0.3,
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
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
                      fontSize: 16,
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
                text: l10n.upgradeToPro,
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

  Widget _buildPlanOptionFromPackage(Package package) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _selectedPackage?.identifier == package.identifier;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final isYearly = package.packageType == PackageType.annual ||
        package.identifier.contains('yearly');

    String title = isYearly
        ? l10n.yearly
        : package.packageType == PackageType.monthly ||
                package.identifier.contains('monthly')
            ? l10n.monthly
            : package.storeProduct.title;

    final price = package.storeProduct.priceString;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = package;
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
