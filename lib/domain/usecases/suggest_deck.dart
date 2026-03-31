import 'dart:math';
import 'package:beyblade_x_collection/core/constants/app_constants.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';
import 'suggest_combo.dart';

class DeckSlotConfig {
  final String strategy;
  const DeckSlotConfig({required this.strategy});
}

class DeckResult {
  final List<ComboResult> slots;
  final double totalScore;

  const DeckResult({required this.slots, required this.totalScore});
}

class SuggestDeck {
  final _random = Random();

  DeckResult? execute({
    required PartsDatabase db,
    required List<DeckSlotConfig> slotConfigs,
    required List<String> availableBlades,
    required List<String> availableRatchets,
    required List<String> availableBits,
    bool shuffle = false,
  }) {
    if (availableBlades.length < slotConfigs.length ||
        availableRatchets.length < slotConfigs.length ||
        availableBits.length < slotConfigs.length) {
      return null;
    }

    // Build scored combos per slot config
    final slotsResults = <List<ComboResult>>[];

    final usedBlades = <String>{};
    final usedRatchets = <String>{};
    final usedBits = <String>{};

    for (final config in slotConfigs) {
      final weights = AppConstants.comboWeights[config.strategy];
      if (weights == null) return null;

      final combos = <ComboResult>[];

      for (final blade in availableBlades) {
        if (usedBlades.contains(blade)) continue;
        final bladeStats = db.blades[blade];
        if (bladeStats == null) continue;

        for (final ratchet in availableRatchets) {
          if (usedRatchets.contains(ratchet)) continue;
          final ratchetStats = db.ratchets[ratchet];
          if (ratchetStats == null) continue;

          for (final bit in availableBits) {
            if (usedBits.contains(bit)) continue;
            final bitStats = db.bits[bit];
            if (bitStats == null) continue;

            double score = 0;
            for (final entry in weights.entries) {
              final avg = (StatUtils.getStatValue(bladeStats, entry.key) +
                      StatUtils.getStatValue(ratchetStats, entry.key) +
                      StatUtils.getStatValue(bitStats, entry.key)) /
                  3.0;
              score += avg * entry.value;
            }

            if (shuffle) {
              score *= 0.85 + _random.nextDouble() * 0.30;
            }

            combos.add(ComboResult(blade: blade, ratchet: ratchet, bit: bit, score: score));
          }
        }
      }

      if (combos.isEmpty) return null;

      combos.sort((a, b) => b.score.compareTo(a.score));

      // Pick the best combo that doesn't reuse parts
      ComboResult? best;
      for (final combo in combos) {
        if (!usedBlades.contains(combo.blade) &&
            !usedRatchets.contains(combo.ratchet) &&
            !usedBits.contains(combo.bit)) {
          best = combo;
          break;
        }
      }

      if (best == null) return null;

      usedBlades.add(best.blade);
      usedRatchets.add(best.ratchet);
      usedBits.add(best.bit);
      slotsResults.add([best]);
    }

    final slots = slotsResults.map((s) => s.first).toList();
    final totalScore = slots.fold<double>(0, (sum, s) => sum + s.score);

    return DeckResult(slots: slots, totalScore: totalScore);
  }
}
