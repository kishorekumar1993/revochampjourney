enum VariableScope { app, page, component, session }

class AppVariable {
  final String id;
  final String name;
  final String type; // String, int, double, bool, List, Map, Object
  final dynamic defaultValue;
  final dynamic currentValue;
  final VariableScope scope;

  AppVariable({
    required this.id,
    required this.name,
    required this.type,
    this.defaultValue,
    this.currentValue,
    required this.scope,
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
    };
  }

  AppVariable copyWith({
    String? id,
    String? name,
    String? type,
    dynamic defaultValue,
    dynamic currentValue,
    VariableScope? scope,
  }) {
    return AppVariable(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      defaultValue: defaultValue ?? this.defaultValue,
      currentValue: currentValue ?? this.currentValue,
      scope: scope ?? this.scope,
    );
  }
}
