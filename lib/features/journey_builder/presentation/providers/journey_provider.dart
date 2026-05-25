import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models.dart';

// Initial state creator to populate "Motor Insurance" as seen in the mockup
JourneyConfig getInitialJourney() {
  return JourneyConfig(
    journeyName: "Motor Insurance Journey",
    version: "1.0.0",
    steps: [
      JourneyStep(
        id: "personal",
        title: "Personal Details",
        description: "Please provide your basic information",
        nextStep: "vehicle",
        fields: [
          InputComponent(
            id: "fullName",
            label: "Full Name",
            type: "text",
            required: true,
            placeholder: "Enter full name",
          ),
          InputComponent(
            id: "dob",
            label: "Date of Birth",
            type: "date",
            required: true,
            placeholder: "DD/MM/YYYY",
          ),
          InputComponent(
            id: "mobile",
            label: "Mobile Number",
            type: "phone",
            required: true,
            placeholder: "Enter mobile number",
          ),
          InputComponent(
            id: "email",
            label: "Email Address",
            type: "text",
            required: false,
            placeholder: "Enter email address",
          ),
          OptionsComponent(
            id: "gender",
            label: "Gender",
            type: "radio",
            required: true,
            options: ["Male", "Female", "Other"],
            defaultValue: "Male",
          ),
          OptionsComponent(
            id: "maritalStatus",
            label: "Marital Status",
            type: "dropdown",
            required: false,
            placeholder: "Select marital status",
            options: ["Single", "Married", "Divorced", "Widowed"],
          ),
          InputComponent(
            id: "address",
            label: "Address",
            type: "textarea",
            required: false,
            placeholder: "Enter your current address",
          ),
        ],
        validations: [
          StepValidation(type: "required", field: "fullName", message: "Full Name is required"),
          StepValidation(type: "required", field: "mobile", message: "Mobile number is required"),
          StepValidation(type: "required", field: "dob", message: "Date of Birth is required"),
        ],
        conditions: [
          StepCondition(type: "visibleIf", field: "gender", operator: "equals", value: "Female"),
          StepCondition(type: "enableIf", field: "email", operator: "contains", value: "@"),
        ],
        apiCalls: [
          StepAPI(method: "POST", url: "/api/v1/personal-info", description: "Save personal details info"),
        ],
        actions: [
          StepAction(trigger: "onSubmit", actionType: "apiCall", details: "Submit personal details"),
        ],
      ),
      JourneyStep(
        id: "vehicle",
        title: "Vehicle Details",
        description: "Please provide vehicle information",
        nextStep: "nominee",
        fields: [
          InputComponent(
            id: "vehicleNum",
            label: "Vehicle Number",
            type: "text",
            required: true,
            placeholder: "e.g. MH-12-AB-1234",
          ),
          OptionsComponent(
            id: "vehicleMake",
            label: "Make",
            type: "dropdown",
            required: true,
            placeholder: "Select manufacturer",
            options: ["Toyota", "Honda", "Hyundai", "Suzuki", "Tata"],
          ),
          InputComponent(
            id: "vehicleModel",
            label: "Model",
            type: "text",
            required: true,
            placeholder: "Enter vehicle model",
          ),
          OptionsComponent(
            id: "regYear",
            label: "Registration Year",
            type: "dropdown",
            required: true,
            placeholder: "Select registration year",
            options: ["2026", "2025", "2024", "2023", "2022", "2021", "2020"],
          ),
        ],
      ),
      JourneyStep(
        id: "nominee",
        title: "Nominee Details",
        description: "Provide nominee description for coverage",
        nextStep: "documents",
        fields: [
          InputComponent(
            id: "nomineeName",
            label: "Nominee Full Name",
            type: "text",
            required: true,
            placeholder: "Enter nominee name",
          ),
          OptionsComponent(
            id: "nomineeRelation",
            label: "Relationship",
            type: "dropdown",
            required: true,
            placeholder: "Select relationship",
            options: ["Spouse", "Father", "Mother", "Son", "Daughter"],
          ),
        ],
      ),
      JourneyStep(
        id: "documents",
        title: "Upload Documents",
        description: "Upload necessary documents",
        nextStep: "review",
        fields: [
          InputComponent(
            id: "panDoc",
            label: "PAN Card",
            type: "file",
            required: true,
          ),
          InputComponent(
            id: "drivingLicense",
            label: "Driving License",
            type: "file",
            required: true,
          ),
        ],
      ),
      JourneyStep(
        id: "review",
        title: "Review & Confirm",
        description: "Review your submitted data",
        nextStep: "payment",
        fields: [
          OptionsComponent(
            id: "termsAccepted",
            label: "I accept the policy terms and declarations",
            type: "switch",
            required: true,
            defaultValue: "false",
          ),
        ],
      ),
      JourneyStep(
        id: "payment",
        title: "Payment",
        description: "Enter premium payment details",
        nextStep: "success",
        fields: [
          OptionsComponent(
            id: "paymentMethod",
            label: "Select Payment Mode",
            type: "radio",
            required: true,
            options: ["Credit Card", "Debit Card", "UPI", "Net Banking"],
            defaultValue: "Credit Card",
          ),
          InputComponent(
            id: "otpVerify",
            label: "Verification Code",
            type: "otp",
            required: true,
            placeholder: "Enter 6-digit OTP",
          ),
        ],
      ),
      JourneyStep(
        id: "success",
        title: "Success",
        description: "Your policy generated successfully!",
        fields: [
          LayoutComponent(
            id: "successDiv",
            label: "Congratulations! Policy PDF has been sent to your email.",
            type: "divider",
          ),
        ],
      ),
    ],
  );
}

