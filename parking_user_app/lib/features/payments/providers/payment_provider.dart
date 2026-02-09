import 'package:flutter/material.dart';
import 'package:parking_user_app/features/payments/models/transaction_model.dart';
import 'package:parking_user_app/features/payments/services/payment_service.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  double _balance = 0.0;
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  double get balance => _balance;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> fetchWalletData() async {
    _isLoading = true;
    notifyListeners();
    _balance = await _paymentService.getWalletBalance();
    _transactions = await _paymentService.getTransactions();
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> initiatePesapalPayment({
    required double amount,
    required String description,
    bool isWalletTopup = true,
  }) async {
    return await _paymentService.initiatePesapalPayment(
      amount: amount,
      description: description,
      isWalletTopup: isWalletTopup,
    );
  }
}
