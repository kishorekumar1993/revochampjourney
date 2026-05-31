import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revojourneytryone/core/component_engine/models/component_node.dart';
import 'package:revojourneytryone/core/component_engine/renderer/component_renderer.dart';

void main() {
  testWidgets('ComponentRenderer renders Container child slot correctly', (WidgetTester tester) async {
    final childNode = ComponentNode(
      id: 'text-child',
      type: 'Text',
      properties: {'text': 'Hello Slot'},
      children: [],
      actions: [],
    );

    final containerNode = ComponentNode(
      id: 'container',
      type: 'Container',
      properties: {},
      children: [],
      slots: {'child': childNode},
      actions: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ComponentRenderer.render(
              containerNode,
              isDesignMode: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hello Slot'), findsOneWidget);
  });

  testWidgets('ComponentRenderer renders legacy Container direct child fallback correctly', (WidgetTester tester) async {
    final childNode = ComponentNode(
      id: 'text-child-legacy',
      type: 'Text',
      properties: {'text': 'Legacy Slot'},
      children: [],
      actions: [],
    );

    final containerNode = ComponentNode(
      id: 'container-legacy',
      type: 'Container',
      properties: {},
      children: [childNode],
      slots: {'child': null},
      actions: [],
    );

    expect(containerNode.getSlotChild('child')?.id, 'text-child-legacy');
    expect(containerNode.hasSlotChild('child'), isTrue);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ComponentRenderer.render(
              containerNode,
              isDesignMode: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Legacy Slot'), findsOneWidget);
  });
}
