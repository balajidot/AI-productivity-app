import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../chat_provider.dart';
import '../feedback_provider.dart';
import '../ai_usage_provider.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../../../settings/presentation/paywall_screen.dart';
import '../../../tasks/presentation/task_provider.dart';

class NaturalLanguageInputBar extends ConsumerStatefulWidget {
  const NaturalLanguageInputBar({super.key});

  @override
  ConsumerState<NaturalLanguageInputBar> createState() =>
      _NaturalLanguageInputBarState();
}

class _NaturalLanguageInputBarState
    extends ConsumerState<NaturalLanguageInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isProcessing) return;

    final usage = ref.read(aiUsageProvider);
    final isPremium = ref.read(isPremiumProvider);

    if (!isPremium && usage.isLimitReached) {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const PaywallScreen(),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final aiService = ref.read(aiServiceProvider);

      // Parse task via AI
      final parsedTask = await aiService.parseTaskFromNaturalLanguage(text);

      if (parsedTask != null && mounted) {
        // Success Haptic
        HapticFeedback.mediumImpact();

        // Add task (Optimistic UI handled by the provider)
        await ref.read(tasksProvider.notifier).addTask(parsedTask);

        // Record AI usage for free users
        ref.read(aiUsageProvider.notifier).recordMessageSent();

        _controller.clear();
        _focusNode.unfocus();

        if (!mounted) return;
        // Show success indicator via feedbackProvider
        ref.read(feedbackProvider.notifier).showMessage('Task added: ${parsedTask.title}');
      }
    } catch (e) {
      if (mounted) {
        ref.read(feedbackProvider.notifier).showError('Failed to add task. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFocused = _focusNode.hasFocus;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isFocused
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(
              LucideIcons.sparkles,
              size: 20,
              color: isFocused
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Ask Zeno or add a task...',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                style: theme.textTheme.bodyLarge,
                onSubmitted: (_) => _handleSubmit(),
              ),
            ),
            const SizedBox(width: 8),
            _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: _controller.text.trim().isNotEmpty ? _handleSubmit : null,
                    icon: Icon(
                      LucideIcons.arrowUp,
                      color: _controller.text.trim().isNotEmpty
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.3,
                            ),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _controller.text.trim().isNotEmpty
                          ? theme.colorScheme.primaryContainer
                          : Colors.transparent,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
