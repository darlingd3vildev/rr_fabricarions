import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/user_role.dart';
import 'package:rr_fabrication/screens/common/app_drawer.dart';

enum AdminScreen {
  dashboard,
  users,
  products,
  orders,
  workers,
  stages,
}

class AdminDrawer extends StatelessWidget {
  final AdminScreen currentScreen;

  const AdminDrawer({
    super.key,
    required this.currentScreen,
  });

  DrawerItem _mapToDrawerItem(AdminScreen screen) {
    switch (screen) {
      case AdminScreen.dashboard:
        return DrawerItem.adminDashboard;
      case AdminScreen.users:
        return DrawerItem.adminUsers;
      case AdminScreen.products:
        return DrawerItem.adminProducts;
      case AdminScreen.stages:
        return DrawerItem.adminStages;
      case AdminScreen.orders:
        return DrawerItem.adminOrders;
      case AdminScreen.workers:
        return DrawerItem.adminWorkers;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDrawer(
      currentItem: _mapToDrawerItem(currentScreen),
      userRole: UserRole.ADMIN,
    );
  }
}
