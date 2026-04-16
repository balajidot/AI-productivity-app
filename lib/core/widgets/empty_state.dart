import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String description;
  final String? imagePath;
  final IconData? icon;
  final double iconSize;
  final Color? iconColor;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.description,
    this.imagePath,
    this.icon,
    this.iconSize = 80,
    this.iconColor,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath!,
                height: 180,
                width: 180,
                fit: BoxFit.contain,
              )
            else
              Icon(
                icon ?? LucideIcons.clipboardSignature,
                size: iconSize,
                color: iconColor ?? theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
            const SizedBox(height: 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            if (onActionPressed != null && actionLabel != null) ...[
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(LucideIcons.plus, size: 20),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
