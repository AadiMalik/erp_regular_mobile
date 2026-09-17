import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'reset_password_screen.dart';
import 'verify_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await AuthService.forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (!res.success) {
      setState(() => _error = res.message);
      return;
    }
    final email = _emailCtrl.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerifyOtpScreen(
          email: email,
          onResend: () => AuthService.forgotPassword(email),
          onSubmit: (code) async {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: email, code: code)));
            return null;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Enter your account's email and we'll send a verification code."),
            const SizedBox(height: 16),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send Code'),
            ),
          ],
        ),
      ),
    );
  }
}
