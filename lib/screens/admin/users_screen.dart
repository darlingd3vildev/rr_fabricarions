import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/user_role.dart';
import 'package:rr_fabrication/screens/admin/admin_drawer.dart';
import 'package:rr_fabrication/screens/admin/user_list.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<UserRole?> _tabs = [
    null, // All
    UserRole.CUSTOMER,
    UserRole.WORKER,
    UserRole.MARKETING,
    UserRole.ATTENDANCE,
    UserRole.ADMIN,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(currentScreen: AdminScreen.users),
      appBar: AppBar(
        title: const Text('Manage Users & Roles'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All Users'),
            Tab(text: 'Customers'),
            Tab(text: 'Workers'),
            Tab(text: 'Marketing'),
            Tab(text: 'Attendance'),
            Tab(text: 'Admins'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((roleFilter) {
                return UserList(
                  roleFilter: roleFilter,
                  searchQuery: _searchQuery,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}