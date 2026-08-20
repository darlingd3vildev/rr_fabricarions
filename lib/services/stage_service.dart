import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/stage_model.dart';

class StageService {
  final CollectionReference _stagesCollection =
      FirebaseFirestore.instance.collection('stages');

  Stream<List<StageModel>> getStagesStream() {
    return _stagesCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StageModel.fromFirestore(doc))
            .toList());
  }

  Future<void> addStage({
    required String name,
    required String description,
  }) async {
    try {
      await _stagesCollection.add({
        'name': name.trim(),
        'description': description.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding stage: $e');
      rethrow;
    }
  }

  Future<void> updateStage({
    required String id,
    required String name,
    required String description,
  }) async {
    try {
      await _stagesCollection.doc(id).update({
        'name': name.trim(),
        'description': description.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating stage: $e');
      rethrow;
    }
  }

  Future<void> deleteStage(String id) async {
    try {
      await _stagesCollection.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting stage: $e');
      rethrow;
    }
  }
}
