import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class VipPurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static const Set<String> _productIds = {
    'strangr_vip_48h',
    'strangr_vip_monthly',
  };

  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;

  void initialize(Function(PurchaseDetails) onPurchaseSuccess) {
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList, onPurchaseSuccess);
      },
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        debugPrint('IAP Stream Error: $error');
      },
    );
    _queryProducts();
  }

  Future<void> _queryProducts() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) return;

    final response = await _iap.queryProductDetails(_productIds);
    if (response.error == null) {
      _products = response.productDetails;
    } else {
      debugPrint('Error querying products: ${response.error}');
    }
  }

  Future<bool> buyProduct(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    return await _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  void _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
    Function(PurchaseDetails) onPurchaseSuccess,
  ) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        onPurchaseSuccess(purchaseDetails);
        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchaseDetails.error}');
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
