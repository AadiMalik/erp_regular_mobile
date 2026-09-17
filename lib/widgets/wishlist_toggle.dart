import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/branch_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../screens/auth/login_screen.dart';

/// Shared heart/add-to-cart tap handlers for every ProductCard: a guest is
/// sent to sign in instead of firing a request that would just 401 with no
/// explanation, otherwise the action runs against the shared providers so
/// every screen's state (and ProductCard's own busy/confirmation UI) stays
/// consistent. Both return whether the action itself actually happened
/// (false when redirected to login), which ProductCard uses to decide
/// whether to show a confirmation.
Future<bool> toggleWishlistOrPromptLogin(BuildContext context, String productId) async {
  if (!context.read<AuthProvider>().isLoggedIn) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    return false;
  }
  return context.read<WishlistProvider>().toggle(productId);
}

Future<bool> addToCartOrPromptLogin(BuildContext context, String productId, String variationId, {int quantity = 1}) async {
  if (!context.read<AuthProvider>().isLoggedIn) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    return false;
  }
  final branchId = context.read<BranchProvider>().selectedId;
  return context.read<CartProvider>().add(productId, variationId, quantity: quantity, branchId: branchId);
}
