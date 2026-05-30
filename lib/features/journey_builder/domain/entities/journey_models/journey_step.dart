import 'journey_field.dart';
import 'step_settings_models.dart';

class JourneyStep {
  String id;
  String title;
  String description;
  String? nextStep;
  List<JourneyField> fields;
  List<StepValidation> validations;
  List<StepCondition> conditions;
  List<StepAPI> apiCalls;
  List<StepAction> actions;
  Map<String, dynamic>? screenLayout;
  List<JourneyField>? _flattenedCache;

  JourneyStep({
    required this.id,
    required this.title,
    this.description = '',
    this.nextStep,
    required this.fields,
    this.validations = const [],
    this.conditions = const [],
    this.apiCalls = const [],
    this.actions = const [],
    this.screenLayout,
  });

  List<JourneyField> get flattenedFields {
    _flattenedCache ??= _flattenFields(fields);
    return _flattenedCache!;
  }

  List<JourneyField> _flattenFields(List<JourneyField> fieldList) {
    final flattened = <JourneyField>[];
    for (final field in fieldList) {
      flattened.add(field);
      if (field.nestedFields != null && field.nestedFields!.isNotEmpty) {
        flattened.addAll(_flattenFields(field.nestedFields!));
      }
    }
    return flattened;
  }

  void invalidateCache() {
    _flattenedCache = null;
  }

  factory JourneyStep.fromJson(Map<String, dynamic> json) {
    var fieldsList = json['fields'] as List? ?? [];
    var validationsList = json['validations'] as List? ?? [];
    var conditionsList = json['conditions'] as List? ?? [];
    var apiCallsList = json['apiCalls'] as List? ?? [];
    var actionsList = json['actions'] as List? ?? [];

    return JourneyStep(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      nextStep: json['nextStep'],
      fields: fieldsList.map((field) => JourneyField.fromJson(field)).toList(),
      validations: validationsList.map((val) => StepValidation.fromJson(val)).toList(),
      conditions: conditionsList.map((cond) => StepCondition.fromJson(cond)).toList(),
      apiCalls: apiCallsList.map((api) => StepAPI.fromJson(api)).toList(),
      actions: actionsList.map((act) => StepAction.fromJson(act)).toList(),
      screenLayout: json['screenLayout'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      if (nextStep != null) 'nextStep': nextStep,
      'fields': fields.map((field) => field.toJson()).toList(),
      'validations': validations.map((v) => v.toJson()).toList(),
      'conditions': conditions.map((c) => c.toJson()).toList(),
      'apiCalls': apiCalls.map((a) => a.toJson()).toList(),
      'actions': actions.map((a) => a.toJson()).toList(),
      if (screenLayout != null) 'screenLayout': screenLayout,
    };
  }

  JourneyStep copyWith({
    String? id,
    String? title,
    String? description,
    String? nextStep,
    List<JourneyField>? fields,
    List<StepValidation>? validations,
    List<StepCondition>? conditions,
    List<StepAPI>? apiCalls,
    List<StepAction>? actions,
    Map<String, dynamic>? screenLayout,
  }) {
    return JourneyStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      nextStep: nextStep ?? this.nextStep,
      fields: fields ?? this.fields.map((f) => f.copyWith()).toList(),
      validations: validations ?? this.validations.map((v) => v.copyWith()).toList(),
      conditions: conditions ?? this.conditions.map((c) => c.copyWith()).toList(),
      apiCalls: apiCalls ?? this.apiCalls.map((a) => a.copyWith()).toList(),
      actions: actions ?? this.actions.map((a) => a.copyWith()).toList(),
      screenLayout: screenLayout ?? this.screenLayout,
    );
  }
}
