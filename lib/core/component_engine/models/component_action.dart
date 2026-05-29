class ComponentAction {
  final String event; // e.g. onTap, onChanged, onSubmit
  final List<ActionStep> steps;

  ComponentAction({
    required this.event,
    required this.steps,
  });

  factory ComponentAction.fromJson(Map<String, dynamic> json) {
    var stepsList = json['steps'] as List? ?? [];
    return ComponentAction(
      event: json['event'] ?? 'onTap',
      steps: stepsList.map((step) => ActionStep.fromJson(step)).toList(),
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
  final String type; // e.g. validate, api, navigate, saveToken
  final Map<String, dynamic> properties;

  ActionStep({
    required this.type,
    this.properties = const {},
  });

  factory ActionStep.fromJson(Map<String, dynamic> json) {
    final type = json['type'] ?? 'validate';
    final properties = Map<String, dynamic>.from(json)..remove('type');
    return ActionStep(
      type: type,
      properties: properties,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      ...properties,
    };
  }

  ActionStep copyWith({
    String? type,
    Map<String, dynamic>? properties,
  }) {
    return ActionStep(
      type: type ?? this.type,
      properties: properties ?? Map<String, dynamic>.from(this.properties),
    );
  }
}
