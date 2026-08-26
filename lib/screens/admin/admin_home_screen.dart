import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/order_model.dart';
import 'package:rr_fabrication/models/user_role.dart';
import 'package:rr_fabrication/screens/admin/admin_drawer.dart';
import 'package:rr_fabrication/screens/admin/order_detail_screen.dart';
import 'package:rr_fabrication/screens/admin/orders_screen.dart';
import 'package:rr_fabrication/screens/admin/products_screen.dart';
import 'package:rr_fabrication/screens/admin/stages_screen.dart';
import 'package:rr_fabrication/screens/admin/users_screen.dart';
import 'package:rr_fabrication/screens/marketing/enquiries_screen.dart';
import 'package:rr_fabrication/services/order_service.dart';

class AdminHomeScreen extends StatefulWidget {
  final UserRole userRole;
  const AdminHomeScreen({super.key, this.userRole = UserRole.ADMIN});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final OrderService _orderService = OrderService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(currentScreen: AdminScreen.dashboard),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RR Fabrications Management',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Overview of fabrication operations, active build pipelines, customer enquiries, and user roles.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Stats Stream Row
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .snapshots(),
              builder: (context, ordersSnap) {
                final totalOrders = ordersSnap.data?.docs.length ?? 0;
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .snapshots(),
                  builder: (context, prodsSnap) {
                    final totalProducts = prodsSnap.data?.docs.length ?? 0;
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('enquiries')
                          .snapshots(),
                      builder: (context, enqSnap) {
                        final totalEnquiries = enqSnap.data?.docs.length ?? 0;
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .snapshots(),
                          builder: (context, usersSnap) {
                            final totalUsers =
                                usersSnap.data?.docs.length ?? 0;

                            return GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.7,
                              children: [
                                _buildStatCard(
                                  title: 'Active Orders',
                                  count: '$totalOrders',
                                  icon: Icons.shopping_cart_outlined,
                                  color: Colors.blue[700]!,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (c) => const OrdersScreen()),
                                  ),
                                ),
                                _buildStatCard(
                                  title: 'Products Catalog',
                                  count: '$totalProducts',
                                  icon: Icons.inventory_2_outlined,
                                  color: Colors.indigo[700]!,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (c) => const ProductsScreen()),
                                  ),
                                ),
                                _buildStatCard(
                                  title: 'Enquiries & Leads',
                                  count: '$totalEnquiries',
                                  icon: Icons.support_agent_outlined,
                                  color: Colors.teal[700]!,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (c) => const EnquiriesScreen(
                                          userRole: UserRole.ADMIN),
                                    ),
                                  ),
                                ),
                                _buildStatCard(
                                  title: 'Users & Roles',
                                  count: '$totalUsers',
                                  icon: Icons.people_outline,
                                  color: Colors.purple[700]!,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (c) => const UsersScreen()),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Modules Navigation Grid
            const Text(
              'Management Modules',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                _buildModuleTile(
                  title: 'Orders',
                  icon: Icons.shopping_cart_outlined,
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const OrdersScreen()),
                  ),
                ),
                _buildModuleTile(
                  title: 'Products',
                  icon: Icons.inventory_2_outlined,
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const ProductsScreen()),
                  ),
                ),
                _buildModuleTile(
                  title: 'Stages',
                  icon: Icons.account_tree_outlined,
                  color: Colors.deepOrange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const StagesScreen()),
                  ),
                ),
                _buildModuleTile(
                  title: 'Enquiries',
                  icon: Icons.support_agent_outlined,
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) =>
                          const EnquiriesScreen(userRole: UserRole.ADMIN),
                    ),
                  ),
                ),
                _buildModuleTile(
                  title: 'Users & Roles',
                  icon: Icons.people_alt_outlined,
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const UsersScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Live Recent Orders Feed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const OrdersScreen()),
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            StreamBuilder<List<OrderModel>>(
              stream: _orderService.getOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        const Text(
                          'No orders created yet',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.take(4).length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          child: Text(
                            '${order.completionPercentage}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        title: Text(
                          order.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                            '${order.dimensions} • Status: ${order.status.displayName}'),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderDetailScreen(orderId: order.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}