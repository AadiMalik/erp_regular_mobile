import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Google reCAPTCHA v2 checkbox, shown in a WebView (no native Flutter SDK
/// exists for it - see the plan discussion). Pops with the token string on
/// success, or null if the user backs out without completing it.
class CaptchaScreen extends StatefulWidget {
  final String siteKey;
  const CaptchaScreen({super.key, required this.siteKey});

  @override
  State<CaptchaScreen> createState() => _CaptchaScreenState();
}

class _CaptchaScreenState extends State<CaptchaScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'CaptchaChannel',
        onMessageReceived: (message) {
          if (mounted) Navigator.pop(context, message.message);
        },
      )
      ..loadHtmlString(_html(widget.siteKey));
  }

  static String _html(String siteKey) => '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<script src="https://www.google.com/recaptcha/api.js" async defer></script>
</head>
<body style="display:flex;align-items:center;justify-content:center;height:100vh;margin:0;">
<div class="g-recaptcha" data-sitekey="$siteKey" data-callback="onVerify"></div>
<script>function onVerify(token){CaptchaChannel.postMessage(token);}</script>
</body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify you\'re human')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
