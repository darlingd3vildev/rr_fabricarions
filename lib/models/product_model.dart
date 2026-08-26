import 'package:cloud_firestore/cloud_firestore.dart';

class ProductVariant {
  final String id;
  final String dimensions; // e.g., "10 x 12 ft", "6 x 4 ft standard"
  final double price; // e.g., 25000.0
  final String? priceUnit; // e.g., "per piece", "per sq. ft"
  final String? materialSpec; // e.g., "16 Gauge Mild Steel, Powder Coated"
  final String? description;

  ProductVariant({
    required this.id,
    required this.dimensions,
    required this.price,
    this.priceUnit,
    this.materialSpec,
    this.description,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    final rawPrice = map['price'];
    double parsedPrice = 0.0;
    if (rawPrice is num) {
      parsedPrice = rawPrice.toDouble();
    } else if (rawPrice != null) {
      parsedPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
    }

    return ProductVariant(
      id: map['id']?.toString() ?? '',
      dimensions: map['dimensions']?.toString() ?? '',
      price: parsedPrice,
      priceUnit: map['priceUnit']?.toString(),
      materialSpec: map['materialSpec']?.toString(),
      description: map['description']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dimensions': dimensions,
      'price': price,
      if (priceUnit != null && priceUnit!.isNotEmpty) 'priceUnit': priceUnit,
      if (materialSpec != null && materialSpec!.isNotEmpty)
        'materialSpec': materialSpec,
      if (description != null && description!.isNotEmpty)
        'description': description,
    };
  }

  ProductVariant copyWith({
    String? id,
    String? dimensions,
    double? price,
    String? priceUnit,
    String? materialSpec,
    String? description,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      dimensions: dimensions ?? this.dimensions,
      price: price ?? this.price,
      priceUnit: priceUnit ?? this.priceUnit,
      materialSpec: materialSpec ?? this.materialSpec,
      description: description ?? this.description,
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final List<String> imageUrls;
  final List<String> stageIds;
  final List<ProductVariant> variants;
  final DateTime? createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    List<String>? imageUrls,
    String? imageUrl,
    this.stageIds = const [],
    this.variants = const [],
    this.createdAt,
  }) : imageUrls = imageUrls ??
            (imageUrl != null && imageUrl.trim().isNotEmpty
                ? [imageUrl.trim()]
                : const []);

  /// Primary image URL for backward compatibility with orders, list tiles, etc.
  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  /// Whether this product has configured dimension pricing variants
  bool get hasVariants => variants.isNotEmpty;

  /// Lowest price among variants (or null if no variants)
  double? get minPrice {
    if (variants.isEmpty) return null;
    return variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
  }

  /// Highest price among variants (or null if no variants)
  double? get maxPrice {
    if (variants.isEmpty) return null;
    return variants.map((v) => v.price).reduce((a, b) => a > b ? a : b);
  }

  /// Formatted price range string (e.g., "₹15,000 - ₹35,000" or "Custom Pricing")
  String get priceRangeString {
    if (variants.isEmpty) return 'Price on Request';
    final min = minPrice!;
    final max = maxPrice!;
    if (min == max) {
      return '₹${min.toStringAsFixed(0)}';
    }
    return '₹${min.toStringAsFixed(0)} - ₹${max.toStringAsFixed(0)}';
  }

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

    List<String> parsedImageUrls = [];
    final rawImageUrls = data['imageUrls'];
    if (rawImageUrls is List) {
      parsedImageUrls = rawImageUrls
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final legacyImageUrl = data['imageUrl'] as String?;
    if (parsedImageUrls.isEmpty &&
        legacyImageUrl != null &&
        legacyImageUrl.trim().isNotEmpty) {
      parsedImageUrls.add(legacyImageUrl.trim());
    }

    List<ProductVariant> parsedVariants = [];
    final rawVariants = data['variants'];
    if (rawVariants is List) {
      for (final item in rawVariants) {
        if (item is Map<String, dynamic>) {
          parsedVariants.add(ProductVariant.fromMap(item));
        } else if (item is Map) {
          parsedVariants.add(
            ProductVariant.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return ProductModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrls: parsedImageUrls,
      stageIds: parsedStageIds,
      variants: parsedVariants,
      createdAt: createdDateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'stageIds': stageIds,
      'variants': variants.map((v) => v.toMap()).toList(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? imageUrls,
    String? imageUrl,
    List<String>? stageIds,
    List<ProductVariant>? variants,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrls: imageUrls ?? (imageUrl != null ? [imageUrl] : this.imageUrls),
      stageIds: stageIds ?? this.stageIds,
      variants: variants ?? this.variants,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
