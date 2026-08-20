import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rr_fabrication/models/user_role.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final UserRole role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final roleString = data['role'] as String? ?? UserRole.CUSTOMER.name;

    return UserModel(
      id: doc.id,
      name: data['name'] as String? ?? 'No Name',
      email: data['email'] as String? ?? 'No Email',
      phoneNumber: data['phoneNumber'] as String?,
      role: UserRole.values
          .firstWhere((e) => e.name == roleString, orElse: () => UserRole.CUSTOMER),
    );
  }
}