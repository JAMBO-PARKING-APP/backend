import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PesapalWebViewScreen extends StatefulWidget {
  final String url;
  final String orderTrackingId;

  const PesapalWebViewScreen({
    super.key,
    required this.url,
    required this.orderTrackingId,
  });

  @override
  State<PesapalWebViewScreen> createState() => _PesapalWebViewScreenState();
}

class _PesapalWebViewScreenState extends State<PesapalWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Check if we hit the callback URL
            if (url.contains('payment-callback')) {
              Navigator.pop(context, true); // Success
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesapal Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
