import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../domain/task.dart';
import '../task_provider.dart';
import '../../data/natural_language_parser.dart';
import '../../../../core/utils/app_utils.dart';

class QuickAddTaskSheet extends ConsumerStatefulWidget {
  final Task? editTask;
  final DateTime? initialDate;
  final String? initialCategory;

  const QuickAddTaskSheet({
    super.key,
    this.editTask,
    this.initialDate,
    this.initialCategory,
  });

  @override
  ConsumerState<QuickAddTaskSheet> createState() => _QuickAddTaskSheetState();
}

class _QuickAddTaskSheetState extends ConsumerState<QuickAddTaskSheet> {
  final _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  late TaskPriority _selectedPriority;
  late String _selectedCategory;
  String? _selectedRecurrence;
  List<String> _suggestions = [];

  bool get isEditing => widget.editTask != null;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      final t = widget.editTask!;
      _controller.text = t.title;
      _selectedDate = t.date;
      _selectedPriority = t.priority;
      _selectedCategory = t.category;
      _selectedRecurrence = t.recurrence;
      if (t.time != null && t.time!.contains(':')) {
        final parts = t.time!.split(':');
        final hour = int.tryParse(parts[0]) ?? 12;
        final minute = int.tryParse(parts[1]) ?? 0;
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      }
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      _selectedPriority = TaskPriority.medium;
      _selectedCategory = widget.initialCategory ?? 'Inbox';
    }

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (text.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    final parsed = NaturalLanguageParser.parse(text);

    setState(() {
      if (parsed.date != null) _selectedDate = parsed.date!;
      if (parsed.time != null) _selectedTime = parsed.time;
      if (parsed.priority != null) _selectedPriority = parsed.priority!;
      if (parsed.category != null) _selectedCategory = parsed.category!;
      if (parsed.recurrence != null) _selectedRecurrence = parsed.recurrence;
      _suggestions = NaturalLanguageParser.getSuggestions(text);
    });
  }

  void _applySuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _onTextChanged(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // Priority styling
    Color priorityColor = theme.colorScheme.onSurfaceVariant;
    String priorityLabel = 'P2';
    if (_selectedPriority == TaskPriority.high) {
      priorityColor = theme.colorScheme.error;
      priorityLabel = 'P1';
    } else if (_selectedPriority == TaskPriority.medium) {
      priorityColor = theme.colorScheme.secondary;
      priorityLabel = 'P2';
    } else {
      priorityColor = theme.colorScheme.primary;
      priorityLabel = 'P3';
    }

    // Date text
    String dateText = 'Today';
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfter = today.add(const Duration(days: 2));

    if (selectedDay == today) {
      dateText = 'Today';
    } else if (selectedDay == tomorrow) {
      dateText = 'Tomorrow';
    } else if (selectedDay == dayAfter) {
      dateText = 'Day After';
    } else {
      dateText = DateFormat('MMM d').format(_selectedDate);
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Text Input
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitTask(),
                    onChanged: _onTextChanged,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: isEditing ? 'Update task...' : 'New task...',
                      hintStyle: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),

                  // Smart Suggestions
                  if (_suggestions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final s = _suggestions[index];
                          return ActionChip(
                            label: Text(s),
                            onPressed: () => _applySuggestion(s),
                            labelStyle: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                            padding: EdgeInsets.zero,
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action Row: Date, Priority, Time, Repeat
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildToolButton(
                          theme,
                          LucideIcons.calendar,
                          dateText,
                          onPressed: _selectDate,
                          isActive: selectedDay != today,
                        ),
                        const SizedBox(width: 8),
                        _buildToolButton(
                          theme,
                          LucideIcons.flag,
                          priorityLabel,
                          onPressed: _togglePriority,
                          isActive: _selectedPriority != TaskPriority.low,
                          iconColor: priorityColor,
                        ),
                        const SizedBox(width: 8),
                        _buildToolButton(
                          theme,
                          LucideIcons.clock,
                          _selectedTime?.format(context) ?? 'Set time',
                          onPressed: _selectTime,
                          isActive: _selectedTime != null,
                        ),
                        const SizedBox(width: 8),
                        _buildToolButton(
                          theme,
                          LucideIcons.repeat,
                          _selectedRecurrence ?? 'No repeat',
                          onPressed: _showRecurrencePicker,
                          isActive: _selectedRecurrence != null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bottom Action Row
                  Row(
                    children: [
                      // Category Button
                      InkWell(
                        onTap: _showCategoryPicker,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _categoryIcon(_selectedCategory),
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedCategory,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Cancel Button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _controller,
                        builder: (context, value, child) {
                          final hasText = value.text.trim().isNotEmpty;
                          return FilledButton(
                            onPressed: hasText ? _submitTask : null,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(isEditing ? 'Save' : 'Add'),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(
    ThemeData theme,
    IconData icon,
    String label, {
    required VoidCallback onPressed,
    bool isActive = false,
    Color? iconColor,
  }) {
    return FilterChip(
      selected: isActive,
      onSelected: (_) => onPressed(),
      avatar: Icon(
        icon,
        size: 16,
        color:
            iconColor ??
            (isActive
                ? theme.colorScheme.onSecondaryContainer
                : theme.colorScheme.onSurfaceVariant),
      ),
      label: Text(label),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: isActive
            ? theme.colorScheme.onSecondaryContainer
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
      ),
      backgroundColor: Colors.transparent,
      selectedColor: theme.colorScheme.secondaryContainer,
      side: BorderSide(
        color: isActive
            ? Colors.transparent
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      visualDensity: VisualDensity.compact,
      showCheckmark: false,
    );
  }

  Future<void> _selectDate() async {
    final theme = Theme.of(context);
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(data: theme, child: child!);
      },
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _selectTime() async {
    final theme = Theme.of(context);
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(data: theme, child: child!);
      },
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  void _showCategoryPicker() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            ...['Inbox', 'Work', 'Personal', 'Health', 'Study', 'Finance'].map((
              cat,
            ) {
              final isSelected = cat == _selectedCategory;
              return ListTile(
                leading: Icon(
                  _categoryIcon(cat),
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  cat,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        LucideIcons.checkCircle,
                        color: theme.colorScheme.primary,
                        size: 20,
                      )
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  setState(() => _selectedCategory = cat);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRecurrencePicker() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Repeat', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            ...[
              null,
              'daily',
              'weekly',
              'monthly',
              'every monday',
              'every tuesday',
              'every wednesday',
              'every thursday',
              'every friday',
              'every saturday',
              'every sunday',
            ].map((rec) {
              final label = rec ?? 'No repeat';
              final isSelected = rec == _selectedRecurrence;
              return ListTile(
                leading: Icon(
                  rec == null ? LucideIcons.x : LucideIcons.repeat,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                title: Text(
                  label[0].toUpperCase() + label.substring(1),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        LucideIcons.checkCircle,
                        color: theme.colorScheme.primary,
                        size: 20,
                      )
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  setState(() => _selectedRecurrence = rec);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _togglePriority() {
    setState(() {
      switch (_selectedPriority) {
        case TaskPriority.low:
          _selectedPriority = TaskPriority.medium;
          break;
        case TaskPriority.medium:
          _selectedPriority = TaskPriority.high;
          break;
        case TaskPriority.high:
          _selectedPriority = TaskPriority.low;
          break;
      }
    });
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Work':
        return LucideIcons.briefcase;
      case 'Personal':
        return LucideIcons.user;
      case 'Health':
        return LucideIcons.heart;
      case 'Study':
        return LucideIcons.bookOpen;
      case 'Finance':
        return LucideIcons.wallet;
      default:
        return LucideIcons.inbox;
    }
  }

  void _submitTask() {
    final rawText = _controller.text.trim();
    if (rawText.isEmpty) return;

    // Use cleaned title for submission
    final parsed = NaturalLanguageParser.parse(rawText);
    String finalTitle = parsed.cleanTitle;

    // Fallback if cleaning removed everything (unlikely but safe)
    if (finalTitle.isEmpty) finalTitle = rawText;

    final task = Task(
      id: isEditing
          ? widget.editTask!.id
          : AppUtils.generateId(prefix: 'task'),
      title: finalTitle,
      date: _selectedDate,
      time: _selectedTime != null ? _formatTimeOfDay(_selectedTime!) : null,
      priority: _selectedPriority,
      category: _selectedCategory,
      recurrence: _selectedRecurrence,
      status: isEditing ? widget.editTask!.status : TaskStatus.todo,
    );

    if (isEditing) {
      ref.read(tasksProvider.notifier).updateTask(task);
    } else {
      ref.read(tasksProvider.notifier).addTask(task);
    }

    Navigator.pop(context);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
