import 'package:flutter_test/flutter_test.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/domain/usecases/rank_parts.dart';

void main() {
  late RankParts rankParts;
  setUp(() { rankParts = RankParts(); });

  test('ranks parts by attack descending', () {
    final parts = {
      'Low': PartStats(attack: 3, defense: 5, stamina: 5, weight: 5),
      'High': PartStats(attack: 9, defense: 5, stamina: 5, weight: 5),
      'Mid': PartStats(attack: 6, defense: 5, stamina: 5, weight: 5),
    };
    final result = rankParts.execute(parts: parts, stat: 'attack');
    expect(result.length, 3);
    expect(result[0].name, 'High');
    expect(result[0].value, 9);
    expect(result[1].name, 'Mid');
    expect(result[2].name, 'Low');
  });

  test('ranks by burst_resistance with null values as 0', () {
    final parts = {
      'NoBR': PartStats(attack: 5, defense: 5, stamina: 5, weight: 5),
      'HasBR': PartStats(attack: 5, defense: 5, stamina: 5, weight: 5, burstResistance: 8),
    };
    final result = rankParts.execute(parts: parts, stat: 'burst_resistance');
    expect(result[0].name, 'HasBR');
    expect(result[0].value, 8);
    expect(result[1].value, 0);
  });
}
