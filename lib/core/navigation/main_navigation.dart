import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/dashboard/presentation/home_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/tasks/presentation/calendar_screen.dart';
import '../../features/chat/presentation/ai_assistant_screen.dart';
import '../../features/habits/presentation/habits_screen.dart';
import '../../features/dashboard/presentation/insights_screen.dart';
import '../providers/providers.dart';
import '../services/notification_service.dart';
import '../../features/chat/presentation/feedback_provider.dart';
import '../../features/tasks/presentation/widgets/quick_add_task_sheet.dart';
import '../../features/dashboard/presentation/widgets/celebration_overlay.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  // Tab indices: 0=Home, 1=Tasks, 2=Schedule, 3=AI, 4=Habits, 5=Insights
  final List<Widget> _screens = [
    const HomeScreen(),
    const TasksScreen(),
    const CalendarScreen(),
    const AIAssistantScreen(),
    const HabitsScreen(),
    const InsightsScreen(),
  ];
  late final ProviderSubscription<FeedbackState> _feedbackSubscription;
  late final ProviderSubscription<CelebrationEvent?> _celebrationSubscription;

  @override
  void initState() {
    super.initState();
    // Wire notification tap to navigate to Tasks tab (index 1)
    NotificationService.onTapCallback = (_) {
      ref.read(navigationProvider.notifier).set(1);
    };

    _feedbackSubscription = ref.listenManual<FeedbackState>(feedbackProvider, (
      previous,
      next,
    ) {
      if (next.message != null &&
          next.timestamp != previous?.timestamp &&
          mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: next.isError
                ? theme.colorScheme.error
                : theme.colorScheme.secondary,
            duration: Duration(seconds: next.isError ? 5 : 3),
            action: next.isError && next.retryCallback != null
                ? SnackBarAction(
                    label: 'RETRY',
                    textColor: theme.colorScheme.onError,
                    onPressed: next.retryCallback!,
                  )
                : null,
          ),
        );
      }
    });

    _celebrationSubscription = ref.listenManual<CelebrationEvent?>(
      celebrationProvider,
      (previous, next) {
        if (next != null &&
            next.timestamp != previous?.timestamp &&
            mounted) {
          CelebrationOverlay.show(context);
        }
      },
    );
  }

  @override
  void dispose() {
    _feedbackSubscription.close();
    _celebrationSubscription.close();
    super.dispose();
  }

  void _showAddTaskModal() {
    final selectedIndex = ref.read(navigationProvider);
    DateTime? initDate;
    String? initCategory;

    if (selectedIndex == 0) {
      final currentCategory = ref.read(selectedCategoryProvider);
      if (currentCategory != 'All') initCategory = currentCategory;
    } else if (selectedIndex == 1) {
      final currentCategory = ref.read(selectedCategoryProvider);
      if (currentCategory != 'All') initCategory = currentCategory;
      final activeTab = ref.read(tasksActiveTabProvider);
      final now = DateTime.now();
      if (activeTab == 1) {
        initDate = now.add(const Duration(days: 1));
      } else if (activeTab == 2) {
        initDate = now.add(const Duration(days: 2));
      } else if (activeTab == 3 || activeTab == 0) {
        initDate = now;
      }
    } else if (selectedIndex == 2) {
      initDate = ref.read(calendarSelectedDateProvider);
      final currentCategory = ref.read(selectedCategoryProvider);
      if (currentCategory != 'All') initCategory = currentCategory;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => QuickAddTaskSheet(
        initialDate: initDate,
        initialCategory: initCategory,
      ),
    );
  }

  void _showAddHabitSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const AddHabitSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationProvider);
    final theme = Theme.of(context);
    final isAiTab = selectedIndex == 3;
    final isHabitsTab = selectedIndex == 4;

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildNavItem(context, theme, index: 0, label: 'Home', icon: LucideIcons.home, selectedIndex: selectedIndex),
                _buildNavItem(context, theme, index: 1, label: 'Tasks', icon: LucideIcons.checkSquare, selectedIndex: selectedIndex),
                _buildNavItem(context, theme, index: 2, label: 'Schedule', icon: LucideIcons.calendar, selectedIndex: selectedIndex),
                _buildNavItem(context, theme, index: 3, label: 'AI', icon: LucideIcons.messageSquare, selectedIndex: selectedIndex),
                _buildNavItem(context, theme, index: 4, label: 'Habits', icon: LucideIcons.repeat, selectedIndex: selectedIndex),
                _buildNavItem(context, theme, index: 5, label: 'Insights', icon: LucideIcons.barChart2, selectedIndex: selectedIndex),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: isAiTab
          ? null
          : FloatingActionButton(
              onPressed:
                  isHabitsTab ? _showAddHabitSheet : _showAddTaskModal,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(LucideIcons.plus,
                  color: theme.colorScheme.onPrimary),
            ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    ThemeData theme, {
    required int index,
    required String label,
    required IconData icon,
    required int selectedIndex,
  }) {
    final isSelected = index == selectedIndex;
    final color = isSelected 
        ? theme.colorScheme.primary 
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: () {
        ref.read(navigationProvider.notifier).set(index);
      },
      // Keep surface clean with no splash behaviors to maintain minimal look
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minWidth: 72),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              color: color, 
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
