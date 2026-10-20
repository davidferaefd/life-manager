import 'package:flutter/material.dart';

import '../models/life_task.dart';
import '../services/app_state.dart';
import 'task_form_dialog.dart';

Future<void> showAppError(BuildContext context, Object error) async {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Não foi possível concluir a operação: $error')),
  );
}

Future<void> editTask(
  BuildContext context,
  AppState state,
  TaskCategory category, {
  LifeTask? task,
}) async {
  final edited = await showTaskFormDialog(
    context,
    category: category,
    task: task,
  );
  if (edited == null || !context.mounted) return;
  try {
    if (task == null) {
      await state.addTask(edited);
    } else {
      await state.updateTask(edited);
    }
  } catch (error) {
    if (context.mounted) await showAppError(context, error);
  }
}

Future<void> confirmTaskDeletion(
  BuildContext context,
  AppState state,
  LifeTask task,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Excluir tarefa?'),
      content: Text('A tarefa "${task.title}" será removida permanentemente.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await state.deleteTask(task.id);
  } catch (error) {
    if (context.mounted) await showAppError(context, error);
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: colors.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
