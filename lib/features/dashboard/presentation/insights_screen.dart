import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ai_productivity_assistant/features/tasks/presentation/task_provider.dart';
import 'widgets/productivity_pulse_gauge.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(body: SafeArea(child: _InsightsBody()));
  }
}

class _InsightsBody extends ConsumerWidget {
  const _InsightsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final metrics = ref.watch(productivityMetricsProvider);
    final selectedRange = ref.watch(insightsRangeProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text('Insights', style: theme.textTheme.displayLarge),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _InsightsRangeSelector(
                    selectedRange: selectedRange,
                    onChanged: (range) =>
                        ref.read(insightsRangeProvider.notifier).set(range),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Intelligence-driven analytics for the last $selectedRange days.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Gauge Section
              RepaintBoundary(child: _PulseGaugeSection(metrics: metrics)),
              const SizedBox(height: 40),

              _MetricsGrid(metrics: metrics),
              const SizedBox(height: 32),

              // Chart Section
              RepaintBoundary(child: _ChartSection(metrics: metrics)),
              const SizedBox(height: 32),

              // AI Recommendation (Hide if no data)
              if ((metrics['totalHours'] ?? '0.0') != '0.0') ...[
                _AIRecommendationCard(metrics: metrics),
                const SizedBox(height: 32),
              ],

              // Category Distribution (Hide if empty)
              const _CategoryDistributionSection(),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }
}

class _PulseGaugeSection extends StatelessWidget {
  final Map<String, dynamic> metrics;
  const _PulseGaugeSection({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final weeklyProgress =
        (metrics['weeklyProgress'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [];

    if (weeklyProgress.isEmpty ||
        weeklyProgress.every((value) => value == 0.0)) {
      return const Center(
        child: ProductivityPulseGauge(progress: 0.0, label: 'Awaiting Data'),
      );
    }

    final double focusScore =
        (weeklyProgress.reduce((a, b) => a + b) /
                (weeklyProgress.length * 10.0))
            .clamp(0.0, 1.0);

    return Center(
      child: ProductivityPulseGauge(
        progress: focusScore,
        label: 'Weekly Focus Pulse',
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final Map<String, dynamic> metrics;
  const _MetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: RepaintBoundary(
            child: _MetricCard(
              title: 'Focus Hours',
              value: '${metrics['totalHours'] ?? '0.0'}h',
              icon: LucideIcons.clock,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: RepaintBoundary(
            child: _MetricCard(
              title: 'Efficiency',
              value: '${metrics['growth'] ?? '0'}%',
              icon: LucideIcons.zap,
              color: theme.colorScheme.tertiary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartSection extends StatelessWidget {
  final Map<String, dynamic> metrics;
  const _ChartSection({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weeklyProgress =
        (metrics['weeklyProgress'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [];
    final spots = weeklyProgress
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    if (spots.isEmpty) {
      return Container(
        height: 252,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            'No recent activity in the last 7 days. Complete tasks to generate insights.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity Wave',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LAST 7 DAYS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 160,
            child: RepaintBoundary(
              child: LineChart(
                duration: const Duration(milliseconds: 400),
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                            theme.colorScheme.primary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsRangeSelector extends StatelessWidget {
  final int selectedRange;
  final ValueChanged<int> onChanged;

  const _InsightsRangeSelector({
    required this.selectedRange,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const ranges = [7, 30, 90];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ranges.map((range) {
        final isSelected = selectedRange == range;
        return ChoiceChip(
          label: Text('${range}D'),
          selected: isSelected,
          onSelected: (_) => onChanged(range),
          selectedColor: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          labelStyle: theme.textTheme.labelSmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryDistributionSection extends ConsumerWidget {
  const _CategoryDistributionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final metrics = ref.watch(productivityMetricsProvider);
    final categoryDist =
        metrics['categoryDistribution'] as Map<String, double>? ?? {};

    if (categoryDist.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category Distribution', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 20),
        ...categoryDist.entries.map((e) {
          Color col;
          switch (e.key) {
            case 'Work':
              col = theme.colorScheme.primary;
              break;
            case 'Personal':
              col = theme.colorScheme.secondary;
              break;
            case 'Health':
              col = Colors.green;
              break;
            case 'Finance':
              col = Colors.amber;
              break;
            case 'Growth':
              col = Colors.indigo;
              break;
            default:
              col = theme.colorScheme.tertiary;
          }
          return _CategoryBar(label: e.key, perc: e.value, color: col);
        }),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final double perc;
  final Color color;
  const _CategoryBar({
    required this.label,
    required this.perc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(perc * 100).toInt()}%',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: perc,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AIRecommendationCard extends StatelessWidget {
  final Map<String, dynamic> metrics;
  const _AIRecommendationCard({required this.metrics});

  String _getInsightText() {
    final double? totalHours = double.tryParse(
      metrics['totalHours']?.toString() ?? '0',
    );
    final int growth = metrics['growth'] as int? ?? 0;
    final categoryDist =
        metrics['categoryDistribution'] as Map<String, double>? ?? {};

    if (totalHours == null || totalHours == 0) {
      return "Deep focus analysis requires more task data. Start completing more tasks to see your patterns.";
    }

    if (growth > 15) {
      return "Excellent! Productivity is up by $growth% compared to last week. You're hitting your flow state more often.";
    }

    String? dominantCategory;
    double maxPerc = 0;
    categoryDist.forEach((k, v) {
      if (v > maxPerc) {
        maxPerc = v;
        dominantCategory = k;
      }
    });

    if (maxPerc > 0.6 && dominantCategory != null) {
      return "Focus alert: $dominantCategory tasks take up ${(maxPerc * 100).toInt()}% of your capacity. Balance other priority areas.";
    }

    if (growth < -10) {
      return "Productivity dipped by ${growth.abs()}%. Consider shifting high-intensity tasks to earlier in your day.";
    }

    return "Consistent performance detected. Your current task completion rate is stable and sustainable.";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.sparkles,
            color: theme.colorScheme.tertiary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _getInsightText(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
