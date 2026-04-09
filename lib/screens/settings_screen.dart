import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';
import '../providers/auth_provider.dart';
import '../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final userEmail = ref.watch(userEmailProvider);
    final userPhoto = ref.watch(userPhotoProvider);
    final settings = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Back Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const GlassContainer(
                      padding: EdgeInsets.all(10),
                      borderRadius: 12,
                      child: Icon(LucideIcons.chevronLeft, size: 20),
                    ),
                  ),
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 44), // Placeholder for balance
                ],
              ),
              const SizedBox(height: 40),

              // Profile Section
              _buildProfileHeader(context, ref, userName, userEmail, userPhoto),
              const SizedBox(height: 32),

              // Settings Sections
              _buildSectionTitle(context, 'Intelligence'),
              const SizedBox(height: 12),
              _buildSettingItem(
                context,
                icon: LucideIcons.zap,
                title: 'Auto-Intelligence Mode',
                subtitle: settings.isAutoAI ? 'Managing speed & quality automatically' : 'Manual engine selection',
                trailing: Switch(
                  value: settings.isAutoAI,
                  onChanged: (v) {
                    HapticFeedback.mediumImpact();
                    settingsNotifier.updateAutoAI(v);
                  },
                  activeTrackColor: AppColors.tertiary.withValues(alpha: 0.5),
                  activeThumbColor: AppColors.tertiary,
                ),
              ),
              _buildSettingItem(
                context,
                icon: LucideIcons.cpu,
                title: 'Intelligence Engine',
                subtitle: _getModelFriendlyName(settings.aiModelId),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _showSelectionDialog(
                    context,
                    'Select Intelligence Engine',
                    [
                      'Gemini 3.1 Pro (Deep Think)',
                      'Gemini 3.1 Flash (High Speed)',
                      'Llama 3.3 70B (Balanced Power)',
                      'Mistral Large 3 (Creative)',
                      'Llama 3.1 8B (Hyper Speed)',
                    ],
                    _getModelFriendlyName(settings.aiModelId),
                    (v) {
                      HapticFeedback.mediumImpact();
                      settingsNotifier.updateAIModel(_getModelIdFromName(v));
                    },
                  );
                },
              ),
              _buildSettingItem(
                context,
                icon: LucideIcons.brain,
                title: 'Smart Task Analysis',
                subtitle: 'AI-powered task decomposition',
                trailing: Switch(
                  value: settings.smartAnalysis,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    settingsNotifier.updateSmartAnalysis(v);
                  },
                  activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  activeThumbColor: Theme.of(context).colorScheme.primary,
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
                    ['Professional', 'Creative', 'Friendly', 'Concise'],
                    settings.aiTone,
                    (v) {
                      HapticFeedback.mediumImpact();
                      settingsNotifier.updateAITone(v);
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              _buildSectionTitle(context, 'Preferences'),
              const SizedBox(height: 12),
              _buildSettingItem(
                context,
                icon: LucideIcons.bell,
                title: 'Notifications',
                subtitle: settings.notificationsEnabled ? 'Enabled' : 'Disabled',
                trailing: Switch(
                  value: settings.notificationsEnabled,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    settingsNotifier.updateNotifications(v);
                  },
                  activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
              ),
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
                    (v) {
                      HapticFeedback.mediumImpact();
                      settingsNotifier.updateTheme(v);
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              _buildSectionTitle(context, 'Account & Privacy'),
              const SizedBox(height: 12),
              _buildSettingItem(
                context,
                icon: LucideIcons.shieldCheck,
                title: 'Privacy Policy',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy Policy coming soon!')),
                  );
                },
              ),
              _buildSettingItem(
                context,
                icon: LucideIcons.database,
                title: 'Data Sync',
                subtitle: 'Synced with Firebase',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data synced successfully!')),
                  );
                },
              ),
              const SizedBox(height: 40),

              // Logout Button
              GlassContainer(
                color: AppColors.error,
                opacity: 0.1,
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => _showSignOutDialog(context, ref),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.logOut, color: AppColors.error, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Sign Out',
                          style: GoogleFonts.inter(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),
              
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Obsidian AI v1.0.0',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref, String name, String email, String? photo) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), width: 2),
              image: photo != null 
                ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover)
                : null,
            ),
            child: photo == null 
              ? Icon(LucideIcons.user, color: Theme.of(context).colorScheme.primary, size: 30)
              : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Premium Member',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.tertiary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.edit3, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onPressed: () => _showEditProfileDialog(context, ref, name),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await ref.read(authServiceProvider).updateDisplayName(controller.text);
                if (context.mounted) Navigator.pop(context);
                // Trigger profile refresh in UI
                ref.invalidate(userNameProvider);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSelectionDialog(
    BuildContext context, 
    String title, 
    List<String> options, 
    String currentSelection,
    Function(String) onSelect,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
        content: RadioGroup<String>(
          groupValue: currentSelection,
          onChanged: (value) {
            if (value != null) {
              onSelect(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) => RadioListTile<String>(
              title: Text(option),
              value: option,
              activeColor: Theme.of(context).colorScheme.primary,
            )).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          letterSpacing: 1.5,
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 20),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          trailing: trailing ?? Icon(LucideIcons.chevronRight, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05);
  }

  String _getModelFriendlyName(String id) {
    switch (id) {
      case 'gemini-3.1-pro-preview': return 'Gemini 3.1 Pro (Deep Think)';
      case 'gemini-3.1-flash-lite-preview': return 'Gemini 3.1 Flash (High Speed)';
      case 'llama-3.3-70b-versatile': return 'Llama 3.3 70B (Balanced Power)';
      case 'openai/gpt-oss-120b': return 'OpenAI GPT-OSS 120B (Premium Reasoning)';
      case 'mistralai/mistral-large-2411': return 'Mistral Large 3 (Creative)';
      case 'llama-3.1-8b-instant': return 'Llama 3.1 8B (Hyper Speed)';
      default: return 'Gemini 3.1 Flash (High Speed)';
    }
  }

  String _getModelIdFromName(String name) {
    if (name.contains('Gemini 3.1 Pro')) return 'gemini-3.1-pro-preview';
    if (name.contains('Gemini 3.1 Flash')) return 'gemini-3.1-flash-lite-preview';
    if (name.contains('Llama 3.3 70B')) return 'llama-3.3-70b-versatile';
    if (name.contains('GPT-OSS')) return 'openai/gpt-oss-120b';
    if (name.contains('Mistral Large 3')) return 'mistralai/mistral-large-2411';
    if (name.contains('Llama 3.1 8B')) return 'llama-3.1-8b-instant';
    return 'gemini-3.1-flash-lite-preview';
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close settings
              ref.read(authServiceProvider).signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
