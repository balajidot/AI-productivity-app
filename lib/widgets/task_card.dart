import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';
import '../widgets/celebration_overlay.dart';
import '../providers/app_providers.dart';

class TaskCard extends ConsumerWidget {
  final Task task;
  final bool isOverdue;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.isOverdue = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCompleted = task.status == TaskStatus.completed;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      background: _buildDismissBackground(
        alignment: Alignment.centerLeft,
        color: Colors.green.withValues(alpha: 0.15),
        icon: LucideIcons.checkCircle,
        label: 'Complete',
        textColor: Colors.greenAccent,
      ),
      secondaryBackground: _buildDismissBackground(
        alignment: Alignment.centerRight,
        color: AppColors.errorDim.withValues(alpha: 0.15),
        icon: LucideIcons.trash2,
        label: 'Delete',
        textColor: AppColors.error,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return true; // Delete
        } else {
          // Toggle Complete
          final wasCompleted = await ref.read(tasksProvider.notifier).toggleTask(task.id);
          if (wasCompleted && context.mounted) {
            CelebrationOverlay.show(context);
          }
          return false;
        }
      },
      onDismissed: (_) => ref.read(tasksProvider.notifier).deleteTask(task.id),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (onTap != null) onTap!();
          },
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            useBlur: false,
            child: Row(
              children: [
                _buildCheckbox(ref, context, isCompleted),
                const SizedBox(width: 14),
                _buildPriorityBar(),
                const SizedBox(width: 14),
                _buildTaskInfo(theme, isCompleted),
                _buildTimeInfo(theme),
              ],
            ),
          ),
        ).animate(onPlay: (c) => c.stop()).scale(
              begin: const Offset(1, 1),
              end: const Offset(0.97, 0.97),
              duration: 100.ms,
              curve: Curves.easeInOut,
            ),
      ),
    );
  }

  Widget _buildDismissBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
    required Color textColor,
  }) {
    return Container(
      alignment: alignment,
      padding: EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: textColor),
            const SizedBox(width: 8),
          ],
          Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
          if (alignment == Alignment.centerRight) ...[
            const SizedBox(width: 8),
            Icon(icon, color: textColor),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckbox(WidgetRef ref, BuildContext context, bool isCompleted) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        final wasCompleted = await ref.read(tasksProvider.notifier).toggleTask(task.id);
        if (wasCompleted && context.mounted) {
          CelebrationOverlay.show(context);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isCompleted
                ? AppColors.primary
                : isOverdue
                    ? AppColors.error
                    : task.priorityColor,
            width: 2,
          ),
          color: isCompleted ? AppColors.primary.withValues(alpha: 0.25) : Colors.transparent,
        ),
        child: isCompleted ? const Icon(Icons.check_rounded, size: 16, color: AppColors.primary) : null,
      ),
    );
  }

  Widget _buildPriorityBar() {
    return Container(
      width: 3,
      height: 32,
      decoration: BoxDecoration(
        color: task.priorityColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTaskInfo(ThemeData theme, bool isCompleted) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted
                  ? theme.colorScheme.onSurfaceVariant
                  : isOverdue
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                task.category,
                style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              ),
              if (task.recurrence != null) ...[
                const SizedBox(width: 6),
                Icon(LucideIcons.repeat, size: 11, color: AppColors.secondary),
                const SizedBox(width: 3),
                Text(
                  task.recurrence!,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (task.time != null)
          Text(
            task.formattedTime,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        Text(
          task.displayDate,
          style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
