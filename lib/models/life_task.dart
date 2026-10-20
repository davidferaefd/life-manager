import 'package:flutter/material.dart';

enum TaskCategory { home, study, work }

enum WorkStatus { todo, inProgress, done }

class LifeTask {
  LifeTask({
    required this.id,
    required this.title,
    required this.category,
    required TimeOfDay plannedTime,
    required Set<int> weekdays,
    Set<String> completedDates = const {},
    this.workStatus = WorkStatus.todo,
  })  : minuteOfDay = plannedTime.hour * 60 + plannedTime.minute,
        weekdays = Set.unmodifiable(weekdays),
        completedDates = Set.unmodifiable(completedDates) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(
          id, 'id', 'O identificador não pode ser vazio.');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'O nome não pode ser vazio.');
    }
    if (weekdays.any((day) => day < DateTime.monday || day > DateTime.sunday)) {
      throw ArgumentError.value(
        weekdays,
        'weekdays',
        'Os dias da semana devem estar entre 1 (segunda) e 7 (domingo).',
      );
    }
  }

  LifeTask._({
    required this.id,
    required this.title,
    required this.category,
    required this.minuteOfDay,
    required Set<int> weekdays,
    required Set<String> completedDates,
    required this.workStatus,
  })  : weekdays = Set.unmodifiable(weekdays),
        completedDates = Set.unmodifiable(completedDates);

  final String id;
  final String title;
  final TaskCategory category;
  final int minuteOfDay;
  final Set<int> weekdays;
  final Set<String> completedDates;
  final WorkStatus workStatus;

  /// Converte os minutos armazenados para o tipo usado pelos seletores do Flutter.
  TimeOfDay get plannedTime => TimeOfDay(
        hour: minuteOfDay ~/ 60,
        minute: minuteOfDay % 60,
      );

  bool isScheduledOn(DateTime date) => weekdays.contains(date.weekday);

  bool isCompletedOn(DateTime date) => completedDates.contains(dateKey(date));

  LifeTask copyWith({
    String? title,
    TaskCategory? category,
    TimeOfDay? plannedTime,
    Set<int>? weekdays,
    Set<String>? completedDates,
    WorkStatus? workStatus,
  }) {
    return LifeTask(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      plannedTime: plannedTime ?? this.plannedTime,
      weekdays: weekdays ?? this.weekdays,
      completedDates: completedDates ?? this.completedDates,
      workStatus: workStatus ?? this.workStatus,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'minuteOfDay': minuteOfDay,
        'weekdays': weekdays.toList()..sort(),
        'completedDates': completedDates.toList()..sort(),
        'workStatus': workStatus.name,
      };

  factory LifeTask.fromJson(Map<String, dynamic> json) {
    final minuteOfDay = json['minuteOfDay'];
    if (minuteOfDay is! int || minuteOfDay < 0 || minuteOfDay >= 24 * 60) {
      throw const FormatException('Horário inválido na tarefa.');
    }

    final categoryName = json['category'];
    final statusName = json['workStatus'];
    final category = TaskCategory.values.where(
      (value) => value.name == categoryName,
    );
    final status = WorkStatus.values.where(
      (value) => value.name == statusName,
    );
    if (category.isEmpty || status.isEmpty) {
      throw const FormatException('Categoria ou status inválido na tarefa.');
    }

    final weekdaysJson = json['weekdays'];
    final completedDatesJson = json['completedDates'];
    if (weekdaysJson is! List || completedDatesJson is! List) {
      throw const FormatException('Dias ou conclusões inválidos na tarefa.');
    }

    return LifeTask._(
      id: json['id'] as String,
      title: json['title'] as String,
      category: category.first,
      minuteOfDay: minuteOfDay,
      weekdays: weekdaysJson.map((value) => value as int).toSet(),
      completedDates:
          completedDatesJson.map((value) => value as String).toSet(),
      workStatus: status.first,
    );
  }
}

String dateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
