import 'package:parking_user_app/core/api_client.dart';

class RewardsService {
  final ApiClient _api = ApiClient();

  Future<LoyaltyBalanceModel> getBalance() async {
    final response = await _api.get('user/rewards/balance/');
    return LoyaltyBalanceModel.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  Future<List<LoyaltyPointTransactionModel>> getHistory() async {
    final response = await _api.get('user/rewards/history/');
    final dynamic payload = response.data;
    final List<dynamic> values;
    if (payload is List) {
      values = payload;
    } else if (payload is Map && payload['results'] is List) {
      values = payload['results'] as List<dynamic>;
    } else {
      throw const FormatException('The rewards history response was invalid.');
    }
    return values
        .whereType<Map>()
        .map(
          (item) => LoyaltyPointTransactionModel.fromJson(
            item.cast<String, dynamic>(),
          ),
        )
        .toList(growable: false);
  }
}

class LoyaltyBalanceModel {
  final int balance;
  final int lifetimePoints;
  final String tier;

  const LoyaltyBalanceModel({
    required this.balance,
    required this.lifetimePoints,
    required this.tier,
  });

  factory LoyaltyBalanceModel.fromJson(Map<String, dynamic> json) =>
      LoyaltyBalanceModel(
        balance: _int(json['balance']),
        lifetimePoints: _int(json['lifetime_points']),
        tier: json['tier']?.toString() ?? 'Bronze',
      );
}

class LoyaltyPointTransactionModel {
  final int amount;
  final String transactionType;
  final String description;

  const LoyaltyPointTransactionModel({
    required this.amount,
    required this.transactionType,
    required this.description,
  });

  factory LoyaltyPointTransactionModel.fromJson(Map<String, dynamic> json) =>
      LoyaltyPointTransactionModel(
        amount: _int(json['amount']),
        transactionType: json['transaction_type']?.toString() ?? 'Points',
        description: json['description']?.toString() ?? '',
      );
}

int _int(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
