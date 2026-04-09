import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';
import '../providers/app_providers.dart';
import '../providers/ai_suggestions_provider.dart';
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
    final isLowPerformance = ref.watch(performanceModeProvider);

    // Watch providers in smaller scopes if possible, but for simplicity here we watch them at top
    final userName = ref.watch(userNameProvider);
    final userPhoto = ref.watch(userPhotoProvider);
    final stats = ref.watch(taskStatsProvider);
    final todayTasks = ref.watch(todayTasksProvider);
    final overdueTasks = ref.watch(overdueTasksProvider);

    return Scaffold(
      body: SafeArea(
        child: RepaintBoundary(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Header with Profile
                    RepaintBoundary(
                      child: _buildHeader(context, theme, userName, userPhoto, isLowPerformance, ref),
                    ),
                    const SizedBox(height: 8),
                    
                    _maybeAnimate(
                      isLowPerformance,
                      Text(
                        _getFocusMessage(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      delay: 200.ms,
                    ),
                    
                    const SizedBox(height: 32),
          
                    // Stats Cards Row
                    _maybeAnimate(
                      isLowPerformance,
                      RepaintBoundary(
                        child: SizedBox(
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
                        ),
                      ),
                      delay: 300.ms,
                      slide: const Offset(0, 0.1),
                    ),
          
                    const SizedBox(height: 32),
          
                    // Smart AI Suggestions
                    _maybeAnimate(
                      isLowPerformance,
                      RepaintBoundary(
                        child: _buildAISuggestionsCarousel(context, theme, ref),
                      ),
                      delay: 400.ms,
                    ),
          
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
              
              // Overdue Section
              if (overdueTasks.isNotEmpty) ...[
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
          
              // Today's Tasks
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
                              'No tasks for today. Tap + to add one!',
                              style: GoogleFonts.inter(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
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
          
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    _maybeAnimate(
                      isLowPerformance,
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
                      ),
                      delay: 600.ms,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _maybeAnimate(bool isLowPerformance, Widget child, {Duration? duration, Duration? delay, Offset? slide}) {
    if (isLowPerformance) return child;
    var anim = child.animate().fadeIn(duration: duration ?? 600.ms, delay: delay);
    if (slide != null) {
      anim = anim.slide(begin: slide, duration: duration ?? 600.ms);
    }
    return anim;
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, String name, String? photo, bool isLowPerformance, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _maybeAnimate(
                isLowPerformance,
                Text(
                  '${_getGreeting()}, $name.', // Correctly using the method
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                duration: 600.ms,
                slide: const Offset(-0.1, 0),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Magic Wand
        _maybeAnimate(
          isLowPerformance,
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              ref.read(chatProvider.notifier).sendMessage("Analyze my current day and suggest optimizations.");
              ref.read(navigationProvider.notifier).set(3); // Switch to AI tab
            },
            child: GlassContainer(
              padding: const EdgeInsets.all(10),
              borderRadius: 14,
              color: theme.colorScheme.tertiary,
              opacity: 0.15,
              child: Icon(LucideIcons.sparkles, color: theme.colorScheme.tertiary, size: 22),
            ),
          ),
          delay: 100.ms,
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
            child: _maybeAnimate(
              isLowPerformance,
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 2),
                  image: photo != null 
                    ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover)
                    : null,
                ),
                child: photo == null 
                  ? const Icon(LucideIcons.user, color: AppColors.primary)
                  : null,
              ),
              delay: 200.ms,
            ),
          ),
        ),
      ],
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
    );
  }

  Widget _buildAISuggestionsCarousel(BuildContext context, ThemeData theme, WidgetRef ref) {
    final suggestions = ref.watch(aiSuggestionsProvider);
    if (suggestions.isEmpty) {
      // Return a basic fallback or the old insight card style if empty
      return _buildAIInsightCard(theme, ref.read(taskStatsProvider), ref);
    }

    return Column(
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
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              suggestion.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      if (suggestion.action != null)
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            // Logic to bypass approval if it's a "Safe" suggestion or just ask
                            ref.read(chatProvider.notifier).sendMessage("I want to: ${suggestion.title}");
                            ref.read(navigationProvider.notifier).set(3);
                          },
                          icon: Icon(LucideIcons.arrowRight, size: 18, color: theme.colorScheme.primary),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAIInsightCard(ThemeData theme, Map<String, int> stats, WidgetRef ref) {
    // ... existed code ...
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
