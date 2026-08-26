import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/user_role.dart';
import 'package:rr_fabrication/screens/Onboarding/auth_gate.dart';
import 'package:rr_fabrication/screens/admin/admin_home_screen.dart';
import 'package:rr_fabrication/screens/admin/orders_screen.dart';
import 'package:rr_fabrication/screens/admin/products_screen.dart';
import 'package:rr_fabrication/screens/admin/stages_screen.dart';
import 'package:rr_fabrication/screens/admin/users_screen.dart';
import 'package:rr_fabrication/screens/attendance/attendance_screen.dart';
import 'package:rr_fabrication/screens/customer/home_screen.dart';
import 'package:rr_fabrication/screens/marketing/enquiries_screen.dart';
import 'package:rr_fabrication/screens/marketing/marketing_home_screen.dart';
import 'package:rr_fabrication/screens/worker/worker_home_screen.dart';
import 'package:rr_fabrication/services/auth_service.dart';

enum DrawerItem {
  adminDashboard,
  adminUsers,
  adminProducts,
  adminStages,
  adminOrders,
  enquiries,
  attendance,
  customerHome,
  workerHome,
  marketingHome,
}

class AppDrawer extends StatefulWidget {
  final DrawerItem currentItem;
  final UserRole? userRole;

  const AppDrawer({
    super.key,
    required this.currentItem,
    this.userRole,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AuthService _authService = AuthService();
  String _userName = 'User';
  String _userEmail = '';
  UserRole _role = UserRole.CUSTOMER;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        if (mounted) {
          setState(() {
            _userEmail = user.email ?? '';
            _userName = user.displayName ?? 'User';
          });
        }

        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          final data = doc.data() ?? {};
          final nameFromDb = data['name'] as String?;
          if (nameFromDb != null && nameFromDb.isNotEmpty) {
            _userName = nameFromDb;
          }
          final roleString = data['role'] as String?;
          if (roleString != null) {
            _role = UserRole.fromString(roleString);
          }
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error loading drawer user info: $e');
    }
  }

