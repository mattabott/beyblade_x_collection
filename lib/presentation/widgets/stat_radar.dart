import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';

class StatRadar extends StatelessWidget {
  final Map<String, PartStats> parts;
  const StatRadar({super.key, required this.parts});

  static const _stats = ['attack', 'defense', 'stamina', 'weight'];
  static const _colors = [Color(0xFFE63946), Color(0xFF4A90D9), Color(0xFF2ECC71), Color(0xFFFFB703), Color(0xFF9B59B6)];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: RadarChart(
        RadarChartData(
          dataSets: parts.entries.toList().asMap().entries.map((entry) {
            final colorIndex = entry.key % _colors.length;
            final stats = entry.value.value;
            return RadarDataSet(
              dataEntries: _stats.map((s) => RadarEntry(value: StatUtils.getStatValue(stats, s).toDouble())).toList(),
              fillColor: _colors[colorIndex].withValues(alpha: 0.2),
              borderColor: _colors[colorIndex],
              borderWidth: 2,
            );
          }).toList(),
          radarShape: RadarShape.polygon,
          radarBorderData: const BorderSide(color: Colors.white24),
          gridBorderData: const BorderSide(color: Colors.white12),
          tickBorderData: const BorderSide(color: Colors.transparent),
          tickCount: 5,
          ticksTextStyle: const TextStyle(fontSize: 0),
          titlePositionPercentageOffset: 0.15,
          getTitle: (index, angle) => RadarChartTitle(text: StatUtils.labelForStat(_stats[index]), angle: 0),
          titleTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
      ),
    );
  }
}
