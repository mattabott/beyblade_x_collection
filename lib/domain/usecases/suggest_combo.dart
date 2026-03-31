import 'dart:math';
import 'package:beyblade_x_collection/core/constants/app_constants.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';

class ComboResult {
  final String blade;
  final String ratchet;
  final String bit;
  final double score;

  const ComboResult({required this.blade, required this.ratchet, required this.bit, required this.score});
}

class SuggestCombo {
  final _random = Random();

  List<ComboResult> execute({
    required PartsDatabase db,
    required String strategy,
    required List<String> availableBlades,
    required List<String> availableRatchets,
    required List<String> availableBits,
    bool shuffle = false,
  }) {
    if (availableBlades.isEmpty || availableRatchets.isEmpty || availableBits.isEmpty) return [];

    final weights = AppConstants.comboWeights[strategy];
    if (weights == null) return [];

    final combos = <ComboResult>[];

    for (final bladeName in availableBlades) {
      final bladeStats = db.blades[bladeName];
      if (bladeStats == null) continue;
      for (final ratchetName in availableRatchets) {
        final ratchetStats = db.ratchets[ratchetName];
        if (ratchetStats == null) continue;
        for (final bitName in availableBits) {
          final bitStats = db.bits[bitName];
          if (bitStats == null) continue;
          double score = 0;
          for (final entry in weights.entries) {
            final stat = entry.key;
            final weight = entry.value;
            final avg = (StatUtils.getStatValue(bladeStats, stat) +
                    StatUtils.getStatValue(ratchetStats, stat) +
                    StatUtils.getStatValue(bitStats, stat)) / 3.0;
            score += avg * weight;
          }
          // Add randomness when shuffle is on (up to ±15% variation)
          if (shuffle) {
            score *= 0.85 + _random.nextDouble() * 0.30;
          }
          combos.add(ComboResult(blade: bladeName, ratchet: ratchetName, bit: bitName, score: score));
        }
      }
    }

    combos.sort((a, b) => b.score.compareTo(a.score));

    // Pick 3 combos with different blades for variety
    final results = <ComboResult>[];
    final usedBlades = <String>{};

    for (final combo in combos) {
      if (!usedBlades.contains(combo.blade)) {
        results.add(combo);
        usedBlades.add(combo.blade);
        if (results.length >= 3) break;
      }
    }

    return results;
  }
}
