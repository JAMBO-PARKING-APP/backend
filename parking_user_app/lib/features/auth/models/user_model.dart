class User {
  final String id;
  final String phone;
  final String firstName;
  final String lastName;
  final String? email;
  final String role;
  final String? profilePhoto;
  final String? country;
  final String? countryName;

  User({
    required this.id,
    required this.phone,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.role,
    this.profilePhoto,
    this.country,
    this.countryName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Try to get country from different field names
    dynamic countryField = json['country'];
    String? countryValue;
    String? countryNameValue = json['country_name'];
    
    // If country is a map/object, extract the name
    if (countryField is Map) {
      countryNameValue = countryField['name'] ?? countryNameValue;
      countryValue = countryField['id']?.toString();
    } else if (countryField is String) {
      countryValue = countryField;
    }
    
    // Print for debugging
    print('🌍 User.fromJson country data:');
    print('   - country field: $countryValue');
    print('   - country_name field: $countryNameValue');
    
    return User(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'],
      role: json['role'] ?? '',
      profilePhoto: json['profile_photo'],
      country: countryValue,
      countryName: countryNameValue,
    );
  }

  String get fullName => '$firstName $lastName';
  
  /// Get the most reliable country identifier
  String get countryIdentifier => countryName ?? country ?? '';
}
