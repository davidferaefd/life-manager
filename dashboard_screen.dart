import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/xp_entry.dart';
import '../services/app_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduledToday =
        state.tasks.where((task) => task.isScheduledOn(today)).toList();
    final completedToday =
        scheduledToday.where((task) => task.isCompletedOn(today)).length;
    final completedLast30Days = _last30DaysCounts(state.xpHistory, today);
    final completionsThisMonth = completedLast30Days.fold<int>(
      0,
      (total, count) => total + count,
    );
    final activeStreak = _activeStreak(
      state.profile.currentStreak,
      state.profile.lastActiveDate,
      today,
    );
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumo & evolução')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: colors.primaryContainer,
                        child: Icon(Icons.bolt_rounded,
                            color: colors.primary, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Nível ${state.profile.level} · ${state.profile.levelTitle}',
                                style: Theme.of(context).textTheme.titleLarge),
                            Text('${state.profile.totalXp} XP acumulados'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${state.profile.xpInCurrentLevel} / 100 XP para o próximo nível',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Text('${state.profile.xpInCurrentLevel}%'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: state.profile.xpInCurrentLevel / 100,
                      minHeight: 10,
                      backgroundColor: colors.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Ofensiva atual',
                  value: '$activeStreak dias',
                  tint: colors.tertiary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: Icons.task_alt_rounded,
                  label: 'Concluídas hoje',
                  value: '$completedToday / ${scheduledToday.length}',
                  tint: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Constância · últimos 30 dias',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '$completionsThisMonth tarefas concluídas no período',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 18, 12),
              child: SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: _chartMax(completedLast30Days),
                    alignment: BarChartAlignment.spaceAround,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: colors.outlineVariant.withValues(alpha: 0.45),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final date = today.subtract(
                            Duration(days: 29 - group.x.toInt()),
                          );
                          return BarTooltipItem(
                            '${date.day}/${date.month}\n${rod.toY.toInt()} tarefas',
                            TextStyle(
                              color: colors.onInverseSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 1,
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
                          interval: 5,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= 30 || index % 5 != 0) {
                              return const SizedBox.shrink();
                            }
                            final date = today.subtract(
                              Duration(days: 29 - index),
                            );
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${date.day}/${date.month}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var index = 0;
                          index < completedLast30Days.length;
                          index++)
                        BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: completedLast30Days[index].toDouble(),
                              color: colors.primary,
                              width: 7,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: _chartMax(completedLast30Days),
                                color: colors.surfaceContainerHighest
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _MetricCard(
            icon: Icons.stars_rounded,
            label: 'Próxima conquista',
            value:
                '${100 - state.profile.xpInCurrentLevel} XP para o nível ${state.profile.level + 1}',
            tint: colors.secondary,
          ),
        ],
      ),
    );
  }

  static List<int> _last30DaysCounts(List<XpEntry> history, DateTime today) {
    final counts = List<int>.filled(30, 0);
    for (final entry in history) {
      final entryDay = DateTime.utc(
        entry.earnedAt.year,
        entry.earnedAt.month,
        entry.earnedAt.day,
      );
      final todayUtc = DateTime.utc(today.year, today.month, today.day);
      final age = todayUtc.difference(entryDay).inDays;
      if (age >= 0 && age < 30) counts[29 - age]++;
    }
    return counts;
  }

  static double _chartMax(List<int> values) {
    final highest = values.fold<int>(
        0, (current, value) => value > current ? value : current);
    return (highest + 1).toDouble();
  }

  static int _activeStreak(int stored, String? lastActiveDate, DateTime today) {
    if (lastActiveDate == null) return 0;
    final lastActive = DateTime.parse(lastActiveDate);
    final daysSince = DateTime.utc(today.year, today.month, today.day)
        .difference(
          DateTime.utc(lastActive.year, lastActive.month, lastActive.day),
        )
        .inDays;
    return daysSince <= 1 && daysSince >= 0 ? stored : 0;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: tint, size: 24),
            const SizedBox(height: 10),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 3),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
