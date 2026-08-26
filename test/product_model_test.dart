import 'package:flutter_test/flutter_test.dart';
import 'package:rr_fabrication/models/product_model.dart';

void main() {
  group('ProductModel Tests', () {
    test('ProductModel instantiates correctly with single and multiple images', () {
      final now = DateTime.now();
      final product = ProductModel(
        id: 'prod-101',
        name: 'Main Entrance Steel Gate',
        description: 'Heavy duty decorative steel gate with primer coating',
        imageUrls: [
          'https://example.com/gate1.jpg',
          'https://example.com/gate2.jpg',
        ],
        stageIds: ['stage-1', 'stage-2', 'stage-3'],
        createdAt: now,
      );

      expect(product.id, equals('prod-101'));
      expect(product.name, equals('Main Entrance Steel Gate'));
      expect(product.description, equals('Heavy duty decorative steel gate with primer coating'));
      expect(product.imageUrl, equals('https://example.com/gate1.jpg'));
      expect(product.imageUrls.length, equals(2));
      expect(product.imageUrls, equals(['https://example.com/gate1.jpg', 'https://example.com/gate2.jpg']));
      expect(product.stageIds, equals(['stage-1', 'stage-2', 'stage-3']));
      expect(product.createdAt, equals(now));
    });

    test('ProductModel handles single legacy imageUrl parameter in constructor', () {
      final product = ProductModel(
        id: 'prod-legacy',
        name: 'Legacy Gate',
        description: 'Legacy product with single image',
        imageUrl: 'https://example.com/single.jpg',
      );

      expect(product.imageUrl, equals('https://example.com/single.jpg'));
      expect(product.imageUrls, equals(['https://example.com/single.jpg']));
    });

    test('ProductModel copyWith updates multiple images properly', () {
      final product = ProductModel(
        id: 'prod-101',
        name: 'Steel Gate',
        description: 'Basic gate',
        stageIds: ['stage-1'],
      );

      final updated = product.copyWith(
        name: 'Sliding Steel Gate',
        description: 'Motorized sliding gate',
        imageUrls: ['https://example.com/sliding1.jpg', 'https://example.com/sliding2.jpg'],
        stageIds: ['stage-1', 'stage-2'],
      );

      expect(updated.id, equals('prod-101'));
      expect(updated.name, equals('Sliding Steel Gate'));
      expect(updated.description, equals('Motorized sliding gate'));
      expect(updated.imageUrl, equals('https://example.com/sliding1.jpg'));
      expect(updated.imageUrls.length, equals(2));
      expect(updated.stageIds, equals(['stage-1', 'stage-2']));
    });

    test('ProductVariant serialization and price range calculations', () {
      final variant1 = ProductVariant(
        id: 'v1',
        dimensions: '8ft x 10ft',
        price: 22000.0,
        priceUnit: 'per piece',
        materialSpec: '16 Gauge MS',
      );

      final variant2 = ProductVariant(
        id: 'v2',
        dimensions: '10ft x 12ft',
        price: 35000.0,
        priceUnit: 'per piece',
        materialSpec: '14 Gauge Heavy Duty MS',
      );

      final map = variant1.toMap();
      expect(map['dimensions'], equals('8ft x 10ft'));
      expect(map['price'], equals(22000.0));
      expect(map['priceUnit'], equals('per piece'));
      expect(map['materialSpec'], equals('16 Gauge MS'));

      final fromMap = ProductVariant.fromMap(map);
      expect(fromMap.dimensions, equals('8ft x 10ft'));
      expect(fromMap.price, equals(22000.0));

      final product = ProductModel(
        id: 'prod-variants',
        name: 'Custom Railing',
        description: 'Steel railing',
        variants: [variant1, variant2],
      );

      expect(product.hasVariants, isTrue);
      expect(product.minPrice, equals(22000.0));
      expect(product.maxPrice, equals(35000.0));
      expect(product.priceRangeString, equals('₹22000 - ₹35000'));
    });

    test('ProductModel toMap outputs correct map structure with imageUrls and imageUrl', () {
      final now = DateTime(2026, 2, 1);
      final product = ProductModel(
        id: 'prod-102',
        name: 'Window Grill',
        description: 'Cast iron window grill',
        imageUrls: ['https://example.com/grill1.jpg'],
        stageIds: ['cutting', 'welding', 'painting'],
        createdAt: now,
      );

      final map = product.toMap();
      expect(map['name'], equals('Window Grill'));
      expect(map['description'], equals('Cast iron window grill'));
      expect(map['imageUrl'], equals('https://example.com/grill1.jpg'));
      expect(map['imageUrls'], equals(['https://example.com/grill1.jpg']));
      expect(map['stageIds'], equals(['cutting', 'welding', 'painting']));
      expect(map['createdAt'], isNotNull);
    });
  });
}
