import 'package:flutter_test/flutter_test.dart';
import 'package:revojourneytryone/core/component_engine/models/component_node.dart';
import 'package:revojourneytryone/core/component_engine/validation/nesting_validator.dart';

void main() {
  group('NestingValidator', () {
    test('Container, Center, Padding, Card enforce single child', () {
      final parent = ComponentNode(
        id: 'parent',
        type: 'Container',
        properties: {},
        children: [],
        slots: {'child': null},
        actions: [],
      );
      final child1 = ComponentNode(
        id: 'child1',
        type: 'TextField',
        properties: {},
        children: [],
        actions: [],
      );
      final child2 = ComponentNode(
        id: 'child2',
        type: 'TextField',
        properties: {},
        children: [],
        actions: [],
      );

      final firstDrop = NestingValidator.validateDrop(parent, child1, null);
      expect(firstDrop.success, isTrue);

      final parentWithChild = parent.copyWith(slots: {'child': child1});
      final secondDrop = NestingValidator.validateDrop(parentWithChild, child2, null);
      expect(secondDrop.success, isFalse);
      expect(secondDrop.errorMessage, contains('Container.child already contains TextField'));
    });

    test('Row and Column allow unlimited children', () {
      final row = ComponentNode(
        id: 'row',
        type: 'Row',
        properties: {},
        children: [],
        actions: [],
      );
      final children = List.generate(
        10,
        (index) => ComponentNode(
          id: 'child_$index',
          type: 'TextField',
          properties: {},
          children: [],
          actions: [],
        ),
      );
      for (final child in children) {
        final result = NestingValidator.validateDrop(row, child, null);
        expect(result.success, isTrue, reason: 'Row should accept unlimited children');
      }

      final column = row.copyWith(type: 'Column');
      for (final child in children) {
        final result = NestingValidator.validateDrop(column, child, null);
        expect(result.success, isTrue, reason: 'Column should accept unlimited children');
      }
    });

    test('Scaffold only accepts named slots and body slot is required', () {
      final scaffold = ComponentNode(
        id: 'scaffold',
        type: 'Scaffold',
        properties: {},
        children: [],
        actions: [],
        slots: {
          'appBar': null,
          'body': null,
          'drawer': null,
          'endDrawer': null,
          'bottomNavigationBar': null,
          'floatingActionButton': null,
          'bottomSheet': null,
        },
      );
      final child = ComponentNode(
        id: 'bodyChild',
        type: 'TextField',
        properties: {},
        children: [],
        actions: [],
      );

      final resultWithNullSlot = NestingValidator.validateDrop(scaffold, child, null);
      expect(resultWithNullSlot.success, isTrue);

      final resultWithBodySlot = NestingValidator.validateDrop(scaffold, child, 'body');
      expect(resultWithBodySlot.success, isTrue);

      final resultWithInvalidSlot = NestingValidator.validateDrop(scaffold, child, 'child');
      expect(resultWithInvalidSlot.success, isFalse);
      expect(resultWithInvalidSlot.errorMessage, contains('requires one of these slots'));

      final warnings = NestingValidator.validateNode(scaffold);
      expect(warnings, contains('Scaffold body missing'));
    });

    test('validateDrop rejects adding child to slot-only parent with direct children state', () {
      final scaffold = ComponentNode(
        id: 'scaffold-invalid',
        type: 'Scaffold',
        properties: {},
        children: [
          ComponentNode(
            id: 'invalid-child',
            type: 'TextField',
            properties: {},
            children: [],
            actions: [],
          ),
        ],
        actions: [],
        slots: {
          'appBar': null,
          'body': null,
          'drawer': null,
          'endDrawer': null,
          'bottomNavigationBar': null,
          'floatingActionButton': null,
          'bottomSheet': null,
        },
      );
      final child = ComponentNode(
        id: 'bodyChild',
        type: 'TextField',
        properties: {},
        children: [],
        actions: [],
      );

      final result = NestingValidator.validateDrop(scaffold, child, 'body');
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('only supports named slots'));
    });

    test('validateDrop rejects second child in legacy direct-child Container state', () {
      final container = ComponentNode(
        id: 'container-invalid',
        type: 'Container',
        properties: {},
        children: [
          ComponentNode(
            id: 'existing-child',
            type: 'TextField',
            properties: {},
            children: [],
            actions: [],
          ),
        ],
        actions: [],
        slots: {'child': null},
      );
      final newChild = ComponentNode(
        id: 'new-child',
        type: 'TextField',
        properties: {},
        children: [],
        actions: [],
      );

      final result = NestingValidator.validateDrop(container, newChild, null);
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('only supports named slots'));
    });

    test('effectiveSlotName returns null for Row and Column when no slot specified', () {
      final row = ComponentNode(
        id: 'row',
        type: 'Row',
        properties: {},
        children: [],
        actions: [],
      );
      final column = row.copyWith(type: 'Column');

      expect(NestingValidator.effectiveSlotName(row, null), isNull);
      expect(NestingValidator.effectiveSlotName(column, null), isNull);
    });

    test('effectiveSlotName defaults Scaffold drop target to body', () {
      final scaffold = ComponentNode(
        id: 'scaffold',
        type: 'Scaffold',
        properties: {},
        children: [],
        actions: [],
        slots: {
          'appBar': null,
          'body': null,
          'drawer': null,
          'endDrawer': null,
          'bottomNavigationBar': null,
          'floatingActionButton': null,
          'bottomSheet': null,
        },
      );

      expect(NestingValidator.effectiveSlotName(scaffold, null), 'body');
    });

    test('validateNode warns when single-child widgets contain more than one child', () {
      final invalidContainer = ComponentNode(
        id: 'invalid',
        type: 'Container',
        properties: {},
        children: [
          ComponentNode(
            id: 'first',
            type: 'TextField',
            properties: {},
            children: [],
            actions: [],
          ),
          ComponentNode(
            id: 'second',
            type: 'TextField',
            properties: {},
            children: [],
            actions: [],
          ),
        ],
        actions: [],
        slots: {'child': null},
      );

      final warnings = NestingValidator.validateNode(invalidContainer);
      expect(warnings, contains('Container contains 2 children'));
    });

    test('validateNode warns when AppBar contains direct children instead of named slots', () {
      final appBar = ComponentNode(
        id: 'appbar-invalid',
        type: 'AppBar',
        properties: {},
        children: [
          ComponentNode(
            id: 'child',
            type: 'Text',
            properties: {'text': 'Hello'},
            children: [],
            actions: [],
          ),
        ],
        actions: [],
        slots: {'title': null, 'leading': null, 'actions': null},
      );

      final warnings = NestingValidator.validateNode(appBar);
      expect(warnings, contains('AppBar only supports named slots and cannot contain direct children'));
    });
  });
}
