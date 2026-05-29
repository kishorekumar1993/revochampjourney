import 'component_action.dart';

class ComponentNode {
  String id;
  String type;
  Map<String, dynamic> properties;
  List<ComponentNode> children;
  List<ComponentAction> actions;

  ComponentNode({
    required this.id,
    required this.type,
    required this.properties,
    required this.children,
    required this.actions,
  });

  factory ComponentNode.fromJson(Map<String, dynamic> json) {
    var childrenList = json['children'] as List? ?? [];
    var actionsList = json['actions'] as List? ?? [];
    return ComponentNode(
      id: json['id'] ?? '',
      type: json['type'] ?? 'Container',
      properties: json['properties'] != null
          ? Map<String, dynamic>.from(json['properties'])
          : {},
      children: childrenList
          .map((child) => ComponentNode.fromJson(Map<String, dynamic>.from(child)))
          .toList(),
      actions: actionsList
          .map((action) => ComponentAction.fromJson(Map<String, dynamic>.from(action)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'properties': properties,
      'children': children.map((child) => child.toJson()).toList(),
      'actions': actions.map((action) => action.toJson()).toList(),
    };
  }

  ComponentNode copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? properties,
    List<ComponentNode>? children,
    List<ComponentAction>? actions,
  }) {
    return ComponentNode(
      id: id ?? this.id,
      type: type ?? this.type,
      properties: properties ?? Map<String, dynamic>.from(this.properties),
      children: children ?? this.children.map((c) => c.copyWith()).toList(),
      actions: actions ?? this.actions.map((a) => a.copyWith()).toList(),
    );
  }
}
