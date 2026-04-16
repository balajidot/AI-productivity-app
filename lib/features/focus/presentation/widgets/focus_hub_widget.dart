import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../pomodoro_provider.dart';

class FocusHubWidget extends ConsumerStatefulWidget {
  final double progress;
  final String label;
  final String subLabel;

  const FocusHubWidget({
    super.key,
    required this.progress,
    this.label = '25:00',
    this.subLabel = 'Focus',
  });

  @override
  ConsumerState<FocusHubWidget> createState() => _FocusHubWidgetState();
}

class _FocusHubWidgetState extends ConsumerState<FocusHubWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _lastProgress = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressAnimation = Tween<double>(
      begin: widget.progress,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    _lastProgress = widget.progress;
  }

  @override
  void didUpdateWidget(FocusHubWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _lastProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ));
      _lastProgress = widget.progress;
      _progressController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunning = ref.watch(pomodoroProvider.select((s) => s.isRunning));

    if (isRunning) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: _HorseshoePainter(
                  progress: _progressAnimation.value,
                  trackColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  progressColor: theme.colorScheme.primary,
                  strokeWidth: 16,
                ),
                child: Center(
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          widget.subLabel.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            final selectedTask =
                ref.watch(pomodoroProvider.select((s) => s.selectedTask));

            if (selectedTask != null) {
              return ActionChip(
                avatar: Icon(
                  LucideIcons.checkCircle,
                  size: 16,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                label: Text(
                  selectedTask.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
                backgroundColor: theme.colorScheme.primaryContainer,
                onPressed: () => _showTaskSelectionSheet(context, ref),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              );
            }

            return TextButton.icon(
              onPressed: () => _showTaskSelectionSheet(context, ref),
              icon: Icon(LucideIcons.link2,
                  size: 15, color: theme.colorScheme.primary),
              label: Text(
                'Link a Task',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              style: TextButton.styleFrom(
                side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    width: 1.2),
                minimumSize: const Size(140, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showTaskSelectionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _TaskSelectionSheet(),
    );
  }
}

class _HorseshoePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _HorseshoePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth;

    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track (background)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);

    // Progress
    if (progress > 0.005) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
          rect, startAngle, sweepAngle * progress.clamp(0.0, 1.0), false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(_HorseshoePainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}

class _TaskSelectionSheet extends ConsumerWidget {
  const _TaskSelectionSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasksList = ref.watch(pomodoroTaskSelectorProvider);
    final selectedTask =
        ref.watch(pomodoroProvider.select((s) => s.selectedTask));

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
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Link a Task to Focus',
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              if (selectedTask != null)
                ListTile(
                  leading: Icon(LucideIcons.x, color: theme.colorScheme.error),
                  title: Text('Unlink Task',
                      style:
                          TextStyle(color: theme.colorScheme.error)),
                  onTap: () {
                    ref.read(pomodoroProvider.notifier).selectTask(null);
                    Navigator.pop(context);
                  },
                ),
              Expanded(
                child: tasksList.isEmpty
                    ? Center(
                        child: Text('No active tasks.',
                            style: theme.textTheme.bodyLarge))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: tasksList.length,
                        itemBuilder: (context, index) {
                          final task = tasksList[index];
                          final isSelected = selectedTask?.id == task.id;
                          return ListTile(
                            leading: Icon(
                              isSelected
                                  ? LucideIcons.checkCircle
                                  : LucideIcons.circle,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              size: 20,
                            ),
                            title: Text(task.title),
                            subtitle: Text(
                                '${task.category} · ${task.priorityLabel}'),
                            onTap: () {
                              ref
                                  .read(pomodoroProvider.notifier)
                                  .selectTask(task);
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
