import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rr_fabrication/screens/user_role.dart';

import 'login_screen.dart';
import 'worker_home_screen.dart';
import 'auth_service.dart';

class HomePage extends StatefulWidget {
  final UserRole userRole;
  const HomePage({super.key, required this.userRole});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.getCurrentUser();
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
          if (widget.userRole == UserRole.ADMIN || widget.userRole == UserRole.WORKER)
            IconButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => WorkerHomeScreen(userRole: widget.userRole)),
                );
              },
              icon: const Icon(Icons.build), // Icon for worker app
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome, ${_currentUser?.displayName ?? 'User'}!',
        ),
      ),
    );
  }
}