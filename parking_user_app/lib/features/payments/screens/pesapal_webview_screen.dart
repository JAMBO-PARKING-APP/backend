import 'dart:async';
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
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _timeoutTimer;

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
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            _timeoutTimer?.cancel();
            setState(() {
              _isLoading = false;
            });
            // Check if we hit the callback URL
            if (url.contains('pesapal/callback')) {
              Navigator.pop(context, true); // Success
            }
          },
          onWebResourceError: (WebResourceError error) {
            _timeoutTimer?.cancel();
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = error.description;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // 20-second timeout for first page load
    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (_isLoading && mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Connection timed out. Please try again.';
        });
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
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
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
