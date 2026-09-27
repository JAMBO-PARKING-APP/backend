import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/features/payments/models/transaction_model.dart';

class PaymentsService {
  final ApiClient _api = ApiClient();

  Future<PaymentSummaryModel> getSummary() async {
    final response = await _api.get('user/payments/summary/');
    return PaymentSummaryModel.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  Future<List<TransactionModel>> getTransactions() async {
    final response = await _api.get('user/transactions/');
    return _parseList(
      response.data,
    ).map(TransactionModel.fromJson).toList(growable: false);
  }

  Future<List<InvoiceModel>> getInvoices() async {
    final response = await _api.get('user/invoices/');
    return _parseList(
      response.data,
    ).map(InvoiceModel.fromJson).toList(growable: false);
  }

  Future<List<PaymentMethodModel>> getMethods() async {
    final response = await _api.get('user/payments/methods/');
    return _parseList(
      response.data,
    ).map(PaymentMethodModel.fromJson).toList(growable: false);
  }

  Future<WalletTopUpResult> topUpWallet(double amount) async {
    final response = await _api.post(
      'user/wallet/topup/',
      data: {'amount': amount, 'description': 'Mobile app wallet top-up'},
    );
    final body = (response.data as Map).cast<String, dynamic>();
    return WalletTopUpResult(
      success: body['success'] == true,
      redirectUrl: body['redirect_url']?.toString(),
      message: (body['message'] ?? body['error'])?.toString(),
    );
  }

  List<Map<String, dynamic>> _parseList(dynamic payload) {
    final dynamic list;
    if (payload is List) {
      list = payload;
    } else if (payload is Map && payload['results'] is List) {
      list = payload['results'];
    } else {
      throw const FormatException(
        'The payment service returned an invalid list.',
      );
    }
    return (list as List)
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }
}

class PaymentSummaryModel {
  final double totalPaid;
  final double pendingAmount;
  final double unpaidViolations;
  final int transactionCount;

  const PaymentSummaryModel({
    required this.totalPaid,
    required this.pendingAmount,
    required this.unpaidViolations,
    required this.transactionCount,
  });

  factory PaymentSummaryModel.fromJson(Map<String, dynamic> json) =>
      PaymentSummaryModel(
        totalPaid: _number(json['total_paid']),
        pendingAmount: _number(json['pending_amount']),
        unpaidViolations: _number(json['unpaid_violations']),
        transactionCount: _number(json['transaction_count']).toInt(),
      );
}

class InvoiceModel {
  final String invoiceNumber;
  final DateTime createdAt;

  const InvoiceModel({required this.invoiceNumber, required this.createdAt});

  factory InvoiceModel.fromJson(Map<String, dynamic> json) => InvoiceModel(
    invoiceNumber: (json['invoice_number'] ?? json['id'] ?? '').toString(),
    createdAt:
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
  );
}

class PaymentMethodModel {
  final String label;
  final bool isDefault;

  const PaymentMethodModel({required this.label, required this.isDefault});

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) =>
      PaymentMethodModel(
        label:
            (json['display_name'] ??
                    json['name'] ??
                    json['payment_method'] ??
                    'Payment method')
                .toString(),
        isDefault: json['is_default'] == true,
      );
}

class WalletTopUpResult {
  final bool success;
  final String? redirectUrl;
  final String? message;

  const WalletTopUpResult({
    required this.success,
    this.redirectUrl,
    this.message,
  });
}

double _number(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
