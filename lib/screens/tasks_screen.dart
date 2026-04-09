import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';
import '../widgets/quick_add_task_sheet.dart';
import '../widgets/celebration_overlay.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _sortBy = 'date'; // 'date', 'priority', 'category'

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final overdueTasks = ref.watch(overdueTasksProvider);
    final todayTasks = ref.watch(todayTasksProvider);
    final tomorrowTasks = ref.watch(tomorrowTasksProvider);
    final upcomingTasks = ref.watch(upcomingTasksProvider);

    final allEmpty = overdueTasks.isEmpty &&
        todayTasks.isEmpty &&
        tomorrowTasks.isEmpty &&
        upcomingTasks.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildFilterTabs(context, selectedCategory),
            Expanded(
              child: allEmpty
                  ? _buildEmptyState(context)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Overdue
                          if (overdueTasks.isNotEmpty) ...[
                            _buildDateHeader('Overdue', AppColors.error, overdueTasks.length),
                            ...overdueTasks.asMap().entries.map((e) =>
                                _buildTaskCard(context, e.value, isOverdue: true)
                                    .animate()
                                    .fadeIn(delay: (e.key * 40).ms)
                                    .slideX(begin: -0.05)),
                            const SizedBox(height: 16),
                          ],
                          // Today
                          if (todayTasks.isNotEmpty) ...[
                            _buildDateHeader('Today', AppColors.primary, todayTasks.length),
                            ...todayTasks.asMap().entries.map((e) =>
                                _buildTaskCard(context, e.value)
                                    .animate()
                                    .fadeIn(delay: (e.key * 40).ms)
                                    .slideY(begin: 0.05)),
                            const SizedBox(height: 16),
                          ],
                          // Tomorrow
                          if (tomorrowTasks.isNotEmpty) ...[
                            _buildDateHeader('Tomorrow', AppColors.secondary, tomorrowTasks.length),
                            ...tomorrowTasks.asMap().entries.map((e) =>
                                _buildTaskCard(context, e.value)
                                    .animate()
                                    .fadeIn(delay: (e.key * 40).ms)
                                    .slideY(begin: 0.05)),
                            const SizedBox(height: 16),
                          ],
                          // Upcoming
                          if (upcomingTasks.isNotEmpty) ...[
                            _buildDateHeader('Upcoming', AppColors.onSurfaceVariant, upcomingTasks.length),
                            ...upcomingTasks.asMap().entries.map((e) =>
                                _buildTaskCard(context, e.value)
                                    .animate()
                                    .fadeIn(delay: (e.key * 40).ms)
                                    .slideY(begin: 0.05)),
                          ],
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskModal(context),
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: AppColors.background),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Tasks', style: Theme.of(context).textTheme.displayLarge),
          GestureDetector(
            onTap: () => _showSortOptions(context),
            child: const GlassContainer(
              padding: EdgeInsets.all(8),
              borderRadius: 8,
              child: Icon(LucideIcons.sliders, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort By', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            _buildSortOption('Date', 'date', LucideIcons.calendar),
            _buildSortOption('Priority', 'priority', LucideIcons.flag),
            _buildSortOption('Category', 'category', LucideIcons.tag),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant),
      title: Text(label, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.onSurface)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildFilterTabs(BuildContext context, String selectedCategory) {
    final categories = ['All', 'Personal', 'Work', 'Health', 'Inbox'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat;
          return Container(
            margin: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) {
                ref.read(selectedCategoryProvider.notifier).set(cat);
              },
              backgroundColor: AppColors.surfaceLow,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: isSelected
                  ? BorderSide(color: AppColors.primary.withValues(alpha: 0.3))
                  : BorderSide.none,
              showCheckmark: isSelected,
              checkmarkColor: AppColors.primary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateHeader(String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task, {bool isOverdue = false}) {
    final isCompleted = task.status == TaskStatus.completed;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      // Right to left = delete
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.checkCircle, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Complete', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.errorDim.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
            SizedBox(width: 8),
            Icon(LucideIcons.trash2, color: AppColors.error),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete
          return true;
        } else {
          // Complete
          final wasCompleted = await ref.read(tasksProvider.notifier).toggleTask(task.id);
          if (wasCompleted && context.mounted) {
            CelebrationOverlay.show(context);
          }
          return false;
        }
      },
      onDismissed: (_) => ref.read(tasksProvider.notifier).deleteTask(task.id),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => _showEditTaskSheet(context, task),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Animated checkbox
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final wasCompleted = await ref.read(tasksProvider.notifier).toggleTask(task.id);
                    if (wasCompleted && context.mounted) {
                      CelebrationOverlay.show(context);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.primary
                            : isOverdue
                                ? AppColors.error
                                : _priorityColor(task.priority),
                        width: 2,
                      ),
                      color: isCompleted
                          ? AppColors.primary.withValues(alpha: 0.25)
                          : Colors.transparent,
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check_rounded, size: 16, color: AppColors.primary)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                // Priority bar
                Container(
                  width: 3,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _priorityColor(task.priority),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                // Task info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted
                              ? AppColors.onSurfaceVariant
                              : isOverdue
                                  ? AppColors.error
                                  : AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            task.category,
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                          ),
                          if (task.recurrence != null) ...[
                            const SizedBox(width: 6),
                            Icon(LucideIcons.repeat, size: 11, color: AppColors.secondary),
                            const SizedBox(width: 3),
                            Text(
                              task.recurrence!,
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Time / Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (task.time != null)
                      Text(
                        _formatTime(task.time!),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    Text(
                      _formatDate(task.date),
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) return 'Today';
    if (taskDate == today.add(const Duration(days: 1))) return 'Tomorrow';
    if (taskDate == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.error;
      case TaskPriority.medium:
        return AppColors.secondary;
      case TaskPriority.low:
        return AppColors.primary;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.clipboardList, size: 64, color: AppColors.outline.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'All clear for now.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a new task',
            style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void _showAddTaskModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const QuickAddTaskSheet(),
    );
  }

  void _showEditTaskSheet(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => QuickAddTaskSheet(editTask: task),
    );
  }
}
