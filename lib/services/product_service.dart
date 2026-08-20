import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/product_model.dart';

class ProductService {
  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');

  Stream<List<ProductModel>> getProductsStream() {
    return _productsCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList());
  }

  Future<void> addProduct({
    required String name,
    required String description,
    String? imageUrl,
    required List<String> stageIds,
  }) async {
    try {
      await _productsCollection.add({
        'name': name.trim(),
        'description': description.trim(),
        'imageUrl': imageUrl?.trim().isNotEmpty == true ? imageUrl!.trim() : null,
        'stageIds': stageIds,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required String description,
    String? imageUrl,
    required List<String> stageIds,
  }) async {
    try {
      await _productsCollection.doc(id).update({
        'name': name.trim(),
        'description': description.trim(),
        'imageUrl': imageUrl?.trim().isNotEmpty == true ? imageUrl!.trim() : null,
        'stageIds': stageIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _productsCollection.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }
}
