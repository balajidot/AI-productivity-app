import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animations/animations.dart';
import '../screens/home_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/ai_assistant_screen.dart';
import '../screens/insights_screen.dart';
import '../providers/app_providers.dart';
import '../widgets/quick_add_task_sheet.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const TasksScreen(),
    const CalendarScreen(),
    const AIAssistantScreen(),
    const InsightsScreen(),
  ];

  void _showAddTaskModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const QuickAddTaskSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = ref.watch(navigationProvider);

    // Deep Bug Check: Add global error listeners
    ref.listen(tasksStreamProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync Error (Tasks): ${next.error}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    ref.listen(habitsStreamProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync Error (Habits): ${next.error}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            fillColor: Colors.transparent,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(selectedIndex),
          child: _screens[selectedIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(navigationProvider.notifier).set(index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(LucideIcons.home),
            selectedIcon: Icon(LucideIcons.home, color: theme.colorScheme.primary),
            label: 'Focus',
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.checkSquare),
            selectedIcon: Icon(LucideIcons.checkSquare, color: theme.colorScheme.primary),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.calendar),
            selectedIcon: Icon(LucideIcons.calendar, color: theme.colorScheme.primary),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.messageSquare),
            selectedIcon: Icon(LucideIcons.messageSquare, color: theme.colorScheme.primary),
            label: 'AI',
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.barChart2),
            selectedIcon: Icon(LucideIcons.barChart2, color: theme.colorScheme.primary),
            label: 'Insights',
          ),
        ],
      ),
      floatingActionButton: selectedIndex == 3 // Hide on AI Chat tab
          ? null
          : FloatingActionButton(
              onPressed: _showAddTaskModal,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(LucideIcons.plus, color: theme.colorScheme.onPrimary),
            ),
    );
  }
}
