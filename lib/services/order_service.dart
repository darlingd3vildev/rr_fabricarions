import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/order_model.dart';
import 'package:rr_fabrication/models/order_stage_model.dart';

class OrderService {
  final CollectionReference _ordersCollection =
      FirebaseFirestore.instance.collection('orders');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<OrderModel>> getOrdersStream() {
    return _ordersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  Stream<OrderModel?> getOrderByIdStream(String orderId) {
    return _ordersCollection.doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return OrderModel.fromFirestore(doc);
    });
  }

  Stream<List<OrderModel>> getOrdersForWorkerStream(String workerId) {
    return _ordersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final allOrders =
          snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

      return allOrders.where((order) {
        return order.stages.any((stage) => stage.assignedWorkerId == workerId);
      }).toList();
    });
  }

  Future<String> addOrder({
    required String productId,
    required String productName,
    required String description,
    required String dimensions,
    OrderStatus status = OrderStatus.pending,
    int completionPercentage = 0,
    List<OrderStageModel>? stages,
    String? customerName,
    String? customerPhone,
    String? enquiryId,
  }) async {
    try {
      List<OrderStageModel> initialStages = stages ?? [];

      // If stages were not explicitly passed, auto-populate from product
      if (initialStages.isEmpty && productId.isNotEmpty) {
        initialStages = await _loadStagesForProduct(productId);
      }

      final docRef = await _ordersCollection.add({
        'productId': productId.trim(),
        'productName': productName.trim(),
        'description': description.trim(),
        'dimensions': dimensions.trim(),
        'status': status.name,
        'completionPercentage': completionPercentage.clamp(0, 100),
        'stages': initialStages.map((s) => s.toMap()).toList(),
        'customerName': customerName?.trim(),
        'customerPhone': customerPhone?.trim(),
        'enquiryId': enquiryId?.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding order: $e');
      rethrow;
    }
  }

  Future<List<OrderStageModel>> _loadStagesForProduct(String productId) async {
    try {
      final productDoc =
          await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) return [];

      final data = productDoc.data() ?? {};
      final stageIds =
          (data['stageIds'] as List?)?.map((e) => e.toString()).toList() ?? [];

      if (stageIds.isEmpty) return [];

      // Fetch all stage documents to get their names
      final stagesSnapshot = await _firestore.collection('stages').get();
      final stageMap = {
        for (var doc in stagesSnapshot.docs)
          doc.id: (doc.data()['name'] as String? ?? 'Stage')
      };

      return stageIds.map((id) {
        return OrderStageModel(
          stageId: id,
          stageName: stageMap[id] ?? 'Stage',
          status: OrderStageStatus.pending,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading stages for product: $e');
      return [];
    }
  }

  Future<void> syncOrderStagesFromProduct(
      String orderId, String productId) async {
    try {
      final stages = await _loadStagesForProduct(productId);
      if (stages.isNotEmpty) {
        await _ordersCollection.doc(orderId).update({
          'stages': stages.map((s) => s.toMap()).toList(),
          'completionPercentage': 0,
          'status': OrderStatus.inProgress.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error syncing order stages: $e');
      rethrow;
    }
  }

  Future<void> assignWorkerToStage({
    required String orderId,
    required int stageIndex,
    required String workerId,
    required String workerName,
  }) async {
    try {
      final doc = await _ordersCollection.doc(orderId).get();
      if (!doc.exists) return;

      final order = OrderModel.fromFirestore(doc);
      if (stageIndex < 0 || stageIndex >= order.stages.length) return;

      final updatedStages = List<OrderStageModel>.from(order.stages);
      final currentStage = updatedStages[stageIndex];

      final newStatus = currentStage.status == OrderStageStatus.pending
          ? OrderStageStatus.assigned
          : currentStage.status;

      updatedStages[stageIndex] = currentStage.copyWith(
        assignedWorkerId: workerId,
        assignedWorkerName: workerName,
        status: newStatus,
      );

      await _ordersCollection.doc(orderId).update({
        'stages': updatedStages.map((s) => s.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error assigning worker to stage: $e');
      rethrow;
    }
  }

  Future<void> updateStageStatus({
    required String orderId,
    required int stageIndex,
    required OrderStageStatus newStatus,
  }) async {
    try {
      final doc = await _ordersCollection.doc(orderId).get();
      if (!doc.exists) return;

      final order = OrderModel.fromFirestore(doc);
      if (stageIndex < 0 || stageIndex >= order.stages.length) return;

      final updatedStages = List<OrderStageModel>.from(order.stages);
      final currentStage = updatedStages[stageIndex];

      DateTime? startedAt = currentStage.startedAt;
      DateTime? completedAt = currentStage.completedAt;

      if (newStatus == OrderStageStatus.inProgress && startedAt == null) {
        startedAt = DateTime.now();
      } else if (newStatus == OrderStageStatus.completed) {
        completedAt = DateTime.now();
      }

      updatedStages[stageIndex] = currentStage.copyWith(
        status: newStatus,
        startedAt: startedAt,
        completedAt: completedAt,
      );

      // Recalculate completion percentage
      final totalStages = updatedStages.length;
      final completedCount = updatedStages
          .where((s) => s.status == OrderStageStatus.completed)
          .length;

      int newPercentage = totalStages > 0
          ? ((completedCount / totalStages) * 100).round()
          : order.completionPercentage;

      OrderStatus newOrderStatus = order.status;
      if (completedCount == totalStages && totalStages > 0) {
        newOrderStatus = OrderStatus.completed;
        newPercentage = 100;
      } else if (newStatus == OrderStageStatus.inProgress ||
          completedCount > 0) {
        newOrderStatus = OrderStatus.inProgress;
      }

      await _ordersCollection.doc(orderId).update({
        'stages': updatedStages.map((s) => s.toMap()).toList(),
        'completionPercentage': newPercentage,
        'status': newOrderStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating stage status: $e');
      rethrow;
    }
  }

  /// Updates only the basic details of an order without overriding stages
  Future<void> updateOrderBasicDetails({
    required String id,
    required String productId,
    required String productName,
    required String description,
    required String dimensions,
    required OrderStatus status,
  }) async {
    try {
      await _ordersCollection.doc(id).update({
        'productId': productId.trim(),
        'productName': productName.trim(),
        'description': description.trim(),
        'dimensions': dimensions.trim(),
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating order basic details: $e');
      rethrow;
    }
  }

  /// Updates the stages pipeline of an order independently
  Future<void> updateOrderStages({
    required String orderId,
    required List<OrderStageModel> stages,
  }) async {
    try {
      final completedCount =
          stages.where((s) => s.status == OrderStageStatus.completed).length;
      final newPercentage = stages.isNotEmpty
          ? ((completedCount / stages.length) * 100).round()
          : 0;

      await _ordersCollection.doc(orderId).update({
        'stages': stages.map((s) => s.toMap()).toList(),
        'completionPercentage': newPercentage,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating order stages: $e');
      rethrow;
    }
  }

  Future<void> updateOrder({
    required String id,
    required String productId,
    required String productName,
    required String description,
    required String dimensions,
    required OrderStatus status,
    required int completionPercentage,
    List<OrderStageModel>? stages,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'productId': productId.trim(),
        'productName': productName.trim(),
        'description': description.trim(),
        'dimensions': dimensions.trim(),
        'status': status.name,
        'completionPercentage': completionPercentage.clamp(0, 100),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (stages != null) {
        updateData['stages'] = stages.map((s) => s.toMap()).toList();
      }

      await _ordersCollection.doc(id).update(updateData);
    } catch (e) {
      debugPrint('Error updating order: $e');
      rethrow;
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      await _ordersCollection.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting order: $e');
      rethrow;
    }
  }
}
