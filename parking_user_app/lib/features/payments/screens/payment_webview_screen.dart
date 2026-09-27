import 'package:flutter/material.dart';
import 'package:parking_user_app/core/analytics_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebviewScreen extends StatefulWidget {
  const PaymentWebviewScreen({super.key, required this.url});

  final String url;

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logEvent(name: 'payment_checkout_opened');
    final uri = Uri.tryParse(widget.url);
    if (uri == null ||
        !uri.hasScheme ||
        !['http', 'https'].contains(uri.scheme)) {
      throw ArgumentError.value(
        widget.url,
        'url',
        'Expected an HTTP(S) payment URL.',
      );
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Unable to load the payment page.'),
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Secure payment'),
      actions: [
        IconButton(
          tooltip: 'Reload payment page',
          onPressed: _controller.reload,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) const LinearProgressIndicator(),
      ],
    ),
  );
}
