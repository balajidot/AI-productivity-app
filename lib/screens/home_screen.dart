import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';
import '../providers/app_providers.dart';
import '../models/app_models.dart';

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
    final userNameAsync = ref.watch(userNameProvider);
    final stats = ref.watch(taskStatsProvider);
    final todayTasks = ref.watch(todayTasksProvider);
    final overdueTasks = ref.watch(overdueTasksProvider);

    final userName = userNameAsync.when(
      data: (name) => name,
      loading: () => '...',
      error: (e, _) => 'User',
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                '${_getGreeting()}, $userName.',
                style: Theme.of(context).textTheme.displayLarge,
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
              const SizedBox(height: 8),
              Text(
                _getFocusMessage(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
              const SizedBox(height: 32),

              // Stats Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Today',
                      '${stats['todayCompleted']}/${stats['todayTotal']}',
                      LucideIcons.checkCircle,
                      AppColors.primary,
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
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 32),

              // AI Insight Card
              GlassContainer(
                color: AppColors.tertiary,
                opacity: 0.1,
                child: Row(
                  children: [
                    const Icon(LucideIcons.zap, color: AppColors.tertiary, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        stats['todayPending']! > 0
                            ? '${stats['todayPending']} tasks remaining today. ${stats['todayCompleted']! > 0 ? "Great progress! " : ""}Focus on high-priority items first.'
                            : stats['todayTotal']! > 0
                                ? '🎉 All tasks done for today! You\'re crushing it.'
                                : 'No tasks planned for today. Add some tasks to stay productive!',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 32),

              // Overdue Section
              if (overdueTasks.isNotEmpty) ...[
                _buildSectionHeader(context, 'Overdue', badgeCount: overdueTasks.length),
                const SizedBox(height: 12),
                ...overdueTasks.map((task) => _buildTaskItem(context, ref, task, isOverdue: true)),
                const SizedBox(height: 24),
              ],

              // Today's Tasks
              _buildSectionHeader(context, "Today's Flow"),
              const SizedBox(height: 12),
              if (todayTasks.isEmpty)
                GlassContainer(
                  child: Row(
                    children: [
                      Icon(LucideIcons.sunrise, color: AppColors.onSurfaceVariant.withValues(alpha: 0.5), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'No tasks for today. Tap + to add one!',
                        style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...todayTasks.map((task) => _buildTaskItem(context, ref, task)),

              const SizedBox(height: 32),

              // Quick Actions
              _buildSectionHeader(context, 'Quick Actions'),
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
                        // Navigate to tasks tab
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
                        // Navigate to AI tab
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

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {int? badgeCount}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        ),
        Icon(LucideIcons.chevronRight, color: AppColors.onSurfaceVariant, size: 20),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, WidgetRef ref, Task task, {bool isOverdue = false}) {
    final isCompleted = task.status == TaskStatus.completed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () => ref.read(tasksProvider.notifier).toggleTask(task.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.primary
                        : isOverdue
                            ? AppColors.error
                            : AppColors.outline,
                    width: 2,
                  ),
                  color: isCompleted ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: AppColors.primary)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted
                          ? AppColors.onSurfaceVariant
                          : isOverdue
                              ? AppColors.error
                              : AppColors.onSurface,
                    ),
                  ),
                  if (task.time != null)
                    Text(
                      task.time!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            _buildPriorityDot(task.priority),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityDot(TaskPriority priority) {
    Color color;
    switch (priority) {
      case TaskPriority.high:
        color = AppColors.error;
        break;
      case TaskPriority.medium:
        color = AppColors.secondary;
        break;
      case TaskPriority.low:
        color = AppColors.primary;
        break;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
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
