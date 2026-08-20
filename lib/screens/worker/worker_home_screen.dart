import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/order_model.dart';
import 'package:rr_fabrication/models/order_stage_model.dart';
import 'package:rr_fabrication/models/user_role.dart';
import 'package:rr_fabrication/screens/common/app_drawer.dart';
import 'package:rr_fabrication/screens/worker/worker_task_detail_screen.dart';
import 'package:rr_fabrication/services/auth_service.dart';
import 'package:rr_fabrication/services/order_service.dart';

class WorkerHomeScreen extends StatefulWidget {
  final UserRole userRole;
  const WorkerHomeScreen({super.key, required this.userRole});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();

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

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.getCurrentUser();
    final workerId = currentUser?.uid ?? '';

    return Scaffold(
      drawer: AppDrawer(
        currentItem: DrawerItem.workerHome,
        userRole: widget.userRole,
      ),
      appBar: AppBar(
        title: const Text('My Work & Tasks'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _orderService.getOrdersForWorkerStream(workerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading tasks: ${snapshot.error}'),
            );
          }

          final orders = snapshot.data ?? [];

          // Collect all assigned stages for this worker
          final List<_WorkerTaskItem> tasks = [];
          for (final order in orders) {
            for (int i = 0; i < order.stages.length; i++) {
              final stage = order.stages[i];
              if (stage.assignedWorkerId == workerId) {
                tasks.add(
                  _WorkerTaskItem(
                    order: order,
                    stage: stage,
                    stageIndex: i,
                  ),
                );
              }
            }
          }

          if (tasks.isEmpty) {
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
                        Icons.engineering_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Tasks Assigned',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When the admin allocates a fabrication stage to you, it will appear here for execution.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final item = tasks[index];
              final order = item.order;
              final stage = item.stage;
              final stageIndex = item.stageIndex;
              final statusColor = _getStatusColor(stage.status);
              final statusBgColor = _getStatusBgColor(stage.status);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkerTaskDetailScreen(
                          orderId: order.id,
                          stageIndex: stageIndex,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stage header & status badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stage ${stageIndex + 1}: ${stage.stageName}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    order.productName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
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
                        const SizedBox(height: 10),

                        // Dimensions & notes
                        Row(
                          children: [
                            Icon(Icons.straighten,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              order.dimensions,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        if (order.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            order.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Tap prompt row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              stage.status == OrderStageStatus.completed
                                  ? 'View Summary'
                                  : (stage.status == OrderStageStatus.inProgress
                                      ? 'Active - Tap to Control'
                                      : 'Tap to Start'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WorkerTaskItem {
  final OrderModel order;
  final OrderStageModel stage;
  final int stageIndex;

  _WorkerTaskItem({
    required this.order,
    required this.stage,
    required this.stageIndex,
  });
}