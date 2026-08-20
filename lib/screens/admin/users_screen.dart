import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/user_role.dart';
import 'package:rr_fabrication/screens/admin/admin_drawer.dart';
import 'package:rr_fabrication/screens/admin/user_list.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(currentScreen: AdminScreen.users),
      appBar: AppBar(
        title: const Text('Manage Users'),
      ),
      body: const UserList(role: UserRole.CUSTOMER),
    );
  }
}