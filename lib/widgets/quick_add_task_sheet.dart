import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';
import '../providers/app_providers.dart';
import '../services/natural_language_parser.dart';

class QuickAddTaskSheet extends ConsumerStatefulWidget {
  final Task? editTask;

  const QuickAddTaskSheet({super.key, this.editTask});

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
      if (t.time != null) {
        final parts = t.time!.split(':');
        _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } else {
      _selectedDate = DateTime.now();
      _selectedPriority = TaskPriority.medium;
      _selectedCategory = 'Inbox';
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
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
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
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  if (isEditing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Edit Task',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),

                  // Text Input
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitTask(),
                    onChanged: _onTextChanged,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g., Team sync tomorrow at 10am @work',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),

                  // Smart Suggestions
                  if (_suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _suggestions.map((s) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _applySuggestion(s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  s,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Action Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildActionChip(
                          theme: theme,
                          icon: LucideIcons.calendar,
                          label: dateText,
                          onTap: _selectDate,
                          isActive: selectedDay != today,
                        ),
                        const SizedBox(width: 8),
                        _buildActionChip(
                          theme: theme,
                          icon: LucideIcons.flag,
                          label: priorityLabel,
                          iconColor: priorityColor,
                          onTap: _togglePriority,
                          isActive: _selectedPriority != TaskPriority.low,
                        ),
                        const SizedBox(width: 8),
                        _buildActionChip(
                          theme: theme,
                          icon: LucideIcons.bell,
                          label: _selectedTime?.format(context) ?? 'Set Time',
                          onTap: _selectTime,
                          isActive: _selectedTime != null,
                        ),
                        const SizedBox(width: 8),
                        _buildActionChip(
                          theme: theme,
                          icon: LucideIcons.repeat,
                          label: _selectedRecurrence ?? 'Repeat',
                          onTap: _showRecurrencePicker,
                          isActive: _selectedRecurrence != null,
                        ),
                        const SizedBox(width: 8),
                        _buildActionChip(
                          theme: theme,
                          icon: LucideIcons.tag,
                          onTap: _showCategoryPicker,
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: theme.colorScheme.outlineVariant, height: 1),
                  ),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category display
                      GestureDetector(
                        onTap: _showCategoryPicker,
                        child: Row(
                          children: [
                            Icon(_categoryIcon(_selectedCategory), color: theme.colorScheme.onSurfaceVariant, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _selectedCategory.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Submit buttons
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(LucideIcons.x, color: theme.colorScheme.onSurfaceVariant, size: 22),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _submitTask,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isEditing ? 'Update' : 'Add Task',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        isEditing ? LucideIcons.check : LucideIcons.arrowUp,
                                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildActionChip({
    required ThemeData theme,
    required IconData icon,
    String? label,
    Color? iconColor,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    final bgColor = isActive
        ? theme.colorScheme.primary.withValues(alpha: 0.15)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: label != null ? 12 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.3) : theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor ?? (isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
              ),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
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
        return Theme(
          data: theme,
          child: child!,
        );
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
        return Theme(
          data: theme,
          child: child!,
        );
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
            ...['Inbox', 'Work', 'Personal', 'Health', 'Study', 'Finance'].map((cat) {
              final isSelected = cat == _selectedCategory;
              return ListTile(
                leading: Icon(
                  _categoryIcon(cat),
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(cat, style: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                )),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20)
                    : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            ...[null, 'daily', 'weekly', 'monthly', 'every monday', 'every friday'].map((rec) {
              final label = rec ?? 'No repeat';
              final isSelected = rec == _selectedRecurrence;
              return ListTile(
                leading: Icon(
                  rec == null ? LucideIcons.x : LucideIcons.repeat,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                title: Text(
                  label[0].toUpperCase() + label.substring(1),
                  style: TextStyle(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20)
                    : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    final task = Task(
      id: isEditing ? widget.editTask!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: _selectedDate,
      time: _selectedTime != null ? '${_selectedTime!.hour}:${_selectedTime!.minute}' : null,
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
}
