import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionService {
  final InAppPurchase _iap = InAppPurchase.instance;
  
  static const String monthlyId = 'obsidian_pro_monthly_199';
  static const String yearlyId = 'obsidian_pro_yearly_1499';
  
  static final Set<String> _productIds = {monthlyId, yearlyId};

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<bool> isAvailable() async {
    return await _iap.isAvailable();
  }

  Future<List<ProductDetails>> getProducts() async {
    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(_productIds);
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('IAP: Products not found: ${response.notFoundIDs}');
      }
      return response.productDetails;
    } catch (e) {
      debugPrint('IAP: Error fetching products: $e');
      return [];
    }
  }

  Future<void> buyProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    if (product.id == monthlyId || product.id == yearlyId) {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }
}
