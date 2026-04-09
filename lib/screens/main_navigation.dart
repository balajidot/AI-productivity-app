import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
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
    final selectedIndex = ref.watch(navigationProvider);

    // Deep Bug Check: Add global error listeners
    ref.listen(tasksStreamProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync Error (Tasks): ${next.error}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
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
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(navigationProvider.notifier).set(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.home),
            selectedIcon: Icon(LucideIcons.home, color: AppColors.primary),
            label: 'Focus',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.checkSquare),
            selectedIcon: Icon(LucideIcons.checkSquare, color: AppColors.primary),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.calendar),
            selectedIcon: Icon(LucideIcons.calendar, color: AppColors.primary),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.messageSquare),
            selectedIcon: Icon(LucideIcons.messageSquare, color: AppColors.primary),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.barChart2),
            selectedIcon: Icon(LucideIcons.barChart2, color: AppColors.primary),
            label: 'Insights',
          ),
        ],
      ),
      floatingActionButton: selectedIndex == 3 // Hide on AI Chat tab
          ? null
          : FloatingActionButton(
              onPressed: _showAddTaskModal,
              backgroundColor: AppColors.primary,
              child: const Icon(LucideIcons.plus, color: AppColors.background),
            ),
    );
  }
}
