import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/presentation/providers/analysis_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';
import 'package:beyblade_x_collection/presentation/widgets/stat_bar.dart';

class RankPartsScreen extends ConsumerStatefulWidget {
  const RankPartsScreen({super.key});
  @override
  ConsumerState<RankPartsScreen> createState() => _RankPartsScreenState();
}

class _RankPartsScreenState extends ConsumerState<RankPartsScreen> {
  PartCategory _category = PartCategory.blade;
  String _stat = 'attack';
  bool _onlyOwned = false;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(partsDatabaseProvider);
    final collectionAsync = ref.watch(collectionProvider);
    final rankPartsUC = ref.watch(rankPartsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classifica Parti'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/analysis')),
      ),
      body: dbAsync.when(
        data: (db) {
          Map<String, PartStats> partsMap = switch (_category) {
            PartCategory.blade => db.blades,
            PartCategory.ratchet => db.ratchets,
            PartCategory.bit => db.bits,
          };
          if (_onlyOwned) {
            final collection = collectionAsync.value;
            if (collection != null) {
              final ownedNames = collection.parts.where((p) => p.category == _category).map((p) => p.name).toSet();
              partsMap = Map.fromEntries(partsMap.entries.where((e) => ownedNames.contains(e.key)));
            }
          }
          final ranked = rankPartsUC.execute(parts: partsMap, stat: _stat);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(children: PartCategory.values.map((cat) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(label: Text(cat.name[0].toUpperCase() + cat.name.substring(1)), selected: cat == _category, onSelected: (_) => setState(() => _category = cat), selectedColor: BeybladeTheme.primary)))).toList()),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _stat,
                          decoration: const InputDecoration(labelText: 'Statistica'),
                          items: StatUtils.allStats.map((s) => DropdownMenuItem(value: s, child: Text(StatUtils.labelForStat(s)))).toList(),
                          onChanged: (v) { if (v != null) setState(() => _stat = v); },
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilterChip(label: const Text('Solo mie'), selected: _onlyOwned, onSelected: (v) => setState(() => _onlyOwned = v), selectedColor: BeybladeTheme.accent),
                    ]),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: ranked.length,
                  itemBuilder: (context, index) {
                    final item = ranked[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(children: [
                          SizedBox(width: 32, child: Text('#${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: index < 3 ? BeybladeTheme.accent : BeybladeTheme.textSecondary, fontFamily: 'monospace'))),
                          Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: StatBar(label: '', value: item.value, color: StatUtils.colorForStat(_stat))),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Errore')),
      ),
    );
  }
}
