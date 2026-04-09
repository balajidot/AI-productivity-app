import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_providers.dart';
import '../models/message_model.dart';
import '../widgets/glass_container.dart';
import '../widgets/empty_state.dart';
import '../widgets/ai_action_card.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(text);
    _controller.clear();
    _scrollToBottom();
    // Scroll again after response arrives
    Future.delayed(const Duration(milliseconds: 1500), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = ref.watch(chatProvider);
    final isLoading = ref.watch(aiLoadingProvider);
    final isLowPerformance = ref.watch(performanceModeProvider);

    // Auto-scroll when new chunks arrive
    ref.listen(chatProvider, (previous, next) {
      if (next.isNotEmpty && next.last.role == MessageRole.assistant) {
        if (previous == null || previous.isEmpty || previous.last.text != next.last.text) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
               _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, theme),
            Expanded(
              child: messages.isEmpty
                  ? _buildWelcomeMessage(context, theme)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length && isLoading) {
                          return _buildTypingIndicator(theme);
                        }
                        final msg = messages[index];
                        final bubble = _buildChatBubble(context, theme, msg);
                        if (isLowPerformance) return bubble;
                        return bubble
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.03);
                      },
                    ),
            ),
            _buildInputArea(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(10),
            borderRadius: 14,
            color: theme.colorScheme.tertiary,
            opacity: 0.2,
            child: Icon(LucideIcons.sparkles, color: theme.colorScheme.tertiary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Obsidian AI • Online',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Clear chat
          GestureDetector(
            onTap: () {
              ref.read(chatProvider.notifier).clearChat();
            },
            child: GlassContainer(
              padding: const EdgeInsets.all(8),
              borderRadius: 8,
              child: Icon(LucideIcons.trash2, size: 18, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(BuildContext context, ThemeData theme, AIMessage message) {
    final isUser = message.role == MessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GlassContainer(
              color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainer,
              opacity: isUser ? 0.3 : 0.7,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 18,
              child: Text(
                message.text,
                style: GoogleFonts.inter(
                  color: isUser && theme.brightness == Brightness.dark 
                      ? Colors.white 
                      : theme.colorScheme.onSurface,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            if (message.actions != null && message.actions!.isNotEmpty) 
              Column(
                children: message.actions!.map((action) => AIActionCard(
                  messageId: message.id,
                  action: action,
                  onApprove: (mId, aId) => ref.read(chatProvider.notifier).executeAction(mId, aId),
                  onReject: (mId, aId) => ref.read(chatProvider.notifier).rejectAction(mId, aId),
                )).toList(),
              ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _formatTime(message.timestamp),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassContainer(
          color: theme.colorScheme.surfaceContainer,
          opacity: 0.7,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(theme, 0),
              const SizedBox(width: 4),
              _buildDot(theme, 200),
              const SizedBox(width: 4),
              _buildDot(theme, 400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(ThemeData theme, int delayMs) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 0.6, end: 1.0, delay: delayMs.ms, duration: 400.ms);
  }

  Widget _buildInputArea(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: GlassContainer(
        borderRadius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Icon(LucideIcons.paperclip, color: theme.colorScheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Ask anything...',
                  hintStyle: GoogleFonts.inter(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
              ),
            ),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(LucideIcons.send, color: theme.colorScheme.onPrimary, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage(BuildContext context, ThemeData theme) {
    final userName = ref.watch(userNameProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          EmptyStateWidget(
            title: 'Hi $userName! 👋',
            description: 'I can help you manage tasks, plan your day, and boost productivity.',
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 32),

          // Quick suggestion cards
          _buildSuggestionCard(theme,
            'Plan my day',
            'Get a personalized daily plan based on your tasks',
            LucideIcons.calendar,
          ),
          _buildSuggestionCard(theme,
            'Show my pending tasks',
            'See all tasks that need your attention',
            LucideIcons.clipboardList,
          ),
          _buildSuggestionCard(theme,
            'Give me productivity tips',
            'AI-powered tips to optimize your workflow',
            LucideIcons.lightbulb,
          ),
          _buildSuggestionCard(theme,
            'Help me prioritize',
            'Smart priority suggestions for your tasks',
            LucideIcons.target,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(ThemeData theme, String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          _controller.text = title;
          _sendMessage();
        },
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, color: theme.colorScheme.onSurfaceVariant, size: 18),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }
}
