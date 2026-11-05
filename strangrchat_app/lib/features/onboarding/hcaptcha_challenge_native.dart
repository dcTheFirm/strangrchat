import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/tokens.dart';

const _challengeHostname = String.fromEnvironment(
  'HCAPTCHA_HOSTNAME',
  defaultValue: 'captcha.strangrchat.app',
);

Future<String?> show(BuildContext context, String siteKey) =>
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _NativeHCaptchaDialog(siteKey: siteKey, hostname: _challengeHostname),
    );

class _NativeHCaptchaDialog extends StatefulWidget {
  const _NativeHCaptchaDialog({required this.siteKey, required this.hostname});

  final String siteKey;
  final String hostname;

  @override
  State<_NativeHCaptchaDialog> createState() => _NativeHCaptchaDialogState();
}

class _NativeHCaptchaDialogState extends State<_NativeHCaptchaDialog> {
  late final WebViewController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'HCaptchaBridge',
        onMessageReceived: _handleMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (_) {
            if (mounted) {
              setState(
                () => _errorMessage = 'Could not load verification. Check your connection and try again.',
              );
            }
          },
        ),
      )
      ..loadHtmlString(
        _challengeHtml,
        baseUrl: Uri(scheme: 'https', host: widget.hostname).toString(),
      );
  }

  String get _challengeHtml =>
      '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: sans-serif; margin: 16px; }
    #status { color: #786f6d; min-height: 1.4em; }
  </style>
  <script>
    function hcaptchaReady() {
      try {
        hcaptcha.render('captcha', {
          sitekey: ${jsonEncode(widget.siteKey)},
          callback: function(token) {
            HCaptchaBridge.postMessage('token:' + token);
          },
          'expired-callback': function() {
            document.getElementById('status').textContent =
              'Verification expired. Please complete it again.';
          },
          'error-callback': function() {
            document.getElementById('status').textContent =
              'Verification could not be completed. Please try again.';
          }
        });
      } catch (error) {
        document.getElementById('status').textContent =
          'Verification could not be loaded. Please try again.';
      }
    }
    window.hcaptchaOnLoad = hcaptchaReady;
  </script>
  <script src="https://js.hcaptcha.com/1/api.js?onload=hcaptchaOnLoad&render=explicit"
          async defer></script>
</head>
<body>
  <div id="captcha"></div>
  <p id="status" role="status"></p>
</body>
</html>
''';

  void _handleMessage(JavaScriptMessage message) {
    if (!message.message.startsWith('token:')) return;
    final token = message.message.substring('token:'.length);
    if (token.isEmpty || !mounted) return;
    Navigator.of(context).pop(token);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Verify you’re human'),
    content: SizedBox(
      width: 340,
      height: 300,
      child: Column(
        children: [
          Expanded(child: WebViewWidget(controller: _controller)),
          if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppTokens.danger),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
    ],
  );
}
