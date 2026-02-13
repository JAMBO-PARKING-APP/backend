import 'package:parking_user_app/features/common/models/country_model.dart';
import 'vehicle_model.dart';

class User {
  final String id;
  final String phone;
  final String firstName;
  final String lastName;
  final String? email;
  final String role;
  final String? profilePhoto;
  final double walletBalance;
  final List<Vehicle> vehicles;
  final Country? countryDetails;

  User({
    required this.id,
    required this.phone,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.role,
    this.profilePhoto,
    this.walletBalance = 0.0,
    this.vehicles = const [],
    this.countryDetails,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'],
      role: json['role'] ?? '',
      profilePhoto: json['profile_photo'],
      walletBalance:
          double.tryParse(json['wallet_balance']?.toString() ?? '0') ?? 0.0,
      vehicles: (json['vehicles'] as List? ?? [])
          .map((v) => Vehicle.fromJson(v))
          .toList(),
      countryDetails: json['country_details'] != null
          ? Country.fromJson(json['country_details'])
          : null,
    );
  }

  String get fullName => '$firstName $lastName';
}
