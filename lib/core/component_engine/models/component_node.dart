import 'component_action.dart';
import '../registry/component_registry.dart';

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
  Map<String, ComponentNode?> slots;
  List<ComponentAction> actions;
  List<String> migrationWarnings;

  ComponentNode({
    required this.id,
    required this.type,
    required this.properties,
    required this.children,
    required this.actions,
    this.slots = const {},
    this.migrationWarnings = const [],
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

    final meta = ComponentRegistry.getByType(type);
    
    Map<String, ComponentNode?> slotsMap = {};
    final migrationWarnings = <String>[];
    if (json['migrationWarnings'] is List) {
      migrationWarnings.addAll((json['migrationWarnings'] as List).map((item) => item.toString()));
    }

    if (json['slots'] is Map) {
      final rawSlots = Map<String, dynamic>.from(json['slots'] as Map);
      rawSlots.forEach((key, val) {
        slotsMap[key] = val != null ? ComponentNode.fromJson(Map<String, dynamic>.from(val as Map)) : null;
      });
    }

    var childrenNodes = childrenList
        .whereType<Map>()
        .map((child) => ComponentNode.fromJson(Map<String, dynamic>.from(child)))
        .toList();

    if (meta != null) {
      for (final slotName in meta.slotNames) {
        slotsMap.putIfAbsent(slotName, () => null);
      }
      if (meta.slotNames.isNotEmpty && childrenNodes.isNotEmpty) {
        if (meta.type == 'Scaffold') {
          ComponentNode? firstBody;
          for (final child in childrenNodes) {
            if (child.type == 'AppBar' && slotsMap['appBar'] == null) {
              slotsMap['appBar'] = child;
            } else if ((child.type == 'BottomNavigationBar' || child.type == 'NavigationBar') && slotsMap['bottomNavigationBar'] == null) {
              slotsMap['bottomNavigationBar'] = child;
            } else if ((child.type == 'FloatingActionButton' || child.type == 'FloatingButton') && slotsMap['floatingActionButton'] == null) {
              slotsMap['floatingActionButton'] = child;
            } else if (child.type == 'Drawer' && slotsMap['drawer'] == null) {
              slotsMap['drawer'] = child;
            } else if (firstBody == null && slotsMap['body'] == null) {
              firstBody = child;
            } else {
              migrationWarnings.add('Migrated ${meta.type}: extra legacy child ${child.type} (${child.id}) was not inserted because Scaffold uses named slots.');
            }
          }
          slotsMap['body'] ??= firstBody;
          childrenNodes = [];
        } else if (meta.slotNames.contains('child')) {
          slotsMap['child'] ??= childrenNodes.first;
          if (childrenNodes.length > 1) {
            for (final extra in childrenNodes.skip(1)) {
              migrationWarnings.add('Migrated ${meta.type}: extra legacy child ${extra.type} (${extra.id}) was not inserted because ${meta.type} supports one child.');
            }
          }
          childrenNodes = [];
        } else if (meta.maxChildren == 0) {
          for (final extra in childrenNodes) {
            migrationWarnings.add('Migrated ${meta.type}: extra legacy child ${extra.type} (${extra.id}) was not inserted because ${meta.type} only uses named slots.');
          }
          childrenNodes = [];
        }
      }
    }

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
      children: childrenNodes,
      slots: slotsMap,
      migrationWarnings: migrationWarnings,
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
      'slots': slots.map((key, child) => MapEntry(key, child?.toJson())),
      if (migrationWarnings.isNotEmpty) 'migrationWarnings': migrationWarnings,
      'actions': actions.map((action) => action.toJson()).toList(),
    };
  }

  ComponentNode? getSlotChild(String slotName) {
    final slotNode = slots[slotName];
    if (slotNode != null) return slotNode;
    if (slotName == 'child' && children.isNotEmpty) {
      return children.first;
    }
    return null;
  }

  bool hasSlotChild(String slotName) => getSlotChild(slotName) != null;

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
    Map<String, ComponentNode?>? slots,
    List<ComponentAction>? actions,
    List<String>? migrationWarnings,
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
      slots: slots ?? this.slots.map((key, val) => MapEntry(key, val?.copyWith())),
      actions: actions ?? this.actions.map((a) => a.copyWith()).toList(),
      migrationWarnings: migrationWarnings ?? List<String>.from(this.migrationWarnings),
    );
  }
}
