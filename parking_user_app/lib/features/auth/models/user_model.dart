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
    try {
      // Parse id field
      final id = json['id'] ?? '';
      print('[User.fromJson] Parsed id: $id');

      // Parse phone field
      final phone = json['phone'] ?? '';
      print('[User.fromJson] Parsed phone: $phone');

      // Parse firstName field
      final firstName = json['first_name'] ?? '';
      print('[User.fromJson] Parsed firstName: $firstName');

      // Parse lastName field
      final lastName = json['last_name'] ?? '';
      print('[User.fromJson] Parsed lastName: $lastName');

      // Parse email field (nullable)
      final email = json['email'] as String?;
      print('[User.fromJson] Parsed email: $email');

      // Parse role field
      final role = json['role'] ?? '';
      print('[User.fromJson] Parsed role: $role');

      // Parse profilePhoto field (nullable)
      final profilePhoto = json['profile_photo'] as String?;
      print('[User.fromJson] Parsed profilePhoto: $profilePhoto');

      // Parse walletBalance field with safe conversion
      final walletBalance = double.tryParse(json['wallet_balance']?.toString() ?? '0') ?? 0.0;
      print('[User.fromJson] Parsed walletBalance: $walletBalance');

      // Parse vehicles list with error handling
      final List<Vehicle> vehicles = [];
      try {
        final vehiclesList = json['vehicles'] as List?;
        if (vehiclesList != null && vehiclesList.isNotEmpty) {
          for (int i = 0; i < vehiclesList.length; i++) {
            try {
              final vehicle = Vehicle.fromJson(vehiclesList[i] as Map<String, dynamic>);
              vehicles.add(vehicle);
              print('[User.fromJson] Successfully parsed vehicle at index $i');
            } catch (e) {
              print('[User.fromJson] Error parsing vehicle at index $i: $e');
              // Skip malformed vehicle entry
              continue;
            }
          }
        }
        print('[User.fromJson] Parsed vehicles: ${vehicles.length} vehicle(s)');
      } catch (e) {
        print('[User.fromJson] Error parsing vehicles list: $e');
        // Fallback to empty list
      }

      // Parse countryDetails with error handling
      Country? countryDetails;
      try {
        if (json['country_details'] != null) {
          countryDetails = Country.fromJson(json['country_details']);
          print('[User.fromJson] Successfully parsed countryDetails');
        } else {
          print('[User.fromJson] countryDetails is null');
        }
      } catch (e) {
        print('[User.fromJson] Error parsing countryDetails: $e');
        countryDetails = null;
        // Fallback to null
      }

      return User(
        id: id,
        phone: phone,
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: role,
        profilePhoto: profilePhoto,
        walletBalance: walletBalance,
        vehicles: vehicles,
        countryDetails: countryDetails,
      );
    } catch (e) {
      print('[User.fromJson] Critical error parsing User from JSON: $e');
      // Return a default User object with safe defaults
      return User(
        id: '',
        phone: '',
        firstName: 'Unknown',
        lastName: 'User',
        email: null,
        role: 'user',
        profilePhoto: null,
        walletBalance: 0.0,
        vehicles: [],
        countryDetails: null,
      );
    }
  }

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'role': role,
      'profile_photo': profilePhoto,
      'wallet_balance': walletBalance,
      'vehicles': vehicles.map((v) => v.toJson()).toList(),
      'country_details': countryDetails?.toJson(),
    };
  }
}
