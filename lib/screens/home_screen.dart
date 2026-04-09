import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';
import '../providers/app_providers.dart';
import '../widgets/task_card.dart';
import '../widgets/section_header.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Good night';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  String _getFocusMessage() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 10) {
      return 'Your morning focus window is active. Best time for deep work.';
    } else if (hour >= 10 && hour < 12) {
      return 'Peak productivity hours. Stay in the flow state.';
    } else if (hour >= 12 && hour < 14) {
      return 'Midday break zone. Good time for lighter tasks.';
    } else if (hour >= 14 && hour < 17) {
      return 'Afternoon focus block. Great for collaborative work.';
    } else if (hour >= 17 && hour < 21) {
      return 'Evening wind-down. Review and plan for tomorrow.';
    } else {
      return 'Rest is productive too. Plan your next day.';
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userName = ref.watch(userNameProvider);
    final userPhoto = ref.watch(userPhotoProvider);
    final stats = ref.watch(taskStatsProvider);
    final todayTasks = ref.watch(todayTasksProvider);
    final overdueTasks = ref.watch(overdueTasksProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Profile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'app_logo',
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${_getGreeting()}, $userName.',
                          style: Theme.of(context).textTheme.displayLarge,
                        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                    child: Hero(
                      tag: 'user_avatar',
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 2),
                          image: userPhoto != null 
                            ? DecorationImage(image: NetworkImage(userPhoto), fit: BoxFit.cover)
                            : null,
                        ),
                        child: userPhoto == null 
                          ? const Icon(LucideIcons.user, color: AppColors.primary)
                          : null,
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).scale(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getFocusMessage(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
              const SizedBox(height: 32),

              // Stats Cards Row
              SizedBox(
                height: 130,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Today',
                        '${stats['todayCompleted']}/${stats['todayTotal']}',
                        LucideIcons.checkCircle,
                        AppColors.primary,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(navigationProvider.notifier).set(1);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Overdue',
                        '${stats['overdue']}',
                        LucideIcons.alertCircle,
                        stats['overdue']! > 0 ? AppColors.error : AppColors.primary,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          ref.read(navigationProvider.notifier).set(1);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total Done',
                        '${stats['completed']}',
                        LucideIcons.trophy,
                        AppColors.tertiary,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(navigationProvider.notifier).set(1);
                        },
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 32),

              // AI Insight Card
              _buildAIInsightCard(theme, stats, ref),

              const SizedBox(height: 32),

              // Overdue Section
              if (overdueTasks.isNotEmpty) ...[
                SectionHeader(
                  title: 'Overdue', 
                  color: AppColors.error, 
                  count: overdueTasks.length
                ),
                ...overdueTasks.map((task) => TaskCard(task: task, isOverdue: true)),
                const SizedBox(height: 24),
              ],

              // Today's Tasks
              SectionHeader(
                title: "Today's Flow", 
                color: AppColors.primary, 
                count: todayTasks.length
              ),
              if (todayTasks.isEmpty)
                GlassContainer(
                  child: Row(
                    children: [
                      Icon(LucideIcons.sunrise, color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No tasks for today. Tap + to add one!',
                          style: GoogleFonts.inter(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: todayTasks.map((task) => TaskCard(task: task)).toList(),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),

              const SizedBox(height: 32),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      context,
                      LucideIcons.plus,
                      'Add Task',
                      AppColors.primary,
                      () {
                        HapticFeedback.lightImpact();
                        ref.read(navigationProvider.notifier).set(1);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAction(
                      context,
                      LucideIcons.messageSquare,
                      'Ask AI',
                      AppColors.tertiary,
                      () {
                        HapticFeedback.lightImpact();
                        ref.read(navigationProvider.notifier).set(3);
                      },
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.stop()).scale(
      begin: const Offset(1, 1),
      end: const Offset(0.96, 0.96),
      duration: 100.ms,
    );
  }
  Widget _buildAIInsightCard(ThemeData theme, Map<String, int> stats, WidgetRef ref) {
    final metrics = ref.watch(productivityMetricsProvider);
    final growth = double.tryParse(metrics['growth'] ?? '0.0') ?? 0.0;
    
    String insight = stats['todayPending']! > 0
        ? '${stats['todayPending']} tasks remaining. ${stats['todayCompleted']! > 0 ? "You're doing great! " : ""}Keep at it.'
        : stats['todayTotal']! > 0
            ? '🎉 Day complete! You hit your peak focus today.'
            : 'Plan your day to stay ahead.';
    
    if (growth > 0) insight = "🚀 You're $growth% more productive today! Keep this momentum.";

    return GlassContainer(
      color: theme.colorScheme.tertiary,
      opacity: 0.1,
      child: Row(
        children: [
          Icon(LucideIcons.zap, color: theme.colorScheme.tertiary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              insight,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
