import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/main.dart';

void main() {
  testWidgets('Smoke test - Verify RevoJourney loads', (WidgetTester tester) async {
    // Set desktop screen size to prevent dashboard layout overflows in testing
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: RevoJourneyApp(),
      ),
    );

    // Verify app starts and renders RevoJourney text
    expect(find.textContaining('RevoJourney'), findsWidgets);
  });
}
