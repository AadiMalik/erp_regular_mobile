import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/branch_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/theme_x.dart';

/// Store picker. [dismissible] false is the first-run gate (splash, no
/// selection yet); true is the reopen-anytime version from the branch pill.
Future<void> showBranchModal(BuildContext context, {bool dismissible = true}) {
  return showModalBottomSheet(
    context: context,
    isDismissible: dismissible,
    enableDrag: dismissible,
    isScrollControlled: true,
    builder: (_) => _BranchModal(dismissible: dismissible),
  );
}

class _BranchModal extends StatelessWidget {
  final bool dismissible;
  const _BranchModal({required this.dismissible});

  @override
  Widget build(BuildContext context) {
    final branch = context.watch<BranchProvider>();
    final c = context.appTheme.colors;

    return PopScope(
      canPop: dismissible,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select a store', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Pricing, stock, and delivery depend on your store.', style: TextStyle(color: c.textMuted, fontSize: 12.5)),
              const SizedBox(height: 16),
              if (branch.loading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
              else if (branch.branches.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text('No stores available.', style: TextStyle(color: c.textMuted)))
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: branch.branches.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final b = branch.branches[i];
                      final selected = b.id == branch.selectedId;
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          await branch.selectBranch(b.id);
                          // Stock/pricing is branch-scoped - refresh the cart
                          // immediately so it doesn't keep showing the
                          // previous store's figures (mirrors the website's
                          // stores/branch.js selectBranch()).
                          if (context.mounted) {
                            unawaited(context.read<CartProvider>().load(branchId: b.id));
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: selected ? c.primary : c.border, width: selected ? 1.5 : 1),
                            borderRadius: BorderRadius.circular(12),
                            color: selected ? c.primaryLight : null,
                          ),
                          child: Row(
                            children: [
                              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? c.primary : c.textFaint, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    if (b.address != null) Text(b.address!, style: TextStyle(color: c.textMuted, fontSize: 12)),
                                    if (b.hours != null) Text(b.hours!, style: TextStyle(color: c.textFaint, fontSize: 11.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
