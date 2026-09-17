import 'package:flutter/material.dart';

import '../services/token_storage.dart';
import '../services/wishlist_service.dart';

/// Which products are wishlisted, shared across Home/Category/Shop/Detail/
/// Wishlist screens so a heart tapped on one screen reflects everywhere
/// else without each screen fetching (and possibly drifting out of sync)
/// its own copy.
class WishlistProvider extends ChangeNotifier {
  Set<String> _productIds = {};

  bool isWishlisted(String productId) => _productIds.contains(productId);

  Future<void> load() async {
    // Guest has no wishlist — skip the guaranteed-401 call. Notifying only
    // after the fetch resolves matches BranchProvider/CartProvider's
    // "don't notify before the first await" convention.
    final token = await TokenStorage.instance.read();
    if (token == null) {
      _productIds = {};
      notifyListeners();
      return;
    }
    _productIds = await WishlistService.fetchWishlistedProductIds();
    notifyListeners();
  }

  Future<bool> toggle(String productId) async {
    final res = await WishlistService.toggleWishlist(productId: productId);
    if (res.success) {
      final isWishlisted = res.data is Map ? res.data['is_wishlisted'] == true : !_productIds.contains(productId);
      if (isWishlisted) {
        _productIds.add(productId);
      } else {
        _productIds.remove(productId);
      }
      notifyListeners();
    }
    return res.success;
  }

  void clear() {
    _productIds = {};
    notifyListeners();
  }
}
