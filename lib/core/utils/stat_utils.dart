import 'package:flutter/material.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';

class StatUtils {
  StatUtils._();

  static const Color attackColor = Color(0xFFE63946);
  static const Color defenseColor = Color(0xFF4A90D9);
  static const Color staminaColor = Color(0xFF2ECC71);
  static const Color weightColor = Color(0xFFF39C12);
  static const Color burstResistanceColor = Color(0xFF9B59B6);

  static Color colorForStat(String stat) {
    return switch (stat) {
      'attack' => attackColor,
      'defense' => defenseColor,
      'stamina' => staminaColor,
      'weight' => weightColor,
      'burst_resistance' => burstResistanceColor,
      _ => Colors.grey,
    };
  }

  static String labelForStat(String stat) {
    return switch (stat) {
      'attack' => 'ATK',
      'defense' => 'DEF',
      'stamina' => 'STA',
      'weight' => 'WGT',
      'burst_resistance' => 'BRS',
      _ => stat.toUpperCase(),
    };
  }

  static int getStatValue(PartStats stats, String stat) {
    return switch (stat) {
      'attack' => stats.attack,
      'defense' => stats.defense,
      'stamina' => stats.stamina,
      'weight' => stats.weight,
      'burst_resistance' => stats.burstResistance ?? 0,
      _ => 0,
    };
  }

  static Color colorForType(String? type) {
    return switch (type) {
      'Attack' => attackColor,
      'Defense' => defenseColor,
      'Stamina' => staminaColor,
      'Balance' => const Color(0xFFFFB703),
      _ => Colors.grey,
    };
  }

  static const List<String> allStats = [
    'attack', 'defense', 'stamina', 'weight', 'burst_resistance',
  ];
}
