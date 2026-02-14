import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/features/payments/models/transaction_model.dart';

class PaymentService {
  final ApiClient _apiClient = ApiClient();

  Future<double> getWalletBalance() async {
    try {
      final response = await _apiClient.get('wallet/balance/');
      if (response.statusCode == 200) {
        return double.tryParse(response.data['balance']?.toString() ?? '0') ??
            0.0;
      }
    } catch (e) {
      return 0.0;
    }
    return 0.0;
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

  Future<Map<String, dynamic>> initiatePesapalPayment({
    required double amount,
    required String description,
    bool isWalletTopup = true,
    String? parkingSessionId,
    String? violationId,
    String? reservationId,
  }) async {
    try {
      final response = await _apiClient.post(
        'payments/pesapal/initiate/',
        data: {
          'amount': amount,
          'description': description,
          'is_wallet_topup': isWalletTopup,
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
    } catch (e) {
      return {'success': false, 'message': 'Payment initiation failed'};
    }
    return {'success': false, 'message': 'Payment initiation failed'};
  }
}
