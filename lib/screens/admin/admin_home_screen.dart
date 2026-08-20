import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/user_role.dart';
import 'package:rr_fabrication/screens/admin/admin_drawer.dart';

class AdminHomeScreen extends StatelessWidget {
  final UserRole userRole;
  const AdminHomeScreen({super.key, this.userRole = UserRole.ADMIN});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(currentScreen: AdminScreen.dashboard),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Welcome, Admin! Select an option from the drawer.'),
      ),
    );
  }
}