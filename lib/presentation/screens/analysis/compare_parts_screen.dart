import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';
import 'package:beyblade_x_collection/presentation/widgets/stat_radar.dart';
import 'package:beyblade_x_collection/presentation/widgets/stat_bar.dart';

class ComparePartsScreen extends ConsumerStatefulWidget {
  const ComparePartsScreen({super.key});
  @override
  ConsumerState<ComparePartsScreen> createState() => _ComparePartsScreenState();
}

class _ComparePartsScreenState extends ConsumerState<ComparePartsScreen> {
  PartCategory _category = PartCategory.blade;
  final List<String> _selectedParts = [];

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(partsDatabaseProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confronta Parti'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/analysis')),
      ),
      body: dbAsync.when(
        data: (db) {
          final Map<String, PartStats> partsMap = switch (_category) {
            PartCategory.blade => db.blades,
            PartCategory.ratchet => db.ratchets,
            PartCategory.bit => db.bits,
          };
          final sortedNames = partsMap.keys.toList()..sort();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Category selector
              Row(
                children: PartCategory.values.map((cat) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(cat.name[0].toUpperCase() + cat.name.substring(1)),
                        selected: cat == _category,
                        onSelected: (_) => setState(() { _category = cat; _selectedParts.clear(); }),
                        selectedColor: BeybladeTheme.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // 2 dropdowns for part selection
              for (int i = 0; i < 2; i++) ...[
                DropdownButtonFormField<String>(
                  initialValue: i < _selectedParts.length ? _selectedParts[i] : null,
                  decoration: InputDecoration(labelText: 'Parte ${i + 1}'),
                  items: sortedNames.map((n) {
                    final s = partsMap[n];
                    return DropdownMenuItem(value: n, child: Row(
                      children: [
                        _partThumbnail(s, 24),
                        const SizedBox(width: 8),
                        Expanded(child: Text(n, overflow: TextOverflow.ellipsis)),
                      ],
                    ));
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      if (i < _selectedParts.length) {
                        if (v != null) _selectedParts[i] = v;
                      } else if (v != null) {
                        _selectedParts.add(v);
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
              ],
              // Radar chart + comparison when both selected
              if (_selectedParts.length >= 2) ...[
                const SizedBox(height: 24),
                SizedBox(
                  height: 280,
                  child: StatRadar(parts: {for (final name in _selectedParts) if (partsMap.containsKey(name)) name: partsMap[name]!}),
                ),
                const SizedBox(height: 12),
                // Legend with images
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _selectedParts.asMap().entries.map((entry) {
                    final colors = [const Color(0xFFE63946), const Color(0xFF4A90D9)];
                    final stats = partsMap[entry.value];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[entry.key % colors.length], shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        _partThumbnail(stats, 28),
                        const SizedBox(width: 4),
                        Text(entry.value, style: const TextStyle(fontSize: 13)),
                      ]),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Detailed stat comparison
                for (final stat in StatUtils.allStats) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(StatUtils.labelForStat(stat), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: StatUtils.colorForStat(stat))),
                  ),
                  for (final name in _selectedParts)
                    if (partsMap.containsKey(name))
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 2),
                        child: StatBar(label: name.length > 6 ? '${name.substring(0, 6)}.' : name, value: StatUtils.getStatValue(partsMap[name]!, stat), color: StatUtils.colorForStat(stat)),
                      ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Errore')),
      ),
    );
  }

  Widget _partThumbnail(PartStats? stats, double size) {
    final url = stats?.imageUrl;
    if (url == null || url.isEmpty) {
      final color = StatUtils.colorForType(stats?.type);
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
        child: Icon(Icons.catching_pokemon, color: color, size: size * 0.6),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
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
