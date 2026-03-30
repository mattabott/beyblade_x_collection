import 'package:flutter_test/flutter_test.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/domain/usecases/compare_parts.dart';

void main() {
  late CompareParts compareParts;
  setUp(() { compareParts = CompareParts(); });

  test('compares two parts and returns stat diffs', () {
    final parts = {
      'PartA': PartStats(attack: 9, defense: 3, stamina: 4, weight: 7),
      'PartB': PartStats(attack: 4, defense: 8, stamina: 7, weight: 5),
    };
    final result = compareParts.execute(parts: parts);
    expect(result.length, 2);
    expect(result[0].name, 'PartA');
    expect(result[0].stats.attack, 9);
    expect(result[1].name, 'PartB');
    expect(result[1].stats.attack, 4);
  });

  test('returns empty for empty input', () {
    final result = compareParts.execute(parts: {});
    expect(result, isEmpty);
  });
}
