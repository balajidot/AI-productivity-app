import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../tasks/presentation/task_provider.dart';
import '../../chat/presentation/chat_provider.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../chat/presentation/ai_suggestions_provider.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/widgets/task_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../focus/presentation/widgets/focus_hub_widget.dart';
import '../../focus/presentation/pomodoro_provider.dart';
import '../../chat/presentation/widgets/nl_input_bar.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../tasks/presentation/widgets/quick_add_task_sheet.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Top-level layout with zero-rebuild triggers where possible
    return const Scaffold(
      body: SafeArea(
        child: _HomeBody(),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _HeaderSection(),
              const SizedBox(height: 16),
              const NaturalLanguageInputBar(),
              const SizedBox(height: 24),
              const _PomodoroSection(),
              const SizedBox(height: 32),
              const _AISuggestionsSection(),
              const SizedBox(height: 32),
            ]),
          ),
        ),
        
        // Dynamic Task Sections
        const _OverdueSection(),
        const _TodaySection(),
        
        // Final Actions
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          sliver: SliverToBoxAdapter(child: _QuickActionsSection()),
        ),
      ],
    );
  }
}

class _HeaderSection extends ConsumerWidget {
  const _HeaderSection();

  ({String text, String descriptor, IconData icon}) _getGreetingData() {
    final hour = DateTime.now().hour;
    if (hour < 6) return (text: 'Good night', descriptor: 'Rest & Recharge', icon: LucideIcons.moon);
    if (hour < 12) return (text: 'Good morning', descriptor: 'Morning Flow', icon: LucideIcons.sun);
    if (hour < 17) return (text: 'Good afternoon', descriptor: 'Deep Focus', icon: LucideIcons.sunMedium);
    if (hour < 21) return (text: 'Good evening', descriptor: 'Evening Review', icon: LucideIcons.sunset);
    return (text: 'Good night', descriptor: 'Night Ritual', icon: LucideIcons.moon);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(userNameProvider);
    final photo = ref.watch(userPhotoProvider);
    final greeting = _getGreetingData();

    return RepaintBoundary(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(greeting.icon, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      greeting.descriptor.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${greeting.text}, $name 👋',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(chatProvider.notifier).sendMessage("Analyze my current day and suggest optimizations.").ignore();
              ref.read(navigationProvider.notifier).set(3);
            },
            icon: Icon(LucideIcons.sparkles, color: theme.colorScheme.primary),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(width: 12),
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
                ),
                child: ClipOval(
                  child: photo != null 
                    ? Image.network(
                        photo, 
                        fit: BoxFit.cover,
                        cacheWidth: 150, // MEMORY OPTIMIZATION: Don't load high-res
                        cacheHeight: 150,
                        errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.user, color: AppColors.primary),
                      )
                    : const Icon(LucideIcons.user, color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PomodoroSection extends ConsumerWidget {
  const _PomodoroSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoro = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final theme = Theme.of(context);

    final totalSeconds = pomodoro.phase == PomodoroPhase.work
        ? ref.read(appSettingsProvider).pomodoroDuration * 60
        : pomodoro.phase == PomodoroPhase.shortBreak
            ? ref.read(appSettingsProvider).shortBreakDuration * 60
            : ref.read(appSettingsProvider).longBreakDuration * 60;
    final progress = totalSeconds > 0
        ? 1.0 - pomodoro.secondsRemaining / totalSeconds
        : 0.0;

    final phaseLabel = switch (pomodoro.phase) {
      PomodoroPhase.work => 'Focus',
      PomodoroPhase.shortBreak => 'Short Break',
      PomodoroPhase.longBreak => 'Long Break',
    };

    final sessionDots = List.generate(4, (i) {
      final filled = i < (pomodoro.sessionCount % 4);
      return Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? theme.colorScheme.primary : Colors.transparent,
          border: filled 
            ? null 
            : Border.all(color: theme.colorScheme.outline, width: 1.5),
        ),
      );
    });

    return Column(
      children: [
        FocusHubWidget(
          progress: progress,
          label: pomodoro.timeDisplay,
          subLabel: phaseLabel,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: sessionDots,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Reset
            IconButton(
              onPressed: notifier.reset,
              icon: const Icon(LucideIcons.rotateCcw),
              tooltip: 'Reset',
            ),
            const SizedBox(width: 12),
            // Start / Pause
            FilledButton.icon(
              onPressed: pomodoro.isRunning ? notifier.pause : notifier.start,
              icon: Icon(
                pomodoro.isRunning ? LucideIcons.pause : LucideIcons.play,
              ),
              label: Text(pomodoro.isRunning ? 'Pause' : 'Start'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


class _AISuggestionsSection extends ConsumerWidget {
  const _AISuggestionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final suggestions = ref.watch(aiSuggestionsProvider);

    if (suggestions.isEmpty) return const SizedBox.shrink();
    
    return RepaintBoundary(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.sparkles, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'AI INSIGHTS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            suggestion.icon as IconData? ?? LucideIcons.zap,
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                suggestion.title,
                                maxLines: 1,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                suggestion.description,
                                maxLines: 2,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }
}

class _OverdueSection extends ConsumerWidget {
  const _OverdueSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overdueTasks = ref.watch(overdueTasksProvider);
    if (overdueTasks.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: 'OVERDUE', 
              color: theme.colorScheme.error, 
              count: overdueTasks.length
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final task = overdueTasks[index];
                return TaskCard(
                  task: task,
                  isOverdue: true,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => QuickAddTaskSheet(editTask: task),
                  ),
                );
              },
              childCount: overdueTasks.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _TodaySection extends ConsumerWidget {
  const _TodaySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final todayTasks = ref.watch(todayTasksProvider);
    final pendingTasks = todayTasks.where((t) => t.status != TaskStatus.completed).toList();
    final completedTasks = todayTasks.where((t) => t.status == TaskStatus.completed).toList();

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: "TODAY'S FLOW", 
              color: theme.colorScheme.primary, 
              count: pendingTasks.length // Only show pending count
            ),
          ),
        ),
        if (todayTasks.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: _EmptyTodayState(),
            ),
          )
        else ...[
          // Pending Tasks
          if (pendingTasks.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = pendingTasks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: TaskCard(
                        task: task,
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => QuickAddTaskSheet(editTask: task),
                        ),
                      ),
                    );
                  },
                  childCount: pendingTasks.length,
                ),
              ),
            ),
            
          // Completed Tasks Separator
          if (completedTasks.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(36, 16, 24, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Icon(LucideIcons.checkCircle2, 
                      size: 14, 
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'COMPLETED',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Completed Tasks
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = completedTasks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Opacity(
                        opacity: 0.7,
                        child: TaskCard(
                          task: task,
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => QuickAddTaskSheet(editTask: task),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: completedTasks.length,
                ),
              ),
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _QuickActionsSection extends ConsumerWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS', 
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurfaceVariant,
          )
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionBtn(
                icon: LucideIcons.plus,
                label: 'Add Task',
                color: theme.colorScheme.primary,
                onTap: () => ref.read(navigationProvider.notifier).set(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionBtn(
                icon: LucideIcons.messageSquare,
                label: 'Ask AI',
                color: theme.colorScheme.secondary,
                onTap: () => ref.read(navigationProvider.notifier).set(3),
              ),
            ),
          ],
        ),

      ],
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            )),
          ],
        ),
      ),
    );
  }
}

// Premium Empty State Widget
class _EmptyTodayState extends StatelessWidget {
  const _EmptyTodayState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.sunrise,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your flow is clear',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoy your peace of mind or add a new goal to start your productivity journey today.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );

  }
}

