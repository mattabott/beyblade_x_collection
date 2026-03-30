import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});
  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  @override
  Widget build(BuildContext context) {
    final collectionAsync = ref.watch(collectionProvider);
    final dbAsync = ref.watch(partsDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/')),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddToWishlistDialog(context),
          child: const Icon(Icons.add)),
      body: collectionAsync.when(
        data: (collection) => dbAsync.when(
          data: (db) {
            if (collection.wishlist.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border,
                        size: 64, color: BeybladeTheme.textSecondary),
                    SizedBox(height: 12),
                    Text('Wishlist vuota',
                        style:
                            TextStyle(color: BeybladeTheme.textSecondary)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: collection.wishlist.length,
              itemBuilder: (context, index) {
                final partName = collection.wishlist[index];
                PartStats? stats;
                PartCategory? category;
                if (db.blades.containsKey(partName)) {
                  stats = db.blades[partName];
                  category = PartCategory.blade;
                } else if (db.ratchets.containsKey(partName)) {
                  stats = db.ratchets[partName];
                  category = PartCategory.ratchet;
                } else if (db.bits.containsKey(partName)) {
                  stats = db.bits[partName];
                  category = PartCategory.bit;
                }

                return Dismissible(
                  key: Key('wishlist_$partName'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: BeybladeTheme.secondary,
                      child:
                          const Icon(Icons.delete, color: Colors.white)),
                  onDismissed: (_) => ref
                      .read(collectionProvider.notifier)
                      .removeFromWishlist(partName),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: stats != null
                          ? Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                  color: StatUtils.colorForType(stats.type)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.catching_pokemon,
                                  color:
                                      StatUtils.colorForType(stats.type)),
                            )
                          : null,
                      title: Text(partName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: stats?.type != null
                          ? Text(stats!.type!,
                              style: TextStyle(
                                  color:
                                      StatUtils.colorForType(stats.type)))
                          : null,
                      trailing: category != null
                          ? IconButton(
                              icon: const Icon(Icons.add_circle,
                                  color: BeybladeTheme.accent),
                              tooltip: 'Aggiungi alla collezione',
                              onPressed: () {
                                ref
                                    .read(collectionProvider.notifier)
                                    .moveWishlistToCollection(
                                        partName, category!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            '$partName aggiunto alla collezione!'),
                                        backgroundColor:
                                            BeybladeTheme.primary));
                              },
                            )
                          : null,
                    ),
                  ),
                );
              },
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Errore')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Errore')),
      ),
    );
  }

  void _showAddToWishlistDialog(BuildContext context) {
    final db = ref.read(partsDatabaseProvider).value;
    if (db == null) return;
    final allParts = <String>[
      ...db.blades.keys,
      ...db.ratchets.keys,
      ...db.bits.keys
    ]..sort();
    final collection = ref.read(collectionProvider).value;
    final wishlist = collection?.wishlist ?? [];
    final available =
        allParts.where((p) => !wishlist.contains(p)).toList();
    String search = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtered = available
              .where(
                  (p) => p.toLowerCase().contains(search.toLowerCase()))
              .toList();
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            builder: (_, scrollController) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                        hintText: 'Cerca parti...',
                        prefixIcon: Icon(Icons.search)),
                    onChanged: (v) =>
                        setModalState(() => search = v),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final name = filtered[index];
                      return ListTile(
                        title: Text(name),
                        trailing: const Icon(Icons.favorite_border,
                            color: BeybladeTheme.secondary),
                        onTap: () {
                          ref
                              .read(collectionProvider.notifier)
                              .addToWishlist(name);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
