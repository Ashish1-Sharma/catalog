import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../constants/plan_constants.dart';

class RevenueCatService {
  static const String _apiKey = 'goog_placeholder_api_key'; // Replace with actual RevenueCat API Key when ready

  static bool _isInitialized = false;

  /// Initialize RevenueCat SDK
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);
      _isInitialized = true;
    } catch (e) {
      debugPrint('RevenueCat init error: $e');
    }
  }

  /// Log in user with backend integer user_id
  static Future<CustomerInfo?> logInUser(int userId) async {
    try {
      if (!_isInitialized) await init();
      LogInResult result = await Purchases.logIn(userId.toString());
      return result.customerInfo;
    } catch (e) {
      debugPrint('RevenueCat logIn error: $e');
      return null;
    }
  }

  /// Purchase subscription package using plan code (catalog_monthly / catalog_monthly_intro50)
  static Future<CustomerInfo?> purchasePlan(String planCode) async {
    try {
      if (!_isInitialized) await init();
      Offerings offerings = await Purchases.getOfferings();
      Package? packageToPurchase;

      if (offerings.current != null) {
        for (var pkg in offerings.current!.availablePackages) {
          if (pkg.storeProduct.identifier == planCode || pkg.identifier == planCode) {
            packageToPurchase = pkg;
            break;
          }
        }
      }

      if (packageToPurchase != null) {
        CustomerInfo customerInfo = await Purchases.purchasePackage(packageToPurchase);
        return customerInfo;
      } else {
        debugPrint('Package $planCode not found in offerings');
        return null;
      }
    } catch (e) {
      debugPrint('RevenueCat purchasePlan error: $e');
      return null;
    }
  }

  /// Check active entitlement status
  static Future<bool> isSubscribed() async {
    try {
      if (!_isInitialized) await init();
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey('pro') ||
             customerInfo.activeSubscriptions.contains(PlanConstants.catalogMonthly) ||
             customerInfo.activeSubscriptions.contains(PlanConstants.catalogMonthlyIntro50);
    } catch (e) {
      debugPrint('RevenueCat getCustomerInfo error: $e');
      return false;
    }
  }
}
