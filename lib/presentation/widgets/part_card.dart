import 'package:flutter/material.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'stat_bar.dart';

class PartCard extends StatelessWidget {
  final String name;
  final PartStats stats;
  final int? quantity;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PartCard({super.key, required this.name, required this.stats, this.quantity, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final typeColor = StatUtils.colorForType(stats.type);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(border: Border(left: BorderSide(color: typeColor, width: 4))),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildImage(typeColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                        if (quantity != null && quantity! > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
                            child: Text('x$quantity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: typeColor)),
                          ),
                      ],
                    ),
                    if (stats.type != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 4),
                        child: Text(stats.type!, style: TextStyle(fontSize: 12, color: typeColor, fontWeight: FontWeight.w600)),
                      ),
                    StatBar(label: 'ATK', value: stats.attack, color: StatUtils.attackColor),
                    StatBar(label: 'DEF', value: stats.defense, color: StatUtils.defenseColor),
                    StatBar(label: 'STA', value: stats.stamina, color: StatUtils.staminaColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Color typeColor) {
    if (stats.imageUrl == null || stats.imageUrl!.isEmpty) {
      return Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.catching_pokemon, color: typeColor, size: 28),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        stats.imageUrl!,
        width: 56,
        height: 56,
        fit: BoxFit.contain,
        headers: const {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 56, height: 56,
            color: typeColor.withValues(alpha: 0.2),
            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('IMAGE ERROR for $name: $error');
          debugPrint('URL was: ${stats.imageUrl}');
          return Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.broken_image, color: Colors.red, size: 24),
          );
        },
      ),
    );
  }
}
