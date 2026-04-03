import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/features/payments/models/transaction_model.dart';
import 'package:parking_user_app/features/payments/models/payment_method_model.dart';

class WalletBalance {
  final double balance;
  final String currency;
  final String currencySymbol;
  final String countryName;
  final String countryCode;
  final double exchangeRate;

  WalletBalance({
    required this.balance,
    required this.currency,
    required this.currencySymbol,
    required this.countryName,
    required this.countryCode,
    required this.exchangeRate,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] ?? 'UGX',
      currencySymbol: json['currency_symbol'] ?? json['currency'] ?? 'UGX',
      countryName: json['country_name'] ?? 'Uganda',
      countryCode: json['country_code'] ?? 'UG',
      exchangeRate: double.tryParse(json['exchange_rate']?.toString() ?? '1') ?? 1.0,
    );
  }
}

class PaymentService {
  final ApiClient _apiClient;

  PaymentService(this._apiClient);

  Future<WalletBalance> getWalletBalance() async {
    try {
      final response = await _apiClient.get('wallet/balance/');
      if (response.statusCode == 200) {
        return WalletBalance.fromJson(response.data);
      }
    } catch (e) {
      print('Error fetching wallet balance: $e');
    }
    return WalletBalance(
      balance: 0.0,
      currency: 'UGX',
      currencySymbol: 'UGX',
      countryName: 'Uganda',
      countryCode: 'UG',
      exchangeRate: 1.0,
    );
  }

  Future<List<Transaction>> getTransactions() async {
    try {
      final response = await _apiClient.get('wallet/transactions/');
      if (response.statusCode == 200) {
        final List data = response.data['results'] ?? response.data;
        return data.map((json) => Transaction.fromJson(json)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<Map<String, dynamic>> topUpWallet({
    required double amount,
    String paymentType = 'MOBILE_MONEY',
  }) async {
    try {
      final response = await _apiClient.post(
        'wallet/topup/',
        data: {
          'amount': amount,
          'payment_type': paymentType,
        },
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'redirect_url': response.data['redirect_url'],
          'order_tracking_id': response.data['order_tracking_id'],
        };
      }
      return {'success': false, 'message': 'Wallet top-up initiation failed'};
    } catch (e) {
      return {'success': false, 'message': 'Wallet top-up initiation failed'};
    }
  }

  Future<Map<String, dynamic>> initiatePesapalPayment({
    required double amount,
    required String description,
    bool isWalletTopup = true,
    String? parkingSessionId,
    String? violationId,
    String? reservationId,
    String paymentType = 'MOBILE_MONEY',
  }) async {
    try {
      final response = await _apiClient.post(
        'payments/pesapal/initiate/',
        data: {
          'amount': amount,
          'description': description,
          'is_wallet_topup': isWalletTopup,
          'payment_type': paymentType,
          if (parkingSessionId?.isNotEmpty ?? false)
            'session_id': parkingSessionId,
          if (violationId?.isNotEmpty ?? false) 'violation_id': violationId,
          if (reservationId?.isNotEmpty ?? false)
            'reservation_id': reservationId,
        },
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'redirect_url': response.data['redirect_url'],
          'order_tracking_id': response.data['order_tracking_id'],
        };
      }
      return {'success': false, 'message': 'Payment initiation failed'};
    } catch (e) {
      return {'success': false, 'message': 'Payment initiation failed'};
    }
  }

  Future<void> preWarmPesapal() async {
    try {
      // Fire and forget pre-warm call
      await _apiClient.get('payments/pesapal/prewarm/');
    } catch (_) {
      // Silent fail - it's just an optimization
    }
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final response = await _apiClient.get('payments/methods/');
      if (response.statusCode == 200) {
        final List data = response.data['results'] ?? response.data;
        return data.map((json) => PaymentMethod.fromJson(json)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<Map<String, dynamic>> executePesapalTokenPayment({
    required double amount,
    required String paymentMethodId,
    String description = 'One-click payment',
  }) async {
    try {
      final response = await _apiClient.post(
        'payments/pesapal/token-execute/',
        data: {
          'amount': amount,
          'payment_method_id': paymentMethodId,
          'description': description,
        },
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'redirect_url': response.data['redirect_url'],
          'order_tracking_id': response.data['order_tracking_id'],
        };
      }
      return {'success': false, 'message': response.data['error'] ?? 'Payment failed'};
    } catch (e) {
      return {'success': false, 'message': 'Payment failed'};
    }
  }

  Future<Map<String, dynamic>> verifyPesapalPayment({
    required String orderTrackingId,
    int retries = 5,
    Duration interval = const Duration(seconds: 2),
  }) async {
    for (var i = 0; i < retries; i++) {
      try {
        final response = await _apiClient.get(
          'transactions/',
          queryParameters: {'search': orderTrackingId},
        );

        if (response.statusCode == 200) {
          final List data = response.data is List
              ? response.data
              : (response.data['results'] ?? []);

          final match = data.cast<Map<String, dynamic>?>().firstWhere(
            (item) =>
                item?['pesapal_order_tracking_id']?.toString() ==
                orderTrackingId,
            orElse: () => null,
          );

          if (match != null) {
            final status = (match['status'] ?? '').toString().toLowerCase();
            if (status == 'completed' || status == 'successful') {
              return {'success': true, 'status': status, 'transaction': match};
            }
            if (status == 'failed' || status == 'cancelled') {
              return {'success': false, 'status': status, 'transaction': match};
            }
          }
        }
      } catch (_) {
        // Best-effort polling; retry until timeout.
      }
      await Future.delayed(interval);
    }

    return {
      'success': false,
      'status': 'pending',
      'message': 'Payment verification timed out',
    };
  }
}
