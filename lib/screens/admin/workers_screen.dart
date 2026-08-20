import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/user_role.dart';
import 'package:rr_fabrication/screens/admin/admin_drawer.dart';
import 'package:rr_fabrication/screens/admin/user_list.dart';

class WorkersScreen extends StatelessWidget {
  const WorkersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(currentScreen: AdminScreen.workers),
      appBar: AppBar(
        title: const Text('Manage Workers'),
      ),
      body: const UserList(role: UserRole.WORKER),
    );
  }
}