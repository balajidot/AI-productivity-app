import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/glass_container.dart';
import '../providers/app_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLowPerformance = ref.watch(performanceModeProvider);
    final metrics = ref.watch(productivityMetricsProvider);
    final weeklyProgress = metrics['weeklyProgress'] as List<double>;
    final categoryDist = metrics['categoryDistribution'] as Map<String, double>;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insights',
                style: theme.textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Data-driven optimization of your workflow.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              
              _buildMetricCard(
                context, 
                theme,
                'Focus Hours', 
                '${metrics['totalHours']}h', 
                '${metrics['growth']}%', 
                LucideIcons.clock,
                isGrowth: (double.tryParse(metrics['growth'] ?? '0') ?? 0) >= 0,
              ),
              const SizedBox(height: 24),
              
              _buildChartSection(context, theme, weeklyProgress, isLowPerformance),
              const SizedBox(height: 32),
              
              _buildAIRecommendation(context, theme, metrics),
              const SizedBox(height: 32),
              
              _buildSectionHeader(context, 'Category Split'),
              const SizedBox(height: 16),
              if (categoryDist.isEmpty)
                Text('Add tasks to see distribution', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ...categoryDist.entries.map((e) {
                Color col;
                switch (e.key) {
                  case 'Work': col = theme.colorScheme.primary; break;
                  case 'Personal': col = theme.colorScheme.secondary; break;
                  case 'Health': col = theme.colorScheme.tertiary; break;
                  case 'Study': col = Colors.orangeAccent; break;
                  case 'Finance': col = Colors.greenAccent; break;
                  default: col = theme.colorScheme.outline;
                }
                return _buildCategoryBar(context, theme, e.key, e.value, col);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, ThemeData theme, String title, String val, String change, IconData icon, {bool isGrowth = true}) {
    return GlassContainer(
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 32),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                Text(val, style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isGrowth ? Colors.green : Colors.red).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              (isGrowth ? '+' : '') + change,
              style: TextStyle(
                color: isGrowth ? Colors.greenAccent : Colors.redAccent, 
                fontSize: 12, 
                fontWeight: FontWeight.bold
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, ThemeData theme, List<double> values, bool isLowPerformance) {
    // Generate spots from values
    final spots = values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Weekly Completion'),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: LineChart(
            duration: isLowPerformance ? Duration.zero : const Duration(milliseconds: 250),
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                  isCurved: true,
                  color: theme.colorScheme.primary,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: !isLowPerformance,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 4,
                      color: theme.colorScheme.surface,
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.primary,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: !isLowPerformance,
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
      ],
    );
  }

  Widget _buildAIRecommendation(BuildContext context, ThemeData theme, Map<String, dynamic> metrics) {
    final growth = double.tryParse(metrics['growth'] ?? '0') ?? 0;
    String advice = "Start completing tasks to get AI-powered productivity advice.";
    if (growth > 0) {
      advice = "Your productivity is up ${metrics['growth']}%! Staying consistent with your current rhythm is key.";
    } else if (metrics['totalHours'] != '0.0') {
      advice = "Try breaking down large tasks into smaller focus blocks to boost your completion rate.";
    }

    return GlassContainer(
      color: theme.colorScheme.tertiary,
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, color: theme.colorScheme.tertiary, size: 20),
              const SizedBox(width: 8),
              Text(
                'NVIDIA AI ADVICE',
                style: TextStyle(
                  color: theme.colorScheme.tertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            advice,
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }

  Widget _buildCategoryBar(BuildContext context, ThemeData theme, String label, double perc, Color color) {
    if (perc <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface)),
              Text('${(perc * 100).toInt()}%', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: perc,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
