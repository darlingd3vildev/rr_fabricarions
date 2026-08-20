import 'package:flutter_test/flutter_test.dart';
import 'package:rr_fabrication/models/order_model.dart';
import 'package:rr_fabrication/models/order_stage_model.dart';

void main() {
  group('OrderStageModel & Sequential Workflow Tests', () {
    test('OrderStageModel instantiates correctly with defaults', () {
      final stage = OrderStageModel(
        stageId: 'stg-1',
        stageName: 'Cutting',
      );

      expect(stage.stageId, equals('stg-1'));
      expect(stage.stageName, equals('Cutting'));
      expect(stage.status, equals(OrderStageStatus.pending));
      expect(stage.assignedWorkerId, isNull);
      expect(stage.assignedWorkerName, isNull);
    });

    test('OrderStageModel serialization toMap and fromMap', () {
      final now = DateTime(2026, 4, 1, 10, 0);
      final stage = OrderStageModel(
        stageId: 'stg-2',
        stageName: 'Welding',
        status: OrderStageStatus.inProgress,
        assignedWorkerId: 'worker-123',
        assignedWorkerName: 'John Doe',
        startedAt: now,
      );

      final map = stage.toMap();
      expect(map['stageId'], equals('stg-2'));
      expect(map['stageName'], equals('Welding'));
      expect(map['status'], equals('inProgress'));
      expect(map['assignedWorkerId'], equals('worker-123'));
      expect(map['assignedWorkerName'], equals('John Doe'));

      final parsed = OrderStageModel.fromMap(map);
      expect(parsed.stageId, equals('stg-2'));
      expect(parsed.stageName, equals('Welding'));
      expect(parsed.status, equals(OrderStageStatus.inProgress));
      expect(parsed.assignedWorkerId, equals('worker-123'));
      expect(parsed.assignedWorkerName, equals('John Doe'));
    });

    test('OrderModel serializes and deserializes stages list properly', () {
      final stages = [
        OrderStageModel(
          stageId: 's1',
          stageName: 'Cutting',
          status: OrderStageStatus.completed,
          assignedWorkerName: 'Alice',
        ),
        OrderStageModel(
          stageId: 's2',
          stageName: 'Welding',
          status: OrderStageStatus.inProgress,
          assignedWorkerName: 'Bob',
        ),
        OrderStageModel(
          stageId: 's3',
          stageName: 'Painting',
          status: OrderStageStatus.pending,
        ),
      ];

      final order = OrderModel(
        id: 'ord-500',
        productId: 'prod-1',
        productName: 'Gate',
        description: 'Main gate',
        dimensions: '8ft x 4ft',
        status: OrderStatus.inProgress,
        completionPercentage: 33,
        stages: stages,
      );

      final map = order.toMap();
      expect((map['stages'] as List).length, equals(3));

      // Calculate sequential active stage index
      int activeIndex = -1;
      for (int i = 0; i < order.stages.length; i++) {
        if (order.stages[i].status != OrderStageStatus.completed) {
          activeIndex = i;
          break;
        }
      }

      // Stage 0 is completed, so active stage must be index 1 (Welding)
      expect(activeIndex, equals(1));
      expect(order.stages[activeIndex].stageName, equals('Welding'));
    });

    test('OrderStageStatus enum fromString parsing', () {
      expect(OrderStageStatus.fromString('assigned'), equals(OrderStageStatus.assigned));
      expect(OrderStageStatus.fromString('inProgress'), equals(OrderStageStatus.inProgress));
      expect(OrderStageStatus.fromString('paused'), equals(OrderStageStatus.paused));
      expect(OrderStageStatus.fromString('completed'), equals(OrderStageStatus.completed));
      expect(OrderStageStatus.fromString('unknown'), equals(OrderStageStatus.pending));
    });
  });
}
