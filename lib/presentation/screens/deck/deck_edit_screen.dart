import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/beyblade_slot.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';
import 'package:beyblade_x_collection/data/models/user_collection.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';
import 'package:beyblade_x_collection/presentation/widgets/stat_bar.dart';

class DeckEditScreen extends ConsumerStatefulWidget {
  final int deckIndex;
  const DeckEditScreen({super.key, required this.deckIndex});

  @override
  ConsumerState<DeckEditScreen> createState() => _DeckEditScreenState();
}

class _DeckEditScreenState extends ConsumerState<DeckEditScreen> {
  late List<BeybladeSlot> _slots;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final collectionAsync = ref.watch(collectionProvider);
    final dbAsync = ref.watch(partsDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: collectionAsync.when(
          data: (c) => Text(c.decks[widget.deckIndex].name),
          loading: () => const Text('...'),
          error: (_, __) => const Text('Errore'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: BeybladeTheme.secondary),
            onPressed: () => _deleteDeck(context, ref),
          ),
        ],
      ),
      body: collectionAsync.when(
        data: (collection) => dbAsync.when(
          data: (db) {
            if (!_initialized) {
              _slots =
                  List.from(collection.decks[widget.deckIndex].slots);
              _initialized = true;
            }
            final ownedBlades = collection.parts
                .where((p) => p.category == PartCategory.blade)
                .map((p) => p.name)
                .toList();
            final ownedRatchets = collection.parts
                .where((p) => p.category == PartCategory.ratchet)
                .map((p) => p.name)
                .toList();
            final ownedBits = collection.parts
                .where((p) => p.category == PartCategory.bit)
                .map((p) => p.name)
                .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._slots.asMap().entries.map((entry) => _buildSlotEditor(
                      context,
                      slotIndex: entry.key,
                      slot: entry.value,
                      ownedBlades: ownedBlades,
                      ownedRatchets: ownedRatchets,
                      ownedBits: ownedBits,
                      db: db,
                    )),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _saveDeck(ref, collection),
                  icon: const Icon(Icons.save),
                  label: const Text('Salva Deck'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BeybladeTheme.accent,
                    foregroundColor: BeybladeTheme.background,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
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

  Widget _buildSlotEditor(
    BuildContext context, {
    required int slotIndex,
    required BeybladeSlot slot,
    required List<String> ownedBlades,
    required List<String> ownedRatchets,
    required List<String> ownedBits,
    required PartsDatabase db,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Beyblade ${slotIndex + 1}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: BeybladeTheme.accent)),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Blade',
              value: slot.blade,
              items: ownedBlades,
              onChanged: (v) => setState(() {
                _slots[slotIndex] = slot.copyWith(blade: v);
              }),
            ),
            const SizedBox(height: 8),
            _buildDropdown(
              label: 'Ratchet',
              value: slot.ratchet,
              items: ownedRatchets,
              onChanged: (v) => setState(() {
                _slots[slotIndex] = slot.copyWith(ratchet: v);
              }),
            ),
            const SizedBox(height: 8),
            _buildDropdown(
              label: 'Bit',
              value: slot.bit,
              items: ownedBits,
              onChanged: (v) => setState(() {
                _slots[slotIndex] = slot.copyWith(bit: v);
              }),
            ),
            if (slot.blade != null &&
                slot.ratchet != null &&
                slot.bit != null) ...[
              const Divider(height: 24),
              _buildComboStats(slot, db),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: null, child: Text('-- Seleziona --')),
        ...items
            .map((item) => DropdownMenuItem(value: item, child: Text(item))),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildComboStats(BeybladeSlot slot, PartsDatabase db) {
    final bladeStats = db.blades[slot.blade];
    final ratchetStats = db.ratchets[slot.ratchet];
    final bitStats = db.bits[slot.bit];
    if (bladeStats == null || ratchetStats == null || bitStats == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Stats Combo',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        for (final stat in ['attack', 'defense', 'stamina'])
          StatBar(
            label: StatUtils.labelForStat(stat),
            value: ((StatUtils.getStatValue(bladeStats, stat) +
                        StatUtils.getStatValue(ratchetStats, stat) +
                        StatUtils.getStatValue(bitStats, stat)) /
                    3)
                .round(),
            color: StatUtils.colorForStat(stat),
          ),
      ],
    );
  }

  void _saveDeck(WidgetRef ref, UserCollection collection) {
    final deck = collection.decks[widget.deckIndex];
    ref
        .read(collectionProvider.notifier)
        .updateDeck(widget.deckIndex, deck.copyWith(slots: _slots));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Deck salvato!'),
        backgroundColor: BeybladeTheme.primary));
  }

  void _deleteDeck(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina Deck'),
        content: const Text('Sei sicuro di voler eliminare questo deck?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: BeybladeTheme.secondary),
            onPressed: () {
              ref.read(collectionProvider.notifier).deleteDeck(widget.deckIndex);
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
