import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_manager/models/life_task.dart';

void main() {
  group('LifeTask', () {
    test('converte horário e preserva dias e conclusões ao serializar', () {
      final task = LifeTask(
        id: 'task-1',
        title: 'Estudar inglês',
        category: TaskCategory.study,
        plannedTime: const TimeOfDay(hour: 14, minute: 5),
        weekdays: {DateTime.monday, DateTime.friday},
        completedDates: {'2026-10-15'},
      );

      final restored = LifeTask.fromJson(task.toJson());

      expect(restored.plannedTime, const TimeOfDay(hour: 14, minute: 5));
      expect(restored.weekdays, {DateTime.monday, DateTime.friday});
      expect(restored.isScheduledOn(DateTime(2026, 10, 16)), isTrue);
      expect(restored.isScheduledOn(DateTime(2026, 10, 15)), isFalse);
      expect(restored.isCompletedOn(DateTime(2026, 10, 15)), isTrue);
    });

    test('rejeita dias da semana fora do intervalo válido', () {
      expect(
        () => LifeTask(
          id: 'task-1',
          title: 'Tarefa inválida',
          category: TaskCategory.home,
          plannedTime: const TimeOfDay(hour: 9, minute: 0),
          weekdays: {0},
        ),
        throwsArgumentError,
      );
    });
  });
}
