import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/domain/usecases/suggest_combo.dart';
import 'package:beyblade_x_collection/presentation/providers/analysis_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';
import 'package:beyblade_x_collection/presentation/widgets/stat_bar.dart';

class SuggestComboScreen extends ConsumerStatefulWidget {
  const SuggestComboScreen({super.key});
  @override
  ConsumerState<SuggestComboScreen> createState() => _SuggestComboScreenState();
}

class _SuggestComboScreenState extends ConsumerState<SuggestComboScreen> {
  String _strategy = 'attack';
  bool _onlyOwned = true;
  List<ComboResult> _results = [];

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(partsDatabaseProvider);
    final collectionAsync = ref.watch(collectionProvider);
    final suggestComboUC = ref.watch(suggestComboProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggerisci Combo'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/analysis')),
      ),
      body: dbAsync.when(
        data: (db) => collectionAsync.when(
          data: (collection) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _strategy,
                  decoration: const InputDecoration(labelText: 'Strategia'),
                  items: const [
                    DropdownMenuItem(value: 'attack', child: Text('Attacco')),
                    DropdownMenuItem(value: 'defense', child: Text('Difesa')),
                    DropdownMenuItem(value: 'stamina', child: Text('Stamina')),
                    DropdownMenuItem(value: 'balance', child: Text('Bilanciato')),
                  ],
                  onChanged: (v) { if (v != null) setState(() => _strategy = v); },
                ),
                const SizedBox(height: 12),
                FilterChip(label: const Text('Solo parti possedute'), selected: _onlyOwned, onSelected: (v) => setState(() => _onlyOwned = v), selectedColor: BeybladeTheme.accent),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    List<String> blades, ratchets, bits;
                    if (_onlyOwned) {
                      blades = collection.parts.where((p) => p.category == PartCategory.blade).map((p) => p.name).toList();
                      ratchets = collection.parts.where((p) => p.category == PartCategory.ratchet).map((p) => p.name).toList();
                      bits = collection.parts.where((p) => p.category == PartCategory.bit).map((p) => p.name).toList();
                    } else {
                      blades = db.blades.keys.toList();
                      ratchets = db.ratchets.keys.toList();
                      bits = db.bits.keys.toList();
                    }
                    setState(() {
                      _results = suggestComboUC.execute(db: db, strategy: _strategy, availableBlades: blades, availableRatchets: ratchets, availableBits: bits);
                    });
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Suggerisci'),
                  style: ElevatedButton.styleFrom(backgroundColor: BeybladeTheme.accent, foregroundColor: BeybladeTheme.background, minimumSize: const Size.fromHeight(50)),
                ),
                const SizedBox(height: 24),
                if (_results.isEmpty)
                  const Center(child: Text('Tocca "Suggerisci" per vedere le migliori combo', style: TextStyle(color: BeybladeTheme.textSecondary))),
                ..._results.asMap().entries.map((entry) {
                  final i = entry.key;
                  final combo = entry.value;
                  final bladeStats = db.blades[combo.blade];
                  final ratchetStats = db.ratchets[combo.ratchet];
                  final bitStats = db.bits[combo.bit];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(border: Border(left: BorderSide(color: i == 0 ? BeybladeTheme.accent : BeybladeTheme.primary, width: 4))),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: i == 0 ? BeybladeTheme.accent : BeybladeTheme.primary, borderRadius: BorderRadius.circular(8)),
                              child: Text('#${i + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: i == 0 ? BeybladeTheme.background : Colors.white)),
                            ),
                            const SizedBox(width: 12),
                            Text('Score: ${combo.score.toStringAsFixed(1)}', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 12),
                          _comboRow('Blade', combo.blade),
                          _comboRow('Ratchet', combo.ratchet),
                          _comboRow('Bit', combo.bit),
                          if (bladeStats != null && ratchetStats != null && bitStats != null) ...[
                            const Divider(height: 20),
                            for (final stat in ['attack', 'defense', 'stamina'])
                              StatBar(
                                label: StatUtils.labelForStat(stat),
                                value: ((StatUtils.getStatValue(bladeStats, stat) + StatUtils.getStatValue(ratchetStats, stat) + StatUtils.getStatValue(bitStats, stat)) / 3).round(),
                                color: StatUtils.colorForStat(stat),
                              ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Errore')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Errore')),
      ),
    );
  }

  Widget _comboRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(color: BeybladeTheme.textSecondary, fontSize: 13))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
