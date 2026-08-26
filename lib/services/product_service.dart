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

  Stream<ProductModel> getProductStream(String id) {
    return _productsCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists) {
        throw Exception('Product not found');
      }
      return ProductModel.fromFirestore(doc);
    });
  }

  Future<ProductModel?> getProductById(String id) async {
    try {
      final doc = await _productsCollection.doc(id).get();
      if (!doc.exists) return null;
      return ProductModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting product by id: $e');
      rethrow;
    }
  }

  Future<void> addProduct({
    required String name,
    required String description,
    List<String>? imageUrls,
    String? imageUrl,
    required List<String> stageIds,
    List<ProductVariant>? variants,
  }) async {
    try {
      final List<String> finalUrls = List<String>.from(imageUrls ?? []);
      if (imageUrl != null &&
          imageUrl.trim().isNotEmpty &&
          !finalUrls.contains(imageUrl.trim())) {
        finalUrls.insert(0, imageUrl.trim());
      }

      await _productsCollection.add({
        'name': name.trim(),
        'description': description.trim(),
        'imageUrl': finalUrls.isNotEmpty ? finalUrls.first : null,
        'imageUrls': finalUrls,
        'stageIds': stageIds,
        'variants': (variants ?? []).map((v) => v.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  /// Updates only product name and description without modifying images or stages
  Future<void> updateProductBasicDetails({
    required String id,
    required String name,
    required String description,
  }) async {
    try {
      await _productsCollection.doc(id).update({
        'name': name.trim(),
        'description': description.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating product basic details: $e');
      rethrow;
    }
  }

  /// Updates only the stage pipeline of the product without touching name, description, or images
  Future<void> updateProductStages({
    required String id,
    required List<String> stageIds,
  }) async {
    try {
      await _productsCollection.doc(id).update({
        'stageIds': stageIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating product stages: $e');
      rethrow;
    }
  }

  /// Updates only the dimension pricing variants of the product
  Future<void> updateProductVariants({
    required String id,
    required List<ProductVariant> variants,
  }) async {
    try {
      await _productsCollection.doc(id).update({
        'variants': variants.map((v) => v.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating product variants: $e');
      rethrow;
    }
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required String description,
    List<String>? imageUrls,
    String? imageUrl,
    required List<String> stageIds,
    List<ProductVariant>? variants,
  }) async {
    try {
      final List<String> finalUrls = List<String>.from(imageUrls ?? []);
      if (imageUrl != null &&
          imageUrl.trim().isNotEmpty &&
          !finalUrls.contains(imageUrl.trim())) {
        finalUrls.insert(0, imageUrl.trim());
      }

      final Map<String, dynamic> updateData = {
        'name': name.trim(),
        'description': description.trim(),
        'imageUrl': finalUrls.isNotEmpty ? finalUrls.first : null,
        'imageUrls': finalUrls,
        'stageIds': stageIds,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (variants != null) {
        updateData['variants'] = variants.map((v) => v.toMap()).toList();
      }

      await _productsCollection.doc(id).update(updateData);
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> addImagesToProduct(
      String productId, List<String> newUrls) async {
    try {
      if (newUrls.isEmpty) return;
      final doc = await _productsCollection.doc(productId).get();
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final List<dynamic> current =
          data['imageUrls'] as List<dynamic>? ?? <dynamic>[];
      final List<String> updated = current.map((e) => e.toString()).toList();
      for (final url in newUrls) {
        if (url.trim().isNotEmpty && !updated.contains(url.trim())) {
          updated.add(url.trim());
        }
      }
      await _productsCollection.doc(productId).update({
        'imageUrls': updated,
        'imageUrl': updated.isNotEmpty ? updated.first : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding images to product: $e');
      rethrow;
    }
  }

  Future<void> removeImageFromProduct(
      String productId, String imageUrlToRemove) async {
    try {
      final doc = await _productsCollection.doc(productId).get();
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final List<dynamic> current =
          data['imageUrls'] as List<dynamic>? ?? <dynamic>[];
      final List<String> updated = current
          .map((e) => e.toString())
          .where((e) => e != imageUrlToRemove)
          .toList();
      await _productsCollection.doc(productId).update({
        'imageUrls': updated,
        'imageUrl': updated.isNotEmpty ? updated.first : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error removing image from product: $e');
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
