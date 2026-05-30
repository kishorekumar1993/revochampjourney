import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/journey_models.dart';
import 'journey_controller.dart';
import 'journey_validation_manager.dart';

mixin JourneyStepManager on StateNotifier<JourneyConfig> {
  Ref get ref;

  // Steps operations
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

  void removeStep(String stepId) {
    final stepToRemove = state.steps.firstWhere((s) => s.id == stepId);
    _checkAndClearSelectedField(stepToRemove.fields);

    final updatedSteps = state.steps.where((s) => s.id != stepId).toList();
    state = state.copyWith(steps: updatedSteps);
  }

  void updateStep(String stepId, JourneyStep updatedStep) {
    updatedStep.invalidateCache();
    final updatedSteps = state.steps.map((s) => s.id == stepId ? updatedStep : s).toList();
    state = state.copyWith(steps: updatedSteps);
  }

  void updateStepLayout(String stepId, Map<String, dynamic> screenLayout, List<JourneyField> fields) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    final updatedStep = step.copyWith(
      screenLayout: screenLayout,
      fields: fields,
    );
    updateStep(stepId, updatedStep);
  }

  void reorderSteps(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.steps.length) return;
    if (newIndex < 0 || newIndex > state.steps.length) return;

    final updatedSteps = List<JourneyStep>.from(state.steps);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final step = updatedSteps.removeAt(oldIndex);
    updatedSteps.insert(newIndex, step);
    
    state = state.copyWith(steps: updatedSteps);
  }

  // Fields operations (mutating specific step fields)
  void addFieldToStep(String stepId, JourneyField field, {int? index}) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;

    final step = state.steps[stepIndex];
    final updatedFields = List<JourneyField>.from(step.fields);
    if (index != null && index >= 0 && index <= updatedFields.length) {
      updatedFields.insert(index, field);
    } else {
      updatedFields.add(field);
    }

    final updatedStep = step.copyWith(fields: updatedFields);
    updatedStep.invalidateCache();
    final updatedSteps = List<JourneyStep>.from(state.steps);
    updatedSteps[stepIndex] = updatedStep;

    state = state.copyWith(steps: updatedSteps);
  }

  void removeFieldFromStep(String stepId, String fieldId) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;

    final step = state.steps[stepIndex];
    final fieldsToRemove = step.fields.where((f) => f.id == fieldId).toList();
    _checkAndClearSelectedField(fieldsToRemove);

    final updatedFields = step.fields.where((f) => f.id != fieldId).toList();

    final updatedStep = step.copyWith(fields: updatedFields);
    updatedStep.invalidateCache();
    final updatedSteps = List<JourneyStep>.from(state.steps);
    updatedSteps[stepIndex] = updatedStep;

    state = state.copyWith(steps: updatedSteps);
  }

  void updateFieldInStep(String stepId, String fieldId, JourneyField updatedField) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;

    final step = state.steps[stepIndex];
    final updatedFields = EngineHelper.updateFieldRecursive(step.fields, fieldId, updatedField);

    final updatedStep = step.copyWith(fields: updatedFields);
    updatedStep.invalidateCache();
    final updatedSteps = List<JourneyStep>.from(state.steps);
    updatedSteps[stepIndex] = updatedStep;

    state = state.copyWith(steps: updatedSteps);
  }

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
  void addFieldToNestedContainer(String stepId, String parentFieldId, JourneyField newField) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;

    final step = state.steps[stepIndex];

    final flatFields = step.flattenedFields;
    if (!flatFields.any((f) => f.id == parentFieldId)) {
      return; // Parent not found, avoid making a stale tree
    }

    final updatedFields = EngineHelper.addFieldToParent(step.fields, parentFieldId, newField);

    final updatedStep = step.copyWith(fields: updatedFields);
    updatedStep.invalidateCache();
    final updatedSteps = List<JourneyStep>.from(state.steps);
    updatedSteps[stepIndex] = updatedStep;

    state = state.copyWith(steps: updatedSteps);
  }

  // Remove a field from any nested container recursively
  void removeFieldFromNestedContainer(String stepId, String fieldId) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;

    final step = state.steps[stepIndex];

    final fieldsToRemove = step.flattenedFields.where((f) => f.id == fieldId).toList();
    if (fieldsToRemove.isEmpty) return; // Field not found, safely return

    _checkAndClearSelectedField(fieldsToRemove);

    final updatedFields = EngineHelper.removeFieldRecursive(step.fields, fieldId);

    final updatedStep = step.copyWith(fields: updatedFields);
    updatedStep.invalidateCache();
    final updatedSteps = List<JourneyStep>.from(state.steps);
    updatedSteps[stepIndex] = updatedStep;

    state = state.copyWith(steps: updatedSteps);
  }
}