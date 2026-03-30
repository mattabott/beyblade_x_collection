import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/presentation/widgets/part_card.dart';

void main() {
  setUp(() {
    Animate.restartOnHotReload = false;
  });

  group('PartCard', () {
    testWidgets('renders name and type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PartCard(
              name: 'Sword Dran',
              stats: PartStats(attack: 8, defense: 4, stamina: 5, weight: 7, type: 'Attack'),
              quantity: 2,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sword Dran'), findsOneWidget);
      expect(find.text('Attack'), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);
    });

    testWidgets('does not show quantity badge when quantity is 1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PartCard(
              name: 'Test',
              stats: PartStats(attack: 5, defense: 5, stamina: 5, weight: 5),
              quantity: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('x1'), findsNothing);
    });
  });
}
