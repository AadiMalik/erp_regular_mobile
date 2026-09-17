import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/branch_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/orders_service.dart';
import '../../services/cart_service.dart';
import '../../theme/theme_x.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/order_timeline.dart';
import '../../widgets/share_sheet.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  String? _error;
  bool _reordering = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await OrdersService.fetchOrder(widget.orderId);
    if (!mounted) return;
    if (!res.success || res.data == null) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Order not found.';
        _order = null;
      });
      return;
    }
    setState(() {
      _order = res.data;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _reorder() async {
    final order = _order;
    if (order == null) return;
    setState(() => _reordering = true);
    final cart = context.read<CartProvider>();
    final branchId = context.read<BranchProvider>().selectedId;
    for (final raw in (order['items'] as List? ?? [])) {
      final it = raw as Map<String, dynamic>;
      final variationId = it['product_variation_id']?.toString();
      if (variationId == null) continue;
      await cart.add('${it['productId']}', variationId, quantity: (it['qty'] as num?)?.round() ?? 1, branchId: branchId);
    }
    if (!mounted) return;
    setState(() => _reordering = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Items added to cart.')));
  }

  @override
  Widget build(BuildContext context) {
    final money = context.watch<SettingsProvider>().money;
    final c = context.appTheme.colors;
    final order = _order;
    final items = (order?['items'] as List?) ?? [];
    final status = '${order?['status'] ?? 'processing'}';
    final history = ((order?['statusHistory'] as List?) ?? []).cast<Map<String, dynamic>>();
    final paymentMethod = order?['paymentMethod'] as Map<String, dynamic>?;
    final placedAt = order?['placedAt'] as String?;

    return Scaffold(
      appBar: AppBar(title: Text('Order #${order?['orderNumber'] ?? widget.orderId}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: EmptyStateView(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load order',
                    text: _error!,
                    ctaLabel: 'Try Again',
                    onCta: _load,
                  ),
                )
              : order == null
                  ? const Center(child: Text('Order not found'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (placedAt != null)
                          Text(
                            'Placed ${DateTime.tryParse(placedAt)?.toLocal().toString().split('.').first ?? placedAt}',
                            style: TextStyle(color: c.textMuted, fontSize: 12),
                          ),
                        const SizedBox(height: 14),
                        OrderTimeline(status: status, statusHistory: history),
                        const Divider(height: 32),
                        const Text('Items', style: TextStyle(fontWeight: FontWeight.w700)),
                        ...items.map((raw) {
                          final it = raw as Map<String, dynamic>;
                          final qty = (it['qty'] as num?) ?? 1;
                          final lineTotal = (it['lineTotal'] as num?) ?? 0;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${it['name'] ?? ''}'),
                            subtitle: Text('${it['variation'] != null ? '${it['variation']} · ' : ''}Qty ${it['qty'] ?? 1}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(money(lineTotal)),
                                IconButton(
                                  icon: const Icon(Icons.share_outlined, size: 18),
                                  tooltip: 'Share this product',
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () => showShareSheet(
                                    context,
                                    productId: '${it['productId']}',
                                    name: '${it['name'] ?? ''}',
                                    image: it['image'] as String?,
                                    slug: it['slug'] as String?,
                                    price: qty > 0 ? lineTotal / qty : lineTotal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 32),
                        _row('Subtotal', money(order['subtotal'] ?? 0)),
                        if ((order['discount'] ?? 0) > 0) _row('Discount', '-${money(order['discount'])}'),
                        if ((order['shipping'] ?? 0) > 0) _row('Shipping', money(order['shipping'])),
                        if ((order['tax'] ?? 0) > 0) _row(taxLineLabel(order['taxPercent'] ?? 0, order['taxType'] ?? 'exclusive'), money(order['tax'])),
                        if ((order['taxDiscount'] ?? 0) > 0) _row(taxDiscountLineLabel(order['taxDiscountPercent'] ?? 0), money(order['taxDiscount'])),
                        const SizedBox(height: 4),
                        Text('Total: ${money(order['total'] ?? 0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const Divider(height: 32),
                        if (order['deliveryAddress'] != null) ...[
                          Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
                          const SizedBox(height: 4),
                          Text('${order['deliveryAddress']}', style: TextStyle(color: c.textSoft)),
                          const SizedBox(height: 16),
                        ],
                        if (paymentMethod != null) ...[
                          Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
                          const SizedBox(height: 4),
                          Text('${paymentMethod['name'] ?? paymentMethod['code'] ?? ''} · ${order['paymentStatus'] ?? ''}', style: TextStyle(color: c.textSoft)),
                          const SizedBox(height: 16),
                        ],
                        OutlinedButton(
                          onPressed: _reordering ? null : _reorder,
                          child: _reordering
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Reorder'),
                        ),
                      ],
                    ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value)]),
      );
}
