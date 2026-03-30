import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';

void main() {
  group('PartStats', () {
    test('deserializes from blade JSON (with type, image_url)', () {
      final json = {
        'attack': 8, 'defense': 4, 'stamina': 5, 'weight': 7,
        'type': 'Attack',
        'image_url': 'https://example.com/image.png',
      };
      final stats = PartStats.fromJson(json);
      expect(stats.attack, 8);
      expect(stats.defense, 4);
      expect(stats.stamina, 5);
      expect(stats.weight, 7);
      expect(stats.type, 'Attack');
      expect(stats.imageUrl, 'https://example.com/image.png');
      expect(stats.burstResistance, isNull);
    });

    test('deserializes from ratchet JSON (with burst_resistance, no type)', () {
      final json = {
        'attack': 5, 'defense': 6, 'stamina': 7, 'weight': 4,
        'burst_resistance': 8, 'image_url': null,
      };
      final stats = PartStats.fromJson(json);
      expect(stats.burstResistance, 8);
      expect(stats.type, isNull);
      expect(stats.imageUrl, isNull);
    });

    test('serializes to JSON', () {
      final stats = PartStats(
        attack: 9, defense: 3, stamina: 4, weight: 4,
        type: 'Attack', burstResistance: 7, imageUrl: null,
      );
      final json = stats.toJson();
      expect(json['attack'], 9);
      expect(json['burst_resistance'], 7);
      expect(json['image_url'], isNull);
    });
  });
}
