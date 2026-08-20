import 'package:flutter_test/flutter_test.dart';
import 'package:rr_fabrication/models/order_model.dart';

void main() {
  group('OrderModel Tests', () {
    test('OrderModel instantiates correctly with all fields', () {
      final now = DateTime.now();
      final order = OrderModel(
        id: 'ord-101',
        productId: 'prod-001',
        productName: 'Heavy Steel Gate',
        description: 'Black matte paint finish with double latch',
        dimensions: '8ft x 6ft',
        status: OrderStatus.inProgress,
        completionPercentage: 65,
        createdAt: now,
      );

      expect(order.id, equals('ord-101'));
      expect(order.productId, equals('prod-001'));
      expect(order.productName, equals('Heavy Steel Gate'));
      expect(order.description, equals('Black matte paint finish with double latch'));
      expect(order.dimensions, equals('8ft x 6ft'));
      expect(order.status, equals(OrderStatus.inProgress));
      expect(order.completionPercentage, equals(65));
      expect(order.createdAt, equals(now));
    });

    test('OrderModel copyWith updates fields properly', () {
      final order = OrderModel(
        id: 'ord-101',
        productId: 'prod-001',
        productName: 'Gate',
        description: 'Standard',
        dimensions: '6ft x 4ft',
        status: OrderStatus.pending,
        completionPercentage: 0,
      );

      final updated = order.copyWith(
        status: OrderStatus.completed,
        completionPercentage: 100,
      );

      expect(updated.id, equals('ord-101'));
      expect(updated.productName, equals('Gate'));
      expect(updated.status, equals(OrderStatus.completed));
      expect(updated.completionPercentage, equals(100));
    });

    test('OrderModel toMap outputs correct map structure', () {
      final now = DateTime(2026, 3, 15);
      final order = OrderModel(
        id: 'ord-102',
        productId: 'prod-002',
        productName: 'Window Grill',
        description: 'Floral pattern',
        dimensions: '4ft x 3ft',
        status: OrderStatus.completed,
        completionPercentage: 100,
        createdAt: now,
      );

      final map = order.toMap();
      expect(map['productId'], equals('prod-002'));
      expect(map['productName'], equals('Window Grill'));
      expect(map['description'], equals('Floral pattern'));
      expect(map['dimensions'], equals('4ft x 3ft'));
      expect(map['status'], equals('completed'));
      expect(map['completionPercentage'], equals(100));
      expect(map['createdAt'], isNotNull);
    });

    test('OrderStatus fromString parses display names and raw enum strings', () {
      expect(OrderStatus.fromString('In Progress'), equals(OrderStatus.inProgress));
      expect(OrderStatus.fromString('inProgress'), equals(OrderStatus.inProgress));
      expect(OrderStatus.fromString('completed'), equals(OrderStatus.completed));
      expect(OrderStatus.fromString('Completed'), equals(OrderStatus.completed));
      expect(OrderStatus.fromString('cancelled'), equals(OrderStatus.cancelled));
      expect(OrderStatus.fromString('unknown_value'), equals(OrderStatus.pending));
    });
  });
}
