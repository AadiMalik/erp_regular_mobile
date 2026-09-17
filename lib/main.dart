import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/branch_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/wishlist_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';
import 'theme/theme_provider.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const SmartMartApp());
}

class SmartMartApp extends StatelessWidget {
  const SmartMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => BranchProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: const _SessionExpiredBinder(
        child: _ThemedApp(),
      ),
    );
  }
}

/// Wires ApiClient's 401 hook once the Provider tree exists: clear auth +
/// wishlist state and push LoginScreen so the user is prompted to re-auth.
class _SessionExpiredBinder extends StatefulWidget {
  final Widget child;
  const _SessionExpiredBinder({required this.child});

  @override
  State<_SessionExpiredBinder> createState() => _SessionExpiredBinderState();
}

class _SessionExpiredBinderState extends State<_SessionExpiredBinder> {
  @override
  void initState() {
    super.initState();
    ApiClient.instance.onSessionExpired = () {
      if (!mounted) return;
      context.read<AuthProvider>().handleSessionExpired();
      context.read<WishlistProvider>().clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nav = appNavigatorKey.currentState;
        if (nav == null) return;
        nav.push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    };
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => MaterialApp(
        title: 'Smart Mart',
        debugShowCheckedModeBanner: false,
        navigatorKey: appNavigatorKey,
        theme: themeProvider.toMaterialTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
