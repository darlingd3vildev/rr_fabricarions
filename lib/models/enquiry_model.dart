import 'package:cloud_firestore/cloud_firestore.dart';

enum EnquiryStatus {
  active,
  followup,
  confirmed,
  cancelled;

  String get displayName {
    switch (this) {
      case EnquiryStatus.active:
        return 'Active';
      case EnquiryStatus.followup:
        return 'In Follow-up';
      case EnquiryStatus.confirmed:
        return 'Confirmed (Converted to Order)';
      case EnquiryStatus.cancelled:
        return 'Cancelled';
    }
  }

  static EnquiryStatus fromString(String? value) {
    if (value == null) return EnquiryStatus.active;
    return EnquiryStatus.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == value.toLowerCase() ||
          e.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => EnquiryStatus.active,
    );
  }
}

class EnquiryComment {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  EnquiryComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  factory EnquiryComment.fromMap(Map<String, dynamic> data) {
    final ts = data['createdAt'];
    DateTime date = DateTime.now();
    if (ts is Timestamp) {
      date = ts.toDate();
    } else if (ts is String) {
      date = DateTime.tryParse(ts) ?? DateTime.now();
    }

    return EnquiryComment(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'User',
      text: data['text'] as String? ?? '',
      createdAt: date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class EnquiryModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String? customerAddress;
  final String? productId;
  final String productName;
  final String dimensions;
  final String description;
  final double? estimatedBudget;
  final EnquiryStatus status;
  final String createdByUserId;
  final String createdByUserName;
  final String? assignedToUserId;
  final String? assignedToUserName;
  final List<EnquiryComment> comments;
  final String? convertedOrderId;
  final String? cancelReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EnquiryModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    this.customerAddress,
    this.productId,
    required this.productName,
    this.dimensions = '',
    this.description = '',
    this.estimatedBudget,
    this.status = EnquiryStatus.active,
    required this.createdByUserId,
    required this.createdByUserName,
    this.assignedToUserId,
    this.assignedToUserName,
    this.comments = const [],
    this.convertedOrderId,
    this.cancelReason,
    this.createdAt,
    this.updatedAt,
  });

  factory EnquiryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final createdTs = data['createdAt'];
    DateTime? createdDate;
    if (createdTs is Timestamp) {
      createdDate = createdTs.toDate();
    }

    final updatedTs = data['updatedAt'];
    DateTime? updatedDate;
    if (updatedTs is Timestamp) {
      updatedDate = updatedTs.toDate();
    }

    final rawComments = data['comments'];
    List<EnquiryComment> parsedComments = [];
    if (rawComments is List) {
      parsedComments = rawComments
          .whereType<Map>()
          .map((item) =>
              EnquiryComment.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    final rawBudget = data['estimatedBudget'];
    double? budget;
    if (rawBudget is num) {
      budget = rawBudget.toDouble();
    }

    return EnquiryModel(
      id: doc.id,
      customerName: data['customerName'] as String? ?? 'Unnamed Customer',
      customerPhone: data['customerPhone'] as String? ?? '',
      customerEmail: data['customerEmail'] as String?,
      customerAddress: data['customerAddress'] as String?,
      productId: data['productId'] as String?,
      productName: data['productName'] as String? ?? 'General Fabrication',
      dimensions: data['dimensions'] as String? ?? '',
      description: data['description'] as String? ?? '',
      estimatedBudget: budget,
      status: EnquiryStatus.fromString(data['status'] as String?),
      createdByUserId: data['createdByUserId'] as String? ?? '',
      createdByUserName: data['createdByUserName'] as String? ?? 'Marketing Staff',
      assignedToUserId: data['assignedToUserId'] as String?,
      assignedToUserName: data['assignedToUserName'] as String?,
      comments: parsedComments,
      convertedOrderId: data['convertedOrderId'] as String?,
      cancelReason: data['cancelReason'] as String?,
      createdAt: createdDate,
      updatedAt: updatedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'customerAddress': customerAddress,
      'productId': productId,
      'productName': productName,
      'dimensions': dimensions,
      'description': description,
      'estimatedBudget': estimatedBudget,
      'status': status.name,
      'createdByUserId': createdByUserId,
      'createdByUserName': createdByUserName,
      'assignedToUserId': assignedToUserId,
      'assignedToUserName': assignedToUserName,
      'comments': comments.map((c) => c.toMap()).toList(),
      'convertedOrderId': convertedOrderId,
      'cancelReason': cancelReason,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  EnquiryModel copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? customerAddress,
    String? productId,
    String? productName,
    String? dimensions,
    String? description,
    double? estimatedBudget,
    EnquiryStatus? status,
    String? createdByUserId,
    String? createdByUserName,
    String? assignedToUserId,
    String? assignedToUserName,
    List<EnquiryComment>? comments,
    String? convertedOrderId,
    String? cancelReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EnquiryModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      customerAddress: customerAddress ?? this.customerAddress,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      dimensions: dimensions ?? this.dimensions,
      description: description ?? this.description,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      status: status ?? this.status,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByUserName: createdByUserName ?? this.createdByUserName,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assignedToUserName: assignedToUserName ?? this.assignedToUserName,
      comments: comments ?? this.comments,
      convertedOrderId: convertedOrderId ?? this.convertedOrderId,
      cancelReason: cancelReason ?? this.cancelReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
