import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beyblade_x_collection/app.dart';

void main() {
  testWidgets('BeybladeApp renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BeybladeApp(),
      ),
    );

    // Pump past animation durations used by flutter_animate
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('BEYBLADE X'), findsOneWidget);
    expect(find.text('MANAGER'), findsOneWidget);
  });
}
