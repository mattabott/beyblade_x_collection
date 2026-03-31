import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
              if (stats.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: stats.imageUrl!,
                    width: 56, height: 56, fit: BoxFit.cover,
                    httpHeaders: const {
                      'User-Agent': 'Mozilla/5.0 (Linux; Android) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
                      'Referer': 'https://beyblade.fandom.com/',
                    },
                    placeholder: (_, __) => Container(width: 56, height: 56, color: typeColor.withValues(alpha: 0.2), child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
                    errorWidget: (_, url, error) => Container(width: 56, height: 56, color: typeColor.withValues(alpha: 0.2), child: Icon(Icons.broken_image, color: typeColor, size: 24)),
                  ),
                )
              else
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.catching_pokemon, color: typeColor, size: 28),
                ),
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
}
