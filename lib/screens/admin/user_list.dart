import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/user_role.dart';
import 'package:rr_fabrication/services/user_service.dart';

import '../../models/user_model.dart';

class UserList extends StatefulWidget {
  final UserRole role;

  const UserList({super.key, required this.role});

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  final UserService _userService = UserService();

  Future<void> _handleRoleChange(UserModel user, bool isWorker) async {
    final newRole = isWorker ? UserRole.WORKER : UserRole.CUSTOMER;
    // Prevent updating if the role is already the new role.
    if (user.role == newRole) return;

    await _userService.updateUserRole(user.id, newRole);
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users') // Access 'role' via 'widget.role'
          .where('role', isEqualTo: widget.role.name)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // For debugging purposes, print the error to the console.
          debugPrint('Error fetching users: ${snapshot.error}');
          return const Center(child: Text('Something went wrong.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No users found with the role: ${widget.role.name}'),
          );
        }

        final users = snapshot.data!.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: Switch(
                  value: user.role == UserRole.WORKER,
                  onChanged: (bool isWorker) {
                    _handleRoleChange(user, isWorker);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}