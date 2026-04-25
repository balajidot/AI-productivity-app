import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../data/subscription_service.dart';
import '../../../core/providers/providers.dart';
import '../../chat/presentation/feedback_provider.dart';

class SubscriptionState {
  static const Object _noChange = Object();

  final List<ProductDetails> products;
  final bool isLoading;
  final bool isPro;
  final String? error;

  SubscriptionState({
    this.products = const [],
    this.isLoading = false,
    this.isPro = false,
    this.error,
  });

  SubscriptionState copyWith({
    List<ProductDetails>? products,
    bool? isLoading,
    bool? isPro,
    Object? error = _noChange,
  }) {
    return SubscriptionState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isPro: isPro ?? this.isPro,
      error: identical(error, _noChange) ? this.error : error as String?,
    );
  }
}

final subscriptionServiceProvider = Provider((ref) => SubscriptionService());

final subscriptionProvider = NotifierProvider<SubscriptionNotifier, SubscriptionState>(SubscriptionNotifier.new);

class SubscriptionNotifier extends Notifier<SubscriptionState> {
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  @override
  SubscriptionState build() {
    final service = ref.read(subscriptionServiceProvider);
    
    // Listen to purchase stream
    _subscription = service.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) => state = state.copyWith(error: error.toString()),
    );

    ref.onDispose(() => _subscription.cancel());

    // FIX C1: Use Future.microtask instead of direct call to avoid
    // mutating state during the build phase (Riverpod rule).
    Future.microtask(() => _init());

    return SubscriptionState();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final service = ref.read(subscriptionServiceProvider);

    // Step 1: Firestore-லிருந்து existing premium status load பண்ணு
    // (App restart ஆனாலும் premium தெரியணும்)
    try {
      final user = ref.read(currentUserProvider);
      final firestore = ref.read(firestoreServiceProvider);
      if (user != null && firestore != null) {
        final doc = await firestore.getUserProfile();
        if (doc != null) {
          final isPremium = doc['isPremium'] as bool? ?? false;
          final expiryTs = doc['expiryDate'] as dynamic;
          final expiry = expiryTs != null
              ? (expiryTs as dynamic).toDate() as DateTime
              : null;
          final isStillActive = isPremium &&
              expiry != null &&
              expiry.isAfter(DateTime.now());
          if (isStillActive) {
            state = state.copyWith(isPro: true);
          }
        }
      }
    } catch (e) {
      // Firestore error = silent fail, store check-க்கு போ
    }

    // Step 2: Store availability check
    final available = await service.isAvailable();
    if (!available) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final products = await service.getProducts();
    state = state.copyWith(products: products, isLoading: false);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        state = state.copyWith(isLoading: true);
      } else {
        if (purchase.status == PurchaseStatus.error) {
          state = state.copyWith(isLoading: false, error: purchase.error?.message);
        } else if (purchase.status == PurchaseStatus.purchased || 
                   purchase.status == PurchaseStatus.restored) {
          _verifyAndEnablePro(purchase);
        }
        
        if (purchase.pendingCompletePurchase) {
          ref.read(subscriptionServiceProvider).completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _verifyAndEnablePro(PurchaseDetails purchase) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final firestore = ref.read(firestoreServiceProvider);
    if (firestore == null) return;

    // Calculate expiry (1 month or 1 year)
    final now = DateTime.now();
    final expiry = purchase.productID == SubscriptionService.yearlyId 
        ? now.add(const Duration(days: 365)) 
        : now.add(const Duration(days: 30));

    try {
      await firestore.updatePremiumStatus(
        isPremium: true,
        planType: purchase.productID == SubscriptionService.yearlyId ? 'Yearly' : 'Monthly',
        expiryDate: expiry,
        purchaseToken: purchase.purchaseID ?? 'unknown',
      );
      state = state.copyWith(isPro: true, isLoading: false);
      
      // Notify main feedback
      ref.read(feedbackProvider.notifier).showMessage('Zeno Pro activated!');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update status');
    }
  }

  Future<void> subscribe(ProductDetails product) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(subscriptionServiceProvider).buyProduct(product);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> restore() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(subscriptionServiceProvider).restorePurchases();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
