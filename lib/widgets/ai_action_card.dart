import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/ai_action_model.dart';
import 'glass_container.dart';

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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: GlassContainer(
        color: isDone 
            ? Colors.green.withValues(alpha: 0.1) 
            : (isRejected ? Colors.red.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainer),
        opacity: 0.8,
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
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
                Text(
                  _getTitle(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
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
                    child: ElevatedButton(
                      onPressed: () => onApprove(messageId, action.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 0,
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
      ),
    );
  }

  IconData _getIcon() {
    switch (action.type) {
      case AIActionType.createTask:
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
    } else if (action.type == AIActionType.updateTask) {
      children = [
        _detailRow(LucideIcons.info, 'Task ID: ${action.parameters['id']}', theme),
        if (p['title'] != null) _detailRow(LucideIcons.edit2, 'New Title: ${p['title']}', theme),
        if (p['status'] != null) _detailRow(LucideIcons.checkCircle, 'New Status: ${p['status']}', theme),
      ];
    } else if (action.type == AIActionType.deleteTasks) {
      final ids = (p['ids'] as List?)?.length ?? 0;
      children = [_detailRow(LucideIcons.trash2, 'Deleting $ids tasks permanently.', theme)];
    } else if (action.type == AIActionType.suggestion) {
      final prompt = p['prompt']?.toString() ?? 'Select an option:';
      final options = (p['options'] as List?) ?? [];
      
      children = [
        _detailRow(LucideIcons.messageSquare, prompt, theme),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final label = opt['label']?.toString() ?? 'Option';
            return ElevatedButton(
              onPressed: () {
                onApprove(messageId, action.id, options: opt); 
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
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
