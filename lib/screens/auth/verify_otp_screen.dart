import 'dart:async';

import 'package:flutter/material.dart';

/// Shared 6-digit OTP entry for both the signup and reset-password flows.
/// [onSubmit] does all the purpose-specific work (verify+set-password for
/// signup, or just handing {email, code} to Reset Password) and navigates
/// on success itself — returning null; a non-null return is shown as an
/// error instead.
class VerifyOtpScreen extends StatefulWidget {
  final String email;
  final Future<String?> Function(String code) onSubmit;
  final Future<void> Function() onResend;

  const VerifyOtpScreen({super.key, required this.email, required this.onSubmit, required this.onResend});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    await widget.onResend();
    if (!mounted) return;
    _startCooldown();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A new code has been sent.')));
  }

  Future<void> _submit() async {
    if (_codeCtrl.text.trim().length != 6) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onSubmit(_codeCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Code')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Enter the 6-digit code sent to ${widget.email}'),
            const SizedBox(height: 16),
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(labelText: 'OTP Code'),
              keyboardType: TextInputType.number,
              maxLength: 6,
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Verify'),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _cooldown > 0 ? null : _resend,
                child: Text(_cooldown > 0 ? 'Resend code in ${_cooldown}s' : 'Resend code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
