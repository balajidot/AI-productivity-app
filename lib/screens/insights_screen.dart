import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insights',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Data-driven optimization of your workflow.',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              
              _buildMetricCard(context, 'Deep Work Hours', '32h', '+12%', LucideIcons.clock),
              const SizedBox(height: 24),
              
              _buildChartSection(context),
              const SizedBox(height: 32),
              
              _buildAIRecommendation(context),
              const SizedBox(height: 32),
              
              _buildSectionHeader(context, 'Category Split'),
              const SizedBox(height: 16),
              _buildCategoryBar(context, 'Development', 0.6, AppColors.primary),
              _buildCategoryBar(context, 'Planning', 0.25, AppColors.secondary),
              _buildCategoryBar(context, 'Meetings', 0.15, AppColors.tertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String val, String change, IconData icon) {
    return GlassContainer(
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              change,
              style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Focus Over Time'),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 3),
                    FlSpot(2.6, 2),
                    FlSpot(4.9, 5),
                    FlSpot(6.8, 3.1),
                    FlSpot(8, 4),
                    FlSpot(9.5, 3),
                    FlSpot(11, 4),
                  ],
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIRecommendation(BuildContext context) {
    return GlassContainer(
      color: AppColors.tertiary,
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: AppColors.tertiary, size: 20),
              const SizedBox(width: 8),
              Text(
                'NVIDIA AI ADVICE',
                style: TextStyle(
                  color: AppColors.tertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Switching to 90-minute Pomodoro cycles has increased your sustained focus by 23%. Stay in this rhythm.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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

  Widget _buildCategoryBar(BuildContext context, String label, double perc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              Text('${(perc * 100).toInt()}%', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: perc,
              backgroundColor: AppColors.surfaceLow,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
