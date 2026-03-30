import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(collectionProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'BEYBLADE X',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: BeybladeTheme.accent,
                      letterSpacing: 4,
                    ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.3),
              Text(
                'MANAGER',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: BeybladeTheme.textSecondary,
                      letterSpacing: 8,
                    ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
              const SizedBox(height: 40),
              Expanded(
                child: collectionAsync.when(
                  data: (collection) {
                    final totalParts = collection.parts.fold<int>(0, (sum, p) => sum + p.quantity);
                    final deckCount = collection.decks.length;
                    final wishlistCount = collection.wishlist.length;

                    return GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.1,
                      children: [
                        _MenuCard(icon: Icons.collections_bookmark, label: 'Collezione', badge: '$totalParts parti', color: BeybladeTheme.secondary, onTap: () => context.go('/collection')),
                        _MenuCard(icon: Icons.style, label: 'Deck', badge: '$deckCount deck', color: BeybladeTheme.primary, onTap: () => context.go('/deck')),
                        _MenuCard(icon: Icons.analytics, label: 'Analisi', badge: null, color: const Color(0xFF2ECC71), onTap: () => context.go('/analysis')),
                        _MenuCard(icon: Icons.favorite, label: 'Wishlist', badge: wishlistCount > 0 ? '$wishlistCount' : null, color: const Color(0xFFE63946), onTap: () => context.go('/wishlist')),
                        _MenuCard(icon: Icons.settings, label: 'Impostazioni', badge: null, color: BeybladeTheme.textSecondary, onTap: () => context.go('/settings')),
                      ].animate(interval: 100.ms).fadeIn(duration: 300.ms).slideY(begin: 0.2),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Errore nel caricamento')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({required this.icon, required this.label, this.badge, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
              if (badge != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                  child: Text(badge!, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
