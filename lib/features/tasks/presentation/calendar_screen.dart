import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'widgets/quick_add_task_sheet.dart';
import 'task_provider.dart';
import '../domain/task.dart';


class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(calendarSelectedDateProvider);
    final formatStr = ref.watch(calendarFormatProvider);
    final calendarFormat = formatStr == 'month' ? CalendarFormat.month : CalendarFormat.week;
    
    final tasksForDay = ref.watch(sortedTasksForDateProvider(
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
    ));
    final taskDateCounts = ref.watch(taskDateCountsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, theme, ref, calendarFormat),
            _buildCalendar(context, theme, ref, taskDateCounts, selectedDate, calendarFormat),
            _buildTimelineHeader(context, theme, tasksForDay, selectedDate),
            Expanded(
              child: tasksForDay.isEmpty
                  ? _buildEmptyDayState(context, theme, ref, selectedDate)
                  : _buildTimelineList(context, theme, ref, tasksForDay),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, WidgetRef ref, CalendarFormat format) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Schedule', 
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ), 
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTodayButton(theme, ref),
              const SizedBox(width: 8),
              _buildToggleViewButton(theme, ref, format),
              const SizedBox(width: 8),
              _buildAddEventButton(context, ref),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    Map<DateTime, int> taskDateCounts,
    DateTime selectedDay,
    CalendarFormat format,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: selectedDay,
        calendarFormat: format,
        availableCalendarFormats: const {
          CalendarFormat.month: 'Month',
          CalendarFormat.week: 'Week',
        },
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: (selected, focused) {
          ref.read(calendarSelectedDateProvider.notifier).set(selected);
        },
        onFormatChanged: (format) {
          ref.read(calendarFormatProvider.notifier).set(format == CalendarFormat.month ? 'month' : 'week');
        },
        eventLoader: (day) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          final count = taskDateCounts[normalizedDay] ?? 0;
          return List.generate(count.clamp(0, 3), (_) => 'task');
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: theme.colorScheme.tertiary,
            shape: BoxShape.circle,
          ),
          markerSize: 6,
          markersMaxCount: 3,
          outsideDaysVisible: false,
          defaultTextStyle: theme.textTheme.bodyMedium!,
          weekendTextStyle: theme.textTheme.bodyMedium!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(LucideIcons.chevronLeft, color: theme.colorScheme.primary, size: 24),
          rightChevronIcon: Icon(LucideIcons.chevronRight, color: theme.colorScheme.primary, size: 24),
        ),
        calendarBuilders: CalendarBuilders(
          headerTitleBuilder: (context, day) {
            if (format == CalendarFormat.week) {
              final startOfWeek = day.subtract(Duration(days: day.weekday - 1));
              final endOfWeek = startOfWeek.add(const Duration(days: 6));
              
              final rangeText = startOfWeek.month == endOfWeek.month
                  ? '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('d').format(endOfWeek)}'
                  : '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d').format(endOfWeek)}';
              
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    rangeText,
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }
            return null; // Use default title for month view
          },
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: theme.textTheme.labelSmall!.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          weekendStyle: theme.textTheme.labelSmall!.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineHeader(BuildContext context, ThemeData theme, List<Task> tasks, DateTime selectedDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    String dayLabel;
    if (selected == today) {
      dayLabel = "Today's Timeline"; 
    } else if (selected == today.add(const Duration(days: 1))) {
      dayLabel = "Tomorrow's Timeline";
    } else {
      dayLabel = DateFormat('MMM d').format(selectedDate);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              dayLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${tasks.length} ${tasks.length == 1 ? 'Task' : 'Tasks'}', 
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList(BuildContext context, ThemeData theme, WidgetRef ref, List<Task> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTimelineItem(context, theme, task, index == tasks.length - 1);
      },
    );
  }

  Widget _buildTimelineItem(BuildContext context, ThemeData theme, Task task, bool isLast) {
    final isCompleted = task.status == TaskStatus.completed;
    final timeLabel = task.time == null ? 'All Day' : task.formattedTime;

    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.high:
        priorityColor = theme.colorScheme.error;
        break;
      case TaskPriority.medium:
        priorityColor = theme.colorScheme.secondary;
        break;
      case TaskPriority.low:
        priorityColor = theme.colorScheme.primary;
        break;
    }

    return Stack(
      children: [
        if (!isLast)
          Positioned(
            left: 70 + 5,
            top: 22,
            bottom: 0,
            child: Container(
              width: 2,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  timeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  semanticsLabel: 'Time: $timeLabel',
                ),
              ),
            ),
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: isCompleted ? theme.colorScheme.primary : priorityColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? theme.colorScheme.primary : priorityColor,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? Icon(LucideIcons.check, size: 8, color: theme.colorScheme.surface)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => QuickAddTaskSheet(editTask: task),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (task.category.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: priorityColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  task.priorityLabel.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: priorityColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                task.category,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayButton(ThemeData theme, WidgetRef ref) {
    return FilledButton(
      onPressed: () => ref.read(calendarSelectedDateProvider.notifier).set(DateTime.now()),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(0, 36),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildToggleViewButton(ThemeData theme, WidgetRef ref, CalendarFormat format) {
    return SizedBox(
      height: 36,
      width: 36,
      child: IconButton.filledTonal(
        onPressed: () {
          final newFormat = format == CalendarFormat.month ? 'week' : 'month';
          ref.read(calendarFormatProvider.notifier).set(newFormat);
        },
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(
          format == CalendarFormat.month ? LucideIcons.layoutList : LucideIcons.layoutGrid,
        ),
        tooltip: format == CalendarFormat.month ? 'Week View' : 'Month View',
      ),
    );
  }

  Widget _buildAddEventButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 36,
      width: 36,
      child: IconButton.filled(
        onPressed: () => _addEventOnDate(context, ref, ref.read(calendarSelectedDateProvider)),
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: const Icon(LucideIcons.calendarPlus),
        tooltip: 'Add Task',
      ),
    );
  }

  Widget _buildEmptyDayState(BuildContext context, ThemeData theme, WidgetRef ref, DateTime selectedDate) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.calendarOff, 
                  size: 32, 
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No tasks scheduled',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Plan your day with a new task',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _addEventOnDate(context, ref, selectedDate),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addEventOnDate(BuildContext context, WidgetRef ref, DateTime selectedDay) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => QuickAddTaskSheet(initialDate: selectedDay),
    );
  }
}
