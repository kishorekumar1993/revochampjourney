import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/providers/journey_provider.dart';
import 'package:revojourneytryone/features/journey_builder/data/models.dart';

import 'journey_history_manager.dart';
import 'journey_validation_manager.dart';

void main() {
  group('HistoryNotifier Tests', () {
    test('push adds new state to past and clears future', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final historyNotifier = container.read(historyProvider.notifier);
      final initialConfig = container.read(historyProvider).present;

      final newConfig = initialConfig.copyWith(journeyName: 'Updated Journey');
      historyNotifier.push(newConfig);

      final historyState = container.read(historyProvider);
      expect(historyState.past.length, 1);
      expect(historyState.past.last.journeyName, 'Motor Insurance Journey');
      expect(historyState.present.journeyName, 'Updated Journey');
      expect(historyState.future.isEmpty, true);
    });

    test('undo restores previous state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final historyNotifier = container.read(historyProvider.notifier);
      final initialConfig = container.read(historyProvider).present;

      final newConfig = initialConfig.copyWith(journeyName: 'Updated Journey');
      historyNotifier.push(newConfig);
      
      historyNotifier.undo();

      final historyState = container.read(historyProvider);
      expect(historyState.present.journeyName, 'Motor Insurance Journey');
      expect(historyState.future.length, 1);
      expect(historyState.future.first.journeyName, 'Updated Journey');
    });
  });

  group('FormValuesNotifier Tests', () {
    test('updateValue updates specific field without mutating unexpectedly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final formValuesNotifier = container.read(formValuesProvider.notifier);
      
      formValuesNotifier.updateValue('fullName', 'John Doe');
      formValuesNotifier.updateValue('email', 'john@example.com');
      
      final state = container.read(formValuesProvider);
      expect(state['fullName'], 'John Doe');
      expect(state['email'], 'john@example.com');
      expect(state.length, 2);
    });
  });

  group('EngineHelper Tests', () {
    test('flattenFields flattens a nested field tree', () {
      final fields = [
        InputComponent(id: '1', label: 'Field 1', type: 'text'),
        LayoutComponent(
          id: '2',
          label: 'Section 1',
          type: 'section',
          nestedFields: [
            InputComponent(id: '3', label: 'Field 3', type: 'text'),
            LayoutComponent(
              id: '4',
              label: 'Section 2',
              type: 'section',
              nestedFields: [
                InputComponent(id: '5', label: 'Field 5', type: 'text'),
              ],
            ),
          ],
        ),
      ];

      final flattened = EngineHelper.flattenFields(fields);
      
      expect(flattened.length, 5);
      expect(flattened.map((f) => f.id).toList(), ['1', '2', '3', '4', '5']);
    });
  });

  group('JourneyStep Memoization Tests', () {
    test('flattenedFields caches and invalidates correctly', () {
      final step = JourneyStep(
        id: 'step1',
        title: 'Step 1',
        fields: [
          LayoutComponent(
            id: 'section1',
            label: 'Section 1',
            type: 'section',
            nestedFields: [
              InputComponent(id: 'field1', label: 'Field 1', type: 'text'),
            ],
          ),
        ],
      );

      expect(step.flattenedFields.length, 2);

      final copiedStep = step.copyWith();
      expect(copiedStep.flattenedFields.length, 2);
    });
  });
}