import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:beyblade_x_collection/presentation/widgets/stat_bar.dart';

void main() {
  setUp(() {
    Animate.restartOnHotReload = false;
  });

  group('StatBar', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StatBar(label: 'ATK', value: 8, maxValue: 10, color: Colors.red))),
      );
      await tester.pumpAndSettle();
      expect(find.text('ATK'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });
  });
}
