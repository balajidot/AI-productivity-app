import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/constants.dart';
import '../../../core/providers/shared_prefs_provider.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/services/notification_service.dart';
import '../../chat/presentation/feedback_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Selection state for Screen 2
  final Set<String> _selectedCategories = {};

  // Selection state for Screen 3
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _reminderEnabled = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    
    try {
      // 1. Save data
      await prefs.setStringList('onboarding_categories', _selectedCategories.toList());
      await prefs.setInt('reminder_hour', _selectedTime.hour);
      await prefs.setInt('reminder_minute', _selectedTime.minute);
      await prefs.setBool('reminder_enabled', _reminderEnabled);
      await prefs.setBool('onboarding_complete', true);

      // 2. Schedule notification if enabled
      if (_reminderEnabled) {
        await NotificationService().scheduleDailyReminder(
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
        );
      }

      // 3. Navigate to MainNavigation
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } catch (e) {
      ref.read(feedbackProvider.notifier).showMessage('Error saving onboarding data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomeScreen(theme),
                  _buildCategoryScreen(theme),
                  _buildReminderScreen(theme),
                ],
              ),
            ),
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.sparkles,
            size: 100,
            color: Colors.amber,
          ),
          const SizedBox(height: 32),
          Text(
            'Meet Zeno',
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your intelligent productivity companion. Tasks, habits, focus — all in one place.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryScreen(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you want to achieve?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the areas you want to focus on.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AppConstants.taskCategories.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return FilterChip(
                label: Text(category),
                avatar: Icon(
                  _getCategoryIcon(category),
                  size: 18,
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.remove(category);
                    }
                  });
                },
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderScreen(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When should I brief you?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'I\'ll send you a daily summary of your upcoming tasks and priorities.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                if (_reminderEnabled) InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (picked != null) {
                      setState(() => _selectedTime = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Text(
                      _selectedTime.format(context),
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Enable Daily Briefing',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _reminderEnabled,
                      onChanged: (value) => setState(() => _reminderEnabled = value),
                    ),
                  ],
                ),
                if (!_reminderEnabled) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'No thanks, I\'ll check tasks manually.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    bool canContinue = true;
    if (_currentPage == 1 && _selectedCategories.isEmpty) {
      canContinue = false;
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: canContinue ? _nextPage : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _currentPage == 0 
                    ? 'Get Started →' 
                    : _currentPage == 1 
                        ? 'Continue →' 
                        : 'Start my journey →',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_currentPage == 1) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _nextPage,
              child: Text(
                'Skip for now',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Work': return LucideIcons.briefcase;
      case 'Personal': return LucideIcons.user;
      case 'Health': return LucideIcons.heart;
      case 'Study': return LucideIcons.bookOpen;
      case 'Finance': return LucideIcons.wallet;
      case 'Inbox': return LucideIcons.inbox;
      default: return LucideIcons.sparkles;
    }
  }
}
