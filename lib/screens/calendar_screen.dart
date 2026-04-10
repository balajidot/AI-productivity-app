import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../widgets/glass_container.dart';
import '../widgets/quick_add_task_sheet.dart';
import '../providers/app_providers.dart';
import '../models/app_models.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDate = _selectedDay ?? DateTime.now();
    final tasksForDay = ref.watch(tasksForDateProvider(
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
    ));
    final taskDates = ref.watch(taskDatesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, theme),
            _buildCalendar(context, theme, taskDates),
            _buildTimelineHeader(context, theme, tasksForDay, selectedDate),
            Expanded(
              child: tasksForDay.isEmpty
                  ? _buildEmptyDayState(context, theme)
                  : _buildTimelineList(context, theme, tasksForDay),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Schedule', style: theme.textTheme.displayLarge),
          Row(
            children: [
              // Week/Month toggle
              GestureDetector(
                onTap: () {
                  setState(() {
                    _calendarFormat = _calendarFormat == CalendarFormat.month
                        ? CalendarFormat.week
                        : CalendarFormat.month;
                  });
                },
                child: GlassContainer(
                  padding: const EdgeInsets.all(8),
                  borderRadius: 8,
                  child: Icon(
                    _calendarFormat == CalendarFormat.month
                        ? LucideIcons.columns
                        : LucideIcons.grid,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Add event
              GestureDetector(
                onTap: () => _addEventOnDate(context),
                child: GlassContainer(
                  padding: const EdgeInsets.all(8),
                  borderRadius: 8,
                  child: Icon(
                    LucideIcons.calendarPlus, 
                    size: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, ThemeData theme, Set<DateTime> taskDates) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(8),
        child: TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
            CalendarFormat.week: 'Week',
          },
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          // Task markers
          eventLoader: (day) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            return taskDates.contains(normalizedDay) ? ['task'] : [];
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
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
            markersMaxCount: 1,
            outsideDaysVisible: false,
            defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface),
            weekendTextStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            leftChevronIcon: Icon(LucideIcons.chevronLeft, color: theme.colorScheme.onSurfaceVariant, size: 20),
            rightChevronIcon: Icon(LucideIcons.chevronRight, color: theme.colorScheme.onSurfaceVariant, size: 20),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            weekendStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
          Text(
            dayLabel,
            style: GoogleFonts.manrope(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${tasks.length} ${tasks.length == 1 ? 'Task' : 'Tasks'}',
              style: GoogleFonts.inter(
                color: theme.colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList(BuildContext context, ThemeData theme, List<Task> tasks) {
    // Sort by time
    final sortedTasks = List<Task>.from(tasks);
    sortedTasks.sort((a, b) {
      if (a.time == null && b.time == null) return 0;
      if (a.time == null) return 1;
      if (b.time == null) return -1;
      return a.time!.compareTo(b.time!);
    });

    final isLowPerformance = ref.watch(performanceModeProvider);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: sortedTasks.length,
      itemBuilder: (context, index) {
        final task = sortedTasks[index];
        final item = _buildTimelineItem(theme, task, index == sortedTasks.length - 1);
        if (isLowPerformance) return item;
        return item
            .animate()
            .fadeIn(delay: (index * 60).ms)
            .slideX(begin: 0.05);
      },
    );
  }

  Widget _buildTimelineItem(ThemeData theme, Task task, bool isLast) {
    final isCompleted = task.status == TaskStatus.completed;
    String timeLabel = 'All Day';
    if (task.time != null) {
      final parts = task.time!.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      timeLabel = '$displayHour:$minute $period';
    }

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

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              timeLabel,
              style: GoogleFonts.inter(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isCompleted ? theme.colorScheme.primary : priorityColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? theme.colorScheme.primary : priorityColor,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? Icon(Icons.check, size: 8, color: theme.colorScheme.surface)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: GlassContainer(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.priority.name.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: priorityColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          task.category,
                          style: GoogleFonts.inter(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.calendarOff, size: 48, color: theme.colorScheme.outline.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'No tasks for this day',
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _addEventOnDate(context),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Task'),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  void _addEventOnDate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => QuickAddTaskSheet(initialDate: _selectedDay),
    );
  }
}
