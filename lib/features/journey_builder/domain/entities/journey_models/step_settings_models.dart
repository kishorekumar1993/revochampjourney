class StepValidation {
  String type;
  String field;
  String message;
  String? regexPattern;
  String? validationUrl;
  String? dependentField;
  String? dependentValue;
  Map<String, dynamic>? condition;
  Map<String, dynamic>? request;
  String? expression;

  StepValidation({
    required this.type,
    required this.field,
    required this.message,
    this.regexPattern,
    this.validationUrl,
    this.dependentField,
    this.dependentValue,
    this.condition,
    this.request,
    this.expression,
  });

  factory StepValidation.fromJson(Map<String, dynamic> json) => StepValidation(
        type: json['type'] ?? 'required',
        field: json['field'] ?? '',
        message: json['message'] ?? '',
        regexPattern: json['regexPattern'],
        validationUrl: json['validationUrl'],
        dependentField: json['dependentField'],
        dependentValue: json['dependentValue'],
        condition: json['condition'],
        request: json['request'],
        expression: json['expression'],
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'field': field,
        'message': message,
        'regexPattern': regexPattern,
        'validationUrl': validationUrl,
        'dependentField': dependentField,
        'dependentValue': dependentValue,
        'condition': condition,
        'request': request,
        'expression': expression,
      };

  StepValidation copyWith({
    String? type,
    String? field,
    String? message,
    String? regexPattern,
    String? validationUrl,
    String? dependentField,
    String? dependentValue,
    Map<String, dynamic>? condition,
    Map<String, dynamic>? request,
    String? expression,
  }) {
    return StepValidation(
      type: type ?? this.type,
      field: field ?? this.field,
      message: message ?? this.message,
      regexPattern: regexPattern ?? this.regexPattern,
      validationUrl: validationUrl ?? this.validationUrl,
      dependentField: dependentField ?? this.dependentField,
      dependentValue: dependentValue ?? this.dependentValue,
      condition: condition ?? this.condition,
      request: request ?? this.request,
      expression: expression ?? this.expression,
    );
  }
}

class StepCondition {
  String type;
  String field;
  String operator;
  String value;
  String? targetStep;

  StepCondition({
    required this.type,
    required this.field,
    required this.operator,
    required this.value,
    this.targetStep,
  });

  factory StepCondition.fromJson(Map<String, dynamic> json) => StepCondition(
        type: json['type'] ?? 'visibleIf',
        field: json['field'] ?? '',
        operator: json['operator'] ?? 'equals',
        value: json['value']?.toString() ?? '',
        targetStep: json['targetStep'],
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'field': field,
        'operator': operator,
        'value': value,
        'targetStep': targetStep,
      };

  StepCondition copyWith({
    String? type,
    String? field,
    String? operator,
    String? value,
    String? targetStep,
  }) {
    return StepCondition(
      type: type ?? this.type,
      field: field ?? this.field,
      operator: operator ?? this.operator,
      value: value ?? this.value,
      targetStep: targetStep ?? this.targetStep,
    );
  }
}

class StepAPI {
  String method;
  String url;
  String description;
  Map<String, dynamic>? headers;
  String? body;

  StepAPI({
    required this.method,
    required this.url,
    required this.description,
    this.headers,
    this.body,
  });

  factory StepAPI.fromJson(Map<String, dynamic> json) => StepAPI(
        method: json['method'] ?? 'GET',
        url: json['url'] ?? '',
        description: json['description'] ?? '',
        headers: json['headers'],
        body: json['body']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'method': method,
        'url': url,
        'description': description,
        'headers': headers,
        'body': body,
      };

  StepAPI copyWith({
    String? method,
    String? url,
    String? description,
    Map<String, dynamic>? headers,
    String? body,
  }) {
    return StepAPI(
      method: method ?? this.method,
      url: url ?? this.url,
      description: description ?? this.description,
      headers: headers ?? this.headers,
      body: body ?? this.body,
    );
  }
}

class StepAction {
  String trigger;
  String actionType;
  String details;

  StepAction({
    required this.trigger,
    required this.actionType,
    required this.details,
  });

  factory StepAction.fromJson(Map<String, dynamic> json) => StepAction(
        trigger: json['trigger'] ?? 'onSubmit',
        actionType: json['actionType'] ?? '',
        details: json['details'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'trigger': trigger,
        'actionType': actionType,
        'details': details,
      };

  StepAction copyWith({
    String? trigger,
    String? actionType,
    String? details,
  }) {
    return StepAction(
      trigger: trigger ?? this.trigger,
      actionType: actionType ?? this.actionType,
      details: details ?? this.details,
    );
  }
}
