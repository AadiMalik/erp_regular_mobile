import 'package:flutter/material.dart';

import '../theme/theme_x.dart';

const _steps = ['processing', 'shipped', 'out_for_delivery', 'delivered'];
const _stepIcons = [Icons.receipt_long, Icons.inventory_2_outlined, Icons.local_shipping_outlined, Icons.check_circle_outline];
const _stepLabels = ['Processing', 'Shipped', 'Out for Delivery', 'Delivered'];

/// 4-step order status timeline, mirrors OrderTimeline.vue. Falls back to an
/// alt terminal step for cancelled/returned orders instead of the normal 4.
class OrderTimeline extends StatelessWidget {
  final String status;
  final List<Map<String, dynamic>> statusHistory;
  const OrderTimeline({super.key, required this.status, this.statusHistory = const []});

  @override
  Widget build(BuildContext context) {
    final c = context.appTheme.colors;
    final reached = statusHistory.map((h) => '${h['status']}').toSet()..add(status);
    final isAlt = ['cancelled', 'returned', 'return_requested'].contains(status);

    if (isAlt) {
      return Row(
        children: [
          Icon(status == 'cancelled' ? Icons.cancel_outlined : Icons.assignment_return_outlined, color: c.danger),
          const SizedBox(width: 8),
          Text(status == 'cancelled' ? 'Order Cancelled' : 'Return Requested', style: TextStyle(color: c.danger, fontWeight: FontWeight.w700)),
        ],
      );
    }

    final currentIndex = _steps.indexOf(status).clamp(0, _steps.length - 1);

    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftDone = (i - 1) ~/ 2 < currentIndex || reached.contains(_steps[(i - 1) ~/ 2]);
          return Expanded(child: Container(height: 2, color: leftDone ? c.primary : c.border));
        }
        final idx = i ~/ 2;
        final done = idx <= currentIndex || reached.contains(_steps[idx]);
        return Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: done ? c.primary : c.bgAlt,
              child: Icon(_stepIcons[idx], size: 14, color: done ? Colors.white : c.textFaint),
            ),
            const SizedBox(height: 4),
            SizedBox(width: 60, child: Text(_stepLabels[idx], textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, color: done ? c.text : c.textFaint))),
          ],
        );
      }),
    );
  }
}
