import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  CartTotals _totals = const CartTotals();
  Map<String, dynamic>? _voucher;
  bool _loading = false;

  List<CartItem> get items => _items;
  CartTotals get totals => _totals;
  Map<String, dynamic>? get voucher => _voucher;
  bool get loading => _loading;
  int get count => _items.fold(0, (sum, i) => sum + i.quantity.round());
  num get subtotal => _totals.subtotal;

  // branchId is a required param on every call (not cached) — a stale
  // remembered branch previously meant cart/checkout could price against
  // the wrong store once the user switched branches after the cart first
  // loaded. Callers should always pass BranchProvider.selectedId fresh.

  Future<void> load({String? branchId}) async {
    // See BranchProvider.load: notifying before the first await can fire
    // mid-build when this runs from a screen's initState, so don't notify
    // until the fetch actually resolves.
    _loading = true;
    final res = await CartService.fetchCart(branchId: branchId);
    _items = res.data?.items ?? [];
    _totals = res.data?.totals ?? const CartTotals();
    _voucher = res.data?.voucher;
    _loading = false;
    notifyListeners();
  }

  Future<bool> add(String productId, String productVariationId, {int quantity = 1, String? branchId}) async {
    final res = await CartService.addToCart(
      productId: productId,
      productVariationId: productVariationId,
      quantity: quantity,
      branchId: branchId,
    );
    if (res.success) await load(branchId: branchId);
    return res.success;
  }

  /// Returns null on success, or the server/error message on failure.
  Future<String?> updateQuantity(String cartItemId, num quantity, {String? branchId}) async {
    if (quantity < 1) return remove(cartItemId, branchId: branchId);
    final res = await CartService.updateCartItem(cartItemId, quantity, branchId: branchId);
    await load(branchId: branchId);
    return res.success ? null : (res.message ?? 'Could not update quantity.');
  }

  /// Returns null on success, or the server/error message on failure.
  Future<String?> remove(String cartItemId, {String? branchId}) async {
    final res = await CartService.removeCartItem(cartItemId);
    await load(branchId: branchId);
    return res.success ? null : (res.message ?? 'Could not remove item.');
  }
}
