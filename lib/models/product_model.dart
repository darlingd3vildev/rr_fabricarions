import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final List<String> stageIds;
  final DateTime? createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.stageIds = const [],
    this.createdAt,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestamp = data['createdAt'];
    DateTime? createdDateTime;
    if (timestamp is Timestamp) {
      createdDateTime = timestamp.toDate();
    }

    final rawStageIds = data['stageIds'];
    List<String> parsedStageIds = [];
    if (rawStageIds is List) {
      parsedStageIds = rawStageIds.map((e) => e.toString()).toList();
    }

    return ProductModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      stageIds: parsedStageIds,
      createdAt: createdDateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'stageIds': stageIds,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? stageIds,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      stageIds: stageIds ?? this.stageIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
