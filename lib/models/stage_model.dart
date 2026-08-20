import 'package:cloud_firestore/cloud_firestore.dart';

class StageModel {
  final String id;
  final String name;
  final String description;
  final DateTime? createdAt;

  StageModel({
    required this.id,
    required this.name,
    required this.description,
    this.createdAt,
  });

  factory StageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestamp = data['createdAt'];
    DateTime? createdDateTime;
    if (timestamp is Timestamp) {
      createdDateTime = timestamp.toDate();
    }

    return StageModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt: createdDateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  StageModel copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return StageModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
