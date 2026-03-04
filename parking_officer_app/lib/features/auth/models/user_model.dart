class User {
  final String id;
  final String phone;
  final String firstName;
  final String lastName;
  final String? email;
  final String role;
  final String? profilePhoto;
  final bool canReceiveChats;

  User({
    required this.id,
    required this.phone,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.role,
    this.profilePhoto,
    this.canReceiveChats = false,
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
      canReceiveChats: json['can_receive_chats'] ?? false,
    );
  }

  String get fullName => '$firstName $lastName';
}
