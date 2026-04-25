import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/task_provider.dart';
import '../../chat/presentation/chat_provider.dart';
import '../../chat/presentation/feedback_provider.dart';
import '../../../core/utils/app_utils.dart';

class GoalDecomposerSheet extends ConsumerStatefulWidget {
  const GoalDecomposerSheet({super.key});

  @override
  ConsumerState<GoalDecomposerSheet> createState() => _GoalDecomposerSheetState();
}

class _GoalDecomposerSheetState extends ConsumerState<GoalDecomposerSheet> {
  final _goalController = TextEditingController();
  String _selectedTimeframe = '2 weeks';
  bool _isAnalyzing = false;
  Map<String, dynamic>? _results;

  final List<String> _timeframes = ['1 week', '2 weeks', '1 month', '3 months'];

  Future<void> _decompose() async {
    if (_goalController.text.isEmpty) return;
    
    setState(() => _isAnalyzing = true);
    try {
      final aiService = ref.read(aiServiceProvider);
      final results = await aiService.decomposeGoal(
        _goalController.text,
        _selectedTimeframe,
      );
      if (!mounted) return;
      
      final tasks = results['tasks'] as List?;
      if (tasks == null || tasks.isEmpty) {
        setState(() => _isAnalyzing = false);
        ref.read(feedbackProvider.notifier).showError(
          'AI could not decompose this goal. Please try a more specific goal description.',
        );
        return;
      }

      setState(() {
        _results = results;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ref.read(feedbackProvider.notifier).showError('Failed to decompose goal. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 24),
          if (_results == null) _buildInputForm(theme) else _buildResultView(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(LucideIcons.target, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text('Goal Decomposer', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.x),
        ),
      ],
    );
  }

  Widget _buildInputForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What is your big goal?', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _goalController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g., Build a personal portfolio website from scratch...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 20),
        Text('Timeframe', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedTimeframe,
          items: _timeframes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _selectedTimeframe = v!),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: _isAnalyzing ? null : _decompose,
            icon: _isAnalyzing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(LucideIcons.sparkles),
            label: Text(_isAnalyzing ? 'Analyzing goal...' : 'Decompose with AI'),
          ),
        ),
      ],
    );
  }

  Widget _buildResultView(ThemeData theme) {
    final milestones = List<String>.from(_results!['milestones'] ?? []);
    final tasksData = List<Map<String, dynamic>>.from(_results!['tasks'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Milestones', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...milestones.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(LucideIcons.checkCircle, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(m, style: theme.textTheme.bodyMedium)),
            ],
          ),
        )),
        const Divider(height: 32),
        Text('Daily Action Tasks', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...tasksData.map((t) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.plus, size: 14),
              const SizedBox(width: 12),
              Expanded(child: Text(t['title'] ?? '')),
            ],
          ),
        )),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _results = null),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  for (final t in tasksData) {
                    ref.read(tasksProvider.notifier).addTask(Task(
                      id: AppUtils.generateId(prefix: 'task'),
                      title: t['title'] ?? '',
                      date: DateTime.now().add(const Duration(days: 1)),
                      priority: TaskPriority.values[(t['priority'] as int? ?? 1).clamp(0, 2)],
                      category: t['category'] ?? 'Work',
                    ));
                  }
                  Navigator.pop(context);
                  ref.read(feedbackProvider.notifier).showMessage('Added plan to your tasks!');
                },
                child: const Text('Add to Tasks'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
