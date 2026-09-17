import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/social_login_buttons.dart';
import '../legal/policy_page_screen.dart';
import 'captcha_screen.dart';
import 'verify_otp_screen.dart';

/// Mirrors the site's signup: collect details, send an OTP to the email
/// (the password is held here in memory, not sent yet), verify the OTP,
/// then commit the password via set-password once a session token exists.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _busy = false;
  bool _agreedToTerms = false;
  String? _error;

  bool get _passwordValid {
    final p = _passwordCtrl.text;
    return p.length >= 8 && p.contains(RegExp(r'[A-Z]')) && p.contains(RegExp(r'[a-z]')) && p.contains(RegExp(r'[0-9]'));
  }

  Future<void> _sendOtp() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (!_passwordValid) {
      setState(() => _error = 'Password must be 8+ chars with upper, lower, and a number.');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (!_agreedToTerms) {
      setState(() => _error = 'Please agree to the Terms & Conditions to continue.');
      return;
    }
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
    final res = await AuthService.sendOtp(_emailCtrl.text.trim(),
        name: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim(), captchaToken: captchaToken);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!res.success) {
      setState(() => _error = res.message);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerifyOtpScreen(
          email: _emailCtrl.text.trim(),
          onResend: () => AuthService.resendOtp(_emailCtrl.text.trim(), name: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim()),
          onSubmit: (code) => _verify(code),
        ),
      ),
    );
  }

  Future<String?> _verify(String code) async {
    final outcome = await context.read<AuthProvider>().verifyOtp(
          email: _emailCtrl.text.trim(),
          code: code,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
    if (!outcome.success) return outcome.message;

    if (outcome.requiresPassword) {
      final setRes = await AuthService.setPassword(_passwordCtrl.text);
      if (!setRes.success) return setRes.message;
    }

    if (!mounted) return null;
    context.read<CartProvider>().load(branchId: context.read<BranchProvider>().selectedId);
    context.read<WishlistProvider>().load();
    Navigator.of(context).popUntil((r) => r.isFirst);
    return null;
  }

  Future<void> _signupWithSocial(String provider, String token) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final outcome = provider == 'google'
        ? await auth.loginWithGoogle(token, createProfile: true)
        : await auth.loginWithFacebook(token, createProfile: true);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!outcome.success) {
      setState(() => _error = outcome.message);
      return;
    }
    context.read<CartProvider>().load(branchId: context.read<BranchProvider>().selectedId);
    context.read<WishlistProvider>().load();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 14),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            TextField(controller: _passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 14),
            TextField(controller: _confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password')),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(value: _agreedToTerms, onChanged: (v) => setState(() => _agreedToTerms = v ?? false)),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('I agree to the '),
                      _PolicyLink(
                        label: 'Terms & Conditions',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PolicyPageScreen(title: 'Terms & Conditions', slug: 'terms-conditions'))),
                      ),
                      const Text(' and '),
                      _PolicyLink(
                        label: 'Privacy Policy',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PolicyPageScreen(title: 'Privacy Policy', slug: 'privacy-policy'))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _sendOtp,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Continue'),
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
            SocialLoginButtons(onToken: _signupWithSocial, onError: (m) => setState(() => _error = m)),
          ],
        ),
      ),
    );
  }
}

class _PolicyLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PolicyLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
    );
  }
}
