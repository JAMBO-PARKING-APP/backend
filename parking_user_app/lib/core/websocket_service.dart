import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:parking_user_app/core/storage_manager.dart';
import 'package:parking_user_app/core/constants.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  final StorageManager _storageManager = StorageManager();
  bool _isConnected = false;

  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get updates => _controller.stream;

  Timer? _reconnectTimer;

  Future<void> connect() async {
    if (_isConnected) return;

    final token = await _storageManager.getAccessToken();
    if (token == null) {
      debugPrint('[WebSocket] No token, cannot connect.');
      return;
    }

    final wsUrl = '${AppConstants.wsUrl}/parking/?token=$token';

    debugPrint('[WebSocket] Connecting to $wsUrl');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _isConnected = true;
      _reconnectTimer?.cancel();

      _channel!.stream.listen(
        (message) {
          debugPrint('[WebSocket] Received: $message');
          try {
            final data = jsonDecode(message);
            _controller.add(data);
          } catch (e) {
            debugPrint('[WebSocket] Error decoding message: $e');
          }
        },
        onError: (error) {
          debugPrint('[WebSocket] Error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('[WebSocket] Connection closed');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('[WebSocket] Connection failed: $e');
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _channel = null;

    // Attempt reconnection
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('[WebSocket] Reconnecting...');
      connect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
