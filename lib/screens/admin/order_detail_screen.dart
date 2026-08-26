import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/order_model.dart';
import 'package:rr_fabrication/models/order_stage_model.dart';
import 'package:rr_fabrication/models/product_model.dart';
import 'package:rr_fabrication/models/stage_model.dart';
import 'package:rr_fabrication/models/user_model.dart';
import 'package:rr_fabrication/models/user_role.dart';
import 'package:rr_fabrication/services/order_service.dart';
import 'package:rr_fabrication/services/product_service.dart';
import 'package:rr_fabrication/services/stage_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();
  final StageService _stageService = StageService();

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
                          'Editing basic details preserves all worker assignments and stage progress.',
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
                            prefixIcon: const Icon(Icons.inventory_2_outlined),
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
                            prefixIcon: const Icon(Icons.description_outlined),
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
                                content: Text('Failed to update order: $e'),
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
                  label: Text(isSubmitting ? 'Saving...' : 'Save Details'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showManageOrderStagesDialog({
    required OrderModel order,
    required List<StageModel> availableStages,
  }) {
    List<OrderStageModel> workingStages =
        List<OrderStageModel>.from(order.stages);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void addStageFromMaster(StageModel master) {
              setDialogState(() {
                workingStages.add(
                  OrderStageModel(
                    stageId: master.id,
                    stageName: master.name,
                    status: OrderStageStatus.pending,
                  ),
                );
              });
            }

            void moveStage(int oldIndex, int newIndex) {
              if (newIndex < 0 || newIndex >= workingStages.length) return;
              setDialogState(() {
                final item = workingStages.removeAt(oldIndex);
                workingStages.insert(newIndex, item);
              });
            }

            void removeStage(int index) {
              setDialogState(() {
                workingStages.removeAt(index);
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.account_tree_outlined),
                  SizedBox(width: 8),
                  Text('Manage Process Stages'),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reorder, add, or remove stages specifically for this order.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),

                      // List of current stages
                      if (workingStages.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber[300]!),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No stages in pipeline. Add stages below or sync from product definition.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: workingStages.length,
                          itemBuilder: (context, index) {
                            final stage = workingStages[index];
                            final isFirst = index == 0;
                            final isLast = index == workingStages.length - 1;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey[200]!),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.15),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  stage.stageName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  stage.assignedWorkerName != null
                                      ? 'Worker: ${stage.assignedWorkerName} (${stage.status.displayName})'
                                      : 'Status: ${stage.status.displayName}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_upward,
                                          size: 16),
                                      onPressed: isFirst
                                          ? null
                                          : () => moveStage(index, index - 1),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_downward,
                                          size: 16),
                                      onPressed: isLast
                                          ? null
                                          : () => moveStage(index, index + 1),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18, color: Colors.red),
                                      onPressed: () => removeStage(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 16),
                      const Text(
                        'Add Stage to Pipeline:',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      if (availableStages.isEmpty)
                        const Text(
                          'No predefined stages found.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: availableStages.map((s) {
                            return ActionChip(
                              avatar: const Icon(Icons.add, size: 14),
                              label: Text(s.name,
                                  style: const TextStyle(fontSize: 11)),
                              onPressed: () => addStageFromMaster(s),
                            );
                          }).toList(),
                        ),

                      if (order.productId.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () async {
                            try {
                              await _orderService.syncOrderStagesFromProduct(
                                  order.id, order.productId);
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Stages synchronized from Product'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Sync failed: $e')),
                              );
                            }
                          },
                          icon: const Icon(Icons.sync, size: 16),
                          label: const Text('Reset & Sync from Product Stages'),
                        ),
                      ],
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
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            await _orderService.updateOrderStages(
                              orderId: order.id,
                              stages: workingStages,
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Order stages updated'),
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
                                    Text('Failed to update stages: $e'),
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
                      : const Icon(Icons.save),
                  label: Text(
                      isSubmitting ? 'Saving Stages...' : 'Save Stage Pipeline'),
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
            'Are you sure you want to delete order for "${order.productName}"?\nThis will remove all associated stages and worker progress.',
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
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
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

  void _showWorkerAllocationDialog({
    required OrderModel order,
    required int stageIndex,
    required OrderStageModel stage,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.person_add_alt_1_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Allocate Worker for ${stage.stageName}',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: UserRole.WORKER.name)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    heightFactor: 3,
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading workers: ${snapshot.error}'),
                  );
                }

                final workers = (snapshot.data?.docs ?? [])
                    .map((doc) => UserModel.fromFirestore(doc))
                    .toList();

                if (workers.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.engineering_outlined,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text(
                          'No workers available',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Assign worker role to users under "Workers" or "Users" screen.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select a worker to execute Stage ${stageIndex + 1} (${stage.stageName}):',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: workers.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final worker = workers[index];
                          final isCurrentlyAssigned =
                              stage.assignedWorkerId == worker.id;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.15),
                              child: Text(
                                worker.name.isNotEmpty
                                    ? worker.name[0].toUpperCase()
                                    : 'W',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              worker.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              worker.email,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            trailing: isCurrentlyAssigned
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : const Icon(Icons.chevron_right),
                            onTap: () async {
                              Navigator.of(dialogContext).pop();
                              try {
                                await _orderService.assignWorkerToStage(
                                  orderId: order.id,
                                  stageIndex: stageIndex,
                                  workerId: worker.id,
                                  workerName: worker.name,
                                );
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Assigned "${stage.stageName}" to ${worker.name}',
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to assign worker: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
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

        return StreamBuilder<List<StageModel>>(
          stream: _stageService.getStagesStream(),
          builder: (context, stagesSnapshot) {
            final availableStages = stagesSnapshot.data ?? [];

            return StreamBuilder<OrderModel?>(
              stream: _orderService.getOrderByIdStream(widget.orderId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Order Details')),
                    body: const Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Order Details')),
                    body: Center(
                      child: Text('Error loading order: ${snapshot.error}'),
                    ),
                  );
                }

                final order = snapshot.data;
                if (order == null) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Order Details')),
                    body: const Center(child: Text('Order not found')),
                  );
                }

                final product = productMap[order.productId];
                final productImageUrl = product?.imageUrl;
                final statusColor = _getStatusColor(order.status);
                final statusBgColor = _getStatusBackgroundColor(order.status);

                final stages = order.stages;
                int activeStageIndex = -1;
                for (int i = 0; i < stages.length; i++) {
                  if (stages[i].status != OrderStageStatus.completed) {
                    activeStageIndex = i;
                    break;
                  }
                }

                return Scaffold(
                  appBar: AppBar(
                    title: Text('Order: ${order.productName}'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete Order',
                        color: Colors.white,
                        onPressed: () => _confirmDeleteOrder(order),
                      ),
                    ],
                  ),
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Order Summary Card with Separate "Edit Basic Details" button
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (productImageUrl != null &&
                                        productImageUrl.isNotEmpty) ...[
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: Image.network(
                                          productImageUrl,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) =>
                                              const SizedBox.shrink(),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                    ],
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order.productName,
                                            style: const TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.straighten,
                                                  size: 15,
                                                  color: Colors.grey[700]),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Dimensions: ${order.dimensions}',
                                                style: TextStyle(
                                                  fontSize: 13,
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
                                if (order.description.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    order.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Overall Progress: ${order.completionPercentage}%',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${stages.where((s) => s.status == OrderStageStatus.completed).length} / ${stages.length} Stages',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
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
                                const Divider(height: 24),
                                // Separate Edit Basic Details Action
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _showEditOrderBasicDetailsDialog(
                                        existingOrder: order,
                                        availableProducts: availableProducts,
                                      ),
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 16),
                                      label: const Text(
                                          'Edit Name, Specs & Status'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 2. Sequential Process Stages Section Header with "Manage Stages" button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.format_list_numbered, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Sequential Process Stages',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              onPressed: () => _showManageOrderStagesDialog(
                                order: order,
                                availableStages: availableStages,
                              ),
                              icon: const Icon(Icons.tune, size: 16),
                              label: const Text('Manage Stages'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Only the current stage is active. Future stages remain disabled in red until earlier stages are completed.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3. Stage Pipeline List
                        if (stages.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber[300]!),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 36, color: Colors.orange),
                                const SizedBox(height: 8),
                                const Text(
                                  'No stages assigned to this order',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _showManageOrderStagesDialog(
                                    order: order,
                                    availableStages: availableStages,
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add / Manage Stages'),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: stages.length,
                            itemBuilder: (context, index) {
                              final stage = stages[index];
                              final isCompleted = stage.status ==
                                  OrderStageStatus.completed;
                              final isActive = index == activeStageIndex;
                              final isFutureLocked =
                                  index > activeStageIndex &&
                                      activeStageIndex != -1;

                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 12.0),
                                child: _buildStageCard(
                                  context: context,
                                  order: order,
                                  stage: stage,
                                  stageIndex: index,
                                  activeStageIndex: activeStageIndex,
                                  isCompleted: isCompleted,
                                  isActive: isActive,
                                  isFutureLocked: isFutureLocked,
                                ),
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
      },
    );
  }

  Widget _buildStageCard({
    required BuildContext context,
    required OrderModel order,
    required OrderStageModel stage,
    required int stageIndex,
    required int activeStageIndex,
    required bool isCompleted,
    required bool isActive,
    required bool isFutureLocked,
  }) {
    // 1. COMPLETED STAGE (Green card with checkmark)
    if (isCompleted) {
      return Card(
        elevation: 1,
        color: Colors.green[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.green[300]!, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stage ${stageIndex + 1}: ${stage.stageName}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stage.assignedWorkerName != null
                          ? 'Completed by ${stage.assignedWorkerName}'
                          : 'Completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.green[900],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. ACTIVE STAGE (Single Actionable Button)
    if (isActive) {
      final isAssigned = stage.assignedWorkerName != null &&
          stage.assignedWorkerName!.isNotEmpty;

      return Card(
        elevation: 3,
        color: Theme.of(context)
            .colorScheme
            .primary
            .withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${stageIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stage ${stageIndex + 1}: ${stage.stageName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAssigned
                              ? 'Assigned to: ${stage.assignedWorkerName} (${stage.status.displayName})'
                              : 'Status: Pending Worker Allocation',
                          style: TextStyle(
                            fontSize: 12,
                            color: isAssigned
                                ? Theme.of(context).colorScheme.primary
                                : Colors.orange[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor:
                        Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _showWorkerAllocationDialog(
                    order: order,
                    stageIndex: stageIndex,
                    stage: stage,
                  ),
                  icon: Icon(isAssigned
                      ? Icons.swap_horiz
                      : Icons.person_add_alt_1),
                  label: Text(
                    isAssigned
                        ? 'Reallocate Worker (${stage.assignedWorkerName})'
                        : 'Allocate Worker for this Stage',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. FUTURE LOCKED STAGES (Disabled in RED color)
    return Card(
      elevation: 0,
      color: Colors.red[50]?.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.red[300]!.withValues(alpha: 0.8),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.red[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline,
                  color: Colors.red[700], size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stage ${stageIndex + 1}: ${stage.stageName}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[900],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Disabled (Waiting for Stage ${activeStageIndex + 1} to complete)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'LOCKED',
                style: TextStyle(
                  color: Colors.red[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
