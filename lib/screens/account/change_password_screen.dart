import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _passwordValid {
    final p = _passwordCtrl.text;
    return p.length >= 8 && p.contains(RegExp(r'[A-Z]')) && p.contains(RegExp(r'[a-z]')) && p.contains(RegExp(r'[0-9]'));
  }

  Future<void> _submit() async {
    if (_currentCtrl.text.isEmpty) {
      setState(() => _error = 'Enter your current password.');
      return;
    }
    if (!_passwordValid) {
      setState(() => _error = 'New password must be 8+ chars with upper, lower, and a number.');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await AuthService.changePassword(currentPassword: _currentCtrl.text, password: _passwordCtrl.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!res.success) {
      setState(() => _error = res.message);
      return;
    }
    // Server revokes all tokens on a password change, so the local session
    // is dead too — force a fresh sign-in, same as the site.
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated. Please sign in again.')));
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _currentCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
            const SizedBox(height: 14),
            TextField(controller: _passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
            const SizedBox(height: 14),
            TextField(controller: _confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password')),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}
