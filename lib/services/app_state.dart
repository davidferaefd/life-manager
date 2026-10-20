import 'package:flutter/foundation.dart';

import '../models/app_data.dart';
import '../models/life_task.dart';
import '../models/user_profile.dart';
import '../models/vocabulary_item.dart';
import '../models/xp_entry.dart';
import 'local_storage_service.dart';

class AppState extends ChangeNotifier {
  AppState(this._storage) : _data = AppData.empty();

  AppState.inMemory()
      : _storage = null,
        _data = AppData.empty();

  final LocalStorageService? _storage;
  AppData _data;
  Future<void> _saveQueue = Future<void>.value();

  UserProfile get profile => _data.profile;
  List<LifeTask> get tasks => _data.tasks;
  List<XpEntry> get xpHistory => _data.xpHistory;
  List<VocabularyItem> get vocabulary => _data.vocabulary;

  Future<void> initialize() async {
    final storage = _storage;
    if (storage == null) return;
    _data = storage.load();
    notifyListeners();
  }

  Future<void> addTask(LifeTask task) async {
    if (_data.tasks.any((existing) => existing.id == task.id)) {
      throw StateError('Já existe uma tarefa com o identificador ${task.id}.');
    }
    _data = AppData(
      profile: profile,
      tasks: [...tasks, task],
      xpHistory: xpHistory,
      vocabulary: vocabulary,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> updateTask(LifeTask updatedTask) async {
    final index = tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index < 0) {
      throw StateError('A tarefa ${updatedTask.id} não foi encontrada.');
    }
    final updatedTasks = [...tasks];
    updatedTasks[index] = updatedTask;
    _replaceData(tasks: updatedTasks);
    await _persist();
  }

  Future<void> deleteTask(String taskId) async {
    if (!tasks.any((task) => task.id == taskId)) {
      throw StateError('A tarefa $taskId não foi encontrada.');
    }
    _replaceData(tasks: tasks.where((task) => task.id != taskId).toList());
    await _persist();
  }

  Future<void> setWorkStatus(String taskId, WorkStatus status) async {
    if (status == WorkStatus.done) {
      await completeTask(taskId);
      final index = tasks.indexWhere((task) => task.id == taskId);
      if (index >= 0 && tasks[index].workStatus != WorkStatus.done) {
        final updatedTasks = [...tasks];
        updatedTasks[index] =
            updatedTasks[index].copyWith(workStatus: WorkStatus.done);
        _replaceData(tasks: updatedTasks);
        await _persist();
      }
      return;
    }
    final index = tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) throw StateError('A tarefa $taskId não foi encontrada.');
    final updatedTasks = [...tasks];
    updatedTasks[index] = updatedTasks[index].copyWith(workStatus: status);
    _replaceData(tasks: updatedTasks);
    await _persist();
  }

  Future<void> completeTask(String taskId, {DateTime? completedAt}) async {
    final index = tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) throw StateError('A tarefa $taskId não foi encontrada.');

    final now = completedAt ?? DateTime.now();
    final key = dateKey(now);
    final task = tasks[index];
    if (task.completedDates.contains(key)) return;

