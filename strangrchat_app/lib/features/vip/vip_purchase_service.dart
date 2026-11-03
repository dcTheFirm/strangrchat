import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/network/api_client.dart';

/// Thin Google Play Billing boundary for VIP products.
///
/// Product IDs must exactly match the products configured in Play Console.  A
/// backend should validate [PurchaseDetails.verificationData] before granting
/// an entitlement in production; Phase 5 deliberately keeps that step local.
class VipPurchaseService {
  VipPurchaseService({InAppPurchase? inAppPurchase, ApiClient? apiClient})
      : _iap = inAppPurchase ?? InAppPurchase.instance,
        _apiClient = apiClient ?? ApiClient();

  static const pass48HoursId = 'strangr_vip_48h';
  static const monthlyId = 'strangr_vip_monthly';
  static const productIds = <String>{pass48HoursId, monthlyId};

  final InAppPurchase _iap;
  final ApiClient _apiClient;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _storeAvailable = false;
  List<ProductDetails> _products = const [];
  String? _storeError;

  bool get storeAvailable => _storeAvailable;
  List<ProductDetails> get products => List.unmodifiable(_products);
  String? get storeError => _storeError;

  /// Starts listening before products are queried, so a purchase updated while
  /// the paywall is opening cannot be missed.
  Future<void> initialize({
    required ValueChanged<PurchaseDetails> onPurchaseGranted,
    ValueChanged<String>? onPurchaseValidationFailed,
  }) async {
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = _iap.purchaseStream.listen(
      (purchases) => _handlePurchaseUpdates(
        purchases,
        onPurchaseGranted,
        onPurchaseValidationFailed,
      ),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('VIP purchase stream error: $error');
      },
      onDone: () => _purchaseSubscription?.cancel(),
    );
    await queryProducts();
  }

  Future<void> queryProducts() async {
    _storeError = null;
    _storeAvailable = await _iap.isAvailable();
    if (!_storeAvailable) {
      _products = const [];
      _storeError = 'Google Play Billing is unavailable on this device.';
      return;
    }

    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      _products = const [];
      _storeError = response.error!.message;
      debugPrint('VIP product query failed: ${response.error}');
      return;
    }

    _products = response.productDetails;
    if (response.notFoundIDs.isNotEmpty) {
      _storeError = 'VIP products are not configured in Google Play yet.';
      debugPrint('Missing VIP product IDs: ${response.notFoundIDs.join(', ')}');
    }
  }

  ProductDetails? productFor(String productId) {
    for (final product in _products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  Future<bool> buy(ProductDetails product) {
    // Google Play uses the non-consumable purchase path for subscriptions.
    return _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
    ValueChanged<PurchaseDetails> onPurchaseGranted,
    ValueChanged<String>? onPurchaseValidationFailed,
  ) async {
    for (final purchase in purchases) {
      var validationSucceeded = false;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          debugPrint('VIP purchase pending: ${purchase.productID}');
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final validated = await _validateWithServer(purchase);
          if (validated) {
            validationSucceeded = true;
            onPurchaseGranted(purchase);
          } else {
            onPurchaseValidationFailed?.call(
              'Your purchase could not be validated. Please try restoring it later.',
            );
          }
          break;
        case PurchaseStatus.error:
          debugPrint('VIP purchase failed: ${purchase.error}');
          break;
        case PurchaseStatus.canceled:
          debugPrint('VIP purchase cancelled: ${purchase.productID}');
          break;
      }

      // Acknowledge only a verified entitlement. This lets Google Play retry
      // delivery if the server is temporarily unavailable.
      if (purchase.pendingCompletePurchase &&
          ((purchase.status != PurchaseStatus.purchased &&
              purchase.status != PurchaseStatus.restored) ||
              validationSucceeded)) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<bool> _validateWithServer(PurchaseDetails purchase) async {
    final purchaseToken = purchase.verificationData.serverVerificationData;
    if (purchaseToken.isEmpty) return false;

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/vip/validate-purchase',
        data: {
          'productId': purchase.productID,
          'purchaseToken': purchaseToken,
          'verificationSource': purchase.verificationData.source,
        },
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data?['success'] == true;
    } catch (error) {
      debugPrint('VIP server validation failed: $error');
      return false;
    }
  }

  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
  }
}
