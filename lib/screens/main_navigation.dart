import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../screens/home_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/ai_assistant_screen.dart';
import '../screens/insights_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TasksScreen(),
    const CalendarScreen(),
    const AIAssistantScreen(),
    const InsightsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
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
    );
  }
}
