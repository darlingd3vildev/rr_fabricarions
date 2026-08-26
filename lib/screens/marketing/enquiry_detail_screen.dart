import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/enquiry_model.dart';
import 'package:rr_fabrication/models/product_model.dart';
import 'package:rr_fabrication/screens/admin/order_detail_screen.dart';
import 'package:rr_fabrication/services/auth_service.dart';
import 'package:rr_fabrication/services/enquiry_service.dart';
import 'package:rr_fabrication/services/product_service.dart';

class EnquiryDetailScreen extends StatefulWidget {
  final String enquiryId;
  final EnquiryModel? initialEnquiry;

  const EnquiryDetailScreen({
    super.key,
    required this.enquiryId,
    this.initialEnquiry,
  });

  @override
  State<EnquiryDetailScreen> createState() => _EnquiryDetailScreenState();
}

class _EnquiryDetailScreenState extends State<EnquiryDetailScreen> {
  final EnquiryService _enquiryService = EnquiryService();
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();

  final TextEditingController _commentController = TextEditingController();
  bool _isAddingComment = false;

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

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAddingComment = true);

    try {
      final user = _authService.getCurrentUser();
      final userId = user?.uid ?? 'marketing';
      final userName = user?.displayName ?? user?.email ?? 'Marketing Staff';

      await _enquiryService.addComment(
        enquiryId: widget.enquiryId,
        userId: userId,
        userName: userName,
        text: text,
      );

      _commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Follow-up comment added'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingComment = false);
      }
    }
  }

  void _showConfirmToOrderDialog(EnquiryModel enquiry) {
    final dimensionsController =
        TextEditingController(text: enquiry.dimensions);
    final descriptionController =
        TextEditingController(text: enquiry.description);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
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
                  Icon(Icons.check_circle_outline, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Convert to Fabrication Order'),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Finalising this enquiry will create a new live order and mark this enquiry as Confirmed.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Product: ${enquiry.productName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Customer: ${enquiry.customerName} (${enquiry.customerPhone})',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: dimensionsController,
                        decoration: InputDecoration(
                          labelText: 'Final Dimensions *',
                          hintText: 'e.g., 10ft x 12ft',
                          prefixIcon: const Icon(Icons.straighten),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Order Notes & Specifications',
                          hintText: 'Any custom client instructions...',
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
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (dimensionsController.text.trim().isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please specify dimensions'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          try {
                            final user = _authService.getCurrentUser();
                            final userId = user?.uid ?? 'marketing';
                            final userName = user?.displayName ??
                                user?.email ??
                                'Marketing Staff';

                            final createdOrderId =
                                await _enquiryService.confirmAndConvertToOrder(
                              enquiry: enquiry,
                              customDimensions:
                                  dimensionsController.text.trim(),
                              customDescription:
                                  descriptionController.text.trim(),
                              confirmedByUserId: userId,
                              confirmedByUserName: userName,
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (mounted) {
                              _showOrderCreatedSuccessDialog(
                                  createdOrderId, enquiry.productName);
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content:
                                    Text('Failed to convert to order: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                      isSubmitting ? 'Creating Order...' : 'Confirm & Create Order'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showOrderCreatedSuccessDialog(String orderId, String productName) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.celebration, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Order Created!'),
            ],
          ),
          content: Text(
            'Enquiry for "$productName" has been confirmed and converted into Order #$orderId.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Stay on Enquiry'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(orderId: orderId),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View Live Order'),
            ),
          ],
        );
      },
    );
  }

  void _showCancelEnquiryDialog(EnquiryModel enquiry) {
    final reasonController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text('Cancel Enquiry'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to cancel the enquiry for "${enquiry.customerName}"?',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Cancellation Reason (Optional)',
                  hintText: 'e.g. Budget mismatch, customer postponed...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Back'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await _enquiryService.updateStatus(
                    enquiryId: enquiry.id,
                    status: EnquiryStatus.cancelled,
                    cancelReason: reasonController.text.trim(),
                  );
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Enquiry marked as cancelled'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel enquiry: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Confirm Cancellation'),
            ),
          ],
        );
      },
    );
  }

  void _showEditEnquiryDialog(
      EnquiryModel enquiry, List<ProductModel> products) {
    final customerNameController =
        TextEditingController(text: enquiry.customerName);
    final customerPhoneController =
        TextEditingController(text: enquiry.customerPhone);
    final customerEmailController =
        TextEditingController(text: enquiry.customerEmail ?? '');
    final customerAddressController =
        TextEditingController(text: enquiry.customerAddress ?? '');
    final dimensionsController =
        TextEditingController(text: enquiry.dimensions);
    final descriptionController =
        TextEditingController(text: enquiry.description);
    final budgetController = TextEditingController(
        text: enquiry.estimatedBudget?.toStringAsFixed(0) ?? '');

    String? selectedProductId = enquiry.productId;
    String selectedProductName = enquiry.productName;
    EnquiryStatus selectedStatus = enquiry.status;

    final formKey = GlobalKey<FormState>();
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
              title: const Row(
                children: [
                  Icon(Icons.edit_note),
                  SizedBox(width: 8),
                  Text('Edit Enquiry Details'),
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
                          decoration: InputDecoration(
                            labelText: 'Customer Name *',
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
                            labelText: 'Product',
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
                        DropdownButtonFormField<EnquiryStatus>(
                          initialValue: selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            prefixIcon: const Icon(Icons.flag_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: EnquiryStatus.values
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.displayName),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedStatus = val);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: dimensionsController,
                          decoration: InputDecoration(
                            labelText: 'Dimensions',
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
                            prefixIcon: const Icon(Icons.currency_rupee),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Requirements / Notes',
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(dialogContext);

                    try {
                      final budget = double.tryParse(budgetController.text.trim());
                      await _enquiryService.updateEnquiry(
                        id: enquiry.id,
                        customerName: customerNameController.text.trim(),
                        customerPhone: customerPhoneController.text.trim(),
                        customerEmail: customerEmailController.text.trim().isNotEmpty
                            ? customerEmailController.text.trim()
                            : null,
                        customerAddress:
                            customerAddressController.text.trim().isNotEmpty
                                ? customerAddressController.text.trim()
                                : null,
                        productId: selectedProductId,
                        productName: selectedProductName,
                        dimensions: dimensionsController.text.trim(),
                        description: descriptionController.text.trim(),
                        estimatedBudget: budget,
                        status: selectedStatus,
                      );
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Enquiry updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to update enquiry: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Save Changes'),
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

        return StreamBuilder<EnquiryModel?>(
          stream: _enquiryService.getEnquiryByIdStream(widget.enquiryId),
          initialData: widget.initialEnquiry,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                snapshot.data == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Enquiry Details')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final enquiry = snapshot.data;
            if (enquiry == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Enquiry Details')),
                body: const Center(child: Text('Enquiry not found')),
              );
            }

            final statusColor = _getStatusColor(enquiry.status);
            final statusBgColor = _getStatusBgColor(enquiry.status);
            final isConfirmed = enquiry.status == EnquiryStatus.confirmed;
            final isCancelled = enquiry.status == EnquiryStatus.cancelled;

            return Scaffold(
              appBar: AppBar(
                title: Text(enquiry.customerName),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit Enquiry',
                    onPressed: () => _showEditEnquiryDialog(enquiry, products),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Customer & Status Header Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.15),
                                  child: Text(
                                    enquiry.customerName.isNotEmpty
                                        ? enquiry.customerName[0].toUpperCase()
                                        : 'C',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        enquiry.customerName,
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.phone,
                                              size: 15,
                                              color: Colors.green[700]),
                                          const SizedBox(width: 6),
                                          Text(
                                            enquiry.customerPhone,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusBgColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Text(
                                    enquiry.status.displayName,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (enquiry.customerEmail != null &&
                                enquiry.customerEmail!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.email_outlined,
                                      size: 15, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Text(
                                    enquiry.customerEmail!,
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ],
                            if (enquiry.customerAddress != null &&
                                enquiry.customerAddress!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 15, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      enquiry.customerAddress!,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Product Specs Card
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Product & Requirement Specifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 20),
                            _buildInfoRow('Product Name', enquiry.productName),
                            if (enquiry.dimensions.isNotEmpty)
                              _buildInfoRow(
                                  'Dimensions / Size', enquiry.dimensions),
                            if (enquiry.estimatedBudget != null)
                              _buildInfoRow('Estimated Budget',
                                  '₹${enquiry.estimatedBudget!.toStringAsFixed(0)}'),
                            if (enquiry.description.isNotEmpty)
                              _buildInfoRow('Notes / Specs', enquiry.description),
                            _buildInfoRow(
                                'Created By', enquiry.createdByUserName),
                            if (isCancelled && enquiry.cancelReason != null)
                              _buildInfoRow(
                                  'Cancel Reason', enquiry.cancelReason!,
                                  valueColor: Colors.red[700]),
                            if (isConfirmed &&
                                enquiry.convertedOrderId != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Converted to Order #${enquiry.convertedOrderId}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[900],
                                        fontSize: 13,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                OrderDetailScreen(
                                              orderId:
                                                  enquiry.convertedOrderId!,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('Open Order'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Primary Action Buttons (Confirm to Order / Cancel)
                    if (!isConfirmed && !isCancelled) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () =>
                                  _showConfirmToOrderDialog(enquiry),
                              icon: const Icon(Icons.check_circle),
                              label: const Text(
                                'Confirm & Convert to Order',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[700],
                              side: BorderSide(color: Colors.red[300]!),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () =>
                                _showCancelEnquiryDialog(enquiry),
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 4. Follow-up Timeline & Comments Section
                    Row(
                      children: [
                        Icon(Icons.forum_outlined,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Follow-up Activity (${enquiry.comments.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'All team members with Marketing role can add and view follow-up logs.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),

                    // Add Follow-up Note Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _commentController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Add follow-up call note or update...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.all(10),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Quick Suggestion Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildQuickChip('📞 Called customer'),
                                const SizedBox(width: 6),
                                _buildQuickChip('📄 Sent quotation'),
                                const SizedBox(width: 6),
                                _buildQuickChip('📐 Site visit planned'),
                                const SizedBox(width: 6),
                                _buildQuickChip('⏳ Awaiting decision'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: _isAddingComment ? null : _submitComment,
                              icon: _isAddingComment
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send, size: 16),
                              label: const Text('Post Follow-up'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Timeline of Comments
                    if (enquiry.comments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        child: Text(
                          'No follow-up notes logged yet.',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: enquiry.comments.length,
                        separatorBuilder: (c, i) => const Divider(height: 16),
                        itemBuilder: (context, index) {
                          // Display in reverse chronological order
                          final comment = enquiry
                              .comments[enquiry.comments.length - 1 - index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  comment.userName.isNotEmpty
                                      ? comment.userName[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          comment.userName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          _formatDate(comment.createdAt),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment.text,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
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

  Widget _buildQuickChip(String text) {
    return InkWell(
      onTap: () {
        _commentController.text = text;
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
