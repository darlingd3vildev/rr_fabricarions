import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/enquiry_model.dart';
import 'package:rr_fabrication/models/user_role.dart';
import 'package:rr_fabrication/screens/common/app_drawer.dart';
import 'package:rr_fabrication/screens/marketing/enquiries_screen.dart';
import 'package:rr_fabrication/screens/marketing/enquiry_detail_screen.dart';
import 'package:rr_fabrication/services/enquiry_service.dart';

class MarketingHomeScreen extends StatefulWidget {
  final UserRole userRole;

  const MarketingHomeScreen({
    super.key,
    this.userRole = UserRole.MARKETING,
  });

  @override
  State<MarketingHomeScreen> createState() => _MarketingHomeScreenState();
}

class _MarketingHomeScreenState extends State<MarketingHomeScreen> {
  final EnquiryService _enquiryService = EnquiryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        currentItem: DrawerItem.adminOrders,
        userRole: widget.userRole,
      ),
      appBar: AppBar(
        title: const Text('Marketing & Enquiries'),
      ),
      body: StreamBuilder<List<EnquiryModel>>(
        stream: _enquiryService.getEnquiriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final enquiries = snapshot.data ?? [];
          final total = enquiries.length;
          final active =
              enquiries.where((e) => e.status == EnquiryStatus.active).length;
          final followup =
              enquiries.where((e) => e.status == EnquiryStatus.followup).length;
          final confirmed = enquiries
              .where((e) => e.status == EnquiryStatus.confirmed)
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.teal[700]!,
                        Colors.teal[500]!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enquiry & Sales Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Track customer leads, log follow-up notes, and convert finalized enquiries into live fabrication orders.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.teal[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EnquiriesScreen(
                                userRole: widget.userRole,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.list_alt),
                        label: const Text(
                          'View All Enquiries',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Metric Cards Grid
                const Text(
                  'Pipeline Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Leads',
                        count: '$total',
                        icon: Icons.people_outline,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Active Leads',
                        count: '$active',
                        icon: Icons.bolt,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'In Follow-up',
                        count: '$followup',
                        icon: Icons.phone_in_talk_outlined,
                        color: Colors.amber[800]!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Converted Orders',
                        count: '$confirmed',
                        icon: Icons.check_circle_outline,
                        color: Colors.green[700]!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Enquiries
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EnquiriesScreen(
                              userRole: widget.userRole,
                            ),
                          ),
                        );
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (enquiries.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text(
                          'No enquiries recorded yet',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: enquiries.take(5).length,
                    itemBuilder: (context, index) {
                      final enquiry = enquiries[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal[50],
                            child: Text(
                              enquiry.customerName.isNotEmpty
                                  ? enquiry.customerName[0].toUpperCase()
                                  : 'C',
                              style: TextStyle(
                                color: Colors.teal[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            enquiry.customerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                              '${enquiry.customerPhone} • ${enquiry.productName}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: enquiry.status == EnquiryStatus.confirmed
                                  ? Colors.green[50]
                                  : Colors.blue[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              enquiry.status.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color:
                                    enquiry.status == EnquiryStatus.confirmed
                                        ? Colors.green[800]
                                        : Colors.blue[800],
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EnquiryDetailScreen(
                                  enquiryId: enquiry.id,
                                  initialEnquiry: enquiry,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
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
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
