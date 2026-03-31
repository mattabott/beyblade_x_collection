import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';
import 'package:beyblade_x_collection/presentation/widgets/part_card.dart';

class AddPartScreen extends ConsumerStatefulWidget {
  const AddPartScreen({super.key});
  @override
  ConsumerState<AddPartScreen> createState() => _AddPartScreenState();
}

class _AddPartScreenState extends ConsumerState<AddPartScreen> {
  PartCategory _selectedCategory = PartCategory.blade;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(partsDatabaseProvider);
    final collectionAsync = ref.watch(collectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aggiungi Parti'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: PartCategory.values.map((cat) {
                final isSelected = cat == _selectedCategory;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(
                        cat.name[0].toUpperCase() + cat.name.substring(1),
                      ),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                      selectedColor: BeybladeTheme.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cerca...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: dbAsync.when(
              data: (db) {
                final Map<String, PartStats> partsMap =
                    switch (_selectedCategory) {
                  PartCategory.blade => db.blades,
                  PartCategory.ratchet => db.ratchets,
                  PartCategory.bit => db.bits,
                };
                var entries = partsMap.entries.where((e) {
                  if (_searchQuery.isEmpty) return true;
                  return e.key
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                }).toList();
                entries.sort((a, b) => a.key.compareTo(b.key));

                return collectionAsync.when(
                  data: (collection) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final owned = collection.parts
                            .where((p) =>
                                p.name == entry.key &&
                                p.category == _selectedCategory)
                            .fold<int>(0, (sum, p) => sum + p.quantity);
                        return PartCard(
                          name: entry.key,
                          stats: entry.value,
                          quantity: owned > 0 ? owned : null,
                          onTap: () {
                            ref
                                .read(collectionProvider.notifier)
                                .addPart(entry.key, _selectedCategory);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${entry.key} aggiunto!'),
                                duration: const Duration(seconds: 1),
                                backgroundColor: BeybladeTheme.primary,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Errore caricamento DB')),
            ),
          ),
        ],
      ),
    );
  }
}
