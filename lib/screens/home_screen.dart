import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/life_task.dart';
import '../services/app_state.dart';
import '../widgets/screen_helpers.dart';
import '../widgets/task_card.dart';

enum _TaskFilter { pending, completed, all }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _TaskFilter _filter = _TaskFilter.pending;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = DateTime.now();
    final tasks = state.tasks
        .where((task) => task.category == TaskCategory.home)
        .toList()
      ..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
    final dueToday = tasks.where((task) => task.isScheduledOn(today)).toList();
    final otherTasks =
        tasks.where((task) => !task.isScheduledOn(today)).toList();
    final visibleTasks = dueToday.where((task) {
      final completed = task.isCompletedOn(today);
      return _filter == _TaskFilter.all ||
          (_filter == _TaskFilter.completed && completed) ||
          (_filter == _TaskFilter.pending && !completed);
    }).toList();
    final doneCount =
        dueToday.where((task) => task.isCompletedOn(today)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Casa'),
        actions: [
          IconButton(
            tooltip: 'Adicionar tarefa doméstica',
            onPressed: () => editTask(context, state, TaskCategory.home),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editTask(context, state, TaskCategory.home),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova tarefa'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.home_rounded,
                      size: 32, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rotina de hoje',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                            '$doneCount de ${dueToday.length} tarefas concluídas'),
                      ],
                    ),
                  ),
                  Text(
                    '${dueToday.isEmpty ? 0 : (doneCount * 100 ~/ dueToday.length)}%',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<_TaskFilter>(
            segments: const [
              ButtonSegment(
                  value: _TaskFilter.pending, label: Text('Pendentes')),
              ButtonSegment(
                  value: _TaskFilter.completed, label: Text('Concluídas')),
              ButtonSegment(value: _TaskFilter.all, label: Text('Todas')),
            ],
            selected: {_filter},
            onSelectionChanged: (selection) =>
                setState(() => _filter = selection.first),
          ),
          const SizedBox(height: 10),
          if (visibleTasks.isEmpty)
            EmptyState(
              icon: Icons.checklist_rounded,
              title:
                  dueToday.isEmpty ? 'Dia livre por enquanto' : 'Tudo em dia',
              message: dueToday.isEmpty
                  ? tasks.isEmpty
                      ? 'Adicione uma tarefa e escolha os dias em que ela se repete.'
                      : 'Não há tarefas previstas para hoje. Confira suas outras rotinas abaixo.'
                  : 'Não há tarefas ${_filter == _TaskFilter.completed ? 'concluídas' : 'pendentes'} para este filtro.',
            )
          else
            for (final task in visibleTasks)
              TaskCard(
                task: task,
                completed: task.isCompletedOn(today),
                canComplete: true,
                onCompletionChanged: (completed) async {
                  try {
                    if (completed) {
                      await state.completeTask(task.id, completedAt: today);
                    } else {
                      await state.reopenTask(task.id, completedAt: today);
                    }
                  } catch (error) {
                    if (context.mounted) await showAppError(context, error);
                  }
                },
                onEdit: () => editTask(
                  context,
                  state,
                  TaskCategory.home,
                  task: task,
                ),
                onDelete: () => confirmTaskDeletion(context, state, task),
              ),
          if (otherTasks.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Outras rotinas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            for (final task in otherTasks)
              TaskCard(
                task: task,
                completed: false,
                canComplete: false,
                onCompletionChanged: (_) {},
                onEdit: () => editTask(
                  context,
                  state,
                  TaskCategory.home,
                  task: task,
                ),
                onDelete: () => confirmTaskDeletion(context, state, task),
              ),
          ],
        ],
      ),
    );
  }
}
