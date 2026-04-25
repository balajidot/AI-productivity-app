import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../tasks/presentation/task_provider.dart';
import '../../settings/presentation/settings_provider.dart';
import 'paywall_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/constants.dart';
import '../../chat/presentation/feedback_provider.dart';
import '../../../core/utils/service_failure.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final userEmail = ref.watch(userEmailProvider);
    final userPhoto = ref.watch(userPhotoProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              RepaintBoundary(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.chevronLeft, size: 20),
                      ),
                    ),
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              RepaintBoundary(
                child: _buildProfileHeader(
                  context,
                  ref,
                  userName,
                  userEmail,
                  userPhoto,
                ),
              ),
              const SizedBox(height: 32),
              RepaintBoundary(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'Intelligence'),
                    const SizedBox(height: 12),
                    Consumer(
                      builder: (context, ref, child) {
                        final settings = ref.watch(appSettingsProvider);
                        final settingsNotifier = ref.read(
                          appSettingsProvider.notifier,
                        );

                        return _buildSettingsGroup(
                          context,
                          items: [
                            _buildSettingItem(
                              context,
                              icon: LucideIcons.brain,
                              title: 'Smart Task Analysis',
                              subtitle: 'AI-powered task decomposition',
                              trailing: Switch(
                                value: settings.smartAnalysis,
                                onChanged: (value) {
                                  HapticFeedback.lightImpact();
                                  settingsNotifier.updateSmartAnalysis(value);
                                },
                                activeTrackColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.5),
                                activeThumbColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                            ),
                            _buildSettingItem(
                              context,
                              icon: LucideIcons.sparkles,
                              title: 'AI Persona Tone',
                              subtitle: settings.aiTone,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _showSelectionDialog(
                                  context,
                                  'Select Assistant Tone',
                                  [
                                    'Professional',
                                    'Creative',
                                    'Friendly',
                                    'Concise',
                                  ],
                                  settings.aiTone,
                                  (value) {
                                    HapticFeedback.mediumImpact();
                                    settingsNotifier.updateAITone(value);
                                  },
                                );
                              },
                            ),
                            _buildSettingItem(
                              context,
                              icon: LucideIcons.bot,
                              title: 'AI Intelligence Model',
                              subtitle:
                                  AppConstants.modelLabels[settings
                                      .aiModelId] ??
                                  settings.aiModelId,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _showSelectionDialog(
                                  context,
                                  'Select AI Model',
                                  AppConstants.modelLabels.keys.toList(),
                                  settings.aiModelId,
                                  (value) {
                                    HapticFeedback.mediumImpact();
                                    settingsNotifier.updateAiModel(value);
                                  },
                                  labels: AppConstants.modelLabels,
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              RepaintBoundary(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'Preferences'),
                    const SizedBox(height: 12),
                    Consumer(
                      builder: (context, ref, child) {
                        final settings = ref.watch(appSettingsProvider);
                        final settingsNotifier = ref.read(
                          appSettingsProvider.notifier,
                        );

                        return _buildSettingsGroup(
                          context,
                          items: [
                            _buildSettingItem(
                              context,
                              icon: LucideIcons.moon,
                              title: 'Focus Theme',
                              subtitle: settings.themeMode,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _showSelectionDialog(
                                  context,
                                  'Select Theme',
                                  ['Light', 'Dark', 'System'],
                                  settings.themeMode,
                                  (value) {
                                    HapticFeedback.mediumImpact();
                                    settingsNotifier.updateTheme(value);
                                  },
                                );
                              },
                            ),
                            _buildSettingItem(
                              context,
                              icon: LucideIcons.eyeOff,
                              title: 'Hide Completed Tasks',
                              subtitle: 'Clean up your daily flow',
                              trailing: Switch(
                                value: settings.hideCompletedTasks,
                                onChanged: (value) {
                                  HapticFeedback.lightImpact();
                                  settingsNotifier.updateHideCompletedTasks(
                                    value,
                                  );
                                },
                                activeTrackColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.5),
                                activeThumbColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              RepaintBoundary(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'Focus Timer'),
                    const SizedBox(height: 12),
                    Consumer(
                      builder: (context, ref, child) {
                        final settings = ref.watch(appSettingsProvider);
                        final notifier = ref.read(appSettingsProvider.notifier);
                        return _buildSettingsGroup(
                          context,
                          items: [
                            _buildSettingItem(
                              context,
                              icon: LucideIcons.timer,
                              title: 'Work Duration',
                              subtitle: '${settings.pomodoroDuration} min',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _showSelectionDialog(
                                  context,
                                  'Work Duration',
                                  ['15', '20', '25', '30', '45', '60'],
                                  settings.pomodoroDuration.toString(),
                                  (value) {
                                    final v = int.tryParse(value);
                                    if (v != null) {
                                      notifier.updatePomodoroDuration(v);
                                    }
                                  },
                                  labels: {
                                    '15': '15 min',
                                    '20': '20 min',
                                    '25': '25 min (default)',
                                    '30': '30 min',
                                    '45': '45 min',
                                    '60': '60 min',
                                  },
                                );
                              },
                            ),
                            _buildSettingItem(
                              context,
                              icon: LucideIcons.coffee,
                              title: 'Short Break',
                              subtitle: '${settings.shortBreakDuration} min',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _showSelectionDialog(
                                  context,
                                  'Short Break',
                                  ['3', '5', '10'],
                                  settings.shortBreakDuration.toString(),
                                  (value) {
                                    final v = int.tryParse(value);
                                    if (v != null) {
                                      notifier.updateShortBreakDuration(v);
                                    }
                                  },
                                  labels: {
                                    '3': '3 min',
                                    '5': '5 min (default)',
                                    '10': '10 min',
                                  },
                                );
                              },
                            ),
                            _buildSettingItem(
                              context,
                              icon: LucideIcons.batteryCharging,
                              title: 'Long Break',
                              subtitle: '${settings.longBreakDuration} min',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _showSelectionDialog(
                                  context,
                                  'Long Break',
                                  ['10', '15', '20', '30'],
                                  settings.longBreakDuration.toString(),
                                  (value) {
                                    final v = int.tryParse(value);
                                    if (v != null) {
                                      notifier.updateLongBreakDuration(v);
                                    }
                                  },
                                  labels: {
                                    '10': '10 min',
                                    '15': '15 min (default)',
                                    '20': '20 min',
                                    '30': '30 min',
                                  },
                                );
                              },
                            ),
                            _buildSettingItem(
                              context,
                              icon: LucideIcons.moon,
                              title: 'Strict Mode (Zen Mode)',
                              subtitle: 'Fails Pomodoro if app is minimized',
                              trailing: Switch(
                                value: settings.zenModeEnabled,
                                onChanged: (value) {
                                  HapticFeedback.lightImpact();
                                  notifier.updateZenMode(value);
                                },
                                activeTrackColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.5),
                                activeThumbColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              RepaintBoundary(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'Account & Privacy'),
                    const SizedBox(height: 12),
                    _buildSettingsGroup(
                      context,
                      items: [
                        _buildSettingItem(
                          context,
                          icon: LucideIcons.shieldCheck,
                          title: 'Privacy Policy',
                          onTap: () {
                            ref.read(feedbackProvider.notifier).showMessage(
                              'Privacy Policy coming soon!',
                            );
                          },
                        ),
                        _buildSettingItem(
                          context,
                          icon: LucideIcons.database,
                          title: 'Data Sync',
                          subtitle: 'Synced with Firebase',
                          onTap: () async {
                            await ref.read(tasksProvider.notifier).refresh();
                            ref.read(feedbackProvider.notifier).showMessage(
                              'Latest tasks synced successfully.',
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              RepaintBoundary(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _showSignOutDialog(context, ref),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.logOut,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Sign Out',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Zeno v1.0.0',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    String name,
    String email,
    String? photo,
  ) {
    final headerContent = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'user_avatar',
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: photo != null
                    ? Image.network(
                        photo,
                        fit: BoxFit.cover,
                        cacheWidth:
                            210, // Optimized for 70dp display at 3x scale
                        cacheHeight: 210,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          LucideIcons.user,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        ),
                      )
                    : Icon(
                        LucideIcons.user,
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, _) {
                    final isPremium = ref.watch(isPremiumProvider);
                    if (isPremium) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.checkCircle,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Zeno Pro ✦',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.crown,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Free Plan',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const PaywallScreen(),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Upgrade',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                LucideIcons.chevronRight,
                                size: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              LucideIcons.edit3,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () => _showEditProfileDialog(context, ref, name),
          ),
        ],
      ),
    );

    return headerContent;
  }

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Edit Profile',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 20),
        ),
        content: TextField(
          controller: controller,
          textInputAction: TextInputAction.done,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final trimmedName = controller.text.trim();

                if (trimmedName.isEmpty) {
                  ref.read(feedbackProvider.notifier).showMessage(
                    'Display name cannot be empty.',
                  );
                  return;
                }

              if (trimmedName == currentName.trim()) {
                Navigator.pop(dialogContext);
                return;
              }

              try {
                await ref
                    .read(authServiceProvider)
                    .updateDisplayName(trimmedName);
                ref.read(profileRefreshProvider.notifier).bump();

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                ref.read(feedbackProvider.notifier).showMessage(
                  'Profile updated successfully.',
                );
              } on FirebaseAuthException catch (error) {
                ref.read(feedbackProvider.notifier).showError(
                  ServiceFailure.fromAuth(error),
                );
              } catch (_) {
                ref.read(feedbackProvider.notifier).showMessage(
                  'Profile update failed.',
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) {
      controller.dispose();
    });
  }

  void _showSelectionDialog(
    BuildContext context,
    String title,
    List<String> options,
    String currentSelection,
    Function(String) onSelect, {
    Map<String, String>? labels,
  }) {
    String selectedValue = currentSelection;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 20),
          ),
          content: RadioGroup<String>(
            groupValue: selectedValue,
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedValue = value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options
                  .map(
                    (option) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(labels?[option] ?? option),
                      leading: Radio<String>(value: option),
                      onTap: () => setState(() => selectedValue = option),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedValue != currentSelection) {
                  onSelect(selectedValue);
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context, {
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.zero,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 52,
                  endIndent: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurface,
        size: 20,
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing:
          trailing ??
          Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Sign Out',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 20),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authServiceProvider).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
