import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../config/animation_config.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';
import '../providers/app_providers.dart';
import '../providers/ai_suggestions_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/section_header.dart';
import 'settings_screen.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _HeaderSection(),
              const SizedBox(height: 8),
              const _FocusMessageSection(),
              const SizedBox(height: 32),
              const _StatsSection(),
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
          padding: EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(child: _QuickActionsSection()),
        ),
      ],
    );
  }
}

class _HeaderSection extends ConsumerWidget {
  const _HeaderSection();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Good night';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(userNameProvider);
    final photo = ref.watch(userPhotoProvider);
    final isLowPerformance = ref.watch(performanceModeProvider);

    return RepaintBoundary(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _maybeAnimate(
                  isLowPerformance,
                  Text(
                    '${_getGreeting()}, $name.',
                    style: theme.textTheme.displayLarge,
                  ),
                  slide: AnimationConfig.subtleSlideX,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _maybeAnimate(
            isLowPerformance,
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                ref.read(chatProvider.notifier).sendMessage("Analyze my current day and suggest optimizations.");
                ref.read(navigationProvider.notifier).set(3);
              },
              child: GlassContainer(
                padding: const EdgeInsets.all(10),
                borderRadius: 14,
                color: theme.colorScheme.tertiary,
                opacity: 0.15,
                child: Icon(LucideIcons.sparkles, color: theme.colorScheme.tertiary, size: 22),
              ),
            ),
            delay: AnimationConfig.staggerDelay,
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

class _FocusMessageSection extends ConsumerWidget {
  const _FocusMessageSection();

  String _getFocusMessage() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 10) return 'Morning focus window active. Best for deep work.';
    if (hour >= 10 && hour < 12) return 'Peak productivity hours. Stay in the flow.';
    if (hour >= 12 && hour < 14) return 'Midday break zone. Time for lighter tasks.';
    if (hour >= 14 && hour < 17) return 'Afternoon focus block. Great for collabs.';
    if (hour >= 17 && hour < 21) return 'Evening wind-down. Review and plan.';
    return 'Rest is productive too. Recharge now.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLowPerformance = ref.watch(performanceModeProvider);
    
    return _maybeAnimate(
      isLowPerformance,
      Text(
        _getFocusMessage(),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      delay: AnimationConfig.staggerDelay * 2,
    );
  }
}

class _StatsSection extends ConsumerWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(taskStatsProvider);
    final isLowPerformance = ref.watch(performanceModeProvider);

    return _maybeAnimate(
      isLowPerformance,
      RepaintBoundary(
        child: SizedBox(
          height: 130,
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Today',
                  value: '${stats['todayCompleted']}/${stats['todayTotal']}',
                  icon: LucideIcons.checkCircle,
                  color: AppColors.primary,
                  onTap: () => ref.read(navigationProvider.notifier).set(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Overdue',
                  value: '${stats['overdue']}',
                  icon: LucideIcons.alertCircle,
                  color: (stats['overdue'] ?? 0) > 0 ? AppColors.error : AppColors.primary,
                  onTap: () => ref.read(navigationProvider.notifier).set(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Trophy',
                  value: '${stats['completed']}',
                  icon: LucideIcons.trophy,
                  color: AppColors.tertiary,
                  onTap: () => ref.read(navigationProvider.notifier).set(1),
                ),
              ),
            ],
          ),
        ),
      ),
      delay: AnimationConfig.staggerDelay * 3,
      slide: AnimationConfig.subtleSlide,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
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
    );
  }
}

class _AISuggestionsSection extends ConsumerWidget {
  const _AISuggestionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLowPerformance = ref.watch(performanceModeProvider);
    final suggestions = ref.watch(aiSuggestionsProvider);

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return _maybeAnimate(
      isLowPerformance,
      RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.sparkles, size: 16, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'Obsidian Insights',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.tertiary,
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
                    child: GlassContainer(
                      color: theme.colorScheme.surfaceContainer,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(suggestion.icon as IconData? ?? LucideIcons.zap, color: theme.colorScheme.primary, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  suggestion.title,
                                  maxLines: 1,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  suggestion.description,
                                  maxLines: 2,
                                  style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      delay: AnimationConfig.staggerDelay * 4,
    );
  }
}

class _OverdueSection extends ConsumerWidget {
  const _OverdueSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overdueTasks = ref.watch(overdueTasksProvider);
    if (overdueTasks.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Overdue', 
              color: AppColors.error, 
              count: overdueTasks.length
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => TaskCard(task: overdueTasks[index], isOverdue: true),
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

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: "Today's Flow", 
              color: AppColors.primary, 
              count: todayTasks.length
            ),
          ),
        ),
        if (todayTasks.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: GlassContainer(
                child: Row(
                  children: [
                    Icon(LucideIcons.sunrise, color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No tasks for today. Tap Add Task to begin!',
                        style: GoogleFonts.inter(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => TaskCard(task: todayTasks[index]),
                childCount: todayTasks.length,
              ),
            ),
          ),
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
    final isLowPerformance = ref.watch(performanceModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        _maybeAnimate(
          isLowPerformance,
          Row(
            children: [
              Expanded(
                child: _QuickActionBtn(
                  icon: LucideIcons.plus,
                  label: 'Add Task',
                  color: AppColors.primary,
                  onTap: () => ref.read(navigationProvider.notifier).set(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionBtn(
                  icon: LucideIcons.messageSquare,
                  label: 'Ask AI',
                  color: AppColors.tertiary,
                  onTap: () => ref.read(navigationProvider.notifier).set(3),
                ),
              ),
            ],
          ),
          delay: AnimationConfig.staggerDelay * 5,
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: color, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// Utility for smooth performance
Widget _maybeAnimate(bool isLowPerformance, Widget child, {Duration? duration, Duration? delay, Offset? slide}) {
  if (isLowPerformance) return child;
  return child
      .animate(delay: delay)
      .fadeIn(
        duration: duration ?? AnimationConfig.standardDuration,
        curve: AnimationConfig.professionalCurve,
      )
      .slide(
        begin: slide ?? AnimationConfig.subtleSlide,
        duration: duration ?? AnimationConfig.standardDuration,
        curve: AnimationConfig.professionalCurve,
      );
}
