import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/life_task.dart';
import '../models/vocabulary_item.dart';
import '../services/app_state.dart';
import '../widgets/screen_helpers.dart';
import '../widgets/task_card.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  static const _focusLength = 25 * 60;
  static const _breakLength = 5 * 60;

  Timer? _timer;
  int _secondsRemaining = _focusLength;
  bool _isFocusSession = true;
  bool _isRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      return;
    }
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _isFocusSession = !_isFocusSession;
          _secondsRemaining = _isFocusSession ? _focusLength : _breakLength;
          _isRunning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFocusSession
                ? 'Pausa concluída. Hora de focar!'
                : 'Sessão de foco concluída. Faça uma pausa!'),
          ),
        );
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isFocusSession = true;
      _secondsRemaining = _focusLength;
    });
  }

  String get _timerLabel {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _addVocabulary(AppState state) async {
    final termController = TextEditingController();
    final translationController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<VocabularyItem>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nova palavra ou tópico'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: termController,
                autofocus: true,
                decoration:
                    const InputDecoration(labelText: 'Palavra ou tópico'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Preencha este campo.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: translationController,
                decoration: const InputDecoration(
                  labelText: 'Tradução ou anotação',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Preencha este campo.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final now = DateTime.now();
              Navigator.pop(
                dialogContext,
                VocabularyItem(
                  id: now.microsecondsSinceEpoch.toString(),
                  term: termController.text.trim(),
                  translation: translationController.text.trim(),
                  createdAt: now,
                ),
              );
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    termController.dispose();
    translationController.dispose();
    if (result == null || !mounted) return;
    try {
      await state.addVocabulary(result);
    } catch (error) {
      if (mounted) await showAppError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = DateTime.now();
    final tasks = state.tasks
        .where((task) => task.category == TaskCategory.study)
        .toList()
      ..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
    final scheduledToday =
        tasks.where((task) => task.isScheduledOn(today)).toList();
    final otherStudyTasks =
        tasks.where((task) => !task.isScheduledOn(today)).toList();
    final colors = Theme.of(context).colorScheme;
    final progress = _isFocusSession
        ? 1 - _secondsRemaining / _focusLength
        : 1 - _secondsRemaining / _breakLength;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudos & Inglês'),
        actions: [
          IconButton(
            tooltip: 'Adicionar estudo',
            onPressed: () => editTask(context, state, TaskCategory.study),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editTask(context, state, TaskCategory.study),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo estudo'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _isFocusSession
                            ? Icons.center_focus_strong
                            : Icons.coffee,
                        color: colors.secondary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isFocusSession ? 'Sessão de foco' : 'Pausa',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        _isFocusSession ? '25 min' : '5 min',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 166,
                    height: 166,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 9,
                          backgroundColor: colors.surfaceContainerHighest,
                          strokeCap: StrokeCap.round,
                        ),
                        Center(
                          child: Text(
                            _timerLabel,
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _toggleTimer,
                        icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(_isRunning ? 'Pausar' : 'Iniciar'),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: 'Reiniciar Pomodoro',
                        onPressed: _resetTimer,
                        icon: const Icon(Icons.restart_alt_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _SectionHeading(
            title: 'Plano de estudos de hoje',
            action: IconButton(
              tooltip: 'Adicionar estudo',
              onPressed: () => editTask(context, state, TaskCategory.study),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ),
          if (scheduledToday.isEmpty)
            EmptyState(
              icon: Icons.menu_book_rounded,
              title: tasks.isEmpty
                  ? 'Seu plano começa aqui'
                  : 'Nenhum estudo para hoje',
              message: tasks.isEmpty
                  ? 'Adicione cursos, tópicos e horários para organizar seus estudos.'
                  : 'Veja abaixo os outros tópicos programados.',
            )
          else
            for (final task in scheduledToday)
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
                  TaskCategory.study,
                  task: task,
                ),
                onDelete: () => confirmTaskDeletion(context, state, task),
              ),
          if (otherStudyTasks.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Outros tópicos programados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            for (final task in otherStudyTasks)
              TaskCard(
                task: task,
                completed: false,
                canComplete: false,
                onCompletionChanged: (_) {},
                onEdit: () => editTask(
                  context,
                  state,
                  TaskCategory.study,
                  task: task,
                ),
                onDelete: () => confirmTaskDeletion(context, state, task),
              ),
          ],
          const SizedBox(height: 16),
          _SectionHeading(
            title: 'Revisão de vocabulário',
            action: IconButton(
              tooltip: 'Adicionar vocabulário',
              onPressed: () => _addVocabulary(state),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ),
          if (state.vocabulary.isEmpty)
            const EmptyState(
              icon: Icons.translate_rounded,
              title: 'Sua lista está vazia',
              message: 'Guarde palavras, traduções ou tópicos para revisar.',
            )
          else
            for (final item in state.vocabulary)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colors.secondaryContainer,
                    child:
                        Icon(Icons.translate_rounded, color: colors.secondary),
                  ),
                  title: Text(item.term),
                  subtitle: Text(
                    '${item.translation}\nRevisada ${item.reviewCount} vez(es)',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Marcar como revisada',
                    onPressed: () async {
                      try {
                        await state.markVocabularyReviewed(item.id);
                      } catch (error) {
                        if (context.mounted) await showAppError(context, error);
                      }
                    },
                    icon: const Icon(Icons.done_all_rounded),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.action});

  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        action,
      ],
    );
  }
}
