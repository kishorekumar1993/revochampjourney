class ComponentAction {
  final String event; // e.g. onTap, onChanged, onSubmit, onLoad, onFocus, onSuccess, onError
  final List<ActionStep> steps;

  ComponentAction({
    required this.event,
    required this.steps,
  });

  factory ComponentAction.fromJson(Map<String, dynamic> json) {
    var stepsList = json['steps'] as List? ?? [];
    return ComponentAction(
      event: json['event'] ?? 'onTap',
      steps: stepsList.map((step) => ActionStep.fromJson(Map<String, dynamic>.from(step))).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event': event,
      'steps': steps.map((step) => step.toJson()).toList(),
    };
  }

  ComponentAction copyWith({
    String? event,
    List<ActionStep>? steps,
  }) {
    return ComponentAction(
      event: event ?? this.event,
      steps: steps ?? this.steps.map((s) => s.copyWith()).toList(),
    );
  }
}

class ActionStep {
  final String id;
  final String type; // validate, api, navigate, saveToken, updateVariable, loop, delay, condition, snackbar, alert
  final bool enabled;
  final List<Map<String, dynamic>> conditions;
  final List<ActionStep> successSteps;
  final List<ActionStep> failureSteps;
  final List<ActionStep> nestedSteps;
  final Map<String, dynamic> properties;

  ActionStep({
    required this.id,
    required this.type,
    this.enabled = true,
    this.conditions = const [],
    this.successSteps = const [],
    this.failureSteps = const [],
    this.nestedSteps = const [],
    this.properties = const {},
  });

  factory ActionStep.fromJson(Map<String, dynamic> json) {
    final type = json['type'] ?? 'validate';
    final id = json['id'] ?? 'step_${DateTime.now().millisecondsSinceEpoch}_${json.hashCode}';
    final enabled = json['enabled'] ?? true;
    final conditionsList = json['conditions'] as List? ?? [];
    final successList = json['successSteps'] as List? ?? [];
    final failureList = json['failureSteps'] as List? ?? [];
    final nestedList = json['nestedSteps'] as List? ?? [];

    final properties = Map<String, dynamic>.from(json)
      ..remove('id')
      ..remove('type')
      ..remove('enabled')
      ..remove('conditions')
      ..remove('successSteps')
      ..remove('failureSteps')
      ..remove('nestedSteps');

    return ActionStep(
      id: id,
      type: type,
      enabled: enabled,
      conditions: conditionsList.map((c) => Map<String, dynamic>.from(c)).toList(),
      successSteps: successList.map((step) => ActionStep.fromJson(Map<String, dynamic>.from(step))).toList(),
      failureSteps: failureList.map((step) => ActionStep.fromJson(Map<String, dynamic>.from(step))).toList(),
      nestedSteps: nestedList.map((step) => ActionStep.fromJson(Map<String, dynamic>.from(step))).toList(),
      properties: properties,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'enabled': enabled,
      'conditions': conditions,
      'successSteps': successSteps.map((step) => step.toJson()).toList(),
      'failureSteps': failureSteps.map((step) => step.toJson()).toList(),
      'nestedSteps': nestedSteps.map((step) => step.toJson()).toList(),
      ...properties,
    };
  }

  ActionStep copyWith({
    String? id,
    String? type,
    bool? enabled,
    List<Map<String, dynamic>>? conditions,
    List<ActionStep>? successSteps,
    List<ActionStep>? failureSteps,
    List<ActionStep>? nestedSteps,
    Map<String, dynamic>? properties,
  }) {
    return ActionStep(
      id: id ?? this.id,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      conditions: conditions ?? this.conditions,
      successSteps: successSteps ?? this.successSteps.map((s) => s.copyWith()).toList(),
      failureSteps: failureSteps ?? this.failureSteps.map((s) => s.copyWith()).toList(),
      nestedSteps: nestedSteps ?? this.nestedSteps.map((s) => s.copyWith()).toList(),
      properties: properties ?? Map<String, dynamic>.from(this.properties),
    );
  }
}
