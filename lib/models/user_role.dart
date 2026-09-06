enum UserRole { protected, guardian }

extension UserRoleX on UserRole {
  String get apiValue => name.toUpperCase();

  String get label {
    switch (this) {
      case UserRole.protected:
        return 'Protected';
      case UserRole.guardian:
        return 'Guardian';
    }
  }

  static UserRole fromApiValue(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.apiValue == value,
      orElse: () => UserRole.protected,
    );
  }
}
