import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
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

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surfaceHighest,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surfaceHighest,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) setState(() => _selectedTime = time);
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

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            ...['Inbox', 'Work', 'Personal', 'Health', 'Study', 'Finance'].map((cat) {
              final isSelected = cat == _selectedCategory;
              return ListTile(
                leading: Icon(
                  _categoryIcon(cat),
                  color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
                title: Text(cat, style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                )),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Repeat', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            ...[null, 'daily', 'weekly', 'monthly', 'every monday', 'every friday'].map((rec) {
              final label = rec ?? 'No repeat';
              final isSelected = rec == _selectedRecurrence;
              return ListTile(
                leading: Icon(
                  rec == null ? LucideIcons.x : LucideIcons.repeat,
                  color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                  size: 20,
                ),
                title: Text(
                  label[0].toUpperCase() + label.substring(1),
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
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

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Work': return LucideIcons.briefcase;
      case 'Personal': return LucideIcons.user;
      case 'Health': return LucideIcons.heart;
      case 'Study': return LucideIcons.bookOpen;
      case 'Finance': return LucideIcons.dollarSign;
      default: return LucideIcons.inbox;
    }
  }

  void _submitTask() {
    final rawText = _controller.text.trim();
    if (rawText.isEmpty) return;

    // Parse for clean title
    final parsed = NaturalLanguageParser.parse(rawText);

    if (isEditing) {
      final updatedTask = widget.editTask!.copyWith(
        title: parsed.cleanTitle,
        date: _selectedDate,
        time: _selectedTime != null
            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
            : null,
        priority: _selectedPriority,
        category: _selectedCategory,
        recurrence: _selectedRecurrence,
      );
      ref.read(tasksProvider.notifier).updateTask(updatedTask);
    } else {
      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: parsed.cleanTitle,
        category: _selectedCategory,
        priority: _selectedPriority,
        date: _selectedDate,
        time: _selectedTime != null
            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
            : null,
        status: TaskStatus.todo,
        recurrence: _selectedRecurrence,
      );
      ref.read(tasksProvider.notifier).addTask(newTask);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Priority styling
    Color priorityColor = AppColors.onSurfaceVariant;
    String priorityLabel = 'P2';
    if (_selectedPriority == TaskPriority.high) {
      priorityColor = AppColors.error;
      priorityLabel = 'P1';
    } else if (_selectedPriority == TaskPriority.medium) {
      priorityColor = AppColors.secondary;
      priorityLabel = 'P2';
    } else {
      priorityColor = AppColors.primary;
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
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                color: AppColors.outlineVariant,
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
                          color: AppColors.primary,
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g., Team sync tomorrow at 10am @work',
                      hintStyle: TextStyle(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
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
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  s,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.primary,
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
                          icon: LucideIcons.calendar,
                          label: dateText,
                          onTap: _selectDate,
                          isActive: selectedDay != today,
                        ),
                        const SizedBox(width: 8),
                        _buildActionChip(
                          icon: LucideIcons.flag,
                          label: priorityLabel,
                          iconColor: priorityColor,
                          onTap: _togglePriority,
                          isActive: _selectedPriority != TaskPriority.low,
                        ),
                        const SizedBox(width: 8),
                        _buildActionChip(
                          icon: LucideIcons.bell,
                          label: _selectedTime?.format(context) ?? 'Set Time',
                          onTap: _selectTime,
                          isActive: _selectedTime != null,
                        ),
                        const SizedBox(width: 8),
                        _buildActionChip(
                          icon: LucideIcons.repeat,
                          label: _selectedRecurrence ?? 'Repeat',
                          onTap: _showRecurrencePicker,
                          isActive: _selectedRecurrence != null,
                        ),
                        const SizedBox(width: 8),
                        _buildActionChip(
                          icon: LucideIcons.tag,
                          onTap: _showCategoryPicker,
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: AppColors.outlineVariant, height: 1),
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
                            Icon(_categoryIcon(_selectedCategory), color: AppColors.onSurfaceVariant, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _selectedCategory.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Submit buttons
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.x, color: AppColors.onSurfaceVariant, size: 22),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryContainer],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
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
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.background,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        isEditing ? LucideIcons.check : LucideIcons.arrowUp,
                                        color: AppColors.background.withValues(alpha: 0.9),
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
    required IconData icon,
    String? label,
    Color? iconColor,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    final bgColor = isActive
        ? AppColors.primary.withValues(alpha: 0.15)
        : AppColors.surfaceHighest;

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
              color: isActive ? AppColors.primary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor ?? (isActive ? AppColors.primary : AppColors.onSurfaceVariant),
              ),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
