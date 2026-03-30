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

    expect(find.text('Beyblade X Manager'), findsOneWidget);
  });
}
