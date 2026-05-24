import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/main.dart';

void main() {
  testWidgets('Smoke test - Verify RevoJourney loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RevoJourneyApp(),
      ),
    );

    // Verify app starts and renders RevoJourney text
    expect(find.textContaining('RevoJourney'), findsWidgets);
  });
}
