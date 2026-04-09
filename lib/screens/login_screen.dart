import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_container.dart';
import '../theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF020617),
                ],
              ),
            ),
          ),
          
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo / Icon
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Image.file(
                              // Using the generated premium logo path
                              File('C:/Users/acer/.gemini/antigravity/brain/84557f4d-862a-4173-ba0e-05e68b89c66a/google_obsidian_logo_1775731529907.png'),
                              width: 80,
                              height: 80,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                LucideIcons.layoutGrid,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 800.ms).scale(delay: 200.ms),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Text(
                        'Obsidian AI',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          letterSpacing: -1,
                        ),
                      ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Premium AI Productivity & Focus',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
                      
                      const SizedBox(height: 64),
                      
                      // Login Button
                      GlassContainer(
                        padding: EdgeInsets.zero,
                        child: InkWell(
                          onTap: _isLoading ? null : _handleGoogleSignIn,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 64,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(LucideIcons.chrome, size: 24),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Continue with Google',
                                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        'Secure cloud synchronization enabled',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ).animate().fadeIn(delay: 800.ms),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
