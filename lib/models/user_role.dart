/// Defines the possible user roles in the application.
enum UserRole {
  /// Full access to all features, including administrative tasks.
  ADMIN,
  /// The default role for new users, with standard customer access.
  CUSTOMER,
  /// A user with workshop task and stage completion permissions.
  WORKER,
  /// A user managing customer enquiries, follow-ups, and order conversion.
  MARKETING,
  /// A user managing staff attendance, check-in, and check-out verification.
  ATTENDANCE;

  String get displayName {
    switch (this) {
      case UserRole.ADMIN:
        return 'Administrator';
      case UserRole.CUSTOMER:
        return 'Customer';
      case UserRole.WORKER:
        return 'Worker';
      case UserRole.MARKETING:
        return 'Marketing';
      case UserRole.ATTENDANCE:
        return 'Attendance';
    }
  }

  static UserRole fromString(String? value) {
    if (value == null) return UserRole.CUSTOMER;
    return UserRole.values.firstWhere(
      (e) =>
          e.name.toUpperCase() == value.toUpperCase() ||
          e.displayName.toUpperCase() == value.toUpperCase(),
      orElse: () => UserRole.CUSTOMER,
    );
  }
}