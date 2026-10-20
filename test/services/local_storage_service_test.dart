import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_manager/models/life_task.dart';
import 'package:life_manager/models/vocabulary_item.dart';
import 'package:life_manager/services/app_state.dart';
import 'package:life_manager/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restaura tarefas, vocabulário, XP e perfil do armazenamento local',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final state = AppState(LocalStorageService(preferences));
    await state.initialize();

    final task = LifeTask(
      id: 'saved-task',
      title: 'Revisar inglês',
      category: TaskCategory.study,
      plannedTime: const TimeOfDay(hour: 19, minute: 15),
      weekdays: {DateTime.thursday},
    );
    await state.addTask(task);
    await state.completeTask(task.id, completedAt: DateTime(2026, 10, 15));
    await state.addVocabulary(
      VocabularyItem(
        id: 'saved-word',
        term: 'Consistency',
        translation: 'Constância',
        createdAt: DateTime(2026, 10, 15),
      ),
    );

    final restored = AppState(LocalStorageService(preferences));
    await restored.initialize();

    expect(restored.tasks.single.plannedTime,
        const TimeOfDay(hour: 19, minute: 15));
    expect(restored.tasks.single.weekdays, {DateTime.thursday});
    expect(restored.profile.totalXp, 10);
    expect(restored.xpHistory, hasLength(1));
    expect(restored.vocabulary.single.term, 'Consistency');
    state.dispose();
    restored.dispose();
  });
}
