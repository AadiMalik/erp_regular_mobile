import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/branch_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/wishlist_provider.dart';
import '../theme/theme_provider.dart';
import 'main_shell.dart';

/// First screen: loads the ERP-selected theme/settings/session before
/// anything renders, so the app never flashes the wrong colors.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      context.read<ThemeProvider>().loadFromApi(),
      context.read<SettingsProvider>().loadFromApi(),
      context.read<AuthProvider>().restore(),
      context.read<BranchProvider>().load(),
      context.read<WishlistProvider>().load(),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
  }

  @override
  Widget build(BuildContext context) {
    // The real theme isn't loaded yet at this point, so this can't read
    // context.appTheme — fall back to platform brightness instead of a
    // theme1-specific color.
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? Colors.black : Colors.white,
      body: Center(child: CircularProgressIndicator(color: dark ? Colors.white : Colors.black)),
    );
  }
}
