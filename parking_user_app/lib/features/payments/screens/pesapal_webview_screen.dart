import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/features/payments/services/payment_service.dart';

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
  final PaymentService _paymentService = PaymentService(ApiClient());

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
              _verifyAndClose();
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
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Secure Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE7ECF3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Color(0xFF0078D4), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your payment is encrypted and processed securely.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE7ECF3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: WebViewWidget(controller: _controller),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.08),
              child: const Center(child: CircularProgressIndicator()),
            ),
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

  Future<void> _verifyAndClose() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final result = await _paymentService.verifyPesapalPayment(
      orderTrackingId: widget.orderTrackingId,
    );
    if (!mounted) return;
    Navigator.pop(context, result['success'] == true);
  }
}