    final completedDates = {...task.completedDates, key};
    final updatedTasks = [...tasks];
    updatedTasks[index] = task.copyWith(
      completedDates: completedDates,
      workStatus: task.category == TaskCategory.work
          ? WorkStatus.done
          : task.workStatus,
    );
    final entry = XpEntry(
      id: now.microsecondsSinceEpoch.toString(),
      taskId: taskId,
      amount: 10,
      earnedAt: now,
    );
    _data = AppData(
      profile: _profileAfterCompletion(now),
      tasks: updatedTasks,
      xpHistory: [...xpHistory, entry],
      vocabulary: vocabulary,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> reopenTask(String taskId, {DateTime? completedAt}) async {
    final index = tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) throw StateError('A tarefa $taskId não foi encontrada.');
    final key = dateKey(completedAt ?? DateTime.now());
    final task = tasks[index];
    if (!task.completedDates.contains(key)) return;

    final updatedTasks = [...tasks];
    updatedTasks[index] = task.copyWith(
      completedDates: {...task.completedDates}..remove(key),
      workStatus: task.category == TaskCategory.work
          ? WorkStatus.todo
          : task.workStatus,
    );
    final removedEntries = xpHistory
        .where(
            (entry) => entry.taskId == taskId && dateKey(entry.earnedAt) == key)
        .toList();
    final updatedHistory =
        xpHistory.where((entry) => !removedEntries.contains(entry)).toList();
    final remainingDays =
        updatedHistory.map((entry) => dateKey(entry.earnedAt)).toSet();
    final latestDate =
        remainingDays.isEmpty ? null : (remainingDays.toList()..sort()).last;
    var streak = 0;
    if (latestDate != null) {
      final parsedDate = DateTime.parse(latestDate);
      var currentDate =
          DateTime.utc(parsedDate.year, parsedDate.month, parsedDate.day);
      while (remainingDays.contains(dateKey(currentDate))) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      }
    }
    _data = AppData(
      profile: profile.copyWith(
        totalXp: (profile.totalXp -
                removedEntries.fold<int>(
                  0,
                  (total, entry) => total + entry.amount,
                ))
            .clamp(0, profile.totalXp)
            .toInt(),
        currentStreak: streak,
        lastActiveDate: latestDate,
        clearLastActiveDate: latestDate == null,
      ),
      tasks: updatedTasks,
      xpHistory: updatedHistory,
      vocabulary: vocabulary,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> addVocabulary(VocabularyItem item) async {
    if (_data.vocabulary.any((existing) => existing.id == item.id)) {
      throw StateError(
          'Já existe um item de vocabulário com esse identificador.');
    }
    _replaceData(vocabulary: [...vocabulary, item]);
    await _persist();
  }

  Future<void> markVocabularyReviewed(String itemId) async {
    final index = vocabulary.indexWhere((item) => item.id == itemId);
    if (index < 0) {
      throw StateError('O item de vocabulário $itemId não foi encontrado.');
    }
    final item = vocabulary[index];
    final reviewed = VocabularyItem(
      id: item.id,
      term: item.term,
      translation: item.translation,
      createdAt: item.createdAt,
      lastReviewedAt: DateTime.now(),
      reviewCount: item.reviewCount + 1,
    );
    final updatedVocabulary = [...vocabulary];
    updatedVocabulary[index] = reviewed;
    _replaceData(vocabulary: updatedVocabulary);
    await _persist();
  }

  void _replaceData({
    List<LifeTask>? tasks,
    List<VocabularyItem>? vocabulary,
  }) {
    _data = AppData(
      profile: profile,
      tasks: tasks ?? this.tasks,
      xpHistory: xpHistory,
      vocabulary: vocabulary ?? this.vocabulary,
    );
    notifyListeners();
  }

  UserProfile _profileAfterCompletion(DateTime completedAt) {
    final previousDate = profile.lastActiveDate;
    final today =
        DateTime(completedAt.year, completedAt.month, completedAt.day);
    var streak = profile.currentStreak;

    if (previousDate == null) {
      streak = 1;
    } else {
      final previous = DateTime.parse(previousDate);
      final previousDay =
          DateTime.utc(previous.year, previous.month, previous.day);
      final currentDay = DateTime.utc(today.year, today.month, today.day);
      final difference = currentDay.difference(previousDay).inDays;
      if (difference == 1) {
        streak++;
      } else if (difference > 1) {
        streak = 1;
      }
    }

    return profile.copyWith(
      totalXp: profile.totalXp + 10,
      currentStreak: streak,
      lastActiveDate: dateKey(today),
    );
  }

  Future<void> _persist() async {
    final storage = _storage;
    if (storage == null) return;

    final snapshot = _data;
    final operation = _saveQueue.then((_) => storage.save(snapshot));
    // A falha é propagada para a operação atual sem bloquear tentativas futuras.
    _saveQueue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    await operation;
  }
}
