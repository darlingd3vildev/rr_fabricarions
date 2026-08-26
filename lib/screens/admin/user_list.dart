import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/user_model.dart';
import 'package:rr_fabrication/models/user_role.dart';
import 'package:rr_fabrication/services/user_service.dart';

class UserList extends StatefulWidget {
  final UserRole? roleFilter;
  final String searchQuery;

  const UserList({
    super.key,
    this.roleFilter,
    this.searchQuery = '',
  });

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  final UserService _userService = UserService();

  Color _getRoleBadgeColor(UserRole role) {
    switch (role) {
      case UserRole.ADMIN:
        return Colors.purple;
      case UserRole.MARKETING:
        return Colors.teal;
      case UserRole.ATTENDANCE:
        return Colors.indigo;
      case UserRole.WORKER:
        return Colors.orange[800]!;
      case UserRole.CUSTOMER:
        return Colors.blue[700]!;
    }
  }

  void _showRoleChangeDialog(UserModel user) {
    UserRole selectedRole = user.role;
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.manage_accounts),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Assign Role for ${user.name}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select permission role for ${user.email}:',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 12),
                      ...UserRole.values.map((role) {
                        final isSelected = selectedRole == role;
                        final color = _getRoleBadgeColor(role);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.08)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? color : Colors.grey[300]!,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              setDialogState(() => selectedRole = role);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: isSelected ? color : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          role.displayName,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? color
                                                : Colors.grey[900],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _getRoleDescription(role),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedRole == user.role
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);
                          try {
                            await _userService.updateUserRole(
                                user.id, selectedRole);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Updated ${user.name}\'s role to ${selectedRole.displayName}',
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to update role: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: const Text('Save Role'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.ADMIN:
        return 'Full access to all modules, orders, users, and stages.';
      case UserRole.MARKETING:
        return 'Manage customer enquiries, follow-ups, and convert to orders.';
      case UserRole.ATTENDANCE:
        return 'Kiosk check-in / check-out verification with photo capture.';
      case UserRole.WORKER:
        return 'View and execute assigned fabrication process tasks.';
      case UserRole.CUSTOMER:
        return 'Browse products and track personal orders.';
    }
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('users');

    if (widget.roleFilter != null) {
      query = query.where('role', isEqualTo: widget.roleFilter!.name);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('Error fetching users: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        List<UserModel> users =
            docs.map((doc) => UserModel.fromFirestore(doc)).toList();

        // Apply in-memory search filter
        if (widget.searchQuery.trim().isNotEmpty) {
          final q = widget.searchQuery.trim().toLowerCase();
          users = users.where((u) {
            return u.name.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q) ||
                (u.phoneNumber != null && u.phoneNumber!.contains(q));
          }).toList();
        }

        if (users.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_search, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    widget.roleFilter != null
                        ? 'No users found with role: ${widget.roleFilter!.displayName}'
                        : 'No users found matching query',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final roleColor = _getRoleBadgeColor(user.role);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              elevation: 1,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: roleColor.withValues(alpha: 0.15),
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: roleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: roleColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  user.role.displayName,
                                  style: TextStyle(
                                    color: roleColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (user.phoneNumber != null &&
                              user.phoneNumber!.isNotEmpty)
                            Text(
                              'Phone: ${user.phoneNumber}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Change Role',
                      onPressed: () => _showRoleChangeDialog(user),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}