// Active step ID
final activeStepIdProvider = StateProvider<String>((ref) => "personal");

// Selected Field ID (the one selected in the design canvas)
final selectedFieldIdProvider = StateProvider<String?>((ref) => null);

// History State for Undo/Redo operations
class HistoryState {
  final List<JourneyConfig> past;
  final JourneyConfig present;
  final List<JourneyConfig> future;

  HistoryState({
    required this.past,
    required this.present,
    required this.future,
  });
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final Ref _ref;
  static const int maxHistoryLength = 50;
  bool _isUndoing = false;

  HistoryNotifier(this._ref, JourneyConfig initial)
      : super(HistoryState(past: [], present: initial, future: []));

  void push(JourneyConfig nextConfig) {
    if (_isUndoing) return;
    var newPast = [...state.past, state.present.copyWith()];
    if (newPast.length > maxHistoryLength) {
      newPast = newPast.sublist(newPast.length - maxHistoryLength);
    }
    state = HistoryState(
      past: newPast,
      present: nextConfig,
      future: [],
    );
  }

  void undo() {
    if (state.past.isEmpty) return;
    final previous = state.past.last;
    final newPast = state.past.sublist(0, state.past.length - 1);
    state = HistoryState(
      past: newPast,
      present: previous,
      future: [state.present.copyWith(), ...state.future],
    );
    _applyToConfig(state.present);
  }

  void redo() {
    if (state.future.isEmpty) return;
    final next = state.future.first;
    final newFuture = state.future.sublist(1);
    state = HistoryState(
      past: [...state.past, state.present.copyWith()],
      present: next,
      future: newFuture,
    );
    _applyToConfig(state.present);
  }

  void reset(JourneyConfig config) {
    state = HistoryState(past: [], present: config, future: []);
    _applyToConfig(config);
  }

  void rollbackTo(int pastIndex) {
    if (pastIndex < 0 || pastIndex >= state.past.length) return;
    final target = state.past[pastIndex];
    final newPast = state.past.sublist(0, pastIndex);
    final newFuture = [
      ...state.past.sublist(pastIndex + 1),
      state.present.copyWith(),
      ...state.future
    ];
    state = HistoryState(
      past: newPast,
      present: target,
      future: newFuture,
    );
    _applyToConfig(state.present);
  }

  void _applyToConfig(JourneyConfig config) {
    _isUndoing = true;
    _ref.read(journeyConfigProvider.notifier).syncWithHistory(config);
    _isUndoing = false;
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final notifier = HistoryNotifier(ref, getInitialJourney());
  ref.listen<JourneyConfig>(journeyConfigProvider, (prev, next) {
    notifier.push(next);
  });
  return notifier;
});

// Journey Config Provider
class JourneyConfigNotifier extends StateNotifier<JourneyConfig> {
  final Ref _ref;

