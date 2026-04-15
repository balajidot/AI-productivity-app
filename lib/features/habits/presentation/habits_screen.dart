import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../domain/habit.dart';
import 'habit_provider.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/empty_state.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(body: SafeArea(child: _HabitsBody()));
  }
}

class _HabitsBody extends ConsumerWidget {
  const _HabitsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final theme = Theme.of(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Habits', style: theme.textTheme.displaySmall),
                if (habits.isNotEmpty)
                  _StatsChip(
                    completed: habits.where((h) => h.completedToday).length,
                    total: habits.length,
                  ),
              ],
            ),
          ),
        ),
        if (habits.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(child: _HabitStatsRow(habits: habits)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _HabitTile(habit: habits[index]),
                childCount: habits.length,
              ),
            ),
          ),
        ] else
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              imagePath: 'assets/images/empty_habits.png',
              title: 'No Habits Yet',
              description:
                  'Build powerful daily systems. Tap + to add your first habit.',
            ),
          ),
      ],
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsChip extends StatelessWidget {
  final int completed;
  final int total;
  const _StatsChip({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allDone = completed == total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: allDone
            ? Colors.green.withValues(alpha: 0.15)
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$completed / $total done',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: allDone ? Colors.green : theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _HabitStatsRow extends StatelessWidget {
  final List<Habit> habits;
  const _HabitStatsRow({required this.habits});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final longestStreak = habits.fold(0, (m, h) => h.streak > m ? h.streak : m);
    final completedToday = habits.where((h) => h.completedToday).length;

    return Row(
      children: [
        _StatCard(
          label: 'Today',
          value: '$completedToday/${habits.length}',
          icon: LucideIcons.checkCircle,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Best Streak',
          value: '${longestStreak}d',
          icon: LucideIcons.flame,
          color: Colors.orange,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Habits',
          value: '${habits.length}',
          icon: LucideIcons.list,
          color: theme.colorScheme.tertiary,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Habit Tile ───────────────────────────────────────────────────────────────

class _HabitTile extends ConsumerWidget {
  final Habit habit;
  const _HabitTile({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDone = habit.completedToday;

    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(LucideIcons.trash2, color: theme.colorScheme.error),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Habit'),
            content: Text('Delete "${habit.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(habitsProvider.notifier).deleteHabit(habit.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDone
              ? Colors.green.withValues(alpha: 0.08)
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDone
                ? Colors.green.withValues(alpha: 0.25)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ref
                  .read(habitsProvider.notifier)
                  .toggleHabitDay(habit.id, DateTime.now());
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? Colors.green.withValues(alpha: 0.15)
                    : theme.colorScheme.surfaceContainerHigh,
                border: Border.all(
                  color: isDone
                      ? Colors.green
                      : theme.colorScheme.outlineVariant,
                  width: isDone ? 2 : 1,
                ),
              ),
              child: Icon(
                isDone ? LucideIcons.check : _iconFromName(habit.icon),
                size: 20,
                color: isDone ? Colors.green : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          title: Text(
            habit.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              decoration: isDone ? TextDecoration.lineThrough : null,
              color: isDone
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                  : theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              _WeekStrip(habit: habit),
            ],
          ),
          trailing: habit.streak > 0
              ? _StreakBadge(streak: habit.streak)
              : null,
        ),
      ),
    );
  }

  IconData _iconFromName(String name) {
    final map = {
      'star': LucideIcons.star,
      'book': LucideIcons.bookOpen,
      'run': LucideIcons.activity,
      'water': LucideIcons.droplet,
      'sleep': LucideIcons.moon,
      'meditate': LucideIcons.brain,
      'workout': LucideIcons.activity,
      'write': LucideIcons.edit3,
      'music': LucideIcons.headphones,
      'code': LucideIcons.terminal,
      'eat': LucideIcons.utensils,
      'walk': LucideIcons.navigation,
    };
    return map[name] ?? LucideIcons.star;
  }
}

class _WeekStrip extends StatelessWidget {
  final Habit habit;
  const _WeekStrip({required this.habit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final days = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });
    final completedSet = habit.completedDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      children: List.generate(7, (i) {
        final day = days[i];
        final done = completedSet.contains(day);
        final isToday = day == DateTime(today.year, today.month, today.day);
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Column(
            children: [
              Text(
                labels[day.weekday - 1],
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontWeight:
                      isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? Colors.green
                      : (isToday
                          ? theme.colorScheme.primary.withValues(alpha: 0.25)
                          : theme.colorScheme.surfaceContainerHighest),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.flame, size: 12, color: Colors.orange),
          const SizedBox(width: 3),
          Text(
            '$streak',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Habit Sheet ──────────────────────────────────────────────────────────

class AddHabitSheet extends ConsumerStatefulWidget {
  const AddHabitSheet({super.key});

  @override
  ConsumerState<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<AddHabitSheet> {
  final _controller = TextEditingController();
  String _selectedIcon = 'star';
  bool _submitting = false;

  static final _icons = {
    'star': LucideIcons.star,
    'book': LucideIcons.bookOpen,
    'run': LucideIcons.activity,
    'water': LucideIcons.droplet,
    'sleep': LucideIcons.moon,
    'meditate': LucideIcons.brain,
    'workout': LucideIcons.activity,
    'write': LucideIcons.edit3,
    'music': LucideIcons.headphones,
    'code': LucideIcons.terminal,
    'eat': LucideIcons.utensils,
    'walk': LucideIcons.navigation,
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() => _submitting = true);
    await ref.read(habitsProvider.notifier).addHabit(
      Habit(
        id: AppUtils.generateId(prefix: 'habit'),
        name: name,
        icon: _selectedIcon,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('New Habit', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'e.g. Read 30 minutes',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ICON',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _icons.entries.map((e) {
              final isSelected = _selectedIcon == e.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedIcon = e.key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    e.value,
                    size: 22,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Habit'),
            ),
          ),
        ],
      ),
    );
  }
}
