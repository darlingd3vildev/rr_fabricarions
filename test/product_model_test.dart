import 'package:flutter_test/flutter_test.dart';
import 'package:rr_fabrication/models/product_model.dart';

void main() {
  group('ProductModel Tests', () {
    test('ProductModel instantiates correctly with all fields', () {
      final now = DateTime.now();
      final product = ProductModel(
        id: 'prod-101',
        name: 'Main Entrance Steel Gate',
        description: 'Heavy duty decorative steel gate with primer coating',
        imageUrl: 'https://example.com/gate.jpg',
        stageIds: ['stage-1', 'stage-2', 'stage-3'],
        createdAt: now,
      );

      expect(product.id, equals('prod-101'));
      expect(product.name, equals('Main Entrance Steel Gate'));
      expect(product.description, equals('Heavy duty decorative steel gate with primer coating'));
      expect(product.imageUrl, equals('https://example.com/gate.jpg'));
      expect(product.stageIds, equals(['stage-1', 'stage-2', 'stage-3']));
      expect(product.createdAt, equals(now));
    });

    test('ProductModel copyWith updates fields properly', () {
      final product = ProductModel(
        id: 'prod-101',
        name: 'Steel Gate',
        description: 'Basic gate',
        stageIds: ['stage-1'],
      );

      final updated = product.copyWith(
        name: 'Sliding Steel Gate',
        description: 'Motorized sliding gate',
        imageUrl: 'https://example.com/sliding.jpg',
        stageIds: ['stage-1', 'stage-2'],
      );

      expect(updated.id, equals('prod-101'));
      expect(updated.name, equals('Sliding Steel Gate'));
      expect(updated.description, equals('Motorized sliding gate'));
      expect(updated.imageUrl, equals('https://example.com/sliding.jpg'));
      expect(updated.stageIds, equals(['stage-1', 'stage-2']));
    });

    test('ProductModel toMap outputs correct map structure', () {
      final now = DateTime(2026, 2, 1);
      final product = ProductModel(
        id: 'prod-102',
        name: 'Window Grill',
        description: 'Cast iron window grill',
        imageUrl: null,
        stageIds: ['cutting', 'welding', 'painting'],
        createdAt: now,
      );

      final map = product.toMap();
      expect(map['name'], equals('Window Grill'));
      expect(map['description'], equals('Cast iron window grill'));
      expect(map['imageUrl'], isNull);
      expect(map['stageIds'], equals(['cutting', 'welding', 'painting']));
      expect(map['createdAt'], isNotNull);
    });
  });
}
