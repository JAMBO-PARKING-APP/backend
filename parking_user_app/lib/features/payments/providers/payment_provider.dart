import 'package:flutter/foundation.dart';
import 'package:parking_user_app/features/payments/services/payment_service.dart';
import 'package:parking_user_app/features/payments/models/transaction_model.dart';
import 'package:parking_user_app/features/payments/models/payment_method_model.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentService _paymentService;
  
  WalletBalance? _walletBalance;
  List<Transaction> _transactions = [];
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = false;

  PaymentProvider(this._paymentService);

  WalletBalance? get walletBalance => _walletBalance;
  List<Transaction> get transactions => _transactions;
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  bool get isLoading => _isLoading;

  Future<void> fetchWalletData() async {
    _isLoading = true;
    notifyListeners();
    _walletBalance = await _paymentService.getWalletBalance();
    _transactions = await _paymentService.getTransactions();
    _paymentMethods = await _paymentService.getPaymentMethods();
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> topUpWallet({
    required double amount,
    String paymentType = 'MOBILE_MONEY',
  }) async {
    return await _paymentService.topUpWallet(
      amount: amount,
      paymentType: paymentType,
    );
  }

  Future<Map<String, dynamic>> initiatePesapalPayment({
    required double amount,
    required String description,
    bool isWalletTopup = true,
    String paymentType = 'MOBILE_MONEY',
  }) async {
    return await _paymentService.initiatePesapalPayment(
      amount: amount,
      description: description,
      isWalletTopup: isWalletTopup,
      paymentType: paymentType,
    );
  }

  Future<Map<String, dynamic>> executePesapalTokenPayment({
    required double amount,
    required String paymentMethodId,
    String description = 'One-click payment',
  }) async {
    return await _paymentService.executePesapalTokenPayment(
      amount: amount,
      paymentMethodId: paymentMethodId,
      description: description,
    );
  }
}
