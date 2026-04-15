import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/ai_action_model.dart';

// AIActionCard now uses Material 3 surface containers.

class AIActionCard extends StatelessWidget {
  final String messageId;
  final AIAction action;
  final Function(String, String, {Map<String, dynamic>? options}) onApprove;
  final Function(String, String) onReject;

  const AIActionCard({
    super.key,
    required this.messageId,
    required this.action,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = action.isExecuted;
    final isRejected = action.isRejected;

    try {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDone 
              ? Colors.green.withValues(alpha: 0.1) 
              : (isRejected ? Colors.red.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainer),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone 
                ? Colors.green.withValues(alpha: 0.2) 
                : (isRejected ? Colors.red.withValues(alpha: 0.2) : theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIcon(),
                  size: 20,
                  color: isDone ? Colors.green : (isRejected ? Colors.red : theme.colorScheme.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getTitle(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (isDone)
                  const Icon(LucideIcons.checkCircle, color: Colors.green, size: 16)
                else if (isRejected)
                  const Icon(LucideIcons.xCircle, color: Colors.red, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetails(theme),
            if (!isDone && !isRejected) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => onReject(messageId, action.id),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => onApprove(messageId, action.id),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    } catch (e) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: theme.colorScheme.error, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Proposed action formatting error. Please try again.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  IconData _getIcon() {
    switch (action.type) {
      case AIActionType.createTask:
      case AIActionType.createBulkTasks:
        return LucideIcons.plusCircle;
      case AIActionType.updateTask:
        return LucideIcons.edit3;
      case AIActionType.deleteTasks:
        return LucideIcons.trash2;
      case AIActionType.suggestion:
        return LucideIcons.helpCircle;
      default:
        return LucideIcons.activity;
    }
  }

  String _getTitle() {
    switch (action.type) {
      case AIActionType.createTask:
        return 'Proposed Task';
      case AIActionType.createBulkTasks:
        return 'Plan Execution Deck';
      case AIActionType.updateTask:
        return 'Update Task';
      case AIActionType.deleteTasks:
        return 'Batch Delete';
      case AIActionType.suggestion:
        return 'Obsidian Suggests';
      default:
        return 'System Action';
    }
  }

  Widget _buildDetails(ThemeData theme) {
    final p = action.parameters;
    List<Widget> children = [];

    if (action.type == AIActionType.createTask) {
      children = [
        _detailRow(LucideIcons.type, p['title']?.toString() ?? 'Untitled', theme),
        _detailRow(LucideIcons.calendar, p['date']?.toString() ?? 'No date', theme),
        if (p['time'] != null) _detailRow(LucideIcons.clock, p['time'].toString(), theme),
        _detailRow(LucideIcons.layers, p['category']?.toString() ?? 'Inbox', theme),
      ];
    } else if (action.type == AIActionType.createBulkTasks) {
      final rawTasks = p['tasks'];
      final List tasks = rawTasks is List ? rawTasks : [];
      
      children = [
        Text(
          'Strategic breakdown: ${tasks.length} sub-tasks identified.',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...tasks.take(5).map((t) {
          String title = 'Subtask';
          if (t is Map) {
            title = t['title']?.toString() ?? 'Subtask';
          } else if (t is String) {
            title = t;
          }
          return _detailRow(LucideIcons.arrowRight, title, theme);
        }),
        if (tasks.length > 5)
          _detailRow(LucideIcons.moreHorizontal, '+ ${tasks.length - 5} more steps', theme),
      ];
    } else if (action.type == AIActionType.updateTask) {
      children = [
        _detailRow(LucideIcons.info, 'Task ID: ${p['id']}', theme),
        if (p['title'] != null) _detailRow(LucideIcons.edit2, 'New Title: ${p['title']}', theme),
        if (p['status'] != null) _detailRow(LucideIcons.checkCircle, 'New Status: ${p['status']}', theme),
      ];
    } else if (action.type == AIActionType.deleteTasks) {
      final rawIds = p['ids'];
      final idsCount = rawIds is List ? rawIds.length : 0;
      children = [_detailRow(LucideIcons.trash2, 'Deleting $idsCount tasks permanently.', theme)];
    } else if (action.type == AIActionType.suggestion) {
      final prompt = p['prompt']?.toString() ?? 'Select an option:';
      final rawOptions = p['options'];
      final List options = rawOptions is List ? rawOptions : [];
      
      children = [
        _detailRow(LucideIcons.messageSquare, prompt, theme),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            String label = 'Option';
            if (opt is Map) {
              label = opt['label']?.toString() ?? 'Option';
            } else if (opt is String) {
              label = opt;
            }
            
            return ElevatedButton(
              onPressed: () {
                onApprove(messageId, action.id, options: opt is Map<String, dynamic> ? opt : {'value': opt.toString()}); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(label),
            );
          }).toList(),
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _detailRow(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