  Future<void> _signOut(BuildContext context) async {
    Navigator.pop(context); // Close drawer
    await _authService.signOut();

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthGate()),
        (route) => false,
      );
    }
  }

  void _navigateTo(BuildContext context, DrawerItem targetItem, Widget screen) {
    Navigator.pop(context); // Close drawer
    if (widget.currentItem == targetItem) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final effectiveRole = widget.userRole ?? _role;

    final initial = _userName.trim().isNotEmpty
        ? _userName.trim()[0].toUpperCase()
        : 'U';

    return Drawer(
      child: Column(
        children: [
          // 1. TOP RACK: Initial avatar in circle, User Name beside it, Sign Out below
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 48,
              left: 16,
              right: 16,
              bottom: 18,
            ),
            decoration: BoxDecoration(
              color: primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _userName.isNotEmpty ? _userName : 'User',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_userEmail.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          _userEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (effectiveRole != UserRole.CUSTOMER) ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            effectiveRole.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => _signOut(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[600]?.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. DRAWER NAVIGATION LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                // ADMIN SECTION
                if (effectiveRole == UserRole.ADMIN) ...[
                  _buildSectionHeader('ADMINISTRATION'),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    item: DrawerItem.adminDashboard,
                    onTap: () => _navigateTo(
                      context,
                      DrawerItem.adminDashboard,
                      const AdminHomeScreen(userRole: UserRole.ADMIN),
                    ),
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.inventory_2_outlined,
                    title: 'Products',
                    item: DrawerItem.adminProducts,
                    onTap: () => _navigateTo(
                      context,
                      DrawerItem.adminProducts,
                      const ProductsScreen(),
                    ),
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.account_tree_outlined,
                    title: 'Process Stages',
                    item: DrawerItem.adminStages,
                    onTap: () => _navigateTo(
                      context,
                      DrawerItem.adminStages,
                      const StagesScreen(),
                    ),
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.shopping_cart_outlined,
                    title: 'Orders',
                    item: DrawerItem.adminOrders,
                    onTap: () => _navigateTo(
                      context,
                      DrawerItem.adminOrders,
                      const OrdersScreen(),
                    ),
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.support_agent_outlined,
                    title: 'Enquiries & Leads',
                    item: DrawerItem.enquiries,
                    onTap: () => _navigateTo(
                      context,
                      DrawerItem.enquiries,
                      const EnquiriesScreen(userRole: UserRole.ADMIN),
                    ),
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.people_alt_outlined,
                    title: 'Users & Roles',
                    item: DrawerItem.adminUsers,
                    onTap: () => _navigateTo(
                      context,
                      DrawerItem.adminUsers,
                      const UsersScreen(),
                    ),
                  ),
                  const Divider(height: 20),
                  _buildSectionHeader('SWITCH VIEWS'),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.storefront_outlined,
                    title: 'Customer View',
                    item: DrawerItem.customerHome,
                    onTap: () => _navigateTo(
                      context,
                      DrawerItem.customerHome,
                      HomePage(userRole: effectiveRole),
                    ),
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.build_outlined,
                    title: 'Worker Tasks View',
                    item: DrawerItem.workerHome,
                    onTap: () => _navigateTo(
                      context,
                      DrawerItem.workerHome,
                      WorkerHomeScreen(userRole: effectiveRole),
                    ),
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.trending_up,
                    title: 'Marketing View',
                    item: DrawerItem.marketingHome,
                    onTap: () => _navigateTo(
                      context,
                      DrawerItem.marketingHome,
                      const MarketingHomeScreen(userRole: UserRole.MARKETING),
                    ),
                  ),
                ] else if (effectiveRole == UserRole.ATTENDANCE) ...[
                  _buildSectionHeader('ATTENDANCE PANEL'),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.fingerprint,
                    title: 'Attendance Kiosk',
                    item: DrawerItem.attendance,
                    onTap: () => _navigateTo(
                      context,
                      DrawerItem.attendance,
                      const AttendanceScreen(userRole: UserRole.ATTENDANCE),
                    ),
                  ),
                ] else if (effectiveRole == UserRole.MARKETING) ...[
                  _buildSectionHeader('MARKETING PANEL'),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    title: 'Marketing Dashboard',
                    item: DrawerItem.marketingHome,
                    onTap: () => _navigateTo(
                      context,
                      DrawerItem.marketingHome,
                      const MarketingHomeScreen(userRole: UserRole.MARKETING),
                    ),
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.support_agent_outlined,
                    title: 'Customer Enquiries',
                    item: DrawerItem.enquiries,
                    onTap: () => _navigateTo(
                      context,
                      DrawerItem.enquiries,
                      const EnquiriesScreen(userRole: UserRole.MARKETING),
                    ),
                  ),
                ] else if (effectiveRole == UserRole.WORKER) ...[
                  _buildSectionHeader('WORKER PANEL'),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.assignment_outlined,
                    title: 'My Work & Tasks',
                    item: DrawerItem.workerHome,
                    onTap: () => _navigateTo(
                      context,
                      DrawerItem.workerHome,
                      WorkerHomeScreen(userRole: effectiveRole),
                    ),
                  ),
                ] else ...[
                  _buildSectionHeader('CUSTOMER MENU'),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.home_outlined,
                    title: 'Home',
                    item: DrawerItem.customerHome,
                    onTap: () => _navigateTo(
                      context,
                      DrawerItem.customerHome,
                      HomePage(userRole: effectiveRole),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required DrawerItem item,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isSelected = widget.currentItem == item;

    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        color: isSelected ? primaryColor : Colors.grey[700],
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? primaryColor : Colors.grey[900],
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      selectedColor: primaryColor,
      selectedTileColor: primaryColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      onTap: onTap,
    );
  }
}
