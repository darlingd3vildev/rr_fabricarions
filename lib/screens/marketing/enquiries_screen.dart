import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/enquiry_model.dart';
import 'package:rr_fabrication/models/product_model.dart';
import 'package:rr_fabrication/models/user_role.dart';
import 'package:rr_fabrication/screens/common/app_drawer.dart';
import 'package:rr_fabrication/screens/marketing/enquiry_detail_screen.dart';
import 'package:rr_fabrication/services/auth_service.dart';
import 'package:rr_fabrication/services/enquiry_service.dart';
import 'package:rr_fabrication/services/product_service.dart';

class EnquiriesScreen extends StatefulWidget {
  final UserRole userRole;

  const EnquiriesScreen({
    super.key,
    this.userRole = UserRole.MARKETING,
  });

  @override
  State<EnquiriesScreen> createState() => _EnquiriesScreenState();
}

class _EnquiriesScreenState extends State<EnquiriesScreen>
    with SingleTickerProviderStateMixin {
  final EnquiryService _enquiryService = EnquiryService();
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<EnquiryStatus?> _statusTabs = [
    null, // All
    EnquiryStatus.active,
    EnquiryStatus.followup,
    EnquiryStatus.confirmed,
    EnquiryStatus.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(EnquiryStatus status) {
    switch (status) {
      case EnquiryStatus.active:
        return Colors.blue[700]!;
      case EnquiryStatus.followup:
        return Colors.amber[800]!;
      case EnquiryStatus.confirmed:
        return Colors.green[700]!;
      case EnquiryStatus.cancelled:
        return Colors.red[700]!;
    }
  }

  Color _getStatusBgColor(EnquiryStatus status) {
    switch (status) {
      case EnquiryStatus.active:
        return Colors.blue[50]!;
      case EnquiryStatus.followup:
        return Colors.amber[50]!;
      case EnquiryStatus.confirmed:
        return Colors.green[50]!;
      case EnquiryStatus.cancelled:
        return Colors.red[50]!;
    }
  }

  void _showAddEnquiryDialog(List<ProductModel> products) {
    final customerNameController = TextEditingController();
    final customerPhoneController = TextEditingController();
    final customerEmailController = TextEditingController();
    final customerAddressController = TextEditingController();
    final dimensionsController = TextEditingController();
    final descriptionController = TextEditingController();
    final budgetController = TextEditingController();
    final initialNoteController = TextEditingController();

    String? selectedProductId = products.isNotEmpty ? products.first.id : null;
    String selectedProductName =
        products.isNotEmpty ? products.first.name : 'Custom Fabrication';

    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.add_comment_outlined),
                  SizedBox(width: 8),
                  Text('New Customer Enquiry'),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: customerNameController,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: 'Customer Name *',
                            hintText: 'e.g. Rajesh Kumar',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: customerPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number *',
                            hintText: 'e.g. 9876543210',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: selectedProductId,
                          decoration: InputDecoration(
                            labelText: 'Product / Fabrication Type',
                            prefixIcon: const Icon(Icons.inventory_2_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Custom / Other Fabrication'),
                            ),
                            ...products.map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.name),
                                )),
                          ],
                          onChanged: (val) {
                            setDialogState(() {
                              selectedProductId = val;
                              if (val != null) {
                                final match =
                                    products.where((p) => p.id == val);
                                if (match.isNotEmpty) {
                                  selectedProductName = match.first.name;
                                }
                              } else {
                                selectedProductName = 'Custom Fabrication';
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: dimensionsController,
                          decoration: InputDecoration(
                            labelText: 'Dimensions / Area',
                            hintText: 'e.g. 10ft x 12ft, 50 running feet',
                            prefixIcon: const Icon(Icons.straighten),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: budgetController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Estimated Budget (₹)',
                            hintText: 'e.g. 35000',
                            prefixIcon: const Icon(Icons.currency_rupee),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: initialNoteController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Initial Follow-up / Notes',
                            hintText: 'Customer requirement details or call summary...',
                            prefixIcon: const Icon(Icons.notes),
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSubmitting = true);

                          try {
                            final user = _authService.getCurrentUser();
                            final userId = user?.uid ?? 'marketing';
                            final userName = user?.displayName ??
                                user?.email ??
                                'Marketing Staff';
                            final budget =
                                double.tryParse(budgetController.text.trim());

                            await _enquiryService.addEnquiry(
                              customerName: customerNameController.text.trim(),
                              customerPhone:
                                  customerPhoneController.text.trim(),
                              customerEmail:
                                  customerEmailController.text.trim().isNotEmpty
                                      ? customerEmailController.text.trim()
                                      : null,
                              customerAddress: customerAddressController
                                      .text
                                      .trim()
                                      .isNotEmpty
                                  ? customerAddressController.text.trim()
                                  : null,
                              productId: selectedProductId,
                              productName: selectedProductName,
                              dimensions: dimensionsController.text.trim(),
                              description: descriptionController.text.trim(),
                              estimatedBudget: budget,
                              createdByUserId: userId,
                              createdByUserName: userName,
                              initialNote: initialNoteController.text.trim(),
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            messenger.showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Enquiry created successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content:
                                    Text('Failed to create enquiry: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add),
                  label: Text(
                      isSubmitting ? 'Creating...' : 'Create Enquiry'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductModel>>(
      stream: _productService.getProductsStream(),
      builder: (context, productsSnapshot) {
        final products = productsSnapshot.data ?? [];

        return Scaffold(
          drawer: AppDrawer(
            currentItem: DrawerItem.adminOrders,
            userRole: widget.userRole,
          ),
          appBar: AppBar(
            title: const Text('Enquiries & Leads'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'All Enquiries'),
                Tab(text: 'Active'),
                Tab(text: 'Follow-up'),
                Tab(text: 'Confirmed (Orders)'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddEnquiryDialog(products),
            icon: const Icon(Icons.add),
            label: const Text('New Enquiry'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by customer name, phone, product...',
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
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
                child: StreamBuilder<List<EnquiryModel>>(
                  stream: _enquiryService.getEnquiriesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading enquiries: ${snapshot.error}'),
                      );
                    }

                    final allEnquiries = snapshot.data ?? [];

                    return TabBarView(
                      controller: _tabController,
                      children: _statusTabs.map((statusFilter) {
                        var filtered = allEnquiries;

                        if (statusFilter != null) {
                          filtered = filtered
                              .where((e) => e.status == statusFilter)
                              .toList();
                        }

                        if (_searchQuery.trim().isNotEmpty) {
                          final q = _searchQuery.trim().toLowerCase();
                          filtered = filtered.where((e) {
                            return e.customerName.toLowerCase().contains(q) ||
                                e.customerPhone.contains(q) ||
                                e.productName.toLowerCase().contains(q) ||
                                e.description.toLowerCase().contains(q);
                          }).toList();
                        }

                        if (filtered.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.support_agent,
                                      size: 56, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text(
                                    statusFilter != null
                                        ? 'No ${statusFilter.displayName} enquiries'
                                        : 'No enquiries found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Create a new enquiry to start following up with customers.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 10,
                            bottom: 80,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final enquiry = filtered[index];
                            final statusColor = _getStatusColor(enquiry.status);
                            final statusBgColor =
                                _getStatusBgColor(enquiry.status);
                            final latestComment = enquiry.comments.isNotEmpty
                                ? enquiry.comments.last
                                : null;

                            return Card(
                              elevation: 1.5,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
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
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.12),
                                            child: Text(
                                              enquiry.customerName.isNotEmpty
                                                  ? enquiry.customerName[0]
                                                      .toUpperCase()
                                                  : 'C',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  enquiry.customerName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${enquiry.customerPhone} • ${enquiry.productName}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[700],
                                                    fontWeight:
                                                        FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusBgColor,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: statusColor
                                                    .withValues(alpha: 0.4),
                                              ),
                                            ),
                                            child: Text(
                                              enquiry.status.displayName,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (enquiry.dimensions.isNotEmpty ||
                                          enquiry.estimatedBudget != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            if (enquiry
                                                .dimensions.isNotEmpty) ...[
                                              Icon(Icons.straighten,
                                                  size: 13,
                                                  color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text(
                                                enquiry.dimensions,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                            ],
                                            if (enquiry.estimatedBudget !=
                                                null) ...[
                                              Icon(Icons.currency_rupee,
                                                  size: 13,
                                                  color: Colors.grey[600]),
                                              const SizedBox(width: 2),
                                              Text(
                                                'Budget: ₹${enquiry.estimatedBudget!.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                      if (latestComment != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.chat_bubble_outline,
                                                  size: 12,
                                                  color: Colors.grey[600]),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  '${latestComment.userName}: ${latestComment.text}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
