import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';

void main() {
  group('PartsDatabase', () {
    test('deserializes from actual DB JSON file', () {
      final file = File('assets/data/beyblade_parts_db.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final db = PartsDatabase.fromJson(json);
      expect(db.blades.length, greaterThanOrEqualTo(60));
      expect(db.ratchets.length, greaterThanOrEqualTo(20));
      expect(db.bits.length, greaterThanOrEqualTo(30));
      expect(db.version, 1);
      final swordDran = db.blades['Sword Dran']!;
      expect(swordDran.attack, 8);
      expect(swordDran.type, 'Attack');
      final r160 = db.ratchets['1-60']!;
      expect(r160.burstResistance, 8);
      final flatF = db.bits['Flat (F)']!;
      expect(flatF.type, 'Attack');
      expect(flatF.attack, 9);
    });

    test('serializes back to JSON', () {
      final db = PartsDatabase(
        blades: {'TestBlade': PartStats(attack: 5, defense: 5, stamina: 5, weight: 5)},
        ratchets: {},
        bits: {},
        version: 1,
      );
      final json = db.toJson();
      expect(json['version'], 1);
      expect((json['blades'] as Map).containsKey('TestBlade'), isTrue);
    });
  });
}
