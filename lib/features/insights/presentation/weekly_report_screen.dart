import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/task_provider.dart';
import '../../habits/presentation/habit_provider.dart';
import '../../chat/presentation/chat_provider.dart';
import '../../chat/presentation/feedback_provider.dart';
import '../../../core/providers/shared_prefs_provider.dart';
import '../../../core/constants/secrets.dart';
import '../data/weekly_report_service.dart';

class WeeklyReportScreen extends ConsumerStatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  ConsumerState<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends ConsumerState<WeeklyReportScreen> {
  WeeklyReport? _report;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _generateReport());
  }

  Future<void> _generateReport() async {
    try {
      final tasks = ref.read(metricsTasksProvider).value ?? [];
      final habits = ref.read(habitsProvider);

      final prefs = ref.read(sharedPreferencesProvider);
      
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // Filter tasks completed in last 7 days
      final completedTasks = tasks.where((t) => 
        t.status == TaskStatus.completed && 
        t.date.isAfter(sevenDaysAgo)
      ).toList();

      // Habits completed in last 7 days
      int habitsDoneCount = 0;
      for (final h in habits) {
        habitsDoneCount += h.completedDates.where((d) => d.isAfter(sevenDaysAgo)).length;
      }

      // AI Messages in last 7 days


      // Focus minutes (Pomodoro sessions x 25)
      final sessionCount = prefs.getInt('weekly_pomodoro_count') ?? 0;
      final focusMinutes = sessionCount * 25;

      // Extract top categories
      final categoryCounts = <String, int>{};
      for (final t in completedTasks) {
        categoryCounts[t.category] = (categoryCounts[t.category] ?? 0) + 1;
      }
      final topCategories = categoryCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final report = await WeeklyReportService.generate(
        tasksCompleted: completedTasks.length,
        habitsCompleted: habitsDoneCount,
        focusMinutes: focusMinutes,
        totalTasks: tasks.where((t) => t.date.isAfter(sevenDaysAgo)).length,
        totalHabits: habits.length * 7, // Max theoretical completions
        topCategories: topCategories.take(3).map((e) => e.key).toList(),
        geminiApiKey: Secrets.geminiApiKey,
      );

      if (mounted) {
        setState(() {
          _report = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Insight'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _generateReport();
            },
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Analysis failed: $_error'),
            TextButton(
              onPressed: _generateReport,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_report == null) return const SizedBox();

    final report = _report!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 32),
          _buildScoreHero(theme, report.score),
          const SizedBox(height: 32),
          _buildMetricGrid(theme),
          const SizedBox(height: 40),
          _buildSection(theme, 'What went well', LucideIcons.checkCircle, report.whatWentWell, Colors.green),
          const SizedBox(height: 32),
          _buildSection(theme, 'Areas to improve', LucideIcons.target, report.areasToImprove, Colors.orange),
          const SizedBox(height: 32),
          _buildActionPlan(theme, report.nextWeekTasks),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        const Icon(LucideIcons.sparkles, color: Colors.amber),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly AI Report', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text('Analysis of your past 7 days', style: theme.textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreHero(ThemeData theme, int score) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('Productivity Score', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('$score', style: theme.textTheme.displayLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          )),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(ThemeData theme) {
    final tasks = ref.watch(metricsTasksProvider).value ?? [];
    final habits = ref.watch(habitsProvider);
    final messages = ref.watch(messagesStreamProvider).value ?? [];
    final prefs = ref.watch(sharedPreferencesProvider);
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    final completedTasks = tasks.where((t) => t.status == TaskStatus.completed && t.date.isAfter(sevenDaysAgo)).length;
    int habitsDone = 0;
    for (final h in habits) {
      habitsDone += h.completedDates.where((d) => d.isAfter(sevenDaysAgo)).length;
    }
    final focusMins = (prefs.getInt('weekly_pomodoro_count') ?? 0) * 25;
    final aiIntns = messages.where((m) => m.timestamp.isAfter(sevenDaysAgo)).length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(theme, LucideIcons.checkSquare, 'Tasks', '$completedTasks'),
        _buildMetricCard(theme, LucideIcons.repeat, 'Habits', '$habitsDone'),
        _buildMetricCard(theme, LucideIcons.timer, 'Focus', '${focusMins ~/ 60}h'),
        _buildMetricCard(theme, LucideIcons.messageSquare, 'AI Chat', '$aiIntns'),
      ],
    );
  }

  Widget _buildMetricCard(ThemeData theme, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(label, style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, IconData icon, List<String> points, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        ...points.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•', style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(child: Text(p, style: theme.textTheme.bodyMedium)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildActionPlan(ThemeData theme, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.list, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text('Next week\'s action plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 16),
        ...tasks.map((t) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.plus, size: 16),
              const SizedBox(width: 12),
              Expanded(child: Text(t.title)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(t.category, style: TextStyle(fontSize: 10, color: theme.colorScheme.primary)),
              ),
            ],
          ),
        )),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: () {
              for (final t in tasks) {
                ref.read(tasksProvider.notifier).addTask(t);
              }
              Navigator.pop(context);
              ref.read(feedbackProvider.notifier).showMessage('Added tasks to your plan! 🎯');
            },
            icon: const Icon(LucideIcons.calendarPlus),
            label: const Text('Add these tasks to my plan'),
          ),
        ),
      ],
    );
  }
}
