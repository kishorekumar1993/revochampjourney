enum VariableScope { app, page, component, session }

class AppVariable {
  final String id;
  final String name;
  final String type; // String, int, double, bool, List, Map, Object
  final dynamic defaultValue;
  final dynamic currentValue;
  final VariableScope scope;

  // Enterprise attributes
  final bool isSecret;
  final bool isComputed;
  final String computedExpression;
  final bool isPersistent;
  final String persistenceType; // none, shared_preferences, hive, secure_storage
  final double? validationMin;
  final double? validationMax;
  final bool validationRequired;
  final String? boundWidgetId;
  final String? boundProperty; // text, color, visibility, value, etc.
  final String? boundApiId;
  final String? boundApiField; // request header, param, body, etc.

  AppVariable({
    required this.id,
    required this.name,
    required this.type,
    this.defaultValue,
    this.currentValue,
    required this.scope,
    this.isSecret = false,
    this.isComputed = false,
    this.computedExpression = '',
    this.isPersistent = false,
    this.persistenceType = 'none',
    this.validationMin,
    this.validationMax,
    this.validationRequired = false,
    this.boundWidgetId,
    this.boundProperty,
    this.boundApiId,
    this.boundApiField,
  });

  factory AppVariable.fromJson(Map<String, dynamic> json) {
    return AppVariable(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'String',
      defaultValue: json['defaultValue'],
      currentValue: json['currentValue'],
      scope: VariableScope.values.firstWhere(
        (e) => e.toString().split('.').last == json['scope'],
        orElse: () => VariableScope.app,
      ),
      isSecret: json['isSecret'] ?? false,
      isComputed: json['isComputed'] ?? false,
      computedExpression: json['computedExpression'] ?? '',
      isPersistent: json['isPersistent'] ?? false,
      persistenceType: json['persistenceType'] ?? 'none',
      validationMin: (json['validationMin'] as num?)?.toDouble(),
      validationMax: (json['validationMax'] as num?)?.toDouble(),
      validationRequired: json['validationRequired'] ?? false,
      boundWidgetId: json['boundWidgetId'],
      boundProperty: json['boundProperty'],
      boundApiId: json['boundApiId'],
      boundApiField: json['boundApiField'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'defaultValue': defaultValue,
      'currentValue': currentValue,
      'scope': scope.toString().split('.').last,
      'isSecret': isSecret,
      'isComputed': isComputed,
      'computedExpression': computedExpression,
      'isPersistent': isPersistent,
      'persistenceType': persistenceType,
      'validationMin': validationMin,
      'validationMax': validationMax,
      'validationRequired': validationRequired,
      'boundWidgetId': boundWidgetId,
      'boundProperty': boundProperty,
      'boundApiId': boundApiId,
      'boundApiField': boundApiField,
    };
  }

  AppVariable copyWith({
    String? id,
    String? name,
    String? type,
    dynamic defaultValue,
    dynamic currentValue,
    VariableScope? scope,
    bool? isSecret,
    bool? isComputed,
    String? computedExpression,
    bool? isPersistent,
    String? persistenceType,
    double? validationMin,
    double? validationMax,
    bool? validationRequired,
    String? boundWidgetId,
    String? boundProperty,
    String? boundApiId,
    String? boundApiField,
  }) {
    return AppVariable(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      defaultValue: defaultValue ?? this.defaultValue,
      currentValue: currentValue ?? this.currentValue,
      scope: scope ?? this.scope,
      isSecret: isSecret ?? this.isSecret,
      isComputed: isComputed ?? this.isComputed,
      computedExpression: computedExpression ?? this.computedExpression,
      isPersistent: isPersistent ?? this.isPersistent,
      persistenceType: persistenceType ?? this.persistenceType,
      validationMin: validationMin ?? this.validationMin,
      validationMax: validationMax ?? this.validationMax,
      validationRequired: validationRequired ?? this.validationRequired,
      boundWidgetId: boundWidgetId ?? this.boundWidgetId,
      boundProperty: boundProperty ?? this.boundProperty,
      boundApiId: boundApiId ?? this.boundApiId,
      boundApiField: boundApiField ?? this.boundApiField,
    );
  }
}
