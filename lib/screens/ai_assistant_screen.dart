import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../config/animation_config.dart';
import '../providers/app_providers.dart';
import '../models/app_models.dart';
import '../models/message_model.dart';
import '../widgets/glass_container.dart';
import '../widgets/empty_state.dart';
import '../widgets/ai_action_card.dart';
import '../config/constants.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
    
    if (!mounted) return;
    
    ref.read(chatProvider.notifier).sendMessage(text);
    _controller.clear();
    _scrollToBottom();
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text('This will permanently delete all messages in this conversation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clearChat();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = ref.watch(chatProvider);
    final isLoading = ref.watch(aiLoadingProvider);
    final isLowPerformance = ref.watch(performanceModeProvider);
    final settings = ref.watch(appSettingsProvider);

    // Auto-scroll logic optimized: Only trigger on message length change
    ref.listen<List<AIMessage>>(chatProvider, (previous, next) {
      final prevLen = previous?.length ?? 0;
      final nextLen = next.length;
      
      // If we got a new message OR current message (assistant) is streaming text
      if (nextLen > 0) {
        final lastMsg = next.last;
        final prevLastMsgText = (previous != null && previous.isNotEmpty) ? previous.last.text : '';
        
        if (nextLen > prevLen || (lastMsg.role == MessageRole.assistant && lastMsg.text != prevLastMsgText)) {
          _scrollToBottom();
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, theme),
            _buildIntelligenceTrigger(context, theme, settings),
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
                            .fadeIn(duration: AnimationConfig.standardDuration);
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
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
          GestureDetector(
            onTap: _confirmClearChat,
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

  Widget _buildIntelligenceTrigger(BuildContext context, ThemeData theme, AppSettings settings) {
    final currentModel = AppConstants.availableModels.firstWhere(
      (m) => m['id'] == settings.aiModelId,
      orElse: () => AppConstants.availableModels.first,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: GestureDetector(
        onTap: () => _showIntelligenceHub(context),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          borderRadius: 16,
          color: theme.colorScheme.surfaceContainerHighest,
          opacity: 0.4,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(currentModel['icon'] as IconData, color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          currentModel['name'] as String,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            currentModel['tag'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Tap to change intelligence level',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronDown, size: 16, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  void _showIntelligenceHub(BuildContext context) {
    final theme = Theme.of(context);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);
    final currentModelId = ref.read(appSettingsProvider).aiModelId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          color: theme.colorScheme.surface,
          opacity: 0.98,
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(LucideIcons.brainCircuit, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Strategic Intelligence HUB',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the best AI brain for your current task.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: AppConstants.availableModels.length,
                  itemBuilder: (context, index) {
                    final model = AppConstants.availableModels[index];
                    final isSelected = model['id'] == currentModelId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildIntelligenceCard(context, theme, model, isSelected, () {
                        HapticFeedback.heavyImpact();
                        settingsNotifier.updateAIModel(model['id'] as String);
                        Navigator.pop(context);
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIntelligenceCard(
    BuildContext context, 
    ThemeData theme, 
    Map<String, dynamic> model, 
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withValues(alpha: 0.1) 
              : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary 
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                model['icon'] as IconData, 
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          model['name'] as String,
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            model['tag'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    model['desc'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.4,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (message.modelName ?? '').contains('Gemini') ? LucideIcons.sparkles : LucideIcons.zap, 
                        size: 11, 
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'POWERED BY ',
                        style: GoogleFonts.manrope(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        (message.modelName ?? 'Obsidian AI').toUpperCase(),
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            GlassContainer(
              color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainer,
              opacity: isUser ? 0.3 : 0.7,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 18,
              child: isUser 
                ? Text(
                    message.text,
                    style: GoogleFonts.inter(
                      color: isUser && theme.brightness == Brightness.dark 
                          ? Colors.white 
                          : theme.colorScheme.onSurface,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  )
                : Column(
                    children: [
                      MarkdownBody(
                        data: message.text,
                        builders: {
                          'code': VisualMarkdownBuilder(theme),
                        },
                        styleSheet: MarkdownStyleSheet(
                          p: GoogleFonts.inter(
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          strong: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          listBullet: GoogleFonts.inter(
                            color: theme.colorScheme.primary,
                          ),
                          code: GoogleFonts.firaCode(
                            backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                          codeblockPadding: const EdgeInsets.all(12),
                          codeblockDecoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (message.text.contains('![design]') || message.text.contains('![visual]'))
                        _buildVisualDisplay(message.text, theme),
                    ],
                  ),
            ),
            if (message.actions != null && message.actions!.isNotEmpty) 
              Column(
                children: message.actions!.map((action) => AIActionCard(
                  messageId: message.id,
                  action: action,
                  onApprove: (mId, aId, {options}) => ref.read(chatProvider.notifier).executeAction(mId, aId, parametersOverride: options),
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
        .scaleXY(begin: 0.8, end: 1.0, delay: delayMs.ms, duration: AnimationConfig.slowDuration);
  }

  Widget _buildInputArea(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          GlassContainer(
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
        ],
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
    ).animate().fadeIn(duration: AnimationConfig.standardDuration);
  }
}

class VisualMarkdownBuilder extends MarkdownElementBuilder {
  final ThemeData theme;
  VisualMarkdownBuilder(this.theme);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final language = element.attributes['class'];
    final content = element.textContent;

    if (language == 'language-mermaid' || language == 'language-mindmap') {
      // Encode for mermaid.ink
      final bytes = utf8.encode(content);
      final base64 = base64Url.encode(bytes).replaceAll('=', '');
      final imageUrl = 'https://mermaid.ink/img/$base64';

      return Column(
        children: [
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Icon(LucideIcons.alertTriangle, color: theme.colorScheme.error),
                          const SizedBox(height: 8),
                          Text(
                            'Visual generation failed. The AI provided invalid structure.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black26,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(LucideIcons.maximize2, size: 16, color: Colors.white),
                      onPressed: () {
                        // Maximize image logic
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    }
    return null;
  }
}

extension on _AIAssistantScreenState {
  Widget _buildVisualDisplay(String text, ThemeData theme) {
    // Regex to find ![design](path) or ![visual](path)
    final regExp = RegExp(r'!\[(?:design|visual)\]\((.*?)\)');
    final matches = regExp.allMatches(text);
    
    if (matches.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: matches.map((m) {
          final path = m.group(1) ?? '';
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  width: double.infinity,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.imageOff, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text('Image generation in progress...', style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
