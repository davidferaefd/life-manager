import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_manager/models/life_task.dart';
import 'package:life_manager/services/app_state.dart';

void main() {
  group('AppState', () {
    late AppState state;

    setUp(() {
      state = AppState.inMemory();
    });

    tearDown(() {
      state.dispose();
    });

    test('conclusão concede XP uma vez por dia e atualiza a ofensiva',
        () async {
      final task = LifeTask(
        id: 'task-1',
        title: 'Estudar',
        category: TaskCategory.study,
        plannedTime: const TimeOfDay(hour: 18, minute: 0),
        weekdays: {DateTime.monday, DateTime.tuesday},
      );
      await state.addTask(task);

      await state.completeTask(task.id, completedAt: DateTime(2026, 10, 12));
      await state.completeTask(task.id,
          completedAt: DateTime(2026, 10, 12, 20));
      expect(state.profile.totalXp, 10);
      expect(state.xpHistory, hasLength(1));
      expect(state.profile.currentStreak, 1);

      await state.completeTask(task.id, completedAt: DateTime(2026, 10, 13));
      expect(state.profile.totalXp, 20);
      expect(state.profile.currentStreak, 2);

      await state.reopenTask(task.id, completedAt: DateTime(2026, 10, 13));
      expect(state.profile.totalXp, 10);
      expect(state.profile.currentStreak, 1);
      expect(state.tasks.single.isCompletedOn(DateTime(2026, 10, 13)), isFalse);
    });

    test('concluir demanda no Kanban registra XP e marca concluído', () async {
      final task = LifeTask(
        id: 'work-1',
        title: 'Entregar projeto',
        category: TaskCategory.work,
        plannedTime: const TimeOfDay(hour: 17, minute: 0),
        weekdays: {DateTime.thursday},
      );
      await state.addTask(task);

      await state.setWorkStatus(task.id, WorkStatus.done);
      await state.setWorkStatus(task.id, WorkStatus.done);

      expect(state.tasks.single.workStatus, WorkStatus.done);
      expect(state.profile.totalXp, 10);
      expect(state.xpHistory, hasLength(1));
    });
  });
}
