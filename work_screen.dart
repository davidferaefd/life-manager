import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/life_task.dart';
import '../services/app_state.dart';
import '../widgets/screen_helpers.dart';

class WorkScreen extends StatelessWidget {
  const WorkScreen({super.key});

  Future<void> _changeStatus(
    BuildContext context,
    AppState state,
    LifeTask task,
    WorkStatus status,
  ) async {
    try {
      await state.setWorkStatus(task.id, status);
    } catch (error) {
      if (context.mounted) await showAppError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tasks = state.tasks
        .where((task) => task.category == TaskCategory.work)
        .toList()
      ..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
    final statuses = WorkStatus.values;
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trabalho & Projetos'),
        actions: [
          IconButton(
            tooltip: 'Adicionar demanda',
            onPressed: () => editTask(context, state, TaskCategory.work),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editTask(context, state, TaskCategory.work),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova demanda'),
      ),
      body: tasks.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                EmptyState(
                  icon: Icons.work_outline_rounded,
                  title: 'Seu quadro está vazio',
                  message:
                      'Adicione uma demanda ou projeto para organizar o trabalho.',
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Text(
                    'Arraste seu foco de uma etapa para outra',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 92),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final status in statuses)
                          _KanbanLane(
                            status: status,
                            tasks: tasks
                                .where((task) => task.workStatus == status)
                                .toList(),
                            width: (width - 56).clamp(260, 340),
                            onStatusSelected: (task, selected) =>
                                _changeStatus(context, state, task, selected),
                            onEdit: (task) => editTask(
                              context,
                              state,
                              TaskCategory.work,
                              task: task,
                            ),
                            onDelete: (task) =>
                                confirmTaskDeletion(context, state, task),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _KanbanLane extends StatelessWidget {
  const _KanbanLane({
    required this.status,
    required this.tasks,
    required this.width,
    required this.onStatusSelected,
    required this.onEdit,
    required this.onDelete,
  });

  final WorkStatus status;
  final List<LifeTask> tasks;
  final double width;
  final void Function(LifeTask, WorkStatus) onStatusSelected;
  final ValueChanged<LifeTask> onEdit;
  final ValueChanged<LifeTask> onDelete;

  String get _title => switch (status) {
        WorkStatus.todo => 'A Fazer',
        WorkStatus.inProgress => 'Fazendo',
        WorkStatus.done => 'Concluído',
      };

  IconData get _icon => switch (status) {
        WorkStatus.todo => Icons.radio_button_unchecked_rounded,
        WorkStatus.inProgress => Icons.pending_actions_rounded,
        WorkStatus.done => Icons.check_circle_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DragTarget<LifeTask>(
      onWillAcceptWithDetails: (details) => details.data.workStatus != status,
      onAcceptWithDetails: (details) => onStatusSelected(details.data, status),
      builder: (context, candidateData, rejectedData) => Container(
        width: width,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: candidateData.isNotEmpty
              ? colors.secondaryContainer.withValues(alpha: 0.5)
              : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: candidateData.isNotEmpty
                ? colors.secondary
                : colors.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Chip(label: Text('${tasks.length}')),
              ],
            ),
            const Divider(),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        'Solte uma demanda aqui',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Draggable<LifeTask>(
                          data: task,
                          feedback: Material(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: width - 32,
                              child: _WorkTaskCard(
                                task: task,
                                status: status,
                                onStatusSelected: onStatusSelected,
                                onEdit: onEdit,
                                onDelete: onDelete,
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.35,
                            child: _WorkTaskCard(
                              task: task,
                              status: status,
                              onStatusSelected: onStatusSelected,
                              onEdit: onEdit,
                              onDelete: onDelete,
                            ),
                          ),
                          child: _WorkTaskCard(
                            task: task,
                            status: status,
                            onStatusSelected: onStatusSelected,
                            onEdit: onEdit,
                            onDelete: onDelete,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkTaskCard extends StatelessWidget {
  const _WorkTaskCard({
    required this.task,
    required this.status,
    required this.onStatusSelected,
    required this.onEdit,
    required this.onDelete,
  });

  final LifeTask task;
  final WorkStatus status;
  final void Function(LifeTask, WorkStatus) onStatusSelected;
  final ValueChanged<LifeTask> onEdit;
  final ValueChanged<LifeTask> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Opções da demanda',
                  onSelected: (value) {
                    if (value == 'edit') onEdit(task);
                    if (value == 'delete') onDelete(task);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Excluir')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 15, color: colors.secondary),
                const SizedBox(width: 5),
                Text(task.plannedTime.format(context)),
                const Spacer(),
                PopupMenuButton<WorkStatus>(
                  tooltip: 'Mover para outra etapa',
                  initialValue: status,
                  onSelected: (value) => onStatusSelected(task, value),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: WorkStatus.todo,
                      child: Text('A Fazer'),
                    ),
                    PopupMenuItem(
                      value: WorkStatus.inProgress,
                      child: Text('Fazendo'),
                    ),
                    PopupMenuItem(
                      value: WorkStatus.done,
                      child: Text('Concluído (+10 XP)'),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz_rounded,
                            size: 18, color: colors.primary),
                        const SizedBox(width: 3),
                        Text('Mover',
                            style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
