import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';
import 'package:beyblade_x_collection/data/models/user_collection.dart';
import 'package:beyblade_x_collection/domain/usecases/suggest_combo.dart';
import 'package:beyblade_x_collection/domain/usecases/suggest_deck.dart';
import 'package:beyblade_x_collection/presentation/providers/analysis_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';
import 'package:beyblade_x_collection/presentation/widgets/stat_bar.dart';

class SuggestComboScreen extends ConsumerStatefulWidget {
  const SuggestComboScreen({super.key});
  @override
  ConsumerState<SuggestComboScreen> createState() => _SuggestComboScreenState();
}

class _SuggestComboScreenState extends ConsumerState<SuggestComboScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Combo state
  String _comboStrategy = 'attack';
  bool _comboOnlyOwned = true;
  List<ComboResult> _comboResults = [];

  // Deck state
  bool _deckOnlyOwned = true;
  DeckResult? _deckResult;
  final List<String> _deckSlotStrategies = ['attack', 'defense', 'stamina'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(partsDatabaseProvider);
    final collectionAsync = ref.watch(collectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggerisci'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/analysis')),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Combo'),
            Tab(text: 'Deck'),
          ],
        ),
      ),
      body: dbAsync.when(
        data: (db) => collectionAsync.when(
          data: (collection) => TabBarView(
            controller: _tabController,
            children: [
              _buildComboTab(db, collection),
              _buildDeckTab(db, collection),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Errore')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Errore')),
      ),
    );
  }

  // ===================== COMBO TAB =====================

  Widget _buildComboTab(PartsDatabase db, UserCollection collection) {
    final suggestComboUC = ref.watch(suggestComboProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _strategyDropdown(_comboStrategy, (v) => setState(() => _comboStrategy = v)),
        const SizedBox(height: 12),
        FilterChip(label: const Text('Solo parti possedute'), selected: _comboOnlyOwned, onSelected: (v) => setState(() => _comboOnlyOwned = v), selectedColor: BeybladeTheme.accent),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            final (blades, ratchets, bits) = _getParts(db, collection, _comboOnlyOwned);
            setState(() {
              _comboResults = suggestComboUC.execute(db: db, strategy: _comboStrategy, availableBlades: blades, availableRatchets: ratchets, availableBits: bits);
            });
          },
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Suggerisci'),
          style: ElevatedButton.styleFrom(backgroundColor: BeybladeTheme.accent, foregroundColor: BeybladeTheme.background, minimumSize: const Size.fromHeight(50)),
        ),
        if (_comboResults.isNotEmpty) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              final (blades, ratchets, bits) = _getParts(db, collection, _comboOnlyOwned);
              setState(() {
                _comboResults = suggestComboUC.execute(db: db, strategy: _comboStrategy, availableBlades: blades, availableRatchets: ratchets, availableBits: bits, shuffle: true);
              });
            },
            icon: const Icon(Icons.shuffle, size: 18),
            label: const Text('Rigenera'),
            style: OutlinedButton.styleFrom(foregroundColor: BeybladeTheme.textSecondary, side: const BorderSide(color: BeybladeTheme.textSecondary), minimumSize: const Size.fromHeight(42)),
          ),
        ],
        const SizedBox(height: 24),
        if (_comboResults.isEmpty)
          const Center(child: Text('Tocca "Suggerisci" per vedere le migliori combo', style: TextStyle(color: BeybladeTheme.textSecondary))),
        ..._comboResults.asMap().entries.map((entry) => _buildComboCard(db, entry.key, entry.value)),
      ],
    );
  }

  // ===================== DECK TAB =====================

  Widget _buildDeckTab(PartsDatabase db, UserCollection collection) {
    final suggestDeckUC = ref.watch(suggestDeckProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Slot strategy selectors
        for (int i = 0; i < 3; i++) ...[
          _slotStrategySelector(i),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 4),
        // Preset buttons
        Wrap(
          spacing: 8,
          children: [
            ActionChip(label: const Text('3x Attacco'), onPressed: () => setState(() { _deckSlotStrategies[0] = 'attack'; _deckSlotStrategies[1] = 'attack'; _deckSlotStrategies[2] = 'attack'; })),
            ActionChip(label: const Text('3x Difesa'), onPressed: () => setState(() { _deckSlotStrategies[0] = 'defense'; _deckSlotStrategies[1] = 'defense'; _deckSlotStrategies[2] = 'defense'; })),
            ActionChip(label: const Text('Misto'), onPressed: () => setState(() { _deckSlotStrategies[0] = 'attack'; _deckSlotStrategies[1] = 'defense'; _deckSlotStrategies[2] = 'stamina'; })),
            ActionChip(label: const Text('2 ATK + 1 DEF'), onPressed: () => setState(() { _deckSlotStrategies[0] = 'attack'; _deckSlotStrategies[1] = 'attack'; _deckSlotStrategies[2] = 'defense'; })),
          ],
        ),
        const SizedBox(height: 12),
        FilterChip(label: const Text('Solo parti possedute'), selected: _deckOnlyOwned, onSelected: (v) => setState(() => _deckOnlyOwned = v), selectedColor: BeybladeTheme.accent),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            final (blades, ratchets, bits) = _getParts(db, collection, _deckOnlyOwned);
            final configs = _deckSlotStrategies.map((s) => DeckSlotConfig(strategy: s)).toList();
            setState(() {
              _deckResult = suggestDeckUC.execute(db: db, slotConfigs: configs, availableBlades: blades, availableRatchets: ratchets, availableBits: bits);
            });
          },
          icon: const Icon(Icons.style),
          label: const Text('Suggerisci Deck'),
          style: ElevatedButton.styleFrom(backgroundColor: BeybladeTheme.accent, foregroundColor: BeybladeTheme.background, minimumSize: const Size.fromHeight(50)),
        ),
        if (_deckResult != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              final (blades, ratchets, bits) = _getParts(db, collection, _deckOnlyOwned);
              final configs = _deckSlotStrategies.map((s) => DeckSlotConfig(strategy: s)).toList();
              setState(() {
                _deckResult = suggestDeckUC.execute(db: db, slotConfigs: configs, availableBlades: blades, availableRatchets: ratchets, availableBits: bits, shuffle: true);
              });
            },
            icon: const Icon(Icons.shuffle, size: 18),
            label: const Text('Rigenera'),
            style: OutlinedButton.styleFrom(foregroundColor: BeybladeTheme.textSecondary, side: const BorderSide(color: BeybladeTheme.textSecondary), minimumSize: const Size.fromHeight(42)),
          ),
        ],
        const SizedBox(height: 24),
        if (_deckResult == null)
          const Center(child: Text('Scegli le strategie e tocca "Suggerisci Deck"', style: TextStyle(color: BeybladeTheme.textSecondary)))
        else ...[
          // Score header
          Center(child: Text('Score totale: ${_deckResult!.totalScore.toStringAsFixed(1)}', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16))),
          const SizedBox(height: 16),
          // 3 beyblade cards
          ..._deckResult!.slots.asMap().entries.map((entry) {
            final i = entry.key;
            final combo = entry.value;
            final strategy = _deckSlotStrategies[i];
            return _buildDeckSlotCard(db, i, combo, strategy);
          }),
        ],
      ],
    );
  }

  Widget _slotStrategySelector(int index) {
    final strategyLabels = {
      'attack': 'Attacco',
      'defense': 'Difesa',
      'stamina': 'Stamina',
      'balance': 'Bilanciato',
    };
    final strategyColors = {
      'attack': StatUtils.attackColor,
      'defense': StatUtils.defenseColor,
      'stamina': StatUtils.staminaColor,
      'balance': BeybladeTheme.accent,
    };

    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: strategyColors[_deckSlotStrategies[index]]?.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: strategyColors[_deckSlotStrategies[index]]))),
        ),
        const SizedBox(width: 12),
        Text('Bey ${index + 1}:', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Expanded(
          child: SegmentedButton<String>(
            segments: strategyLabels.entries.map((e) => ButtonSegment(
              value: e.key,
              label: Text(e.value, style: const TextStyle(fontSize: 12)),
            )).toList(),
            selected: {_deckSlotStrategies[index]},
            onSelectionChanged: (v) => setState(() => _deckSlotStrategies[index] = v.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeckSlotCard(PartsDatabase db, int index, ComboResult combo, String strategy) {
    final bladeStats = db.blades[combo.blade];
    final ratchetStats = db.ratchets[combo.ratchet];
    final bitStats = db.bits[combo.bit];

    final strategyLabels = {'attack': 'ATK', 'defense': 'DEF', 'stamina': 'STA', 'balance': 'BAL'};
    final strategyColors = {'attack': StatUtils.attackColor, 'defense': StatUtils.defenseColor, 'stamina': StatUtils.staminaColor, 'balance': BeybladeTheme.accent};
    final color = strategyColors[strategy] ?? BeybladeTheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(border: Border(left: BorderSide(color: color, width: 4))),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                child: Text('Bey ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(strategyLabels[strategy] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              ),
              const Spacer(),
              Text(combo.score.toStringAsFixed(1), style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            _comboRow('Blade', combo.blade, bladeStats),
            _comboRow('Ratchet', combo.ratchet, ratchetStats),
            _comboRow('Bit', combo.bit, bitStats),
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
  }

  // ===================== SHARED =====================

  (List<String>, List<String>, List<String>) _getParts(PartsDatabase db, UserCollection collection, bool onlyOwned) {
    if (onlyOwned) {
      return (
        collection.parts.where((p) => p.category == PartCategory.blade).map((p) => p.name).toList(),
        collection.parts.where((p) => p.category == PartCategory.ratchet).map((p) => p.name).toList(),
        collection.parts.where((p) => p.category == PartCategory.bit).map((p) => p.name).toList(),
      );
    }
    return (db.blades.keys.toList(), db.ratchets.keys.toList(), db.bits.keys.toList());
  }

  Widget _strategyDropdown(String value, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Strategia'),
      items: const [
        DropdownMenuItem(value: 'attack', child: Text('Attacco')),
        DropdownMenuItem(value: 'defense', child: Text('Difesa')),
        DropdownMenuItem(value: 'stamina', child: Text('Stamina')),
        DropdownMenuItem(value: 'balance', child: Text('Bilanciato')),
      ],
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }

  Widget _buildComboCard(PartsDatabase db, int index, ComboResult combo) {
    final bladeStats = db.blades[combo.blade];
    final ratchetStats = db.ratchets[combo.ratchet];
    final bitStats = db.bits[combo.bit];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(border: Border(left: BorderSide(color: index == 0 ? BeybladeTheme.accent : BeybladeTheme.primary, width: 4))),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: index == 0 ? BeybladeTheme.accent : BeybladeTheme.primary, borderRadius: BorderRadius.circular(8)),
                child: Text('#${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: index == 0 ? BeybladeTheme.background : Colors.white)),
              ),
              const SizedBox(width: 12),
              Text('Score: ${combo.score.toStringAsFixed(1)}', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            _comboRow('Blade', combo.blade, bladeStats),
            _comboRow('Ratchet', combo.ratchet, ratchetStats),
            _comboRow('Bit', combo.bit, bitStats),
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
  }

  Widget _comboRow(String label, String value, dynamic stats) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 52, child: Text(label, style: const TextStyle(color: BeybladeTheme.textSecondary, fontSize: 12))),
        _partThumbnail(stats, 32),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _partThumbnail(dynamic stats, double size) {
    final url = stats?.imageUrl as String?;
    if (url == null || url.isEmpty) {
      final type = stats?.type as String?;
      final color = StatUtils.colorForType(type);
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
