import 'package:flutter/material.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/data/models/deck.dart';

class DeckPreview extends StatelessWidget {
  final Deck deck;
  final VoidCallback? onTap;
  const DeckPreview({super.key, required this.deck, this.onTap});

  @override
  Widget build(BuildContext context) {
    final filledSlots = deck.slots.where((s) => s.blade != null || s.ratchet != null || s.bit != null).length;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.style, color: BeybladeTheme.accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text(deck.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                  Text('$filledSlots/${deck.slots.length}', style: const TextStyle(color: BeybladeTheme.textSecondary, fontFamily: 'monospace')),
                ],
              ),
              const SizedBox(height: 12),
              ...deck.slots.asMap().entries.map((entry) {
                final i = entry.key;
                final slot = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(color: BeybladeTheme.primary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6)),
                        child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        slot.blade != null ? '${slot.blade} / ${slot.ratchet ?? "?"} / ${slot.bit ?? "?"}' : 'Slot vuoto',
                        style: TextStyle(fontSize: 14, color: slot.blade != null ? BeybladeTheme.textPrimary : BeybladeTheme.textSecondary),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
