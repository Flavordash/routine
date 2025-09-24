import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../utils/logger.dart';

class PurchaseService {
  static const String kMonthlySubscriptionId = 'routine_monthly_sub';
  static const String kYearlySubscriptionId = 'routine_yearly_sub';
  
  static const List<String> _kProductIds = <String>[
    kMonthlySubscriptionId,
    kYearlySubscriptionId,
  ];

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<String> _notFoundIds = <String>[];
  List<ProductDetails> _products = <ProductDetails>[];
  bool _isAvailable = false;
  bool _purchasePending = false;
  String? _queryProductError;

  // Getters
  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  List<ProductDetails> get products => _products;
  List<String> get notFoundIds => _notFoundIds;
  String? get queryProductError => _queryProductError;

  // Callbacks
  Function()? onPurchaseSuccess;
  Function(String error)? onPurchaseError;
  Function()? onRestoreSuccess;
  Function(String error)? onRestoreError;

  Future<void> initialize() async {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (Object error) {
        if (kDebugMode) {
          Logger.instance.error('Purchase stream error: $error');
        }
      },
    );

    await _initStoreInfo();
  }

  Future<void> _initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      _isAvailable = false;
      _products = <ProductDetails>[];
      _purchasePending = false;
      _notFoundIds = <String>[];
      return;
    }

    // iOS setup can be added later if needed

    final ProductDetailsResponse productDetailResponse =
        await _inAppPurchase.queryProductDetails(_kProductIds.toSet());
    
    if (productDetailResponse.error != null) {
      _queryProductError = productDetailResponse.error!.message;
      _isAvailable = false;
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      _queryProductError = 'No products found';
      _isAvailable = false;
      return;
    }

    _products = productDetailResponse.productDetails;
    _notFoundIds = productDetailResponse.notFoundIDs;
    _isAvailable = true;
    _purchasePending = false;
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _purchasePending = true;
      } else {
        _purchasePending = false;
        if (purchaseDetails.status == PurchaseStatus.error) {
          onPurchaseError?.call(purchaseDetails.error?.message ?? 'Purchase failed');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          onPurchaseSuccess?.call();
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> buySubscription(String productId) async {
    if (!_isAvailable) {
      onPurchaseError?.call('Store not available');
      return;
    }

    final ProductDetails? productDetails = _products
        .cast<ProductDetails?>()
        .firstWhere((ProductDetails? product) => product!.id == productId,
            orElse: () => null);

    if (productDetails == null) {
      onPurchaseError?.call('Product not found');
      return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      onRestoreSuccess?.call();
    } catch (error) {
      onRestoreError?.call(error.toString());
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}