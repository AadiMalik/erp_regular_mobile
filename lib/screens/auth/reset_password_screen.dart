import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email, code;
  const ResetPasswordScreen({super.key, required this.email, required this.code});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _passwordValid {
    final p = _passwordCtrl.text;
    return p.length >= 8 && p.contains(RegExp(r'[A-Z]')) && p.contains(RegExp(r'[a-z]')) && p.contains(RegExp(r'[0-9]'));
  }

  Future<void> _submit() async {
    if (!_passwordValid) {
      setState(() => _error = 'Password must be 8+ chars with upper, lower, and a number.');
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
    final res = await AuthService.resetPassword(email: widget.email, code: widget.code, password: _passwordCtrl.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!res.success) {
      setState(() => _error = res.message);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated. Please sign in.')));
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  : const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }
}
