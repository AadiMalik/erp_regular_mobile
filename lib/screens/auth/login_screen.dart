import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/social_login_buttons.dart';
import 'captcha_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

/// Email + password sign-in, mirrors the site's LoginView (plain
/// login-password, no OTP step here — OTP is only for signup/reset).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _obscure = true;

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) return;

    String? captchaToken;
    final authSettings = context.read<SettingsProvider>().settings.auth;
    if (authSettings.captchaEnabled) {
      captchaToken = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => CaptchaScreen(siteKey: authSettings.recaptchaSiteKey!)),
      );
      if (!mounted || captchaToken == null) return; // user backed out
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final outcome = await context
        .read<AuthProvider>()
        .loginWithPassword(email: _emailCtrl.text.trim(), password: _passwordCtrl.text, captchaToken: captchaToken);
    if (!mounted) return;
    setState(() => _busy = false);
    _afterLogin(outcome);
  }

  void _afterLogin(ApiOutcome outcome) {
    if (outcome.success) {
      context.read<CartProvider>().load(branchId: context.read<BranchProvider>().selectedId);
      context.read<WishlistProvider>().load();
      Navigator.pop(context);
    } else {
      setState(() => _error = outcome.message);
    }
  }

  Future<void> _loginWithSocial(String provider, String token) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final outcome = provider == 'google' ? await auth.loginWithGoogle(token) : await auth.loginWithFacebook(token);
    if (!mounted) return;
    setState(() => _busy = false);
    _afterLogin(outcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onSubmitted: (_) => _login(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                child: const Text('Forgot password?'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _busy ? null : _login,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Sign In'),
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                Expanded(child: Divider()),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or')),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            SocialLoginButtons(onToken: _loginWithSocial, onError: (m) => setState(() => _error = m)),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                child: const Text("Don't have an account? Create one"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
