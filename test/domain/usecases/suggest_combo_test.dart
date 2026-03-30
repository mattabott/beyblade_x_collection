import 'package:flutter_test/flutter_test.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';
import 'package:beyblade_x_collection/domain/usecases/suggest_combo.dart';

void main() {
  late SuggestCombo suggestCombo;

  final db = PartsDatabase(
    blades: {
      'Attacker': PartStats(attack: 9, defense: 2, stamina: 3, weight: 7, type: 'Attack'),
      'Defender': PartStats(attack: 3, defense: 9, stamina: 6, weight: 8, type: 'Defense'),
      'Spinner': PartStats(attack: 4, defense: 6, stamina: 9, weight: 5, type: 'Stamina'),
    },
    ratchets: {
      '3-60': PartStats(attack: 7, defense: 6, stamina: 6, weight: 5, burstResistance: 7),
      '9-60': PartStats(attack: 5, defense: 6, stamina: 8, weight: 6, burstResistance: 8),
    },
    bits: {
      'Flat (F)': PartStats(attack: 9, defense: 3, stamina: 4, weight: 4, type: 'Attack'),
      'Ball (B)': PartStats(attack: 2, defense: 7, stamina: 9, weight: 5, type: 'Stamina'),
    },
    version: 1,
  );

  setUp(() { suggestCombo = SuggestCombo(); });

  group('SuggestCombo', () {
    test('attack strategy picks highest attack parts', () {
      final results = suggestCombo.execute(
        db: db, strategy: 'attack',
        availableBlades: ['Attacker', 'Defender', 'Spinner'],
        availableRatchets: ['3-60', '9-60'],
        availableBits: ['Flat (F)', 'Ball (B)'],
      );
      expect(results.length, lessThanOrEqualTo(3));
      expect(results.isNotEmpty, isTrue);
      expect(results.first.blade, 'Attacker');
      expect(results.first.ratchet, '3-60');
      expect(results.first.bit, 'Flat (F)');
    });

    test('defense strategy picks highest defense parts', () {
      final results = suggestCombo.execute(
        db: db, strategy: 'defense',
        availableBlades: ['Attacker', 'Defender'],
        availableRatchets: ['3-60', '9-60'],
        availableBits: ['Flat (F)', 'Ball (B)'],
      );
      expect(results.first.blade, 'Defender');
    });

    test('returns empty list when no parts available', () {
      final results = suggestCombo.execute(
        db: db, strategy: 'attack',
        availableBlades: [], availableRatchets: [], availableBits: [],
      );
      expect(results, isEmpty);
    });
  });
}
