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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(children: [
                          SizedBox(width: 28, child: Text('#${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: index < 3 ? BeybladeTheme.accent : BeybladeTheme.textSecondary, fontFamily: 'monospace'))),
                          const SizedBox(width: 4),
                          _partThumbnail(item.stats, 36),
                          const SizedBox(width: 10),
                          Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: StatBar(label: '', value: item.value, color: StatUtils.colorForStat(_stat))),
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

  Widget _partThumbnail(PartStats stats, double size) {
    final url = stats.imageUrl;
    if (url == null || url.isEmpty) {
      final color = StatUtils.colorForType(stats.type);
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
        child: Icon(Icons.catching_pokemon, color: color, size: size * 0.6),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url, width: size, height: size, fit: BoxFit.contain,
        headers: const {'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36'},
        errorBuilder: (_, __, ___) => Container(
          width: size, height: size,
          color: Colors.grey.withValues(alpha: 0.2),
          child: Icon(Icons.catching_pokemon, size: size * 0.6),
        ),
      ),
    );
  }
}
