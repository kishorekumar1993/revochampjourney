import 'package:flutter_test/flutter_test.dart';

import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_runner/application/journey_execution_engine.dart';
import 'package:revojourneytryone/features/journey_runner/application/journey_step_resolver.dart';
import 'package:revojourneytryone/features/journey_runner/domain/journey_execution_models.dart';

void main() {
  late JourneyConfig config;
  late JourneyExecutionEngine engine;

  setUp(() {
    config = getInitialJourney();
    engine = JourneyExecutionEngine();
  });

  test('resolveNextStepId follows nextStep from journey JSON', () {
    final resolver = JourneyStepResolver();
    final personal = config.steps.firstWhere((s) => s.id == 'personal');
    final next = resolver.resolveNextStepId(personal, {});
    expect(next, 'vehicle');
  });

  test('next action validates required fields before transition', () async {
    final personal = config.steps.firstWhere((s) => s.id == 'personal');
    final result = await engine.execute(
      JourneyExecutionRequest(
        action: JourneyAction.next,
        config: config,
        currentStep: personal,
        formValues: {},
      ),
    );

    expect(result.status, JourneyExecutionStatus.validationFailed);
    expect(result.fieldErrors.containsKey('fullName'), isTrue);
  });

  test('next action transitions when required data is present', () async {
    final personal = config.steps.firstWhere((s) => s.id == 'personal');
    final result = await engine.execute(
      JourneyExecutionRequest(
        action: JourneyAction.next,
        config: config,
        currentStep: personal,
        formValues: {
          'fullName': 'John Doe',
          'dob': '01/01/1990',
          'mobile': '9876543210',
          'gender': 'Male',
        },
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.targetStepId, 'vehicle');
    expect(result.stepHistory, ['personal']);
  });

  test('save draft returns draft payload without validation failure', () async {
    final personal = config.steps.firstWhere((s) => s.id == 'personal');
    final result = await engine.execute(
      JourneyExecutionRequest(
        action: JourneyAction.saveDraft,
        config: config,
        currentStep: personal,
        formValues: {'fullName': 'Partial'},
        stepHistory: const [],
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.savedDraft?.currentStepId, 'personal');
    expect(result.savedDraft?.formValues['fullName'], 'Partial');
  });

  test('previous uses step history instead of linear index', () async {
    final vehicle = config.steps.firstWhere((s) => s.id == 'vehicle');
    final result = await engine.execute(
      JourneyExecutionRequest(
        action: JourneyAction.previous,
        config: config,
        currentStep: vehicle,
        formValues: const {},
        stepHistory: const ['personal'],
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.targetStepId, 'personal');
    expect(result.stepHistory, isEmpty);
  });
}
