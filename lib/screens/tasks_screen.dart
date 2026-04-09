import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../models/app_models.dart';
import '../widgets/glass_container.dart';
import '../widgets/quick_add_task_sheet.dart';
import '../widgets/task_card.dart';
import '../widgets/section_header.dart';
import '../widgets/empty_state.dart';
import '../config/app_colors.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _sortBy = 'date'; // 'date', 'priority', 'category'
  bool _isCompletedExpanded = false;

  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final overdueTasks = ref.watch(overdueTasksProvider);
    final todayTasks = ref.watch(todayTasksProvider);
    final tomorrowTasks = ref.watch(tomorrowTasksProvider);
    final upcomingTasks = ref.watch(upcomingTasksProvider);
    final completedTasks = ref.watch(completedTasksProvider);

    final allEmpty = overdueTasks.isEmpty &&
        todayTasks.isEmpty &&
        tomorrowTasks.isEmpty &&
        upcomingTasks.isEmpty &&
        completedTasks.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, theme),
            if (_isSearching) _buildSearchBar(context, theme),
            _buildFilterTabs(context, theme, selectedCategory),
            Expanded(
              child: allEmpty
                  ? EmptyStateWidget(
                      title: 'All clear for now',
                      description: 'Your productivity is peak performance. Tap + to add a new challenge.',
                      imagePath: 'assets/images/empty_tasks.png',
                      onActionPressed: _showAddTaskModal,
                      actionLabel: 'Add New Task',
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Overdue Section
                          if (overdueTasks.isNotEmpty) ...[
                            SectionHeader(title: 'Overdue', color: theme.colorScheme.error, count: overdueTasks.length),
                            ...overdueTasks.asMap().entries.map((e) =>
                                TaskCard(
                                  task: e.value, 
                                  isOverdue: true,
                                  onTap: () => _showEditTaskSheet(context, e.value),
                                )
                                .animate()
                                .fadeIn(delay: (e.key * 40).ms)
                                .slideX(begin: -0.05)),
                            const SizedBox(height: 16),
                          ],
                          // Today Section
                          if (todayTasks.isNotEmpty) ...[
                            SectionHeader(title: 'Today', color: theme.colorScheme.primary, count: todayTasks.length),
                            ...todayTasks.asMap().entries.map((e) =>
                                TaskCard(
                                  task: e.value,
                                  onTap: () => _showEditTaskSheet(context, e.value),
                                )
                                .animate()
                                .fadeIn(delay: (e.key * 40).ms)
                                .slideY(begin: 0.05)),
                            const SizedBox(height: 16),
                          ],
                          // Tomorrow Section
                          if (tomorrowTasks.isNotEmpty) ...[
                            SectionHeader(title: 'Tomorrow', color: theme.colorScheme.secondary, count: tomorrowTasks.length),
                            ...tomorrowTasks.asMap().entries.map((e) =>
                                TaskCard(
                                  task: e.value,
                                  onTap: () => _showEditTaskSheet(context, e.value),
                                )
                                .animate()
                                .fadeIn(delay: (e.key * 40).ms)
                                .slideY(begin: 0.05)),
                            const SizedBox(height: 16),
                          ],
                          // Upcoming Section
                          if (upcomingTasks.isNotEmpty) ...[
                            SectionHeader(title: 'Upcoming', color: theme.colorScheme.onSurfaceVariant, count: upcomingTasks.length),
                            ...upcomingTasks.asMap().entries.map((e) =>
                                TaskCard(
                                  task: e.value,
                                  onTap: () => _showEditTaskSheet(context, e.value),
                                )
                                .animate()
                                .fadeIn(delay: (e.key * 40).ms)
                                .slideY(begin: 0.05)),
                            const SizedBox(height: 16),
                          ],
                          
                          // Completed Section
                          if (completedTasks.isNotEmpty) ...[
                            _buildCompletedSection(context, theme, completedTasks),
                          ],

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('Tasks', style: theme.textTheme.displayLarge),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).set('');
                    }
                  });
                },
                child: GlassContainer(
                  padding: const EdgeInsets.all(8),
                  borderRadius: 8,
                  child: Icon(
                    _isSearching ? LucideIcons.x : LucideIcons.search,
                    size: 20,
                    color: _isSearching ? AppColors.primary : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showSortOptions(context, theme),
                child: const GlassContainer(
                  padding: EdgeInsets.all(8),
                  borderRadius: 8,
                  child: Icon(LucideIcons.sliders, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: GoogleFonts.inter(color: theme.colorScheme.onSurface),
          onChanged: (value) => ref.read(searchQueryProvider.notifier).set(value),
          decoration: InputDecoration(
            hintText: 'Search tasks or categories...',
            hintStyle: GoogleFonts.inter(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            border: InputBorder.none,
            icon: Icon(LucideIcons.search, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ).animate().fadeIn().slideY(begin: -0.1),
    );
  }

  void _showSortOptions(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort By', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            _buildSortOption(theme, 'Date', 'date', LucideIcons.calendar),
            _buildSortOption(theme, 'Priority', 'priority', LucideIcons.flag),
            _buildSortOption(theme, 'Category', 'category', LucideIcons.tag),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(ThemeData theme, String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
      title: Text(label, style: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface)),
      trailing: isSelected ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildFilterTabs(BuildContext context, ThemeData theme, String selectedCategory) {
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
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: isSelected
                  ? BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3))
                  : BorderSide.none,
              showCheckmark: isSelected,
              checkmarkColor: theme.colorScheme.primary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompletedSection(BuildContext context, ThemeData theme, List<Task> tasks) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isCompletedExpanded = !_isCompletedExpanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  _isCompletedExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Completed',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isCompletedExpanded) ...[
          const SizedBox(height: 8),
          ...tasks.asMap().entries.map((e) =>
              TaskCard(
                task: e.value,
                onTap: () => _showEditTaskSheet(context, e.value),
              )
              .animate()
              .fadeIn(delay: (e.key * 30).ms)
              .slideY(begin: 0.02)),
        ],
      ],
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

  void _showAddTaskModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const QuickAddTaskSheet(),
    );
  }
}
