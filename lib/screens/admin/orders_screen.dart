import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/order_model.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  void _showAddOrderDialog({
    required List<ProductModel> availableProducts,
  }) {
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);

    String? selectedProductId =
        availableProducts.isNotEmpty ? availableProducts.first.id : null;
    String selectedProductName =
        availableProducts.isNotEmpty ? availableProducts.first.name : '';

    final dimensionsController = TextEditingController();
    final descriptionController = TextEditingController();

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
                    Icons.add_shopping_cart,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Create New Order'),
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
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: dimensionsController,
                          decoration: InputDecoration(
                            labelText: 'Dimensions *',
                            hintText: 'e.g., 10x12 ft, 50 running feet',
                            prefixIcon: const Icon(Icons.straighten),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter order dimensions';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description / Client Notes',
                            hintText: 'Specifications or instructions...',
                            prefixIcon:
                                const Icon(Icons.description_outlined),
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
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
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          if (selectedProductId == null ||
                              selectedProductName.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please select a product'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          try {
                            await _orderService.addOrder(
                              productId: selectedProductId!,
                              productName: selectedProductName,
                              description: descriptionController.text,
                              dimensions: dimensionsController.text,
                            );

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Order created successfully'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to create order: $e'),
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
                      : const Icon(Icons.add_shopping_cart),
                  label: Text(
                      isSubmitting ? 'Creating Order...' : 'Create Order'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditOrderBasicDetailsDialog({
    required OrderModel existingOrder,
    required List<ProductModel> availableProducts,
  }) {
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);

    String? selectedProductId = existingOrder.productId;
    String selectedProductName = existingOrder.productName;

    final dimensionsController =
        TextEditingController(text: existingOrder.dimensions);
    final descriptionController =
        TextEditingController(text: existingOrder.description);
    OrderStatus selectedStatus = existingOrder.status;

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
                    Icons.edit_note,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Edit Order Basic Details'),
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
                        Text(
                          'Note: Editing basic details will preserve all assigned workers and completed stage progress.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Product Dropdown
                        DropdownButtonFormField<String>(
                          initialValue:
                              selectedProductId?.isNotEmpty == true
                                  ? selectedProductId
                                  : null,
                          decoration: InputDecoration(
                            labelText: 'Product *',
                            prefixIcon:
                                const Icon(Icons.inventory_2_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: [
                            if (!availableProducts
                                .any((p) => p.id == selectedProductId))
                              DropdownMenuItem<String>(
                                value: selectedProductId,
                                child: Text(selectedProductName),
                              ),
                            ...availableProducts.map((product) {
                              return DropdownMenuItem<String>(
                                value: product.id,
                                child: Text(
                                  product.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
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
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: dimensionsController,
                          decoration: InputDecoration(
                            labelText: 'Dimensions *',
                            hintText: 'e.g., 10x12 ft',
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
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description / Notes',
                            prefixIcon:
                                const Icon(Icons.description_outlined),
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                              child: Text(status.displayName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => selectedStatus = value);
                            }
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

                          setDialogState(() => isSubmitting = true);

                          try {
                            await _orderService.updateOrderBasicDetails(
                              id: existingOrder.id,
                              productId: selectedProductId ?? '',
                              productName: selectedProductName,
                              description: descriptionController.text,
                              dimensions: dimensionsController.text,
                              status: selectedStatus,
                            );

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Order details updated'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content:
                                    Text('Failed to update order: $e'),
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
                      : const Icon(Icons.save),
                  label: Text(
                      isSubmitting ? 'Saving...' : 'Save Details'),
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
      builder: (dialogContext) {
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
            'Are you sure you want to delete order for "${order.productName}"?\nThis will remove all associated stages and progress.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await _orderService.deleteOrder(order.id);
                  messenger.showSnackBar(
                    SnackBar(
                      content:
                          Text('Order for "${order.productName}" deleted'),
                      backgroundColor: Colors.red[700],
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete order: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete'),
            ),
          ],
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
        final productMap = {for (var p in availableProducts) p.id: p};

        return StreamBuilder<List<OrderModel>>(
          stream: _orderService.getOrdersStream(),
          builder: (context, snapshot) {
            final allOrders = snapshot.data ?? [];

            var filteredOrders = allOrders;
            if (_selectedStatusFilter != null) {
              filteredOrders = filteredOrders
                  .where((o) => o.status == _selectedStatusFilter)
                  .toList();
            }

            if (_searchQuery.trim().isNotEmpty) {
              final q = _searchQuery.trim().toLowerCase();
              filteredOrders = filteredOrders.where((o) {
                return o.productName.toLowerCase().contains(q) ||
                    o.dimensions.toLowerCase().contains(q) ||
                    o.description.toLowerCase().contains(q);
              }).toList();
            }

            final hasOrders = allOrders.isNotEmpty;

            return Scaffold(
              drawer: const AdminDrawer(currentScreen: AdminScreen.orders),
              appBar: AppBar(
                title: const Text('Manage Orders'),
              ),
              floatingActionButton: hasOrders
                  ? FloatingActionButton.extended(
                      onPressed: () => _showAddOrderDialog(
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
                  return Center(
                    child: Text('Failed to load orders: ${snapshot.error}'),
                  );
                }

                if (!hasOrders) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Orders Yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create fabrication orders to track progress across sequential process stages.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showAddOrderDialog(
                              availableProducts: availableProducts,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Order'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Search & Filters
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search orders by product or size...',
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('All Orders'),
                            selected: _selectedStatusFilter == null,
                            onSelected: (selected) {
                              setState(() => _selectedStatusFilter = null);
                            },
                          ),
                          const SizedBox(width: 8),
                          ...OrderStatus.values.map((status) {
                            final isSelected =
                                _selectedStatusFilter == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(status.displayName),
                                selected: isSelected,
                                selectedColor: _getStatusBackgroundColor(status),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? _getStatusColor(status)
                                      : null,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStatusFilter =
                                        selected ? status : null;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Order List
                    Expanded(
                      child: filteredOrders.isEmpty
                          ? Center(
                              child: Text(
                                'No orders matching current filter',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 12,
                                bottom: 80,
                              ),
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = filteredOrders[index];
                                final statusColor =
                                    _getStatusColor(order.status);
                                final statusBgColor =
                                    _getStatusBackgroundColor(order.status);
                                final product = productMap[order.productId];
                                final productImageUrl = product?.imageUrl;

                                return Card(
                                  elevation: 1.5,
                                  margin: const EdgeInsets.only(bottom: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.15),
                                    ),
                                  ),
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
                                            if (productImageUrl != null &&
                                                productImageUrl.isNotEmpty)
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.network(
                                                  productImageUrl,
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) =>
                                                      const SizedBox.shrink(),
                                                ),
                                              ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    order.productName,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.straighten,
                                                        size: 13,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        order.dimensions,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Colors.grey[800],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
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
                                                order.status.displayName,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (order.description.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            order.description,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        // Progress Bar
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value:
                                                order.completionPercentage /
                                                    100.0,
                                            minHeight: 6,
                                            backgroundColor: Colors.grey[200],
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              order.completionPercentage == 100
                                                  ? Colors.green
                                                  : (order.completionPercentage >=
                                                          50
                                                      ? Colors.blue
                                                      : Colors.orange),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        // Actions Row: Separate Details vs Stages & Delete
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
                                                  size: 15),
                                              label: const Text(
                                                  'Process Stages'),
                                            ),
                                            const SizedBox(width: 4),
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _showEditOrderBasicDetailsDialog(
                                                existingOrder: order,
                                                availableProducts:
                                                    availableProducts,
                                              ),
                                              icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 15),
                                              label:
                                                  const Text('Edit Details'),
                                            ),
                                            const SizedBox(width: 4),
                                            TextButton.icon(
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    Colors.red[600],
                                              ),
                                              onPressed: () =>
                                                  _confirmDeleteOrder(order),
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 15),
                                              label: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ],
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