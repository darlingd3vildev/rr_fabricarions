import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/order_model.dart';
import 'package:rr_fabrication/models/order_stage_model.dart';
import 'package:rr_fabrication/services/order_service.dart';

class WorkerTaskDetailScreen extends StatefulWidget {
  final String orderId;
  final int stageIndex;

  const WorkerTaskDetailScreen({
    super.key,
    required this.orderId,
    required this.stageIndex,
  });

  @override
  State<WorkerTaskDetailScreen> createState() => _WorkerTaskDetailScreenState();
}

class _WorkerTaskDetailScreenState extends State<WorkerTaskDetailScreen> {
  final OrderService _orderService = OrderService();
  bool _isActionInProgress = false;

  Color _getStatusColor(OrderStageStatus status) {
    switch (status) {
      case OrderStageStatus.pending:
        return Colors.orange[700]!;
      case OrderStageStatus.assigned:
        return Colors.purple[700]!;
      case OrderStageStatus.inProgress:
        return Colors.blue[700]!;
      case OrderStageStatus.paused:
        return Colors.amber[800]!;
      case OrderStageStatus.completed:
        return Colors.green[700]!;
    }
  }

  Color _getStatusBgColor(OrderStageStatus status) {
    switch (status) {
      case OrderStageStatus.pending:
        return Colors.orange[50]!;
      case OrderStageStatus.assigned:
        return Colors.purple[50]!;
      case OrderStageStatus.inProgress:
        return Colors.blue[50]!;
      case OrderStageStatus.paused:
        return Colors.amber[50]!;
      case OrderStageStatus.completed:
        return Colors.green[50]!;
    }
  }

  Future<void> _handleStatusChange(
    OrderStageStatus newStatus,
    String successMessage,
  ) async {
    setState(() => _isActionInProgress = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _orderService.updateStageStatus(
        orderId: widget.orderId,
        stageIndex: widget.stageIndex,
        newStatus: newStatus,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: newStatus == OrderStageStatus.completed
              ? Colors.green
              : (newStatus == OrderStageStatus.paused
                  ? Colors.amber[800]
                  : Colors.blue),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update task: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  void _confirmCompleteTask() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Text('Complete Task'),
            ],
          ),
          content: const Text(
            'Are you sure you want to mark this stage as Completed?\nThis will advance the order to the next stage.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleStatusChange(
                  OrderStageStatus.completed,
                  'Stage completed! Order advanced.',
                );
              },
              child: const Text('Confirm Complete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Execution'),
      ),
      body: StreamBuilder<OrderModel?>(
        stream: _orderService.getOrderByIdStream(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = snapshot.data;
          if (order == null ||
              widget.stageIndex >= order.stages.length ||
              widget.stageIndex < 0) {
            return const Center(
              child: Text('Task not found or order has been removed.'),
            );
          }

          final stage = order.stages[widget.stageIndex];
          final statusColor = _getStatusColor(stage.status);
          final statusBgColor = _getStatusBgColor(stage.status);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Task Stage Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Stage ${widget.stageIndex + 1} of ${order.stages.length}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
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
                                  color: statusColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                stage.status.displayName,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stage.stageName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (stage.assignedWorkerName != null)
                          Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Assigned to: ${stage.assignedWorkerName}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Order Information Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Specifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          icon: Icons.inventory_2_outlined,
                          label: 'Product',
                          value: order.productName,
                        ),
                        const SizedBox(height: 10),
                        _buildDetailRow(
                          icon: Icons.straighten,
                          label: 'Dimensions',
                          value: order.dimensions,
                        ),
                        if (order.description.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildDetailRow(
                            icon: Icons.description_outlined,
                            label: 'Notes',
                            value: order.description,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 3. Worker Interactive Action Controls
                _buildActionControls(stage),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionControls(OrderStageModel stage) {
    if (_isActionInProgress) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // A. COMPLETED: Show celebration box
    if (stage.status == OrderStageStatus.completed) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green[300]!),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 8),
            const Text(
              'Stage Completed!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Great work! This stage has been successfully finished.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.green[800]),
            ),
          ],
        ),
      );
    }

    // B. ASSIGNED OR PENDING: Show "START" Button
    if (stage.status == OrderStageStatus.assigned ||
        stage.status == OrderStageStatus.pending) {
      return SizedBox(
        height: 56,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 3,
          ),
          onPressed: () => _handleStatusChange(
            OrderStageStatus.inProgress,
            'Task started! Status is now In Progress.',
          ),
          icon: const Icon(Icons.play_arrow, size: 28),
          label: const Text(
            'Start Task',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // C. IN PROGRESS: Show "PAUSE" and "COMPLETE" Buttons
    if (stage.status == OrderStageStatus.inProgress) {
      return Column(
        children: [
          Row(
            children: [
              // Pause Button
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => _handleStatusChange(
                      OrderStageStatus.paused,
                      'Task paused.',
                    ),
                    icon: const Icon(Icons.pause, size: 24),
                    label: const Text(
                      'Pause',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Complete Button
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _confirmCompleteTask,
                    icon: const Icon(Icons.check_circle, size: 24),
                    label: const Text(
                      'Complete',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Task is actively in progress.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    // D. PAUSED: Show "RESUME" and "COMPLETE" Buttons
    if (stage.status == OrderStageStatus.paused) {
      return Column(
        children: [
          Row(
            children: [
              // Resume Button
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => _handleStatusChange(
                      OrderStageStatus.inProgress,
                      'Task resumed! Status is now In Progress.',
                    ),
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: const Text(
                      'Resume',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Complete Button
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _confirmCompleteTask,
                    icon: const Icon(Icons.check_circle, size: 24),
                    label: const Text(
                      'Complete',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Task is currently paused. Tap Resume to continue work.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber[900],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
