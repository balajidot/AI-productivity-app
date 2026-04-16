import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'task_provider.dart';
import '../domain/task.dart';
import 'widgets/quick_add_task_sheet.dart';
import 'widgets/task_card.dart';
import '../../../core/widgets/empty_state.dart';

import 'package:intl/intl.dart';
import '../../auth/presentation/auth_provider.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final Map<String, ScrollController> _scrollControllers = {
    'today': ScrollController(),
    'tomorrow': ScrollController(),
    'upcoming': ScrollController(),
    'overdue': ScrollController(),
    'completed': ScrollController(),
  };
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    // Sync initial state if needed
    Future.microtask(() {
      ref.read(tasksActiveTabProvider.notifier).set(_tabController.index);
    });

    for (final controller in _scrollControllers.values) {
      controller.addListener(_onScroll);
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    ref.read(tasksActiveTabProvider.notifier).set(_tabController.index);
  }

  int _lastFetchTime = 0;

  void _onScroll() {
    // Bug #3 Fix: Active tab-இன் controller மட்டும் எடுக்கிறோம்
    final tabKeys = ['today', 'tomorrow', 'upcoming', 'overdue', 'completed'];
    final activeTabKey = tabKeys[_tabController.index];
    final controller = _scrollControllers[activeTabKey];

    if (controller == null || !controller.hasClients) return;

    final maxScroll = controller.position.maxScrollExtent;
    final currentScroll = controller.position.pixels;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastFetchTime < 500) return;

    if (currentScroll >= (maxScroll * 0.8)) {
      _lastFetchTime = now;
      ref.read(tasksProvider.notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    for (final controller in _scrollControllers.values) {
      controller.removeListener(_onScroll);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    
    final todayTasks = ref.watch(todayTasksProvider);
    final tomorrowTasks = ref.watch(tomorrowTasksProvider);
    final upcomingTasks = ref.watch(upcomingTasksProvider);
    final overdueTasks = ref.watch(overdueTasksProvider);
    final completedTasks = ref.watch(completedTasksProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, theme),
            _buildFilterTabs(context, theme, selectedCategory),
            const SizedBox(height: 16),
            _buildTabBar(theme, overdueTasks, todayTasks, tomorrowTasks, upcomingTasks, completedTasks),
            const Divider(height: 1, thickness: 0.5, indent: 24, endIndent: 24, color: Colors.transparent),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildTaskTab(theme, todayTasks, 'today', 'No tasks for today!'),
                  _buildTaskTab(theme, tomorrowTasks, 'tomorrow', 'A fresh start tomorrow.'),
                  _buildTaskTab(theme, upcomingTasks, 'upcoming', 'No upcoming tasks.'),
                  _buildTaskTab(theme, overdueTasks, 'overdue', 'No overdue tasks.', isOverdue: true),
                  _buildTaskTab(theme, completedTasks, 'completed', 'Completed tasks show up here.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, List<Task> overdue, List<Task> today, List<Task> tomorrow, List<Task> upcoming, List<Task> completed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
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
          insets: const EdgeInsets.symmetric(horizontal: -4),
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        labelStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.1,
          fontSize: 14,
        ),
        unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          fontSize: 14,
        ),
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        tabs: [
          _buildTabLabel(theme, 'Today', today.where((t) => t.status != TaskStatus.completed).length),
          _buildTabLabel(theme, 'Tomorrow', tomorrow.where((t) => t.status != TaskStatus.completed).length),
          _buildTabLabel(theme, 'Upcoming', upcoming.where((t) => t.status != TaskStatus.completed).length),
          _buildTabLabel(theme, 'Overdue', overdue.where((t) => t.status != TaskStatus.completed).length, isWarning: overdue.isNotEmpty),
          _buildTabLabel(theme, 'Done', completed.length),
        ],
      ),
    );
  }

  Tab _buildTabLabel(ThemeData theme, String label, int count, {bool isWarning = false}) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isWarning 
                    ? theme.colorScheme.errorContainer 
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: isWarning ? theme.colorScheme.onErrorContainer : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskTab(ThemeData theme, List<Task> tasks, String type, String emptyMsg, {bool isOverdue = false}) {
    final tasksState = ref.watch(tasksProvider);
    final scrollController = _scrollControllers[type]!;
    final searchQuery = ref.watch(searchQueryProvider);

    if (tasks.isEmpty && !tasksState.isLoading) {
      return Center(
        child: EmptyStateWidget(
          title: isOverdue ? 'All Caught Up!' : 'Focus Time',
          description: emptyMsg,
          icon: isOverdue ? LucideIcons.checkCircle2 : LucideIcons.calendarDays,
          onActionPressed: _showAddTaskModal,
          actionLabel: 'New Task',
        ),
      );
    }

    // Group tasks if it's the upcoming tab
    if (type == 'upcoming' && tasks.isNotEmpty) {
      return _buildGroupedTaskView(theme, tasks, scrollController);
    }

    final pendingTasks = type == 'completed' ? [] : tasks.where((t) => t.status != TaskStatus.completed).toList();
    final completedTasks = type == 'completed' ? tasks : tasks.where((t) => t.status == TaskStatus.completed).toList();

    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (pendingTasks.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = pendingTasks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: TaskCard(
                      task: task,
                      isOverdue: isOverdue,
                      onTap: () => _showEditTaskSheet(context, task),
                      searchQuery: searchQuery,
                    ),
                  );
                },
                childCount: pendingTasks.length,
              ),
            ),
          ),
        
        if (completedTasks.isNotEmpty && type != 'completed') ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                children: [
                  Icon(LucideIcons.checkCircle2, 
                    size: 16, 
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'COMPLETED',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = completedTasks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Opacity(
                      opacity: 0.8,
                      child: TaskCard(
                        task: task,
                        isOverdue: false,
                        onTap: () => _showEditTaskSheet(context, task),
                        searchQuery: searchQuery,
                      ),
                    ),
                  );
                },
                childCount: completedTasks.length,
              ),
            ),
          ),
        ],

        if (type == 'completed')
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = completedTasks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: TaskCard(
                      task: task,
                      isOverdue: false,
                      onTap: () => _showEditTaskSheet(context, task),
                      searchQuery: searchQuery,
                    ),
                  );
                },
                childCount: completedTasks.length,
              ),
            ),
          ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 120, top: 20),
            child: _buildPaginationFooter(theme),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedTaskView(ThemeData theme, List<Task> tasks, ScrollController controller) {
    final searchQuery = ref.watch(searchQueryProvider);
    // Group tasks by date
    final groupedTasks = <String, List<Task>>{};
    for (var task in tasks) {
      final dateStr = DateFormat('EEEE, MMM d').format(task.date);
      if (!groupedTasks.containsKey(dateStr)) {
        groupedTasks[dateStr] = [];
      }
      groupedTasks[dateStr]!.add(task);
    }

    final slivers = <Widget>[];
    
    groupedTasks.forEach((date, tasksList) {
      final pendingDateTasks = tasksList.where((t) => t.status != TaskStatus.completed).toList();
      final completedDateTasks = tasksList.where((t) => t.status == TaskStatus.completed).toList();

      if (pendingDateTasks.isEmpty && completedDateTasks.isEmpty) return;

      // Add date header
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              date.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      );

      // Add active tasks for this date
      if (pendingDateTasks.isNotEmpty) {
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = pendingDateTasks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: TaskCard(
                      task: task,
                      onTap: () => _showEditTaskSheet(context, task),
                      searchQuery: searchQuery,
                    ),
                  );
                },
                childCount: pendingDateTasks.length,
              ),
            ),
          ),
        );
      }

      // Add completed tasks for this date with header
      if (completedDateTasks.isNotEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(36, 12, 24, 4),
              child: Text(
                'DONE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        );

        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = completedDateTasks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Opacity(
                      opacity: 0.7,
                      child: TaskCard(
                        task: task,
                        onTap: () => _showEditTaskSheet(context, task),
                        searchQuery: searchQuery,
                      ),
                    ),
                  );
                },
                childCount: completedDateTasks.length,
              ),
            ),
          ),
        );
      }
    });

    // Add pagination footer
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 120, top: 20),
          child: _buildPaginationFooter(theme),
        ),
      ),
    );

    return CustomScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      slivers: slivers,
    );
  }

  Widget _buildPaginationFooter(ThemeData theme) {
    final state = ref.watch(tasksProvider);

    if (state.isLoading) {
      return Center(
        child: Column(
          children: [
            SizedBox(
              width: 24, 
              height: 24, 
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            Text('Syncing...', style: theme.textTheme.labelSmall),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          children: [
            Icon(LucideIcons.cloudOff, color: theme.colorScheme.error, size: 24),
            const SizedBox(height: 8),
            Text('Sync error', style: theme.textTheme.bodySmall),
            TextButton.icon(
              onPressed: () => ref.read(tasksProvider.notifier).loadNextPage(),
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!state.hasMore && state.tasks.isNotEmpty) {
      return Center(
        child: Opacity(
          opacity: 0.4,
          child: Text(
            'End of tasks',
            style: theme.textTheme.labelSmall,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: _buildSearchBar(context, theme),
    );
  }

  Widget _buildSearchBar(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                ]
              : [
                  theme.colorScheme.surface.withValues(alpha: 0.95),
                  theme.colorScheme.surfaceContainerLow,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Icon (left)
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 8),
            child: Icon(
              LucideIcons.search,
              size: 18,
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
          // Text Field
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).set(value);
                setState(() {}); // refresh clear button
              },
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              textAlignVertical: TextAlignVertical.center,
            ),
          ),
          // Clear button (shows only when typing)
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).set('');
                setState(() {});
                HapticFeedback.lightImpact();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.x,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          // Avatar (right)
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 4),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  ref.read(userNameProvider).isNotEmpty 
                      ? ref.read(userNameProvider)[0].toUpperCase() 
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context, ThemeData theme, String selectedCategory) {
    final categories = [
      {'name': 'All', 'icon': LucideIcons.layers},
      {'name': 'Personal', 'icon': LucideIcons.home},
      {'name': 'Work', 'icon': LucideIcons.briefcase},
      {'name': 'Health', 'icon': LucideIcons.heart},
      {'name': 'Study', 'icon': LucideIcons.bookOpen},
      {'name': 'Finance', 'icon': LucideIcons.wallet},
      {'name': 'Inbox', 'icon': LucideIcons.inbox},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat['name'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat['name'] as String),
              avatar: cat['name'] == 'All' 
                  ? Icon(
                      cat['icon'] as IconData, 
                      size: 16, 
                      color: isSelected ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    )
                  : null,
              selected: isSelected,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                ref.read(selectedCategoryProvider.notifier).set(cat['name'] as String);
              },
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.secondaryContainer.withValues(alpha: 0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              showCheckmark: false,
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                color: isSelected ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
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
