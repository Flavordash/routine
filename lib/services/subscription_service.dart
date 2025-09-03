import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionService {
  static SubscriptionService? _instance;
  static SubscriptionService get instance => _instance ??= SubscriptionService._();
  
  SubscriptionService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // TODO: Replace with your actual product IDs from App Store Connect / Google Play Console
  static const String _proSubscriptionId = 'routine_pro_monthly'; // Monthly subscription
  static const String _proSubscriptionYearlyId = 'routine_pro_yearly'; // Yearly subscription
  
  static const Set<String> _productIds = {
    _proSubscriptionId,
    _proSubscriptionYearlyId,
  };

  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _purchasePending = false;

  // Callback functions
  Function(bool)? onSubscriptionChanged;
  Function(String)? onError;

  Future<void> initialize() async {
    // Check if in-app purchase is available
    _isAvailable = await _iap.isAvailable();
    
    if (!_isAvailable) {
      print('In-app purchases not available');
      return;
    }

    // Platform-specific initialization can be added later if needed

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => print('Purchase stream done'),
      onError: (error) => print('Purchase stream error: $error'),
    );

    // Load products
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!_isAvailable) return;

    final ProductDetailsResponse response = await _iap.queryProductDetails(_productIds);
    
    if (response.notFoundIDs.isNotEmpty) {
      print('Products not found: ${response.notFoundIDs}');
    }
    
    _products = response.productDetails;
    print('Loaded ${_products.length} products');
    
    for (var product in _products) {
      print('Product: ${product.id} - ${product.title} - ${product.price}');
    }
  }

  Future<void> purchaseSubscription({bool yearly = false}) async {
    if (!_isAvailable) {
      onError?.call('In-app purchases not available');
      return;
    }

    final productId = yearly ? _proSubscriptionYearlyId : _proSubscriptionId;
    final ProductDetails? product = _products.firstWhere(
      (product) => product.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );

    if (product == null) {
      onError?.call('Subscription product not found');
      return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    _purchasePending = true;

    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('Purchase failed: $e');
      _purchasePending = false;
      onError?.call('Purchase failed: $e');
    }
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    try {
      await _iap.restorePurchases();
    } catch (e) {
      print('Restore purchases failed: $e');
      onError?.call('Restore purchases failed: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      print('Purchase update: ${purchaseDetails.status}');
      
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          // Handle pending purchase
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          _handlePurchaseError(purchaseDetails);
          break;
        case PurchaseStatus.canceled:
          print('Purchase canceled');
          _purchasePending = false;
          break;
      }

      // Always finish the transaction
      if (purchaseDetails.pendingCompletePurchase) {
        _iap.completePurchase(purchaseDetails);
      }
    }
  }

  void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) {
    print('Purchase successful: ${purchaseDetails.productID}');
    _purchasePending = false;
    
    // Update user's pro status
    if (_productIds.contains(purchaseDetails.productID)) {
      onSubscriptionChanged?.call(true);
    }
  }

  void _handlePurchaseError(PurchaseDetails purchaseDetails) {
    print('Purchase error: ${purchaseDetails.error}');
    _purchasePending = false;
    onError?.call('Purchase failed: ${purchaseDetails.error?.message ?? 'Unknown error'}');
  }

  // Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    if (!_isAvailable) return false;

    try {
      await _iap.restorePurchases();
      // This is a simplified check - in production you'd want to verify with your backend
      return false; // Will be updated when purchases are restored
    } catch (e) {
      print('Error checking subscription: $e');
    }
    
    return false;
  }

  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;

  void dispose() {
    _subscription.cancel();
  }
}