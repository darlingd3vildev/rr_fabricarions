import 'package:flutter/material.dart';
import 'package:rr_fabrication/screens/admin/users_screen.dart';

/// Legacy screen wrapper: Worker management is now consolidated under [UsersScreen].
class WorkersScreen extends StatelessWidget {
  const WorkersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UsersScreen();
  }
}