  JourneyConfigNotifier(this._ref, JourneyConfig initial) : super(initial);

  bool updateFromJson(String jsonStr) {
    try {
      final rawDecoded = json.decode(jsonStr);
      final decoded = json.decode(json.encode(rawDecoded)) as Map<String, dynamic>;
      final newConfig = JourneyConfig.fromJson(decoded);
      state = newConfig;
      
      // Clear the history stack when a new JSON is completely loaded
      _ref.read(historyProvider.notifier).reset(newConfig);

      // Reset active step to first step of the loaded configuration
      if (newConfig.steps.isNotEmpty) {
        _ref.read(activeStepIdProvider.notifier).state = newConfig.steps.first.id;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

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
  void addStep(JourneyStep step) {
    final updatedSteps = [...state.steps, step];
    state = state.copyWith(steps: updatedSteps);
  }

  void _checkAndClearSelectedField(List<JourneyField> removedFields) {
    final selectedId = _ref.read(selectedFieldIdProvider);
    if (selectedId == null) return;
    final flattened = EngineHelper.flattenFields(removedFields);
    if (flattened.any((f) => f.id == selectedId)) {
      _ref.read(selectedFieldIdProvider.notifier).state = null;
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

  void syncWithHistory(JourneyConfig config) {
    state = config;
  }
}

final journeyConfigProvider = StateNotifierProvider<JourneyConfigNotifier, JourneyConfig>((ref) {
  return JourneyConfigNotifier(ref, getInitialJourney());
});

// Centralized dynamic form state mapping provider (Step Values)
// Map<String, dynamic> supports strings, booleans, lists (repeater/grid rows), nested objects
class FormValuesNotifier extends StateNotifier<Map<String, dynamic>> {
  FormValuesNotifier() : super({});

  void updateValue(String fieldId, dynamic value) {
    state = Map<String, dynamic>.of(state)..[fieldId] = value;
  }

  void updateValueByPath(List<dynamic> path, dynamic value) {
    if (path.isEmpty) return;
    final newState = Map<String, dynamic>.from(state);
    _setNested(newState, path, value);
    state = newState;
  }

  void _setNested(Map<String, dynamic> current, List<dynamic> path, dynamic value) {
    if (path.length == 1) {
      current[path.first.toString()] = value;
      return;
    }
    
    final key = path.first.toString();
    final nextKey = path[1];
    
    if (nextKey is int) {
      if (!current.containsKey(key) || current[key] is! List) {
        current[key] = [];
      }
      final list = List<dynamic>.from(current[key]);
      while (list.length <= nextKey) {
        list.add(<String, dynamic>{});
      }
      if (path.length == 2) {
        list[nextKey] = value;
      } else {
        if (list[nextKey] is! Map) list[nextKey] = <String, dynamic>{};
        final nextMap = Map<String, dynamic>.from(list[nextKey]);
        _setNested(nextMap, path.sublist(2), value);
        list[nextKey] = nextMap;
      }
      current[key] = list;
    } else {
      if (!current.containsKey(key) || current[key] is! Map) {
        current[key] = <String, dynamic>{};
      }
      final nextMap = Map<String, dynamic>.from(current[key]);
      _setNested(nextMap, path.sublist(1), value);
      current[key] = nextMap;
    }
  }

  void clear() {
    state = {};
  }

  void resetWithDefaults(JourneyStep step) {
    final defaults = <String, dynamic>{};
    for (var f in step.flattenedFields) {
      if (f.defaultValue != null) {
        defaults[f.id] = f.defaultValue!;
      }
    }
    state = defaults;
  }
}

final formValuesProvider = StateNotifierProvider<FormValuesNotifier, Map<String, dynamic>>((ref) {
  return FormValuesNotifier();
});

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

class JourneysListNotifier extends StateNotifier<List<JourneyConfig>> {
  JourneysListNotifier(super.initial);

  void addJourney(JourneyConfig config) {
    if (!state.any((j) => j.journeyName == config.journeyName)) {
      state = [...state, config];
    }
  }

  void removeJourney(String name) {
    state = state.where((j) => j.journeyName != name).toList();
  }

  void saveJourney(JourneyConfig config) {
    final index = state.indexWhere((j) => j.journeyName == config.journeyName);
    if (index != -1) {
      final updatedList = List<JourneyConfig>.from(state);
      updatedList[index] = config;
      state = updatedList;
    } else {
      state = [...state, config];
    }
  }
}

final journeysListProvider = StateNotifierProvider<JourneysListNotifier, List<JourneyConfig>>((ref) {
  final notifier = JourneysListNotifier([
    getInitialJourney(),
  ]);
  Timer? debounceTimer;
  ref.listen<JourneyConfig>(journeyConfigProvider, (prev, next) {
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(milliseconds: 500), () {
      notifier.saveJourney(next);
    });
  });
  ref.onDispose(() {
    debounceTimer?.cancel();
  });
  return notifier;
});

class JourneyRunsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  JourneyRunsNotifier() : super([
    {
      'id': 'RUN-1049',
      'journeyName': 'Motor Insurance Journey',
      'user': 'john.doe@gmail.com',
      'status': 'Completed',
      'currentStep': 'Success',
      'progress': 1.0,
      'stepsCount': '7/7',
      'started': '12 mins ago',
      'data': {
        'fullName': 'John Doe',
        'dob': '25/08/1992',
        'mobile': '+91 9876543210',
        'email': 'john.doe@gmail.com',
        'gender': 'Male',
        'maritalStatus': 'Single',
        'vehicleNum': 'MH-12-PQ-9988',
        'vehicleMake': 'Toyota',
        'vehicleModel': 'Fortuner',
        'regYear': '2025',
        'nomineeName': 'Jane Doe',
        'nomineeRelation': 'Spouse',
        'panDoc': 'pan_uploaded.png',
        'drivingLicense': 'license_scan.jpg',
        'paymentMethod': 'UPI',
        'termsAccepted': 'true',
      }
    },
    {
      'id': 'RUN-1048',
      'journeyName': 'User KYC Onboarding',
      'user': 'alice.smith@yahoo.com',
      'status': 'In Progress',
      'currentStep': 'Facial Verification',
      'progress': 0.75,
      'stepsCount': '3/4',
      'started': '45 mins ago',
      'data': {
        'firstName': 'Alice',
        'lastName': 'Smith',
        'panNumber': 'DKFPD8812K',
        'panDoc': 'alice_pan.png',
        'aadhaarFront': 'aadhaar_front.jpg',
      }
    },
    {
      'id': 'RUN-1047',
      'journeyName': 'Personal Loan Application',
      'user': 'bob.jones@outlook.com',
      'status': 'Draft',
      'currentStep': 'Employment Details',
      'progress': 0.25,
      'stepsCount': '1/4',
      'started': '2 hours ago',
      'data': {
        'fullName': 'Bob Jones',
        'loanAmount': '25000',
      }
    },
    {
      'id': 'RUN-1046',
      'journeyName': 'Motor Insurance Journey',
      'user': 'sarah.k@hotmail.com',
      'status': 'Failed Validation',
      'currentStep': 'Nominee Details',
      'progress': 0.57,
      'stepsCount': '4/7',
      'started': '1 day ago',
      'data': {
        'fullName': 'Sarah Kerigan',
        'dob': '09/11/1988',
        'mobile': '+91 8877665544',
        'gender': 'Female',
        'vehicleNum': 'DL-03-AB-1122',
        'vehicleMake': 'Honda',
      }
    },
    {
      'id': 'RUN-1045',
      'journeyName': 'Service Feedback Survey',
      'user': 'steve.jobs@apple.com',
      'status': 'Completed',
      'currentStep': 'Contact Info',
      'progress': 1.0,
      'stepsCount': '3/3',
      'started': '2 days ago',
      'data': {
        'overallRating': '5 - Highly Satisfied',
        'feedbackComments': 'Awesome builder platform! Love the laptop simulator feature.',
        'followUpEmail': 'steve.jobs@apple.com',
      }
    }
  ]);

  void addRun(Map<String, dynamic> run) {
    state = [run, ...state];
  }
}

final journeyRunsProvider = StateNotifierProvider<JourneyRunsNotifier, List<Map<String, dynamic>>>((ref) {
  return JourneyRunsNotifier();
});
