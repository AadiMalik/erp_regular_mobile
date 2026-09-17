import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/branch_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/theme_x.dart';
import '../widgets/branch_modal.dart';
import 'account/account_screen.dart';
import 'cart/cart_screen.dart';
import 'categories/categories_screen.dart';
import 'home/home_screen.dart';
import 'wishlist/wishlist_screen.dart';

/// Bottom-nav shell — same 5 tabs as BottomNav() in the mobile UI-kit
/// artifact (home / categories / cart / wishlist / account).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [HomeScreen(), CategoriesScreen(), CartScreen(), WishlistScreen(), AccountScreen()];

  @override
  void initState() {
    super.initState();
    context.read<CartProvider>().load(branchId: context.read<BranchProvider>().selectedId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !context.read<BranchProvider>().hasSelection) {
        showBranchModal(context, dismissible: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appTheme.colors;
    final cartCount = context.watch<CartProvider>().count;

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: c.bg,
          indicatorColor: c.primaryLight,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.selected) ? c.primary : c.textFaint,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(color: states.contains(WidgetState.selected) ? c.primary : c.textFaint),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            const NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Categories'),
            NavigationDestination(
              icon: Badge(label: Text('$cartCount'), isLabelVisible: cartCount > 0, child: const Icon(Icons.shopping_cart_outlined)),
              selectedIcon: const Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            const NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Wishlist'),
            const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
          ],
        ),
      ),
    );
  }
}
