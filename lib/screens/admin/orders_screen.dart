import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/order_model.dart';
import 'package:rr_fabrication/models/order_stage_model.dart';
import 'package:rr_fabrication/models/product_model.dart';
import 'package:rr_fabrication/screens/admin/admin_drawer.dart';
import 'package:rr_fabrication/screens/admin/order_detail_screen.dart';
import 'package:rr_fabrication/services/order_service.dart';
import 'package:rr_fabrication/services/product_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();

  OrderStatus? _selectedStatusFilter;

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange[700]!;
      case OrderStatus.inProgress:
        return Colors.blue[700]!;
      case OrderStatus.completed:
        return Colors.green[700]!;
      case OrderStatus.cancelled:
        return Colors.red[700]!;
    }
  }

  Color _getStatusBackgroundColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange[50]!;
      case OrderStatus.inProgress:
        return Colors.blue[50]!;
      case OrderStatus.completed:
        return Colors.green[50]!;
      case OrderStatus.cancelled:
        return Colors.red[50]!;
    }
  }

  void _showAddOrEditOrderDialog({
    OrderModel? existingOrder,
    required List<ProductModel> availableProducts,
  }) {
    final isEditing = existingOrder != null;
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);

    String? selectedProductId = isEditing ? existingOrder.productId : null;
    String selectedProductName = isEditing ? existingOrder.productName : '';

    // If creating and products exist, default to the first product
    if (!isEditing && availableProducts.isNotEmpty) {
      selectedProductId = availableProducts.first.id;
      selectedProductName = availableProducts.first.name;
    }

    final dimensionsController =
        TextEditingController(text: isEditing ? existingOrder.dimensions : '');
    final descriptionController =
        TextEditingController(text: isEditing ? existingOrder.description : '');
    OrderStatus selectedStatus =
        isEditing ? existingOrder.status : OrderStatus.pending;
    double completionPercentage =
        isEditing ? existingOrder.completionPercentage.toDouble() : 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note : Icons.add_shopping_cart,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(isEditing ? 'Edit Order' : 'Create New Order'),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Selection Dropdown
                        if (availableProducts.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber[300]!),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No products found. Please add products in "Products" first.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            initialValue: selectedProductId,
                            decoration: InputDecoration(
                              labelText: 'Select Product *',
                              prefixIcon:
                                  const Icon(Icons.inventory_2_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: availableProducts.map((product) {
                              return DropdownMenuItem<String>(
                                value: product.id,
                                child: Text(
                                  product.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  selectedProductId = value;
                                  final match = availableProducts
                                      .where((p) => p.id == value);
                                  if (match.isNotEmpty) {
                                    selectedProductName = match.first.name;
                                  }
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please select a product';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 16),

                        // Dimensions
                        TextFormField(
                          controller: dimensionsController,
                          decoration: InputDecoration(
                            labelText: 'Dimensions *',
                            hintText: 'e.g., 6ft x 4ft, 1500mm x 900mm',
                            prefixIcon: const Icon(Icons.straighten),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter dimensions';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Description / Notes
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description / Notes',
                            hintText:
                                'Custom client requirements, material grades...',
                            prefixIcon: const Icon(Icons.description_outlined),
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Status Dropdown
                        DropdownButtonFormField<OrderStatus>(
                          initialValue: selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Order Status',
                            prefixIcon: const Icon(Icons.flag_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: OrderStatus.values.map((status) {
                            return DropdownMenuItem<OrderStatus>(
                              value: status,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(status.displayName),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (newStatus) {
                            if (newStatus != null) {
                              setDialogState(() {
                                selectedStatus = newStatus;
                                if (newStatus == OrderStatus.completed) {
                                  completionPercentage = 100.0;
                                } else if (newStatus == OrderStatus.pending &&
                                    completionPercentage == 100.0) {
                                  completionPercentage = 0.0;
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // Completion Percentage Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Completion Progress:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${completionPercentage.round()}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Slider(
                          value: completionPercentage,
                          min: 0,
                          max: 100,
                          divisions: 20, // Step by 5%
                          label: '${completionPercentage.round()}%',
                          onChanged: (value) {
                            setDialogState(() {
                              completionPercentage = value;
                              if (value == 100.0) {
                                selectedStatus = OrderStatus.completed;
                              } else if (value > 0 &&
                                  selectedStatus == OrderStatus.pending) {
                                selectedStatus = OrderStatus.inProgress;
                              }
                            });
                          },
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
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          if (selectedProductId == null ||
                              selectedProductId!.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please select a product'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          try {
                            if (isEditing) {
                              await _orderService.updateOrder(
                                id: existingOrder.id,
                                productId: selectedProductId!,
                                productName: selectedProductName,
                                description: descriptionController.text,
                                dimensions: dimensionsController.text,
                                status: selectedStatus,
                                completionPercentage:
                                    completionPercentage.round(),
                              );
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Order updated successfully'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              await _orderService.addOrder(
                                productId: selectedProductId!,
                                productName: selectedProductName,
                                description: descriptionController.text,
                                dimensions: dimensionsController.text,
                                status: selectedStatus,
                                completionPercentage:
                                    completionPercentage.round(),
                              );
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Order created successfully'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                isSubmitting = false;
                              });
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to save order: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
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
                      : Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(
                    isSubmitting
                        ? 'Saving...'
                        : (isEditing ? 'Save Changes' : 'Create Order'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteOrder(OrderModel order) {
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Order'),
                ],
              ),
              content: Text(
                'Are you sure you want to delete order for "${order.productName}" (${order.dimensions})?\nThis action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() {
                            isDeleting = true;
                          });

                          try {
                            await _orderService.deleteOrder(order.id);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Order for "${order.productName}" deleted'),
                                backgroundColor: Colors.red[700],
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                isDeleting = false;
                              });
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete order: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  icon: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_forever),
                  label: Text(isDeleting ? 'Deleting...' : 'Delete'),
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
        final availableProducts = productsSnapshot.data ?? [];

        return StreamBuilder<List<OrderModel>>(
          stream: _orderService.getOrdersStream(),
          builder: (context, snapshot) {
            final allOrders = snapshot.data ?? [];
            final filteredOrders = _selectedStatusFilter == null
                ? allOrders
                : allOrders
                    .where((o) => o.status == _selectedStatusFilter)
                    .toList();

            final hasOrders = allOrders.isNotEmpty;

            return Scaffold(
              drawer: const AdminDrawer(currentScreen: AdminScreen.orders),
              appBar: AppBar(
                title: const Text('Manage Orders'),
              ),
              floatingActionButton: hasOrders
                  ? FloatingActionButton.extended(
                      onPressed: () => _showAddOrEditOrderDialog(
                        availableProducts: availableProducts,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('New Order'),
                    )
                  : null,
              body: () {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint('Error loading orders: ${snapshot.error}');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Failed to load orders',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (allOrders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No Orders Created Yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create fabrication orders with product details, dimensions, status, and track progress.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showAddOrEditOrderDialog(
                              availableProducts: availableProducts,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Order'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Status Filter Chips
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: Text('All (${allOrders.length})'),
                              selected: _selectedStatusFilter == null,
                              onSelected: (_) {
                                setState(() {
                                  _selectedStatusFilter = null;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ...OrderStatus.values.map((status) {
                              final count = allOrders
                                  .where((o) => o.status == status)
                                  .length;
                              final isSelected =
                                  _selectedStatusFilter == status;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(
                                    '${status.displayName} ($count)',
                                  ),
                                  selected: isSelected,
                                  selectedColor: _getStatusBackgroundColor(status),
                                  checkmarkColor: _getStatusColor(status),
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedStatusFilter =
                                          isSelected ? null : status;
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),

                    // Orders List
                    Expanded(
                      child: filteredOrders.isEmpty
                          ? Center(
                              child: Text(
                                'No orders with status "${_selectedStatusFilter?.displayName}"',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 12,
                                bottom: 80, // Clearance for FAB
                              ),
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = filteredOrders[index];
                                final statusColor = _getStatusColor(order.status);
                                final statusBgColor =
                                    _getStatusBackgroundColor(order.status);

                                return Card(
                                  elevation: 1.5,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              OrderDetailScreen(
                                            orderId: order.id,
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
                                          // Header Row: Product Thumbnail, Name & Status Badge
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              () {
                                                final match = availableProducts
                                                    .where((p) =>
                                                        p.id == order.productId)
                                                    .toList();
                                                final img = match.isNotEmpty
                                                    ? match.first.imageUrl
                                                    : null;
                                                if (img != null &&
                                                    img.isNotEmpty) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 12.0),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      child: Container(
                                                        width: 52,
                                                        height: 52,
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary
                                                                .withValues(
                                                                    alpha:
                                                                        0.15),
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                        child: Image.network(
                                                          img,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (c, e, s) => Icon(
                                                            Icons
                                                                .inventory_2_outlined,
                                                            size: 26,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return const SizedBox.shrink();
                                              }(),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      order.productName,
                                                      style: const TextStyle(
                                                        fontSize: 17,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    // Dimensions Chip
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.straighten,
                                                          size: 14,
                                                          color: Colors.grey[600],
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          order.dimensions,
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors.grey[800],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Status Badge
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: statusBgColor,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: statusColor
                                                        .withValues(alpha: 0.4),
                                                  ),
                                                ),
                                                child: Text(
                                                  order.status.displayName,
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          if (order
                                              .description.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              order.description,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],

                                          const SizedBox(height: 14),

                                          // Completion Progress Bar
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Completion: ${order.completionPercentage}% (${order.stages.where((s) => s.status == OrderStageStatus.completed).length}/${order.stages.length} stages)',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                              Text(
                                                order.completionPercentage == 100
                                                    ? 'Finished'
                                                    : '${100 - order.completionPercentage}% remaining',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: LinearProgressIndicator(
                                              value:
                                                  order.completionPercentage / 100.0,
                                              minHeight: 8,
                                              backgroundColor: Colors.grey[200],
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                order.completionPercentage == 100
                                                    ? Colors.green
                                                    : (order.completionPercentage >= 50
                                                        ? Colors.blue
                                                        : Colors.orange),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 10),
                                          // Actions Row
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          OrderDetailScreen(
                                                        orderId: order.id,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                    Icons.format_list_numbered,
                                                    size: 16),
                                                label: const Text('Process Stages'),
                                              ),
                                              const SizedBox(width: 4),
                                              TextButton.icon(
                                                onPressed: () =>
                                                    _showAddOrEditOrderDialog(
                                                  existingOrder: order,
                                                  availableProducts:
                                                      availableProducts,
                                                ),
                                                icon: const Icon(
                                                    Icons.edit_outlined,
                                                    size: 16),
                                                label: const Text('Edit'),
                                              ),
                                              const SizedBox(width: 4),
                                              TextButton.icon(
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red[600],
                                                ),
                                                onPressed: () =>
                                                    _confirmDeleteOrder(order),
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 16),
                                                label: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              }(),
            );
          },
        );
      },
    );
  }
}