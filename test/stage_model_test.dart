import 'package:flutter_test/flutter_test.dart';
import 'package:rr_fabrication/models/stage_model.dart';

void main() {
  group('StageModel Tests', () {
    test('StageModel instantiates correctly with provided properties', () {
      final now = DateTime.now();
      final stage = StageModel(
        id: 'stage-1',
        name: 'Cutting',
        description: 'Cut raw materials according to blueprints',
        createdAt: now,
      );

      expect(stage.id, equals('stage-1'));
      expect(stage.name, equals('Cutting'));
      expect(stage.description, equals('Cut raw materials according to blueprints'));
      expect(stage.createdAt, equals(now));
    });

    test('StageModel copyWith creates a new instance with updated properties', () {
      final stage = StageModel(
        id: 'stage-1',
        name: 'Cutting',
        description: 'Old description',
      );

      final updatedStage = stage.copyWith(
        name: 'Laser Cutting',
        description: 'High precision laser cutting',
      );

      expect(updatedStage.id, equals('stage-1'));
      expect(updatedStage.name, equals('Laser Cutting'));
      expect(updatedStage.description, equals('High precision laser cutting'));
    });

    test('StageModel toMap outputs expected keys and values', () {
      final now = DateTime(2026, 1, 1);
      final stage = StageModel(
        id: 'stage-2',
        name: 'Welding',
        description: 'TIG welding components',
        createdAt: now,
      );

      final map = stage.toMap();
      expect(map['name'], equals('Welding'));
      expect(map['description'], equals('TIG welding components'));
      expect(map['createdAt'], isNotNull);
    });
  });
}
