import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../services/orders_service.dart';
import '../../widgets/empty_state.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;

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
    final res = await OrdersService.fetchOrders();
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Could not load orders.';
        _orders = [];
      });
      return;
    }
    final list = (res.data?['data'] as List?) ?? [];
    setState(() {
      _orders = list.cast<Map<String, dynamic>>();
      _loading = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final money = context.watch<SettingsProvider>().money;

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: EmptyStateView(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load orders',
                    text: _error!,
                    ctaLabel: 'Try Again',
                    onCta: _load,
                  ),
                )
              : _orders.isEmpty
                  ? const Center(
                      child: EmptyStateView(icon: Icons.receipt_long_outlined, title: 'No orders yet', text: 'Your placed orders will show up here.'),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (_, i) {
                          final o = _orders[i];
                          final id = '${o['id']}';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Order #${o['orderNumber'] ?? id}'),
                            subtitle: Text('${o['status'] ?? ''}'),
                            trailing: Text(money(o['total'] ?? 0)),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: id))),
                          );
                        },
                      ),
                    ),
    );
  }
}
