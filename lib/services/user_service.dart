import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/user_role.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUserRole(String userId, UserRole newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole.name,
      });
    } catch (e) {
      // It's good practice to log the error for debugging.
      debugPrint('Error updating user role: $e');
      // Re-throw the exception to be handled by the UI.
      rethrow;
    }
  }
}