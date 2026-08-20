import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rr_fabrication/models/order_stage_model.dart';

enum OrderStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String? value) {
    if (value == null) return OrderStatus.pending;
    return OrderStatus.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == value.toLowerCase() ||
          e.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
  }
}

class OrderModel {
  final String id;
  final String productId;
  final String productName;
  final String description;
  final String dimensions;
  final OrderStatus status;
  final int completionPercentage;
  final List<OrderStageModel> stages;
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.description,
    required this.dimensions,
    this.status = OrderStatus.pending,
    this.completionPercentage = 0,
    this.stages = const [],
    this.createdAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestamp = data['createdAt'];
    DateTime? createdDateTime;
    if (timestamp is Timestamp) {
      createdDateTime = timestamp.toDate();
    }

    final rawPercentage = data['completionPercentage'];
    int percentage = 0;
    if (rawPercentage is int) {
      percentage = rawPercentage;
    } else if (rawPercentage is num) {
      percentage = rawPercentage.toInt();
    }

    final rawStages = data['stages'];
    List<OrderStageModel> parsedStages = [];
    if (rawStages is List) {
      parsedStages = rawStages
          .whereType<Map>()
          .map((item) =>
              OrderStageModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    return OrderModel(
      id: doc.id,
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      description: data['description'] as String? ?? '',
      dimensions: data['dimensions'] as String? ?? '',
      status: OrderStatus.fromString(data['status'] as String?),
      completionPercentage: percentage.clamp(0, 100),
      stages: parsedStages,
      createdAt: createdDateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'description': description,
      'dimensions': dimensions,
      'status': status.name,
      'completionPercentage': completionPercentage,
      'stages': stages.map((s) => s.toMap()).toList(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  OrderModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? description,
    String? dimensions,
    OrderStatus? status,
    int? completionPercentage,
    List<OrderStageModel>? stages,
    DateTime? createdAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      dimensions: dimensions ?? this.dimensions,
      status: status ?? this.status,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      stages: stages ?? this.stages,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
