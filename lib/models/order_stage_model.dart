import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStageStatus {
  pending,
  assigned,
  inProgress,
  paused,
  completed;

  String get displayName {
    switch (this) {
      case OrderStageStatus.pending:
        return 'Pending';
      case OrderStageStatus.assigned:
        return 'Assigned';
      case OrderStageStatus.inProgress:
        return 'In Progress';
      case OrderStageStatus.paused:
        return 'Paused';
      case OrderStageStatus.completed:
        return 'Completed';
    }
  }

  static OrderStageStatus fromString(String? value) {
    if (value == null) return OrderStageStatus.pending;
    return OrderStageStatus.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == value.toLowerCase() ||
          e.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => OrderStageStatus.pending,
    );
  }
}

class OrderStageModel {
  final String stageId;
  final String stageName;
  final OrderStageStatus status;
  final String? assignedWorkerId;
  final String? assignedWorkerName;
  final DateTime? startedAt;
  final DateTime? completedAt;

  OrderStageModel({
    required this.stageId,
    required this.stageName,
    this.status = OrderStageStatus.pending,
    this.assignedWorkerId,
    this.assignedWorkerName,
    this.startedAt,
    this.completedAt,
  });

  factory OrderStageModel.fromMap(Map<String, dynamic> data) {
    final startTimestamp = data['startedAt'];
    DateTime? startDateTime;
    if (startTimestamp is Timestamp) {
      startDateTime = startTimestamp.toDate();
    }

    final endTimestamp = data['completedAt'];
    DateTime? endDateTime;
    if (endTimestamp is Timestamp) {
      endDateTime = endTimestamp.toDate();
    }

    return OrderStageModel(
      stageId: data['stageId'] as String? ?? '',
      stageName: data['stageName'] as String? ?? 'Stage',
      status: OrderStageStatus.fromString(data['status'] as String?),
      assignedWorkerId: data['assignedWorkerId'] as String?,
      assignedWorkerName: data['assignedWorkerName'] as String?,
      startedAt: startDateTime,
      completedAt: endDateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stageId': stageId,
      'stageName': stageName,
      'status': status.name,
      'assignedWorkerId': assignedWorkerId,
      'assignedWorkerName': assignedWorkerName,
      'startedAt':
          startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  OrderStageModel copyWith({
    String? stageId,
    String? stageName,
    OrderStageStatus? status,
    String? assignedWorkerId,
    String? assignedWorkerName,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return OrderStageModel(
      stageId: stageId ?? this.stageId,
      stageName: stageName ?? this.stageName,
      status: status ?? this.status,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      assignedWorkerName: assignedWorkerName ?? this.assignedWorkerName,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
