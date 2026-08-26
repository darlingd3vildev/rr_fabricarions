import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rr_fabrication/models/enquiry_model.dart';
import 'package:rr_fabrication/models/order_stage_model.dart';

class EnquiryService {
  final CollectionReference _enquiriesCollection =
      FirebaseFirestore.instance.collection('enquiries');
  final CollectionReference _ordersCollection =
      FirebaseFirestore.instance.collection('orders');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<EnquiryModel>> getEnquiriesStream() {
    return _enquiriesCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnquiryModel.fromFirestore(doc))
            .toList());
  }

  Stream<EnquiryModel?> getEnquiryByIdStream(String enquiryId) {
    return _enquiriesCollection.doc(enquiryId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return EnquiryModel.fromFirestore(doc);
    });
  }

  Future<String> addEnquiry({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? customerAddress,
    String? productId,
    required String productName,
    String dimensions = '',
    String description = '',
    double? estimatedBudget,
    required String createdByUserId,
    required String createdByUserName,
    String? initialNote,
  }) async {
    try {
      List<Map<String, dynamic>> initialComments = [];
      if (initialNote != null && initialNote.trim().isNotEmpty) {
        initialComments.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'userId': createdByUserId,
          'userName': createdByUserName,
          'text': initialNote.trim(),
          'createdAt': Timestamp.now(),
        });
      }

      final docRef = await _enquiriesCollection.add({
        'customerName': customerName.trim(),
        'customerPhone': customerPhone.trim(),
        'customerEmail': customerEmail?.trim(),
        'customerAddress': customerAddress?.trim(),
        'productId': productId?.trim(),
        'productName': productName.trim(),
        'dimensions': dimensions.trim(),
        'description': description.trim(),
        'estimatedBudget': estimatedBudget,
        'status': EnquiryStatus.active.name,
        'createdByUserId': createdByUserId,
        'createdByUserName': createdByUserName,
        'comments': initialComments,
        'convertedOrderId': null,
        'cancelReason': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding enquiry: $e');
      rethrow;
    }
  }

  Future<void> updateEnquiry({
    required String id,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? customerAddress,
    String? productId,
    required String productName,
    required String dimensions,
    required String description,
    double? estimatedBudget,
    required EnquiryStatus status,
  }) async {
    try {
      await _enquiriesCollection.doc(id).update({
        'customerName': customerName.trim(),
        'customerPhone': customerPhone.trim(),
        'customerEmail': customerEmail?.trim(),
        'customerAddress': customerAddress?.trim(),
        'productId': productId?.trim(),
        'productName': productName.trim(),
        'dimensions': dimensions.trim(),
        'description': description.trim(),
        'estimatedBudget': estimatedBudget,
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating enquiry: $e');
      rethrow;
    }
  }

  Future<void> addComment({
    required String enquiryId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    try {
      final newComment = EnquiryComment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        userName: userName,
        text: text.trim(),
        createdAt: DateTime.now(),
      );

      await _enquiriesCollection.doc(enquiryId).update({
        'comments': FieldValue.arrayUnion([newComment.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding comment to enquiry: $e');
      rethrow;
    }
  }

  Future<void> updateStatus({
    required String enquiryId,
    required EnquiryStatus status,
    String? cancelReason,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == EnquiryStatus.cancelled && cancelReason != null) {
        updateData['cancelReason'] = cancelReason.trim();
      }

      await _enquiriesCollection.doc(enquiryId).update(updateData);
    } catch (e) {
      debugPrint('Error updating enquiry status: $e');
      rethrow;
    }
  }

  /// Converts a confirmed enquiry into a live fabrication order
  Future<String> confirmAndConvertToOrder({
    required EnquiryModel enquiry,
    String? customDimensions,
    String? customDescription,
    required String confirmedByUserId,
    required String confirmedByUserName,
  }) async {
    try {
      final finalDimensions =
          customDimensions?.trim() ?? enquiry.dimensions.trim();
      final finalDescription =
          customDescription?.trim() ?? enquiry.description.trim();

      // Load process stages for the product if available
      List<OrderStageModel> initialStages = [];
      if (enquiry.productId != null && enquiry.productId!.isNotEmpty) {
        initialStages = await _loadStagesForProduct(enquiry.productId!);
      }

      // 1. Create order in orders collection
      final orderDocRef = await _ordersCollection.add({
        'productId': enquiry.productId ?? '',
        'productName': enquiry.productName,
        'description':
            '$finalDescription\n[Customer: ${enquiry.customerName} | Phone: ${enquiry.customerPhone}]',
        'dimensions': finalDimensions,
        'status': 'pending',
        'completionPercentage': 0,
        'stages': initialStages.map((s) => s.toMap()).toList(),
        'enquiryId': enquiry.id,
        'customerName': enquiry.customerName,
        'customerPhone': enquiry.customerPhone,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final newOrderId = orderDocRef.id;

      // 2. Add system comment in enquiry and mark confirmed
      final confirmComment = EnquiryComment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: confirmedByUserId,
        userName: confirmedByUserName,
        text: 'Confirmed enquiry and converted to Order #$newOrderId',
        createdAt: DateTime.now(),
      );

      await _enquiriesCollection.doc(enquiry.id).update({
        'status': EnquiryStatus.confirmed.name,
        'convertedOrderId': newOrderId,
        'comments': FieldValue.arrayUnion([confirmComment.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return newOrderId;
    } catch (e) {
      debugPrint('Error converting enquiry to order: $e');
      rethrow;
    }
  }

  Future<List<OrderStageModel>> _loadStagesForProduct(String productId) async {
    try {
      final productDoc =
          await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) return [];

      final data = productDoc.data() ?? {};
      final stageIds = (data['stageIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      if (stageIds.isEmpty) return [];

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

  Future<void> deleteEnquiry(String id) async {
    try {
      await _enquiriesCollection.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting enquiry: $e');
      rethrow;
    }
  }
}
