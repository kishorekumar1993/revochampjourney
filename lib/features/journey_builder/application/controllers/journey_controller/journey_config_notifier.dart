import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_step_manager.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_validation_manager.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_import_manager.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_export_manager.dart';
import 'active_step_provider.dart';
import 'initial_journey.dart';

class JourneyConfigNotifier extends StateNotifier<JourneyConfig>
    with
        JourneyImportManager,
        JourneyExportManager,
        JourneyStepManager,
        JourneyValidationManager {
  @override
  final Ref ref;

  JourneyConfigNotifier(this.ref, JourneyConfig initial) : super(initial);

  void updateJourneyName(String name) {
    state = state.copyWith(journeyName: name);
  }

  void updateJourneyVersion(String ver) {
    state = state.copyWith(version: ver);
  }

  void updateJourneyDescription(String desc) {
    state = state.copyWith(description: desc);
  }

  void updateJourneyCategory(String cat) {
    state = state.copyWith(category: cat);
  }

  void updateJourneyLocale(String loc) {
    state = state.copyWith(locale: loc);
  }

  void updateJourneyPlatform(String plat) {
    state = state.copyWith(platform: plat);
  }

  // Steps operations
  @override
  void addStep(JourneyStep step) {
    final updatedSteps = [...state.steps, step];
    state = state.copyWith(steps: updatedSteps);
  }

  void _checkAndClearSelectedField(List<JourneyField> removedFields) {
    final selectedId = ref.read(selectedFieldIdProvider);
    if (selectedId == null) return;
    final flattened = EngineHelper.flattenFields(removedFields);
    if (flattened.any((f) => f.id == selectedId)) {
      ref.read(selectedFieldIdProvider.notifier).state = null;
    }
  }

  @override
  void removeStep(String stepId) {
    final stepToRemove = state.steps.firstWhere((s) => s.id == stepId);
    _checkAndClearSelectedField(stepToRemove.fields);

    final updatedSteps = state.steps.where((s) => s.id != stepId).toList();
    state = state.copyWith(steps: updatedSteps);
  }

  @override
  void updateStep(String stepId, JourneyStep updatedStep) {
    updatedStep.invalidateCache();
    final updatedSteps = state.steps
        .map((s) => s.id == stepId ? updatedStep : s)
        .toList();
    state = state.copyWith(steps: updatedSteps);
  }

  @override
  void updateStepLayout(
    String stepId,
    Map<String, dynamic> screenLayout,
    List<JourneyField> fields,
  ) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    final updatedStep = step.copyWith(
      screenLayout: screenLayout,
      fields: fields,
    );
    updateStep(stepId, updatedStep);
  }

  // --- Step Collection Helpers (Conditions, Validations, APIs, Actions) ---

  @override
  void addConditionToStep(String stepId, StepCondition condition) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    updateStep(
      stepId,
      step.copyWith(conditions: [...step.conditions, condition]),
    );
  }

  @override
  void updateConditionInStep(
    String stepId,
    int index,
    StepCondition condition,
  ) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    final newConds = List<StepCondition>.from(step.conditions);
    newConds[index] = condition;
    updateStep(stepId, step.copyWith(conditions: newConds));
  }

  @override
  void removeConditionFromStep(String stepId, int index) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    final newConds = List<StepCondition>.from(step.conditions)..removeAt(index);
    updateStep(stepId, step.copyWith(conditions: newConds));
  }

  @override
  void addValidationToStep(String stepId, StepValidation validation) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    updateStep(
      stepId,
      step.copyWith(validations: [...step.validations, validation]),
    );
  }

  @override
  void updateValidationInStep(
    String stepId,
    int index,
    StepValidation validation,
  ) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    final newVals = List<StepValidation>.from(step.validations);
    newVals[index] = validation;
    updateStep(stepId, step.copyWith(validations: newVals));
  }

  @override
  void removeValidationFromStep(String stepId, int index) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    final newVals = List<StepValidation>.from(step.validations)
      ..removeAt(index);
    updateStep(stepId, step.copyWith(validations: newVals));
  }

  @override
  void addApiCallToStep(String stepId, StepAPI api) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    updateStep(stepId, step.copyWith(apiCalls: [...step.apiCalls, api]));
  }

  @override
  void updateApiCallInStep(String stepId, int index, StepAPI api) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    final newApis = List<StepAPI>.from(step.apiCalls);
    newApis[index] = api;
    updateStep(stepId, step.copyWith(apiCalls: newApis));
  }

  @override
  void removeApiCallFromStep(String stepId, int index) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);

    if (stepIndex == -1) return;

    final step = state.steps[stepIndex];

    if (index < 0 || index >= step.apiCalls.length) {
      return;
    }

    final updatedApis = List<StepAPI>.from(step.apiCalls)..removeAt(index);

    final updatedStep = step.copyWith(apiCalls: updatedApis);

    updatedStep.invalidateCache();

    final updatedSteps = List<JourneyStep>.from(state.steps);

    updatedSteps[stepIndex] = updatedStep;

    state = state.copyWith(steps: updatedSteps);
  }

  @override
  void reorderFieldsInStep(String stepId, int oldIndex, int newIndex) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;

    final step = state.steps[stepIndex];
    final updatedFields = List<JourneyField>.from(step.fields);
    if (oldIndex < 0 || oldIndex >= updatedFields.length) return;
    if (newIndex < 0 || newIndex > updatedFields.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final field = updatedFields.removeAt(oldIndex);
    updatedFields.insert(newIndex, field);

    final updatedStep = step.copyWith(fields: updatedFields);
    updatedStep.invalidateCache();
    final updatedSteps = List<JourneyStep>.from(state.steps);
    updatedSteps[stepIndex] = updatedStep;

    state = state.copyWith(steps: updatedSteps);
  }

  // Add a field into the nestedFields of a container field (section/card/tabs/accordion/repeater)
  @override
  void addFieldToNestedContainer(
    String stepId,
    String parentFieldId,
    JourneyField newField,
  ) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;

    final step = state.steps[stepIndex];

    final flatFields = step.flattenedFields;
    if (!flatFields.any((f) => f.id == parentFieldId)) {
      return; // Parent not found, avoid making a stale tree
    }

    final updatedFields = EngineHelper.addFieldToParent(
      step.fields,
      parentFieldId,
      newField,
    );

    final updatedStep = step.copyWith(fields: updatedFields);
    updatedStep.invalidateCache();
    final updatedSteps = List<JourneyStep>.from(state.steps);
    updatedSteps[stepIndex] = updatedStep;

    state = state.copyWith(steps: updatedSteps);
  }

  // Remove a field from any nested container recursively
  @override
  void removeFieldFromNestedContainer(String stepId, String fieldId) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;

    final step = state.steps[stepIndex];

    final fieldsToRemove = step.flattenedFields
        .where((f) => f.id == fieldId)
        .toList();
    if (fieldsToRemove.isEmpty) return; // Field not found, safely return

    _checkAndClearSelectedField(fieldsToRemove);

    final updatedFields = EngineHelper.removeFieldRecursive(
      step.fields,
      fieldId,
    );

    final updatedStep = step.copyWith(fields: updatedFields);
    updatedStep.invalidateCache();
    final updatedSteps = List<JourneyStep>.from(state.steps);
    updatedSteps[stepIndex] = updatedStep;

    state = state.copyWith(steps: updatedSteps);
  }

  void syncWithHistory(JourneyConfig config) {
    state = config;
  }
}

final journeyConfigProvider =
    StateNotifierProvider<JourneyConfigNotifier, JourneyConfig>((ref) {
      return JourneyConfigNotifier(ref, getInitialJourney());
    });
