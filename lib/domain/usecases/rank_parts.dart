import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';

class RankedPart {
  final String name;
  final int value;
  final PartStats stats;
  const RankedPart({required this.name, required this.value, required this.stats});
}

class RankParts {
  List<RankedPart> execute({required Map<String, PartStats> parts, required String stat}) {
    final ranked = parts.entries.map((entry) {
      return RankedPart(name: entry.key, value: StatUtils.getStatValue(entry.value, stat), stats: entry.value);
    }).toList();
    ranked.sort((a, b) => b.value.compareTo(a.value));
    return ranked;
  }
}
