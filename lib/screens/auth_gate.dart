import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rr_fabrication/screens/user_info_screen.dart';
import 'package:rr_fabrication/screens/user_role.dart';
import 'package:rr_fabrication/screens/worker_home_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // If the snapshot has data, the user is logged in
        if (snapshot.hasData) {
          // User is logged in, now check their role from Firestore.
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userDocSnapshot) {
              if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }

              if (userDocSnapshot.hasError || !userDocSnapshot.data!.exists) {
                // If user doc doesn't exist, they might be a new user
                // who hasn't completed the info screen.
                return const UserInfoScreen();
              }

              // We have the user document, let's check the role.
              final userData =
                  userDocSnapshot.data!.data() as Map<String, dynamic>;
              final roleString = userData['role'] as String;
              final userRole = UserRole.values.firstWhere(
                  (e) => e.name == roleString,
                  orElse: () => UserRole.CUSTOMER); // Default to CUSTOMER if role not found

              return _buildScreenForRole(userRole);
            },
          );
        }

        // Otherwise, the user is not logged in
        return const LoginScreen();
      },
    );
  }
}

Widget _buildScreenForRole(UserRole role) {
  switch (role) {
    case UserRole.WORKER:
      return WorkerHomeScreen(userRole: role);
    case UserRole.ADMIN: // Admins might default to HomePage but can switch
    case UserRole.CUSTOMER:
    return HomePage(userRole: role);
  }
}