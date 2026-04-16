import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pomodoro_provider.dart';

class FocusHubWidget extends ConsumerStatefulWidget {
  final double progress; // 0.0 to 1.0
  final String label;
  final String subLabel;

  const FocusHubWidget({
    super.key,
    required this.progress,
    this.label = 'Productivity',
    this.subLabel = 'Daily Flow',
  });

  @override
  ConsumerState<FocusHubWidget> createState() => _FocusHubWidgetState();
}

class _FocusHubWidgetState extends ConsumerState<FocusHubWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunning = ref.watch(pomodoroProvider.select((s) => s.isRunning));

    if (isRunning) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0; // reset to 1.0 scale
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: widget.progress),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 120,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _RadialPainter(
                          progress: value,
                          color: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Text(
                            widget.label,
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        Text(
                          widget.subLabel.toUpperCase(),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary.withValues(alpha: 0.8),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Consumer(
            builder: (context, ref, child) {
              final selectedTask = ref.watch(pomodoroProvider.select((s) => s.selectedTask));
              final isRunning = ref.watch(pomodoroProvider.select((s) => s.isRunning));

              if (selectedTask != null) {
                return ActionChip(
                  avatar: Icon(Icons.check_circle_outline, size: 16, color: theme.colorScheme.onPrimaryContainer),
                  label: Text(
                    selectedTask.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                  ),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  onPressed: isRunning ? null : () => _showTaskSelectionSheet(context, ref),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              }

              return ActionChip(
                avatar: const Icon(Icons.link, size: 16),
                label: const Text('Link a Task'),
                onPressed: isRunning ? null : () => _showTaskSelectionSheet(context, ref),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showTaskSelectionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return const _TaskSelectionSheet();
      },
    );
  }
}

class _TaskSelectionSheet extends ConsumerWidget {
  const _TaskSelectionSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We import task_provider.dart dynamically in this file above
    // So activeTasksProvider is available
    final theme = Theme.of(context);
    // Use tasksProvider to get current active ones, this avoid circular dependency issues if imports missed
    final tasksList = ref.watch(pomodoroTaskSelectorProvider);
    final selectedTask = ref.watch(pomodoroProvider.select((s) => s.selectedTask));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Task for Focus', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              if (selectedTask != null)
                ListTile(
                  leading: const Icon(Icons.link_off, color: Colors.red),
                  title: const Text('Unlink Task', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    ref.read(pomodoroProvider.notifier).selectTask(null);
                    Navigator.pop(context);
                  },
                ),
              Expanded(
                child: tasksList.isEmpty
                    ? Center(child: Text('No active tasks.', style: theme.textTheme.bodyLarge))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: tasksList.length,
                        itemBuilder: (context, index) {
                          final task = tasksList[index];
                          final isSelected = selectedTask?.id == task.id;
                          return ListTile(
                            title: Text(task.title),
                            subtitle: Text('${task.category} • ${task.priorityLabel} priority'),
                            trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                            onTap: () {
                              ref.read(pomodoroProvider.notifier).selectTask(task);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}


class _RadialPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _RadialPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    const startAngle = math.pi;
    const sweepAngle = math.pi;

    final paintBase = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final paintProgress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Draw background arc (always visible)
    canvas.drawArc(rect, startAngle, sweepAngle, false, paintBase);

    // Draw progress arc
    if (progress > 0) {
      canvas.drawArc(rect, startAngle, sweepAngle * progress, false, paintProgress);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
