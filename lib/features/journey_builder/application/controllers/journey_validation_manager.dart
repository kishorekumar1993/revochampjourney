import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/journey_models.dart';
import 'journey_step_manager.dart';

mixin JourneyValidationManager on StateNotifier<JourneyConfig>, JourneyStepManager {
  // --- Step Collection Helpers (Conditions, Validations, APIs, Actions) ---

  void addConditionToStep(String stepId, StepCondition condition) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    updateStep(stepId, step.copyWith(conditions: [...step.conditions, condition]));
  }

  void updateConditionInStep(String stepId, int index, StepCondition condition) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    final newConds = List<StepCondition>.from(step.conditions);
    newConds[index] = condition;
    updateStep(stepId, step.copyWith(conditions: newConds));
  }

  void removeConditionFromStep(String stepId, int index) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    final newConds = List<StepCondition>.from(step.conditions)..removeAt(index);
    updateStep(stepId, step.copyWith(conditions: newConds));
  }

  void addValidationToStep(String stepId, StepValidation validation) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    updateStep(stepId, step.copyWith(validations: [...step.validations, validation]));
  }

  void updateValidationInStep(String stepId, int index, StepValidation validation) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    final newVals = List<StepValidation>.from(step.validations);
    newVals[index] = validation;
    updateStep(stepId, step.copyWith(validations: newVals));
  }

  void removeValidationFromStep(String stepId, int index) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    final newVals = List<StepValidation>.from(step.validations)..removeAt(index);
    updateStep(stepId, step.copyWith(validations: newVals));
  }

  void addApiCallToStep(String stepId, StepAPI api) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    updateStep(stepId, step.copyWith(apiCalls: [...step.apiCalls, api]));
  }

  void updateApiCallInStep(String stepId, int index, StepAPI api) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    final newApis = List<StepAPI>.from(step.apiCalls);
    newApis[index] = api;
    updateStep(stepId, step.copyWith(apiCalls: newApis));
  }

  void removeApiCallFromStep(String stepId, int index) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    final newApis = List<StepAPI>.from(step.apiCalls)..removeAt(index);
    updateStep(stepId, step.copyWith(apiCalls: newApis));
  }

  void addActionToStep(String stepId, StepAction action) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    updateStep(stepId, step.copyWith(actions: [...step.actions, action]));
  }

  void updateActionInStep(String stepId, int index, StepAction action) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    final newActions = List<StepAction>.from(step.actions);
    newActions[index] = action;
    updateStep(stepId, step.copyWith(actions: newActions));
  }

  void removeActionFromStep(String stepId, int index) {
    final stepIndex = state.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;
    final step = state.steps[stepIndex];
    final newActions = List<StepAction>.from(step.actions)..removeAt(index);
    updateStep(stepId, step.copyWith(actions: newActions));
  }
}

// Validation and condition evaluation functions
class EngineHelper {
  static List<JourneyField> flattenFields(List<JourneyField> fields) {
    final flattened = <JourneyField>[];
    for (final field in fields) {
      flattened.add(field);
      if (field.nestedFields != null && field.nestedFields!.isNotEmpty) {
        flattened.addAll(flattenFields(field.nestedFields!));
      }
    }
    return flattened;
  }

  static List<JourneyField> updateFieldRecursive(List<JourneyField> fields, String fieldId, JourneyField updatedField) {
    return fields.map((field) {
      if (field.id == fieldId) return updatedField;
      if (field.nestedFields != null && field.nestedFields!.isNotEmpty) {
        return field.copyWith(
          nestedFields: updateFieldRecursive(field.nestedFields!, fieldId, updatedField),
        );
      }
      return field;
    }).toList();
  }

  static List<JourneyField> addFieldToParent(List<JourneyField> fields, String parentId, JourneyField newField) {
    return fields.map((field) {
      if (field.id == parentId) {
        final nested = List<JourneyField>.from(field.nestedFields ?? [])..add(newField);
        return field.copyWith(nestedFields: nested);
      }
      if (field.nestedFields != null && field.nestedFields!.isNotEmpty) {
        return field.copyWith(
          nestedFields: addFieldToParent(field.nestedFields!, parentId, newField),
        );
      }
      return field;
    }).toList();
  }

  static List<JourneyField> removeFieldRecursive(List<JourneyField> fields, String fieldId) {
    return fields.where((f) => f.id != fieldId).map((field) {
      if (field.nestedFields != null && field.nestedFields!.isNotEmpty) {
        return field.copyWith(
          nestedFields: removeFieldRecursive(field.nestedFields!, fieldId),
        );
      }
      return field;
    }).toList();
  }

  static bool evaluateCondition(StepCondition cond, Map<String, dynamic> values) {
    final val = values[cond.field]?.toString();
    if (val == null) return false;
    switch (cond.operator) {
      case 'equals':
        return val.toLowerCase() == cond.value.toLowerCase();
      case 'notEquals':
        return val.toLowerCase() != cond.value.toLowerCase();
      case 'contains':
        return val.toLowerCase().contains(cond.value.toLowerCase());
      default:
        return false;
    }
  }

  // Field visible condition evaluation helper
  static bool isFieldVisible(JourneyField field, Map<String, dynamic> values) {
    if (!field.visible) return false;
    if (field.visibleIf == null) return true;

    final targetField = field.visibleIf!['field'];
    final expectedVal = field.visibleIf!['equals'] ?? field.visibleIf!['value'];
    final operator = field.visibleIf!['operator']?.toString() ?? 'equals';
    if (targetField == null || expectedVal == null) return true;

    final currentVal = values[targetField]?.toString();
    if (currentVal == null) return false;
    switch (operator) {
      case 'notEquals':
        return currentVal.toLowerCase() != expectedVal.toString().toLowerCase();
      case 'contains':
        return currentVal.toLowerCase().contains(expectedVal.toString().toLowerCase());
      case 'equals':
      default:
        return currentVal.toLowerCase() == expectedVal.toString().toLowerCase();
    }
  }
}