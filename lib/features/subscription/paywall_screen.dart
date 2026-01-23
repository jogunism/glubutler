import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:ui';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/services/subscription_service.dart';

/// Paywall 화면 - 모달 팝업 스타일
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offering? _currentOffering;
  Package? _selectedPackage;
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      if (current != null && current.availablePackages.isNotEmpty) {
        setState(() {
          _currentOffering = current;
          _selectedPackage = current.availablePackages.firstWhere(
            (pkg) =>
                pkg.packageType == PackageType.annual ||
                pkg.identifier.contains('yearly'),
            orElse: () => current.availablePackages.first,
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No subscription packages available';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load subscriptions: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _purchase() async {
    if (_selectedPackage == null || _isPurchasing) return;

    setState(() {
      _isPurchasing = true;
    });

    try {
      final customerInfo = await SubscriptionService.purchase(_selectedPackage!);

      if (customerInfo != null && mounted) {
        Navigator.of(context).pop(true);
      } else {
        if (mounted) {
          setState(() {
            _isPurchasing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
        // Only show error if it's not a user cancellation
        final errorMessage = e.toString().toLowerCase();
        if (!errorMessage.contains('cancel') &&
            !errorMessage.contains('user') &&
            !errorMessage.contains('abort')) {
          _showErrorAlert('Unable to complete purchase. Please try again.');
        }
      }
    }
  }

  Future<void> _restorePurchases() async {
    if (_isPurchasing) return;

    setState(() {
      _isPurchasing = true;
    });

    try {
      await SubscriptionService.restorePurchases();

      if (!mounted) return;

      final isPremium = await SubscriptionService.isPremiumActive();

      if (!mounted) return;

      if (isPremium) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isPurchasing = false;
        });
        _showErrorAlert('No purchases found to restore.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPurchasing = false;
      });
      _showErrorAlert('Unable to restore purchases. Please try again.');
    }
  }

  void _showErrorAlert(String message) {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Notice'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Container(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: mediaQuery.size.height * 0.88,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05), // 95% opaque black
              ),
              child: Column(
              children: [
            // Drag indicator
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),

            // Content
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48.0),
                        child: CupertinoActivityIndicator(radius: 16),
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorState(l10n)
                      : SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                _buildHeroSection(),
                                const SizedBox(height: 32),
                                if (_currentOffering != null)
                                  for (final package
                                      in _currentOffering!.availablePackages)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _buildPricingOption(
                                        context: context,
                                        package: package,
                                        isSelected: _selectedPackage
                                                ?.identifier ==
                                            package.identifier,
                                        onTap: () {
                                          setState(() {
                                            _selectedPackage = package;
                                          });
                                        },
                                      ),
                                    ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
            ),

            // Bottom buttons
            if (!_isLoading)
              Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 12,
                    bottom: bottomPadding + 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Restore button (text button, centered)
                      CupertinoButton(
                        onPressed: _isPurchasing ? null : _restorePurchases,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l10n.restorePurchases,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: CupertinoButton(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(14),
                          onPressed: _isPurchasing ? null : _purchase,
                          child: _isPurchasing
                              ? const CupertinoActivityIndicator(
                                  color: Colors.white)
                              : Text(
                                  'Continue',
                                  style: context.textStyles.buttonText,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        // Main icon image
        Image.asset(
          'assets/images/main_icon.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        // Title
        const Text(
          'Unlock Glu Butler Pro',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              color: AppTheme.primaryColor,
              onPressed: _loadOfferings,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingOption({
    required BuildContext context,
    required Package package,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isYearly = package.packageType == PackageType.annual ||
        package.identifier.contains('yearly');

    String title = isYearly
        ? 'Yearly'
        : package.packageType == PackageType.monthly ||
                package.identifier.contains('monthly')
            ? 'Monthly'
            : package.storeProduct.title;

    final price = package.storeProduct.priceString;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.iosCard(context),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.divider(context),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.shadowPrimary,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
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
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      CupertinoIcons.checkmark,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      if (isYearly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.iconGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Best Value',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (package.storeProduct.description.isNotEmpty &&
                      package.storeProduct.description !=
                          package.storeProduct.title) ...[
                    const SizedBox(height: 2),
                    Text(
                      package.storeProduct.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
