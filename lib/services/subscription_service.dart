import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// Provider pra assinatura
final subscriptionProvider = Provider((ref) => SubscriptionService());

class SubscriptionService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SubscriptionService() {
    _iap.purchaseStream.listen((purchases) {
      for (var purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased) {
          _completePurchase(purchase);
        }
      }
    });
  }

  Stream<bool> isPremium(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['premium'] ?? false);
  }

  Future<void> buySubscription(String productId, String type) async {
    final available = await _iap.isAvailable();
    if (!available) throw Exception('Loja não disponível');
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      throw Exception('Produto não encontrado');
    }
    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _completePurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.purchased) {
      await _firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'subscription': purchase.productID,
        'premium': true,
      });
      await _iap.completePurchase(purchase);
    }
  }
}
