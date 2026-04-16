import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'subscription_provider.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subState = ref.watch(subscriptionProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obsidian Pro'),
        centerTitle: true,
      ),
      body: subState.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(LucideIcons.sparkles, size: 80, color: Colors.amber),
                const SizedBox(height: 24),
                Text(
                  'Unlock Your Full Potential',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (subState.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    subState.error!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 40),
                _buildFeatureRow(context, LucideIcons.barChart2, 'Weekly AI Reports', 
                    'Deep dive into your weekly habits & wins.'),
                _buildFeatureRow(context, LucideIcons.target, 'Goal Decomposer', 
                    'Break massive goals into daily tasks.'),
                _buildFeatureRow(context, LucideIcons.brain, 'Obsidian Pro Model', 
                    'Access to our most advanced reasoning model.'),
                const SizedBox(height: 40),
                
                if (subState.isPro) ...[
                  const Icon(LucideIcons.checkCircle, color: Colors.green, size: 48),
                  const SizedBox(height: 12),
                  Text('Pro Activated!', style: theme.textTheme.titleMedium),
                ] else if (subState.products.isEmpty) ...[
                  const Text('No products available in the store at the moment.'),
                ] else ...[
                  ...subState.products.map((product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: () => ref.read(subscriptionProvider.notifier).subscribe(product),
                        child: Text('Upgrade for ${product.price} / ${product.id.contains('yearly') ? 'year' : 'month'}'),
                      ),
                    ),
                  )),
                ],
                
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.read(subscriptionProvider.notifier).restore(),
                  child: const Text('Restore Purchases'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Maybe later'),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String title, String sub) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
                Text(sub, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
