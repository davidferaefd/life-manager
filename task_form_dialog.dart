import 'package:flutter/material.dart';

import '../models/life_task.dart';

const _weekdayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

class TaskFormDialog extends StatefulWidget {
  const TaskFormDialog({
    required this.category,
    this.task,
    super.key,
  });

  final TaskCategory category;
  final LifeTask? task;

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late TimeOfDay _time;
  late Set<int> _weekdays;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _time = widget.task?.plannedTime ?? const TimeOfDay(hour: 9, minute: 0);
    _weekdays = {...?widget.task?.weekdays};
    if (widget.task == null) {
      _weekdays = {
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
      };
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (selected != null && mounted) setState(() => _time = selected);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um dia da semana.')),
      );
      return;
    }
    final task = widget.task;
    Navigator.of(context).pop(
      LifeTask(
        id: task?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        category: widget.category,
        plannedTime: _time,
        weekdays: _weekdays,
        completedDates: task?.completedDates ?? const {},
        workStatus: task?.workStatus ?? WorkStatus.todo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task == null ? 'Nova tarefa' : 'Editar tarefa'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nome da tarefa',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o nome da tarefa.'
                    : null,
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _selectTime,
                icon: const Icon(Icons.schedule_rounded),
                label: Text('Horário: ${_time.format(context)}'),
              ),
              const SizedBox(height: 12),
              Text('Repetir nos dias',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: [
                  for (var index = 0; index < _weekdayLabels.length; index++)
                    FilterChip(
                      label: Text(_weekdayLabels[index]),
                      selected: _weekdays.contains(index + 1),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _weekdays.add(index + 1);
                          } else {
                            _weekdays.remove(index + 1);
                          }
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

Future<LifeTask?> showTaskFormDialog(
  BuildContext context, {
  required TaskCategory category,
  LifeTask? task,
}) {
  return showDialog<LifeTask>(
    context: context,
    builder: (_) => TaskFormDialog(category: category, task: task),
  );
}
