import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Future<String?> show(BuildContext context, String siteKey) =>
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WebHCaptchaDialog(siteKey: siteKey),
    );

class _WebHCaptchaDialog extends StatefulWidget {
  const _WebHCaptchaDialog({required this.siteKey});

  final String siteKey;

  @override
  State<_WebHCaptchaDialog> createState() => _WebHCaptchaDialogState();
}

class _WebHCaptchaDialogState extends State<_WebHCaptchaDialog> {
  late final JSFunction _messageListener;
  web.HTMLIFrameElement? _iframe;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _messageListener = _handleMessage.toJS;
    web.window.addEventListener('message', _messageListener);
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _messageListener);
    super.dispose();
  }

  void _createIframe(Object element) {
    final iframe = element as web.HTMLIFrameElement;
    iframe.title = 'hCaptcha human verification';
    iframe.style
      ..border = '0'
      ..width = '100%'
      ..height = '100%';
    iframe.src = Uri.base
        .resolve('hcaptcha_challenge.html')
        .replace(queryParameters: {'sitekey': widget.siteKey})
        .toString();
    _iframe = iframe;
  }

  void _handleMessage(web.Event event) {
    final message = event as web.MessageEvent;
    if (message.origin != Uri.base.origin ||
        message.source != _iframe?.contentWindow ||
        !(message.data?.isA<JSString>() ?? false)) {
      return;
    }

    final payload = (message.data! as JSString).toDart;
    if (payload.startsWith('hcaptcha-token:')) {
      final token = payload.substring('hcaptcha-token:'.length);
      if (token.isNotEmpty && mounted) Navigator.of(context).pop(token);
    } else if (payload == 'hcaptcha-expired' && mounted) {
      setState(() {
        _statusMessage = 'Verification expired. Please complete it again.';
      });
    } else if (payload == 'hcaptcha-error' && mounted) {
      setState(() {
        _statusMessage =
            'Verification could not be completed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.sizeOf(context).height * 0.62).clamp(
      300.0,
      480.0,
    );
    return AlertDialog(
      title: const Text('Verify you’re human'),
      content: SizedBox(
        width: 360,
        height: height,
        child: Column(
          children: [
            Expanded(
              child: HtmlElementView.fromTagName(
                tagName: 'iframe',
                onElementCreated: _createIframe,
              ),
            ),
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Semantics(
                  liveRegion: true,
                  child: Text(_statusMessage!, textAlign: TextAlign.center),
                ),
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
}
