import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';
import 'package:beyblade_x_collection/data/models/user_collection.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';
import 'package:beyblade_x_collection/presentation/widgets/part_card.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});
  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionAsync = ref.watch(collectionProvider);
    final dbAsync = ref.watch(partsDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('La Mia Collezione'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Blade'),
            Tab(text: 'Ratchet'),
            Tab(text: 'Bit'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/collection/add'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Cerca parti...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String?>(
                  icon: Icon(
                    Icons.filter_list,
                    color: _typeFilter != null
                        ? BeybladeTheme.accent
                        : BeybladeTheme.textSecondary,
                  ),
                  onSelected: (v) => setState(() => _typeFilter = v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: null, child: Text('Tutti')),
                    const PopupMenuItem(
                        value: 'Attack', child: Text('Attack')),
                    const PopupMenuItem(
                        value: 'Defense', child: Text('Defense')),
                    const PopupMenuItem(
                        value: 'Stamina', child: Text('Stamina')),
                    const PopupMenuItem(
                        value: 'Balance', child: Text('Balance')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: collectionAsync.when(
              data: (collection) => dbAsync.when(
                data: (db) => TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPartsList(collection, db, PartCategory.blade),
                    _buildPartsList(collection, db, PartCategory.ratchet),
                    _buildPartsList(collection, db, PartCategory.bit),
                  ],
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const Center(child: Text('Errore caricamento DB')),
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Errore caricamento collezione')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartsList(
    UserCollection collection,
    PartsDatabase db,
    PartCategory category,
  ) {
    final parts = collection.parts
        .where((CollectedPart p) => p.category == category)
        .toList();
    final Map<String, PartStats> statsMap = switch (category) {
      PartCategory.blade => db.blades,
      PartCategory.ratchet => db.ratchets,
      PartCategory.bit => db.bits,
    };

    final filtered = parts.where((CollectedPart p) {
      if (_searchQuery.isNotEmpty &&
          !p.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_typeFilter != null) {
        final stats = statsMap[p.name];
        if (stats != null && stats.type != _typeFilter) return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: BeybladeTheme.textSecondary),
            SizedBox(height: 12),
            Text('Nessuna parte',
                style: TextStyle(color: BeybladeTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final part = filtered[index];
        final stats = statsMap[part.name];
        if (stats == null) return const SizedBox.shrink();
        return PartCard(
          name: part.name,
          stats: stats,
          quantity: part.quantity,
          onLongPress: () => _showPartOptions(context, part),
        );
      },
    );
  }

  void _showPartOptions(BuildContext context, CollectedPart part) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(part.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              if (part.quantity > 1)
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline, color: BeybladeTheme.accent),
                  title: const Text('Rimuovi uno'),
                  subtitle: Text('Quantita attuale: ${part.quantity}'),
                  onTap: () {
                    ref.read(collectionProvider.notifier).removePart(part.name, part.category);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${part.name} ridotto a ${part.quantity - 1}'), backgroundColor: BeybladeTheme.primary),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: BeybladeTheme.secondary),
                title: Text(part.quantity > 1 ? 'Rimuovi tutti' : 'Rimuovi'),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (dlg) => AlertDialog(
                      title: const Text('Conferma'),
                      content: Text('Rimuovere ${part.name} dalla collezione?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dlg), child: const Text('Annulla')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: BeybladeTheme.secondary),
                          onPressed: () {
                            // Remove all quantity
                            for (var i = 0; i < part.quantity; i++) {
                              ref.read(collectionProvider.notifier).removePart(part.name, part.category);
                            }
                            Navigator.pop(dlg);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${part.name} rimosso'), backgroundColor: BeybladeTheme.secondary),
                            );
                          },
                          child: const Text('Rimuovi'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Color(0xFF2ECC71)),
                title: const Text('Aggiungi uno'),
                onTap: () {
                  ref.read(collectionProvider.notifier).addPart(part.name, part.category);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${part.name} ora: ${part.quantity + 1}'), backgroundColor: const Color(0xFF2ECC71)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
