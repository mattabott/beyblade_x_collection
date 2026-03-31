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
        child: collectionAsync.when(
          data: (collection) {
            final totalParts = collection.parts.fold<int>(0, (sum, p) => sum + p.quantity);
            final bladeCount = collection.parts.where((p) => p.category.name == 'blade').fold<int>(0, (s, p) => s + p.quantity);
            final ratchetCount = collection.parts.where((p) => p.category.name == 'ratchet').fold<int>(0, (s, p) => s + p.quantity);
            final bitCount = collection.parts.where((p) => p.category.name == 'bit').fold<int>(0, (s, p) => s + p.quantity);
            final deckCount = collection.decks.length;
            final wishlistCount = collection.wishlist.length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BEYBLADE X',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: BeybladeTheme.accent,
                                letterSpacing: 3,
                                fontSize: 28,
                              ),
                            ),
                            Text(
                              'MANAGER',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: BeybladeTheme.textSecondary,
                                letterSpacing: 6,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Settings icon
                      IconButton(
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.settings, color: BeybladeTheme.textSecondary),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 24),

                  // Hero card - Collection
                  _CollectionHeroCard(
                    totalParts: totalParts,
                    bladeCount: bladeCount,
                    ratchetCount: ratchetCount,
                    bitCount: bitCount,
                    onTap: () => context.push('/collection'),
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1),

                  const SizedBox(height: 14),

                  // Row: Deck + Analisi
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.style,
                          label: 'Deck',
                          subtitle: deckCount > 0 ? '$deckCount deck' : 'Crea il tuo deck',
                          color: BeybladeTheme.primary,
                          height: 130,
                          onTap: () => context.push('/deck'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.analytics,
                          label: 'Analisi',
                          subtitle: 'Confronta e ottimizza',
                          color: const Color(0xFF2ECC71),
                          height: 130,
                          onTap: () => context.push('/analysis'),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1),

                  const SizedBox(height: 14),

                  // Wishlist card
                  _ActionCard(
                    icon: Icons.favorite,
                    label: 'Wishlist',
                    subtitle: wishlistCount > 0 ? '$wishlistCount parti desiderate' : 'Tieni traccia dei tuoi desideri',
                    color: BeybladeTheme.secondary,
                    height: 80,
                    horizontal: true,
                    badgeCount: wishlistCount > 0 ? wishlistCount : null,
                    onTap: () => context.push('/wishlist'),
                  ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Errore nel caricamento')),
        ),
      ),
    );
  }
}

class _CollectionHeroCard extends StatelessWidget {
  final int totalParts;
  final int bladeCount;
  final int ratchetCount;
  final int bitCount;
  final VoidCallback onTap;

  const _CollectionHeroCard({
    required this.totalParts,
    required this.bladeCount,
    required this.ratchetCount,
    required this.bitCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                BeybladeTheme.surface,
                BeybladeTheme.primary.withValues(alpha: 0.3),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: BeybladeTheme.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.collections_bookmark, color: BeybladeTheme.accent, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('La Mia Collezione', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          totalParts > 0 ? '$totalParts parti totali' : 'Inizia ad aggiungere parti',
                          style: const TextStyle(color: BeybladeTheme.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: BeybladeTheme.textSecondary),
                ],
              ),
              if (totalParts > 0) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    _StatChip(label: 'Blade', count: bladeCount, color: BeybladeTheme.secondary),
                    const SizedBox(width: 10),
                    _StatChip(label: 'Ratchet', count: ratchetCount, color: BeybladeTheme.primary),
                    const SizedBox(width: 10),
                    _StatChip(label: 'Bit', count: bitCount, color: const Color(0xFF2ECC71)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final double height;
  final bool horizontal;
  final int? badgeCount;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.height,
    this.horizontal = false,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return SizedBox(
        height: height,
        child: Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
                        Text(subtitle, style: const TextStyle(fontSize: 12, color: BeybladeTheme.textSecondary)),
                      ],
                    ),
                  ),
                  if (badgeCount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                      child: Text('$badgeCount', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: BeybladeTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
