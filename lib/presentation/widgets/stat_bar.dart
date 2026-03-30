import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StatBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;

  const StatBar({super.key, required this.label, required this.value, this.maxValue = 10, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, fontFamily: 'monospace')),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / maxValue,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ).animate().scaleX(begin: 0, end: 1, alignment: Alignment.centerLeft).fadeIn(duration: 400.ms),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 18,
            child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}
