import 'user_role.dart';

class AppUser {
  final String id;
  final String phoneNumber;
  final UserRole role;

  const AppUser({required this.id, required this.phoneNumber, required this.role});

  Map<String, dynamic> toJson() => {'id': id, 'phoneNumber': phoneNumber, 'role': role.apiValue};

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        phoneNumber: json['phoneNumber'] as String,
        role: UserRoleX.fromApiValue(json['role'] as String?),
      );
}
