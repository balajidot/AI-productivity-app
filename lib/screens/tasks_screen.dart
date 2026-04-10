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
import '../widgets/empty_state.dart';
import '../config/app_colors.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with SingleTickerProviderStateMixin {
  String _sortBy = 'date'; // 'date', 'priority', 'category'

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
    final isLowPerformance = ref.watch(performanceModeProvider);
    
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final overdueTasks = ref.watch(overdueTasksProvider);
    final todayTasks = ref.watch(todayTasksProvider);
    final tomorrowTasks = ref.watch(tomorrowTasksProvider);
    final upcomingTasks = ref.watch(upcomingTasksProvider);
    final completedTasks = ref.watch(completedTasksProvider);


    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              RepaintBoundary(child: _buildHeader(context, theme)),
              if (_isSearching) RepaintBoundary(child: _buildSearchBar(context, theme)),
              RepaintBoundary(child: _buildFilterTabs(context, theme, selectedCategory)),
              const SizedBox(height: 8),
              RepaintBoundary(child: _buildTabBar(context, theme, overdueTasks, todayTasks, tomorrowTasks, upcomingTasks, completedTasks)),
              Expanded(
                child: TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildTaskTab(context, theme, todayTasks, 'today', isLowPerformance, 'No tasks for today. Chill or add one!'),
                    _buildTaskTab(context, theme, tomorrowTasks, 'tomorrow', isLowPerformance, 'Tomorrow is a clean slate.'),
                    _buildTaskTab(context, theme, upcomingTasks, 'upcoming', isLowPerformance, 'The future looks bright.'),
                    _buildTaskTab(context, theme, overdueTasks, 'overdue', isLowPerformance, 'All caught up! No overdue items.', isOverdue: true),
                    _buildTaskTab(context, theme, completedTasks, 'completed', isLowPerformance, 'Complete a task to see it here.'),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTaskModal,
          child: const Icon(LucideIcons.plus),
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, ThemeData theme, List<Task> overdue, List<Task> today, List<Task> tomorrow, List<Task> upcoming, List<Task> completed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TabBar(
        isScrollable: true,
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 3,
            color: theme.colorScheme.primary,
          ),
          borderRadius: BorderRadius.circular(3),
          insets: const EdgeInsets.symmetric(horizontal: -4, vertical: -4),
        ),
        labelPadding: const EdgeInsets.only(right: 24),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.bold, 
          fontSize: 14,
          letterSpacing: -0.2,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500, 
          fontSize: 14,
          letterSpacing: -0.2,
        ),
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        tabs: [
          _buildTabLabel('Today', today.length),
          _buildTabLabel('Tomorrow', tomorrow.length),
          _buildTabLabel('Upcoming', upcoming.length),
          _buildTabLabel('Overdue', overdue.length, isWarning: overdue.isNotEmpty),
          _buildTabLabel('Done', completed.length),
        ],
      ),
    );
  }

  Tab _buildTabLabel(String label, int count, {bool isWarning = false}) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isWarning ? AppColors.error : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  color: isWarning ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskTab(BuildContext context, ThemeData theme, List<Task> tasks, String type, bool isLowPerformance, String emptyMsg, {bool isOverdue = false}) {
    if (tasks.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          title: 'All clear',
          description: emptyMsg,
          onActionPressed: _showAddTaskModal,
          actionLabel: 'Add Task',
        ),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final task = tasks[index];
                final card = TaskCard(
                  task: task,
                  isOverdue: isOverdue,
                  onTap: () => _showEditTaskSheet(context, task),
                );
                
                if (isLowPerformance) return card;
                
                return card.animate()
                  .fadeIn(duration: 200.ms, delay: (index * 40).ms)
                  .slideY(begin: 0.05, duration: 200.ms);
              },
              childCount: tasks.length,
            ),
          ),
        ),
      ],
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
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                ref.read(selectedCategoryProvider.notifier).set(cat);
              },
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: isSelected
                  ? BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5), width: 1.5)
                  : BorderSide.none,
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        }).toList(),
      ),
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
