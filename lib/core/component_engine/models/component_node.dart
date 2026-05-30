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
    // Robust extraction: if json contains a steps list or screenLayout, dig deeper.
    if (json.containsKey('screenLayout') && json['screenLayout'] is Map) {
      return ComponentNode.fromJson(Map<String, dynamic>.from(json['screenLayout'] as Map));
    }
    if (json.containsKey('steps') && json['steps'] is List && (json['steps'] as List).isNotEmpty) {
      final firstStep = (json['steps'] as List).first;
      if (firstStep is Map && firstStep.containsKey('screenLayout') && firstStep['screenLayout'] is Map) {
        return ComponentNode.fromJson(Map<String, dynamic>.from(firstStep['screenLayout'] as Map));
      }
    }

    final id = (json['id']?.toString() ?? '').isNotEmpty
        ? json['id'].toString()
        : 'node_${DateTime.now().millisecondsSinceEpoch}_${json.hashCode.abs() % 1000}';
    final type = json['type']?.toString() ?? 'Container';

    Map<String, dynamic> rawProps = {};
    if (json['properties'] is Map) {
      rawProps = Map<String, dynamic>.from(json['properties'] as Map);
    }

    Map<String, dynamic> rawStyles = {};
    if (json['styles'] is Map) {
      rawStyles = Map<String, dynamic>.from(json['styles'] as Map);
    }

    // Legacy style migration: if styles is empty, pull styling keys from properties.
    // Also always migrate style keys even if rawStyles is not empty, so properties bag
    // can act as a fallback for older JSON schemas.
    const styleKeys = [
      'width', 'height', 'minWidth', 'maxWidth', 'minHeight', 'maxHeight',
      'backgroundColor', 'color', 'textColor',
      'fontSize', 'fontWeight', 'fontStyle',
      'textAlign', 'letterSpacing', 'lineHeight', 'maxLines', 'overflow',
      'textDecoration',
      'padding', 'margin',
      'borderRadius', 'borderColor', 'borderWidth',
      'elevation', 'shadow',
      'src', 'fit',
      'spacing', 'runSpacing',
      'gradientStart', 'gradientEnd', 'gradientAngle',
      'opacity', 'flex', 'alignment',
      'scrollDirection', 'crossAxisCount', 'childAspectRatio',
      'crossAxisSpacing', 'mainAxisSpacing', 'mainAxisSize',
      'viewportFraction', 'autoPlay',
    ];
    for (final key in styleKeys) {
      if (rawProps.containsKey(key) && !rawStyles.containsKey(key)) {
        rawStyles[key] = rawProps[key];
      }
    }

    Map<String, dynamic> rawResponsive = {};
    if (json['responsive'] is Map) {
      rawResponsive = Map<String, dynamic>.from(json['responsive'] as Map);
    }

    Map<String, dynamic> rawBindings = {};
    if (json['bindings'] is Map) {
      rawBindings = Map<String, dynamic>.from(json['bindings'] as Map);
    }

    Map<String, dynamic> rawAnimations = {};
    if (json['animations'] is Map) {
      rawAnimations = Map<String, dynamic>.from(json['animations'] as Map);
    }

    var childrenList = json['children'] is List ? (json['children'] as List) : [];
    var actionsList = json['actions'] is List ? (json['actions'] as List) : [];

    return ComponentNode(
      id: id,
      type: type,
      displayName: json['displayName']?.toString(),
      parentId: json['parentId']?.toString(),
      sortOrder: json['sortOrder'] is int ? json['sortOrder'] as int : null,
      isLocked: json['isLocked'] == true,
      isVisible: json['isVisible'] != false,
      isReusable: json['isReusable'] == true,
      properties: rawProps,
      styles: rawStyles,
      responsive: rawResponsive,
      bindings: rawBindings,
      animations: rawAnimations,
      children: childrenList
          .whereType<Map>()
          .map((child) => ComponentNode.fromJson(Map<String, dynamic>.from(child)))
          .toList(),
      actions: actionsList
          .whereType<Map>()
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
