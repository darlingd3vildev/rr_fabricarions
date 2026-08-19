import 'package:flutter/material.dart';
import 'user_role.dart';

import 'auth_service.dart';
import 'home_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  final UserRole userRole;
  const WorkerHomeScreen({super.key, required this.userRole});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _authService.signOut(),
            icon: const Icon(Icons.logout),
          ),
          if (widget.userRole == UserRole.ADMIN || widget.userRole == UserRole.WORKER)
            IconButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => HomePage(userRole: widget.userRole)),
                );
              },
              icon: const Icon(Icons.home), // Icon for main app
            ),
        ],
      ),
      body: const Center(
        child: Text('Welcome, Worker!'),
      ),
    );
  }
}