import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../task_provider.dart';
import '../../domain/task.dart';
import '../../../chat/presentation/feedback_provider.dart';


class TaskCard extends ConsumerWidget {
  final Task task;
  final bool isOverdue;
  final VoidCallback? onTap;
  final String searchQuery;

  const TaskCard({
    super.key,
    required this.task,
    this.isOverdue = false,
    this.onTap,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCompleted = task.status == TaskStatus.completed;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      background: _DismissBackground(
        alignment: Alignment.centerLeft,
        color: Colors.green.withValues(alpha: 0.15),
        icon: LucideIcons.checkCircle,
        label: 'Complete',
        textColor: Colors.green,
      ),
      secondaryBackground: _DismissBackground(
        alignment: Alignment.centerRight,
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        icon: LucideIcons.trash2,
        label: 'Delete',
        textColor: theme.colorScheme.error,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          HapticFeedback.mediumImpact();
          return true; // Delete
        } else {
          HapticFeedback.lightImpact();
          await ref.read(tasksProvider.notifier).toggleTask(task.id);
          return false;
        }
      },
      onDismissed: (_) async {
        await ref.read(tasksProvider.notifier).deleteTask(task.id);
        ref.read(feedbackProvider.notifier).showMessage('Task deleted');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              if (onTap != null) onTap!();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isCompleted 
                    ? theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.6)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCompleted 
                      ? Colors.transparent 
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  width: 1,
                ),
                boxShadow: isCompleted ? [] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildCheckbox(ref, theme, isCompleted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TaskBodySection(
                        task: task,
                        isCompleted: isCompleted,
                        isOverdue: isOverdue,
                        searchQuery: searchQuery,
                      ),
                    ),
                    if (task.time != null || !isCompleted) ...[
                      const SizedBox(width: 8),
                      _TimeDisplay(task: task, isCompleted: isCompleted),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(WidgetRef ref, ThemeData theme, bool isCompleted) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        HapticFeedback.lightImpact();
        await ref.read(tasksProvider.notifier).toggleTask(task.id);
      },
      child: Container(
        padding: const EdgeInsets.all(8), // Explicit hit area enhancement
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withValues(alpha: 0.6), // Much more visible than outline
              width: 2.5,
            ),
            color: isCompleted 
                ? theme.colorScheme.primary 
                : Colors.transparent,
          ),
          child: Center(
            child: AnimatedOpacity(
              opacity: isCompleted ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                LucideIcons.check, 
                size: 18, 
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;
  final Color textColor;

  const _DismissBackground({
    required this.alignment, 
    required this.color, 
    required this.icon, 
    required this.label, 
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      margin: const EdgeInsets.only(bottom: 12, top: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 12),
          ],
          Text(
            label, 
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor, 
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          if (alignment == Alignment.centerRight) ...[
            const SizedBox(width: 12),
            Icon(icon, color: textColor, size: 22),
          ],
        ],
      ),
    );
  }
}

class _TaskBodySection extends StatelessWidget {
  final Task task;
  final bool isCompleted;
  final bool isOverdue;
  final String searchQuery;

  const _TaskBodySection({
    required this.task,
    required this.isCompleted,
    required this.isOverdue,
    this.searchQuery = '',
  });

  List<TextSpan> _buildHighlightedSpans(
    String text,
    String query,
    TextStyle base,
    TextStyle highlight,
  ) {
    if (query.isEmpty) return [TextSpan(text: text, style: base)];
    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    int start = 0;
    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: base));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: base));
      }
      spans.add(TextSpan(text: text.substring(idx, idx + q.length), style: highlight));
      start = idx + q.length;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final baseStyle = (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontWeight: isCompleted ? FontWeight.w400 : FontWeight.w600,
      decoration: isCompleted ? TextDecoration.lineThrough : null,
      color: isCompleted
          ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
          : isOverdue
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface,
      fontSize: 15,
      letterSpacing: 0.1,
    );
    final highlightStyle = baseStyle.copyWith(
      backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w800,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: _buildHighlightedSpans(
              task.title,
              searchQuery,
              baseStyle,
              highlightStyle,
            ),
          ),
        ),
        if (task.description != null && task.description!.isNotEmpty && !isCompleted) ...[
          const SizedBox(height: 2),
          Text(
            task.description!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 2),
        Row(
          children: [
            _buildSmallTag(
              context, 
              task.category, 
              theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
              theme.colorScheme.onSecondaryContainer
            ),
            if (task.recurrence != null && !isCompleted) ...[
              const SizedBox(width: 6),
              _buildSmallTag(
                context, 
                task.recurrence!, 
                theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                theme.colorScheme.onTertiaryContainer,
                icon: LucideIcons.repeat
              ),
            ],
            if (!isCompleted) ...[
              const SizedBox(width: 6),
              _buildPriorityBadge(task.priority),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSmallTag(BuildContext context, String label, Color bgColor, Color textColor, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    final color = TaskPriorityExtension.getColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TimeDisplay extends StatelessWidget {
  final Task task;
  final bool isCompleted;

  const _TimeDisplay({required this.task, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = task.isToday;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (task.time != null)
          Text(
            task.formattedTime,
            style: (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
              fontWeight: FontWeight.w700,
              color: isCompleted 
                  ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4) 
                  : theme.colorScheme.primary,
              fontSize: 13,
            ),
          ),
        Text(
          task.displayDate,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isToday && !isCompleted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
