import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/social_auth_service.dart';

/// Google/Facebook buttons - shown only for the providers enabled in
/// Settings > Social Login & Security. Calls [onToken] with the
/// provider name + token on success, [onError] on failure/cancel.
class SocialLoginButtons extends StatefulWidget {
  final void Function(String provider, String token) onToken;
  final void Function(String message) onError;
  const SocialLoginButtons({super.key, required this.onToken, required this.onError});

  @override
  State<SocialLoginButtons> createState() => _SocialLoginButtonsState();
}

class _SocialLoginButtonsState extends State<SocialLoginButtons> {
  bool _busy = false;

  Future<void> _withGoogle(String clientId) async {
    setState(() => _busy = true);
    try {
      final idToken = await GoogleAuthService.signIn(clientId);
      if (idToken != null) widget.onToken('google', idToken);
    } catch (_) {
      widget.onError('Google sign-in failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withFacebook() async {
    setState(() => _busy = true);
    try {
      final accessToken = await FacebookAuthService.signIn();
      if (accessToken != null) widget.onToken('facebook', accessToken);
    } catch (_) {
      widget.onError('Facebook login failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<SettingsProvider>().settings.auth;
    if (!auth.googleEnabled && !auth.facebookEnabled) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (auth.googleEnabled)
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _withGoogle(auth.googleClientId!),
            icon: const Icon(Icons.g_mobiledata),
            label: const Text('Continue with Google'),
          ),
        if (auth.googleEnabled && auth.facebookEnabled) const SizedBox(height: 10),
        if (auth.facebookEnabled)
          OutlinedButton.icon(
            onPressed: _busy ? null : _withFacebook,
            icon: const Icon(Icons.facebook),
            label: const Text('Continue with Facebook'),
          ),
      ],
    );
  }
}
