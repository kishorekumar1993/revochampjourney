import 'component_action.dart';

class ComponentNode {
  String id;
  String type;
  String? displayName;
  String? parentId;
  int? sortOrder;
  bool isLocked;
  bool isVisible;
  bool isReusable;

  Map<String, dynamic> properties;
  Map<String, dynamic> styles;
  Map<String, dynamic> responsive;
  Map<String, dynamic> bindings;
  Map<String, dynamic> animations;

  List<ComponentNode> children;
  List<ComponentAction> actions;

  ComponentNode({
    required this.id,
    required this.type,
    required this.properties,
    required this.children,
    required this.actions,
    this.displayName,
    this.parentId,
    this.sortOrder,
    this.isLocked = false,
    this.isVisible = true,
    this.isReusable = false,
    this.styles = const {},
    this.responsive = const {},
    this.bindings = const {},
    this.animations = const {},
  });

  factory ComponentNode.fromJson(Map<String, dynamic> json) {
    var childrenList = json['children'] as List? ?? [];
    var actionsList = json['actions'] as List? ?? [];

    Map<String, dynamic> rawProps = json['properties'] != null
        ? Map<String, dynamic>.from(json['properties'])
        : {};

    Map<String, dynamic> rawStyles = json['styles'] != null
        ? Map<String, dynamic>.from(json['styles'])
        : {};

    // Legacy style migration: if styles is empty, pull styling keys from properties
    if (rawStyles.isEmpty) {
      final styleKeys = [
        'width',
        'height',
        'backgroundColor',
        'color',
        'textColor',
        'fontSize',
        'fontWeight',
        'padding',
        'margin',
        'borderRadius',
        'elevation',
        'src',
        'fit',
        'spacing',
        'runSpacing',
      ];
      for (final key in styleKeys) {
        if (rawProps.containsKey(key)) {
          rawStyles[key] = rawProps[key];
        }
      }
    }

    return ComponentNode(
      id: json['id'] ?? '',
      type: json['type'] ?? 'Container',
      displayName: json['displayName'],
      parentId: json['parentId'],
      sortOrder: json['sortOrder'],
      isLocked: json['isLocked'] ?? false,
      isVisible: json['isVisible'] ?? true,
      isReusable: json['isReusable'] ?? false,
      properties: rawProps,
      styles: rawStyles,
      responsive: json['responsive'] != null
          ? Map<String, dynamic>.from(json['responsive'])
          : {},
      bindings: json['bindings'] != null
          ? Map<String, dynamic>.from(json['bindings'])
          : {},
      animations: json['animations'] != null
          ? Map<String, dynamic>.from(json['animations'])
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
      if (displayName != null) 'displayName': displayName,
      if (parentId != null) 'parentId': parentId,
      if (sortOrder != null) 'sortOrder': sortOrder,
      'isLocked': isLocked,
      'isVisible': isVisible,
      'isReusable': isReusable,
      'properties': properties,
      'styles': styles,
      'responsive': responsive,
      'bindings': bindings,
      'animations': animations,
      'children': children.map((child) => child.toJson()).toList(),
      'actions': actions.map((action) => action.toJson()).toList(),
    };
  }

  ComponentNode copyWith({
    String? id,
    String? type,
    String? displayName,
    String? parentId,
    int? sortOrder,
    bool? isLocked,
    bool? isVisible,
    bool? isReusable,
    Map<String, dynamic>? properties,
    Map<String, dynamic>? styles,
    Map<String, dynamic>? responsive,
    Map<String, dynamic>? bindings,
    Map<String, dynamic>? animations,
    List<ComponentNode>? children,
    List<ComponentAction>? actions,
  }) {
    return ComponentNode(
      id: id ?? this.id,
      type: type ?? this.type,
      displayName: displayName ?? this.displayName,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      isReusable: isReusable ?? this.isReusable,
      properties: properties ?? Map<String, dynamic>.from(this.properties),
      styles: styles ?? Map<String, dynamic>.from(this.styles),
      responsive: responsive ?? Map<String, dynamic>.from(this.responsive),
      bindings: bindings ?? Map<String, dynamic>.from(this.bindings),
      animations: animations ?? Map<String, dynamic>.from(this.animations),
      children: children ?? this.children.map((c) => c.copyWith()).toList(),
      actions: actions ?? this.actions.map((a) => a.copyWith()).toList(),
    );
  }
}
