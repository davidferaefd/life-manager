import 'package:flutter/material.dart';

import '../models/life_task.dart';

const _weekdayShortLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    required this.completed,
    required this.onCompletionChanged,
    required this.onEdit,
    required this.onDelete,
    this.canComplete = true,
    super.key,
  });

  final LifeTask task;
  final bool completed;
  final ValueChanged<bool> onCompletionChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canComplete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final days = task.weekdays.toList()..sort();
    final schedule = days.length == 7
        ? 'Todos os dias'
        : days.map((day) => _weekdayShortLabels[day - 1]).join(', ');

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Checkbox(
          value: completed,
          onChanged: canComplete
              ? (value) => onCompletionChanged(value ?? false)
              : null,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: completed ? TextDecoration.lineThrough : null,
            color: completed ? colors.onSurfaceVariant : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              _MetaLabel(
                icon: Icons.schedule_rounded,
                label: task.plannedTime.format(context),
              ),
              _MetaLabel(icon: Icons.repeat_rounded, label: schedule),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Opções da tarefa',
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  const _MetaLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
