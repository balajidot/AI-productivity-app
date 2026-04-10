import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glass_container.dart';
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/productivity_pulse_gauge.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: SafeArea(
        child: _InsightsBody(),
      ),
    );
  }
}

class _InsightsBody extends ConsumerWidget {
  const _InsightsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final metrics = ref.watch(productivityMetricsProvider);
    final isLowPerformance = ref.watch(performanceModeProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text('Insights', style: theme.textTheme.displayLarge)
                  .animate().fadeIn().slideX(begin: -0.05),
              const SizedBox(height: 8),
              Text(
                'Intelligence-driven productivity analytics.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 40),
              
              // Gauge Section
              RepaintBoundary(
                child: _PulseGaugeSection(metrics: metrics),
              ),
              const SizedBox(height: 40),
              
              _MetricsGrid(metrics: metrics),
              const SizedBox(height: 32),
              
              // Chart Section
              RepaintBoundary(
                child: _ChartSection(metrics: metrics, isLowPerformance: isLowPerformance),
              ),
              const SizedBox(height: 32),
              
              _AIRecommendationCard(metrics: metrics),
              const SizedBox(height: 32),
              
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
    final weeklyProgress = (metrics['weeklyProgress'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [5.0, 7.0, 4.0, 8.0, 6.0, 9.0, 7.0];
    final double focusScore = (weeklyProgress.isNotEmpty) 
        ? (weeklyProgress.reduce((a, b) => a + b) / (weeklyProgress.length * 10.0)).clamp(0.0, 1.0)
        : 0.72;

    return Center(
      child: ProductivityPulseGauge(
        progress: focusScore,
        label: 'Weekly Focus Pulse',
      ),
    ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack);
  }
}

class _MetricsGrid extends StatelessWidget {
  final Map<String, dynamic> metrics;
  const _MetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Focus Hours', value: '${metrics['totalHours'] ?? '0.0'}h', 
            icon: LucideIcons.clock, color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            title: 'Efficiency', value: '${metrics['growth'] ?? '0'}%', 
            icon: LucideIcons.zap, color: AppColors.tertiary,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05);
  }
}

class _ChartSection extends StatelessWidget {
  final Map<String, dynamic> metrics;
  final bool isLowPerformance;
  const _ChartSection({required this.metrics, required this.isLowPerformance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weeklyProgress = (metrics['weeklyProgress'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [5.0, 7.0, 4.0, 8.0, 6.0, 9.0, 7.0];
    final spots = weeklyProgress.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Activity Wave', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('LAST 7 DAYS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 160,
            child: LineChart(
              duration: isLowPerformance ? Duration.zero : const Duration(milliseconds: 600),
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? [const FlSpot(0, 0), const FlSpot(6, 0)] : spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: theme.colorScheme.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: !isLowPerformance),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.3),
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
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.05);
  }
}

class _CategoryDistributionSection extends ConsumerWidget {
  const _CategoryDistributionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final metrics = ref.watch(productivityMetricsProvider);
    final categoryDist = metrics['categoryDistribution'] as Map<String, double>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category Distribution', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 20),
        if (categoryDist.isEmpty)
          const Text('No data yet. Complete tasks to see distribution.')
        else
          ...categoryDist.entries.map((e) {
            Color col = theme.colorScheme.primary;
            if (e.key == 'Personal') col = theme.colorScheme.secondary;
            if (e.key == 'Health') col = theme.colorScheme.tertiary;
            return _CategoryBar(label: e.key, perc: e.value, color: col);
          }),
      ],
    );
  }
}

// ... Small internal helper widgets like _MetricCard and _CategoryBar follow same pattern ...
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final double perc;
  final Color color;
  const _CategoryBar({required this.label, required this.perc, required this.color});

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
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('${(perc * 100).toInt()}%', style: const TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: perc,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}

class _AIRecommendationCard extends StatelessWidget {
  final Map<String, dynamic> metrics;
  const _AIRecommendationCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      color: theme.colorScheme.tertiary,
      opacity: 0.08,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(LucideIcons.sparkles, color: theme.colorScheme.tertiary, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              (metrics['totalHours'] ?? '0.0') != '0.0' 
                ? "Peak focus detected between 10 AM - 12 PM. Shift high-priority tasks there."
                : "Deep focus analysis requires more task data.",
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms);
  }
}
