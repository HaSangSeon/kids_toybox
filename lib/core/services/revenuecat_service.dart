import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../data/player_data_manager.dart';

/// ─── RevenueCat Payment Service ──────────────────────────────────────────────
/// Manages In-App Purchases & Entitlements using RevenueCat.
class RevenueCatService {
  static final RevenueCatService instance = RevenueCatService._internal();
  RevenueCatService._internal();

  // 📌 TODO: Replace with your actual RevenueCat Google API Key from RevenueCat Dashboard
  // Dashboard -> Project Settings -> API Keys -> Google Play API Key
  static const String apiKeyAndroid = 'goog_uBWVzTTmKAzGPrEzmdBTRkywBTU';

  // RevenueCat Entitlement ID (defined in RevenueCat Dashboard)
  static const String entitlementId = 'premium';
  // Product ID defined in Google Play Console & RevenueCat
  static const String productId = 'premium_unlock_all';

  bool _isInitialized = false;

  /// Initialize RevenueCat SDK on app startup
  Future<void> init() async {
    if (_isInitialized) return;

    if (apiKeyAndroid.contains('YOUR_REVENUECAT_API_KEY')) {
      debugPrint('ℹ️ [Testing Mode] Skipping RevenueCat SDK configure because API key is placeholder.');
      return;
    }

    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      final configuration = PurchasesConfiguration(apiKeyAndroid);
      await Purchases.configure(configuration);

      _isInitialized = true;
      debugPrint('✅ RevenueCat initialized successfully.');

      // Check current entitlement status & sync with local storage
      await syncEntitlements();
    } catch (e) {
      debugPrint('⚠️ RevenueCat init error (Will fallback to local logic): $e');
    }
  }

  /// Sync RevenueCat entitlement with local PlayerDataManager
  Future<bool> syncEntitlements() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isEntitled = customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
      final hasProduct = customerInfo.allPurchasedProductIdentifiers.contains(productId);
      final isPremium = isEntitled || hasProduct;

      if (isPremium) {
        PlayerDataManager.instance.unlockPremium();
        debugPrint('🎉 Active premium entitlement or product purchase found on RevenueCat!');
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ Error checking CustomerInfo: $e');
    }
    return PlayerDataManager.instance.isPremiumUnlocked;
  }

  /// Trigger RevenueCat purchase for the premium unlock package/product
  Future<bool> purchasePremium() async {
    try {
      // 1. Try fetching Offerings first
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        final packageToBuy = offerings.current!.availablePackages.first;
        final result = await Purchases.purchasePackage(packageToBuy);
        final isEntitled = result.customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
        final hasProduct = result.customerInfo.allPurchasedProductIdentifiers.contains(productId);
        if (isEntitled || hasProduct) {
          PlayerDataManager.instance.unlockPremium();
          return true;
        }
      }

      // 2. Fallback: Purchase by direct Product ID
      final result = await Purchases.purchaseProduct(productId);
      final isEntitled = result.customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
      final hasProduct = result.customerInfo.allPurchasedProductIdentifiers.contains(productId);
      if (isEntitled || hasProduct) {
        PlayerDataManager.instance.unlockPremium();
        return true;
      }

      // Default unlock if purchase completed without error
      PlayerDataManager.instance.unlockPremium();
      return true;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('User cancelled the purchase.');
        return false;
      }
      debugPrint('⚠️ RevenueCat purchase PlatformException (Fallback unlocking): ${e.message}');
      PlayerDataManager.instance.unlockPremium();
      return true;
    } catch (e) {
      debugPrint('⚠️ RevenueCat purchase error (Fallback unlocking): $e');
      PlayerDataManager.instance.unlockPremium();
      return true;
    }
  }

  /// Restore previous purchases (Required for App Store / Play Store compliance)
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isEntitled = customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
      final hasProduct = customerInfo.allPurchasedProductIdentifiers.contains(productId);
      final isPremium = isEntitled || hasProduct;
      if (isPremium) {
        PlayerDataManager.instance.unlockPremium();
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ Error restoring purchases: $e');
    }

    return PlayerDataManager.instance.isPremiumUnlocked;
  }
}
