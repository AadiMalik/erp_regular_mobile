import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/voucher_service.dart';
import '../../services/cart_service.dart';
import '../../theme/theme_x.dart';
import '../../widgets/empty_state.dart';
import '../auth/login_screen.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _voucherCtrl = TextEditingController();
  bool _applyingVoucher = false;
  String? _voucherError;
  final Set<String> _removingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  String? get _branchId => context.read<BranchProvider>().selectedId;

  Future<void> _reload() async {
    if (!mounted) return;
    await context.read<CartProvider>().load(branchId: _branchId);
  }

  Future<void> _applyVoucher() async {
    if (_voucherCtrl.text.trim().isEmpty) return;
    setState(() {
      _applyingVoucher = true;
      _voucherError = null;
    });
    final res = await VoucherService.applyVoucher(_voucherCtrl.text.trim(), branchId: _branchId);
    if (!mounted) return;
    setState(() => _applyingVoucher = false);
    if (res.success) {
      _voucherCtrl.clear();
      await context.read<CartProvider>().load(branchId: _branchId);
    } else {
      setState(() => _voucherError = res.message ?? 'Voucher is not applicable.');
    }
  }

  Future<void> _removeVoucher() async {
    await VoucherService.removeVoucher();
    if (!mounted) return;
    await context.read<CartProvider>().load(branchId: _branchId);
  }

  Future<void> _removeItem(String cartItemId) async {
    setState(() => _removingIds.add(cartItemId));
    final err = await context.read<CartProvider>().remove(cartItemId, branchId: _branchId);
    if (!mounted) return;
    setState(() => _removingIds.remove(cartItemId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Removed from cart'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _bumpQuantity(String cartItemId, num nextQty) async {
    final err = await context.read<CartProvider>().updateQuantity(cartItemId, nextQty, branchId: _branchId);
    if (!mounted || err == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final money = context.watch<SettingsProvider>().money;
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    final c = context.appTheme.colors;
    final t = cart.totals;
    final hasOutOfStock = cart.items.any((i) => !i.inStock);

    return Scaffold(
      appBar: AppBar(title: Text('My Cart (${cart.count})')),
      body: !isLoggedIn
          ? Center(
              child: EmptyStateView(
                icon: Icons.lock_outline,
                title: 'Sign in to view your cart',
                text: 'Log in to add items and check out.',
                ctaLabel: 'Sign In',
                onCta: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              ),
            )
          : cart.loading
              ? const Center(child: CircularProgressIndicator())
              : cart.items.isEmpty
                  ? const Center(
                      child: EmptyStateView(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Your cart is empty',
                        text: "Looks like you haven't added anything yet.",
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _reload,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, _) => const Divider(height: 24),
                        itemBuilder: (_, i) {
                          final item = cart.items[i];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(color: c.bgAlt, borderRadius: BorderRadius.circular(10)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    if (item.variation != null) Text(item.variation!, style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(money(item.unitPrice)),
                                        if (item.unitOldPrice != null) ...[
                                          const SizedBox(width: 6),
                                          Text(money(item.unitOldPrice!), style: TextStyle(fontSize: 11.5, color: c.textFaint, decoration: TextDecoration.lineThrough)),
                                        ],
                                      ],
                                    ),
                                    if (!item.inStock) Text('Out of stock', style: TextStyle(color: c.danger, fontSize: 11.5, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(money(item.lineTotal), style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () => _bumpQuantity(item.id, item.quantity - 1),
                                      ),
                                      Text('${item.quantity}'),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: item.availableStock != null && item.quantity >= item.availableStock!
                                            ? null
                                            : () => _bumpQuantity(item.id, item.quantity + 1),
                                      ),
                                    ],
                                  ),
                                  _removingIds.contains(item.id)
                                      ? const Padding(
                                          padding: EdgeInsets.only(right: 12, top: 4),
                                          child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                        )
                                      : TextButton(
                                          onPressed: () => _removeItem(item.id),
                                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                                          child: Text('Remove', style: TextStyle(fontSize: 12, color: c.danger)),
                                        ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
      bottomNavigationBar: (isLoggedIn && cart.items.isNotEmpty)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _voucherRow(cart, c),
                    const SizedBox(height: 10),
                    _totalsRow('Subtotal', t.subtotal, money),
                    if (t.discount > 0) _totalsRow('Discount', -t.discount, money, color: c.primary),
                    if (t.voucherDiscount > 0) _totalsRow('Voucher', -t.voucherDiscount, money, color: c.primary),
                    if (t.shipping > 0) _totalsRow('Shipping', t.shipping, money) else _totalsRow('Shipping', 0, money, freeLabel: true),
                    if (t.tax > 0) _totalsRow(taxLineLabel(t.taxPercent, t.taxType), t.tax, money),
                    if (t.taxDiscount > 0) _totalsRow(taxDiscountLineLabel(t.taxDiscountPercent), t.taxDiscount, money),
                    const Divider(),
                    if (hasOutOfStock)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'One or more items are out of stock. Remove them to continue to checkout.',
                          style: TextStyle(color: c.danger, fontSize: 12),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Total: ${money(t.total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        ElevatedButton(
                          onPressed: hasOutOfStock
                              ? null
                              : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                          child: const Text('Checkout'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _voucherRow(CartProvider cart, dynamic c) {
    final applied = cart.voucher;
    if (applied != null) {
      return Row(
        children: [
          Icon(Icons.local_offer_outlined, size: 16, color: c.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text('${applied['code'] ?? applied['voucher_code'] ?? 'Voucher'} applied', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.primary)),
          ),
          TextButton(onPressed: _removeVoucher, child: const Text('Remove', style: TextStyle(fontSize: 12.5))),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _voucherCtrl,
            decoration: InputDecoration(
              hintText: 'Voucher code',
              isDense: true,
              errorText: _voucherError,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 42,
          child: ElevatedButton(
            onPressed: _applyingVoucher ? null : _applyVoucher,
            child: _applyingVoucher ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Apply'),
          ),
        ),
      ],
    );
  }

  Widget _totalsRow(String label, num amount, String Function(num) money, {Color? color, bool freeLabel = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(freeLabel ? 'FREE' : money(amount), style: TextStyle(fontSize: 13, color: color, fontWeight: color != null ? FontWeight.w700 : null)),
        ],
      ),
    );
  }
}
