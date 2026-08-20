/// Defines the possible user roles in the application.
enum UserRole {
  /// Full access to all features, including administrative tasks.
  ADMIN,
  /// The default role for new users, with standard access.
  CUSTOMER,
  /// A user with specific operational permissions.
  WORKER,
}