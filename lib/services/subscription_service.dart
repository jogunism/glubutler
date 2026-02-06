import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat 구독 관리 서비스
class SubscriptionService {
  static bool _initialized = false;

  /// RevenueCat SDK 초기화
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('[Subscription] Already initialized');
      return;
    }

    try {
      // Platform-specific API keys from .env
      String apiKey;
      if (Platform.isIOS) {
        apiKey = dotenv.env['REVENUECAT_IOS_API_KEY'] ?? '';
      } else if (Platform.isAndroid) {
        apiKey = dotenv.env['REVENUECAT_ANDROID_API_KEY'] ?? '';
      } else {
        debugPrint('[Subscription] Platform not supported');
        return;
      }

      if (apiKey.isEmpty) {
        debugPrint('[Subscription] API key not found in .env');
        return;
      }

      // Configure RevenueCat
      await Purchases.configure(PurchasesConfiguration(apiKey));

      // Enable debug logs in development
      if (dotenv.env['APP_ENV'] != 'production') {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      _initialized = true;
      debugPrint('[Subscription] Initialized successfully');
    } catch (e) {
      debugPrint('[Subscription] Initialization failed: $e');
    }
  }

  /// 구독 상태 확인 (Premium 구독 여부)
  static Future<bool> isPremiumActive() async {
    if (!_initialized) {
      debugPrint('[Subscription] Not initialized');
      return false;
    }

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final hasPro = customerInfo.entitlements.active.containsKey('premium');
      debugPrint('[Subscription] Premium active: $hasPro');
      return hasPro;
    } catch (e) {
      debugPrint('[Subscription] Error checking premium status: $e');
      return false;
    }
  }

  /// CustomerInfo 가져오기
  static Future<CustomerInfo?> getCustomerInfo() async {
    if (!_initialized) {
      debugPrint('[Subscription] Not initialized');
      return null;
    }

    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('[Subscription] Error getting customer info: $e');
      return null;
    }
  }

  /// 사용 가능한 상품(Offerings) 가져오기
  static Future<Offerings?> getOfferings() async {
    if (!_initialized) {
      debugPrint('[Subscription] Not initialized');
      return null;
    }

    try {
      final offerings = await Purchases.getOfferings();
      debugPrint('[Subscription] Offerings: ${offerings.current?.availablePackages.length}');
      return offerings;
    } catch (e) {
      debugPrint('[Subscription] Error getting offerings: $e');
      return null;
    }
  }

  /// 구매 처리
  static Future<CustomerInfo?> purchase(Package package) async {
    if (!_initialized) {
      debugPrint('[Subscription] Not initialized');
      return null;
    }

    try {
      final purchaseResult = await Purchases.purchasePackage(package);
      debugPrint('[Subscription] Purchase successful');
      return purchaseResult.customerInfo;
    } catch (e) {
      debugPrint('[Subscription] Purchase failed: $e');
      return null;
    }
  }

  /// 구독 복원
  static Future<CustomerInfo?> restorePurchases() async {
    if (!_initialized) {
      debugPrint('[Subscription] Not initialized');
      return null;
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      debugPrint('[Subscription] Restore successful');
      return customerInfo;
    } catch (e) {
      debugPrint('[Subscription] Restore failed: $e');
      return null;
    }
  }

  /// 사용자 ID 설정 (선택사항)
  static Future<void> setUserId(String userId) async {
    if (!_initialized) {
      debugPrint('[Subscription] Not initialized');
      return;
    }

    try {
      await Purchases.logIn(userId);
      debugPrint('[Subscription] User ID set: $userId');
    } catch (e) {
      debugPrint('[Subscription] Error setting user ID: $e');
    }
  }

  /// 로그아웃
  static Future<void> logout() async {
    if (!_initialized) {
      debugPrint('[Subscription] Not initialized');
      return;
    }

    try {
      await Purchases.logOut();
      debugPrint('[Subscription] Logged out');
    } catch (e) {
      debugPrint('[Subscription] Error logging out: $e');
    }
  }

  /// 프로모션 코드 입력 시트 표시 (iOS 14+)
  static Future<void> presentCodeRedemptionSheet() async {
    if (!_initialized) {
      debugPrint('[Subscription] Not initialized');
      return;
    }

    try {
      await Purchases.presentCodeRedemptionSheet();
      debugPrint('[Subscription] Code redemption sheet presented');
    } catch (e) {
      debugPrint('[Subscription] Error presenting code redemption sheet: $e');
    }
  }
}
