import '../../../core/component_engine/models/component_node.dart';
import '../../../core/component_engine/models/component_action.dart';
import '../../../core/component_engine/registry/component_registry.dart';
import '../../../core/component_engine/validation/nesting_validator.dart';

/// The requested parameterless command pattern interface.
abstract class StudioCommand {
  void execute();
  void undo();

  /// Global reference to avoid circular compile/import path issues.
  static dynamic activeController;
}

/// The Command interface defining methods to execute and undo manipulations
/// on the ComponentNode tree.
abstract class VisualBuilderCommand implements StudioCommand {
  /// User-friendly description of the command for the history log.
  String get description;

  /// The ID of the node that should be selected after executing this command.
  String? get selectedNodeIdAfterExecute => null;

  /// The ID of the node that should be selected after undoing this command.
  String? get selectedNodeIdAfterUndo => null;

  @override
  void execute() {
    final controller = StudioCommand.activeController;
    if (controller != null) {
      controller.executeCommand(this);
    }
  }

  @override
  void undo() {
    final controller = StudioCommand.activeController;
    if (controller != null) {
      controller.undoSpecificCommand(this);
    }
  }

  /// Executes the command on the given [root] and returns the updated root node.
  ComponentNode executeTree(ComponentNode root);

  /// Undoes the command on the given [root] and returns the restored root node.
  ComponentNode undoTree(ComponentNode root);
}

/// Helper class for tree search and manipulation.
class ComponentTreeUtils {
  static ComponentNode? findNode(ComponentNode current, String id) {
    if (current.id == id) return current;
    for (final child in current.children) {
      final found = findNode(child, id);
      if (found != null) return found;
    }
    for (final slotChild in current.slots.values) {
      if (slotChild != null) {
        final found = findNode(slotChild, id);
        if (found != null) return found;
      }
    }
    return null;
  }

  static ComponentNode? findParentNode(ComponentNode current, String childId) {
    for (final child in current.children) {
      if (child.id == childId) return current;
      final found = findParentNode(child, childId);
      if (found != null) return found;
    }
    for (final entry in current.slots.entries) {
      final slotChild = entry.value;
      if (slotChild != null) {
        if (slotChild.id == childId) return current;
        final found = findParentNode(slotChild, childId);
        if (found != null) return found;
      }
    }
    return null;
  }

  static ComponentNode? insertChildInParent(ComponentNode current, String parentId, ComponentNode newNode, int index, {String? slotName}) {
    if (current.id == parentId) {
      final meta = ComponentRegistry.getByType(current.type);
      final effectiveSlotName = NestingValidator.effectiveSlotName(current, slotName);

      final validation = NestingValidator.validateDrop(current, newNode, effectiveSlotName);
      if (!validation.success) return current;

      if (effectiveSlotName != null) {
        if (meta == null || !meta.slotNames.contains(effectiveSlotName)) return current;
        final Map<String, ComponentNode?> updatedSlots = Map.from(current.slots);
        final existing = updatedSlots[effectiveSlotName];
        if (existing != null && existing.id != newNode.id) return current;
        updatedSlots[effectiveSlotName] = newNode;
        return current.copyWith(slots: updatedSlots);
      } else {
        final List<ComponentNode> list = List.from(current.children);
        if (meta?.maxChildren != null && list.length >= meta!.maxChildren! && !list.any((child) => child.id == newNode.id)) {
          return current;
        }
        if (index >= 0 && index <= list.length) {
          list.insert(index, newNode);
        } else {
          list.add(newNode);
        }
        return current.copyWith(children: list);
      }
    }
    final List<ComponentNode> updatedChildren = [];
    bool childModified = false;
    for (final child in current.children) {
      final res = insertChildInParent(child, parentId, newNode, index, slotName: slotName);
      if (res != null) {
        updatedChildren.add(res);
        childModified = true;
      } else {
        updatedChildren.add(child);
      }
    }
    final Map<String, ComponentNode?> updatedSlots = Map.from(current.slots);
    bool slotModified = false;
    for (final entry in current.slots.entries) {
      final slotChild = entry.value;
      if (slotChild != null) {
        final res = insertChildInParent(slotChild, parentId, newNode, index, slotName: slotName);
        if (res != null) {
          updatedSlots[entry.key] = res;
          slotModified = true;
        }
      }
    }
    if (childModified || slotModified) {
      return current.copyWith(
        children: childModified ? updatedChildren : null,
        slots: slotModified ? updatedSlots : null,
      );
    }
    return null;
  }

  static ComponentNode? removeNode(ComponentNode current, String targetId) {
    if (current.id == targetId) return null;
    final List<ComponentNode> updatedChildren = [];
    bool childModified = false;
    for (final child in current.children) {
      final res = removeNode(child, targetId);
      if (res == null) {
        childModified = true;
      } else {
        updatedChildren.add(res);
        if (res.id != child.id || res.children.length != child.children.length || res.slots.length != child.slots.length) {
          childModified = true;
        }
      }
    }
    final Map<String, ComponentNode?> updatedSlots = Map.from(current.slots);
    bool slotModified = false;
    for (final entry in current.slots.entries) {
      final slotChild = entry.value;
      if (slotChild != null) {
        final res = removeNode(slotChild, targetId);
        if (res == null) {
          updatedSlots[entry.key] = null;
          slotModified = true;
        } else if (res.id != slotChild.id || res.children.length != slotChild.children.length || res.slots.length != slotChild.slots.length) {
          updatedSlots[entry.key] = res;
          slotModified = true;
        }
      }
    }
    if (childModified || slotModified) {
      return current.copyWith(
        children: childModified ? updatedChildren : current.children,
        slots: slotModified ? updatedSlots : current.slots,
      );
    }
    return current;
  }

  static ComponentNode? updateNodeInTree(ComponentNode current, String id, ComponentNode Function(ComponentNode) updateFn) {
    if (current.id == id) {
      return updateFn(current);
    }
    final List<ComponentNode> updatedChildren = [];
    bool childModified = false;
    for (final child in current.children) {
      final res = updateNodeInTree(child, id, updateFn);
      if (res != null) {
        updatedChildren.add(res);
        if (res.id != child.id || res.properties != child.properties || res.styles != child.styles || res.actions != child.actions || res.children.length != child.children.length || res.slots.length != child.slots.length) {
          childModified = true;
        }
      } else {
        updatedChildren.add(child);
      }
    }
    final Map<String, ComponentNode?> updatedSlots = Map.from(current.slots);
    bool slotModified = false;
    for (final entry in current.slots.entries) {
      final slotChild = entry.value;
      if (slotChild != null) {
        final res = updateNodeInTree(slotChild, id, updateFn);
        if (res != null) {
          updatedSlots[entry.key] = res;
          if (res.id != slotChild.id || res.properties != slotChild.properties || res.styles != slotChild.styles || res.actions != slotChild.actions || res.children.length != slotChild.children.length || res.slots.length != slotChild.slots.length) {
            slotModified = true;
          }
        }
      }
    }
    if (childModified || slotModified) {
      return current.copyWith(
        children: childModified ? updatedChildren : current.children,
        slots: slotModified ? updatedSlots : current.slots,
      );
    }
    return current;
  }
}

/// Command to add a widget (or paste/duplicate a widget)
class AddWidgetCommand extends VisualBuilderCommand {
  final String parentId;
  final ComponentNode node;
  final int? index;
  final String? slotName;
  int? _actualInsertedIndex;

  AddWidgetCommand({
    required this.parentId,
    required this.node,
    this.index,
    this.slotName,
  });

  @override
  String get description => "Add ${node.type} to ${parentId.substring(parentId.lastIndexOf('_') + 1)}";

  @override
  String? get selectedNodeIdAfterExecute => node.id;

  @override
  String? get selectedNodeIdAfterUndo => parentId;

  @override
  ComponentNode executeTree(ComponentNode root) {
    final parentNode = ComponentTreeUtils.findNode(root, parentId);
    if (parentNode == null) return root;
    final effectiveSlot = NestingValidator.effectiveSlotName(parentNode, slotName);
    final validation = NestingValidator.validateDrop(parentNode, node, effectiveSlot, root: root);
    if (!validation.success) return root;

    if (slotName != null) {
      final updated = ComponentTreeUtils.insertChildInParent(root, parentId, node, 0, slotName: effectiveSlot);
      return updated ?? root;
    }
    int targetIndex = index ?? 0;
    if (index == null) {
      targetIndex = parentNode.children.length;
    }
    _actualInsertedIndex = targetIndex;

    final updated = ComponentTreeUtils.insertChildInParent(root, parentId, node, targetIndex, slotName: effectiveSlot);
    return updated ?? root;
  }

  @override
  ComponentNode undoTree(ComponentNode root) {
    final updated = ComponentTreeUtils.removeNode(root, node.id);
    return updated ?? root;
  }
}

/// Command to delete a widget
class DeleteWidgetCommand extends VisualBuilderCommand {
  final String nodeId;
  ComponentNode? _deletedNode;
  String? _parentId;
  int? _index;
  String? _slotName;

  DeleteWidgetCommand({required this.nodeId});

  @override
  String get description {
    final typeName = _deletedNode?.type ?? "Widget";
    return "Delete $typeName ($nodeId)";
  }

  @override
  String? get selectedNodeIdAfterExecute => _parentId;

  @override
  String? get selectedNodeIdAfterUndo => nodeId;

  @override
  ComponentNode executeTree(ComponentNode root) {
    final target = ComponentTreeUtils.findNode(root, nodeId);
    if (target == null) return root;

    final parent = ComponentTreeUtils.findParentNode(root, nodeId);
    if (parent == null) return root; // Cannot delete root node

    _deletedNode = target;
    _parentId = parent.id;
    _index = parent.children.indexWhere((c) => c.id == nodeId);
    for (final entry in parent.slots.entries) {
      if (entry.value?.id == nodeId) {
        _slotName = entry.key;
        break;
      }
    }

    final updated = ComponentTreeUtils.removeNode(root, nodeId);
    return updated ?? root;
  }

  @override
  ComponentNode undoTree(ComponentNode root) {
    if (_deletedNode == null || _parentId == null) return root;
    final restored = ComponentTreeUtils.insertChildInParent(root, _parentId!, _deletedNode!, _index ?? 0, slotName: _slotName);
    return restored ?? root;
  }
}

/// Command to move a widget to a different parent and/or index
class MoveWidgetCommand extends VisualBuilderCommand {
  final String nodeId;
  final String newParentId;
  final int newIndex;
  final String? slotName;

  String? _oldParentId;
  int? _oldIndex;
  String? _oldSlotName;
  ComponentNode? _movingNode;

  MoveWidgetCommand({
    required this.nodeId,
    required this.newParentId,
    required this.newIndex,
    this.slotName,
  });

  @override
  String get description {
    final typeName = _movingNode?.type ?? "Widget";
    return "Move $typeName to ${newParentId.substring(newParentId.lastIndexOf('_') + 1)}";
  }

  @override
  String? get selectedNodeIdAfterExecute => nodeId;

  @override
  String? get selectedNodeIdAfterUndo => nodeId;

  @override
  ComponentNode executeTree(ComponentNode root) {
    final target = ComponentTreeUtils.findNode(root, nodeId);
    if (target == null) return root;
    _movingNode = target;

    final newParent = ComponentTreeUtils.findNode(root, newParentId);
    if (newParent == null) return root;
    final effectiveSlot = NestingValidator.effectiveSlotName(newParent, slotName);
    final validation = NestingValidator.validateDrop(newParent, target, effectiveSlot, root: root);
    if (!validation.success) return root;

    final parent = ComponentTreeUtils.findParentNode(root, nodeId);
    if (parent == null) return root;

    _oldParentId = parent.id;
    _oldIndex = parent.children.indexWhere((c) => c.id == nodeId);
    for (final entry in parent.slots.entries) {
      if (entry.value?.id == nodeId) {
        _oldSlotName = entry.key;
        break;
      }
    }

    // Remove from old parent
    final cleanRoot = ComponentTreeUtils.removeNode(root, nodeId);
    if (cleanRoot == null) return root;

    // Insert into new parent
    final updated = ComponentTreeUtils.insertChildInParent(cleanRoot, newParentId, target, newIndex, slotName: effectiveSlot);
    return updated ?? root;
  }

  @override
  ComponentNode undoTree(ComponentNode root) {
    if (_oldParentId == null || _movingNode == null) return root;

    // Remove from new parent
    final cleanRoot = ComponentTreeUtils.removeNode(root, nodeId);
    if (cleanRoot == null) return root;

    // Insert back to old parent
    final restored = ComponentTreeUtils.insertChildInParent(cleanRoot, _oldParentId!, _movingNode!, _oldIndex ?? 0, slotName: _oldSlotName);
    return restored ?? root;
  }
}

/// Command to update properties and styles of a widget
class UpdatePropertyCommand extends VisualBuilderCommand {
  final String nodeId;
  final Map<String, dynamic> newProperties;
  final Map<String, dynamic> newStyles;

  Map<String, dynamic>? _oldProperties;
  Map<String, dynamic>? _oldStyles;
  ComponentNode? _targetNode;

  UpdatePropertyCommand({
    required this.nodeId,
    required this.newProperties,
    required this.newStyles,
  });

  @override
  String get description {
    final typeName = _targetNode?.type ?? "Widget";
    return "Update properties of $typeName";
  }

  @override
  String? get selectedNodeIdAfterExecute => nodeId;

  @override
  String? get selectedNodeIdAfterUndo => nodeId;

  @override
  ComponentNode executeTree(ComponentNode root) {
    final target = ComponentTreeUtils.findNode(root, nodeId);
    if (target == null) return root;
    _targetNode = target;

    _oldProperties = Map<String, dynamic>.from(target.properties);
    _oldStyles = Map<String, dynamic>.from(target.styles);

    final updated = ComponentTreeUtils.updateNodeInTree(root, nodeId, (node) {
      final updatedProps = Map<String, dynamic>.from(node.properties);
      final updatedStyles = Map<String, dynamic>.from(node.styles);

      updatedProps.addAll(newProperties);
      updatedStyles.addAll(newStyles);

      return node.copyWith(properties: updatedProps, styles: updatedStyles);
    });

    return updated ?? root;
  }

  @override
  ComponentNode undoTree(ComponentNode root) {
    if (_oldProperties == null || _oldStyles == null) return root;

    final updated = ComponentTreeUtils.updateNodeInTree(root, nodeId, (node) {
      return node.copyWith(properties: _oldProperties!, styles: _oldStyles!);
    });

    return updated ?? root;
  }
}

/// Command to update event action flows of a widget
class UpdateActionsCommand extends VisualBuilderCommand {
  final String nodeId;
  final List<ComponentAction> newActions;

  List<ComponentAction>? _oldActions;
  ComponentNode? _targetNode;

  UpdateActionsCommand({
    required this.nodeId,
    required this.newActions,
  });

  @override
  String get description {
    final typeName = _targetNode?.type ?? "Widget";
    return "Update actions of $typeName";
  }

  @override
  String? get selectedNodeIdAfterExecute => nodeId;

  @override
  String? get selectedNodeIdAfterUndo => nodeId;

  @override
  ComponentNode executeTree(ComponentNode root) {
    final target = ComponentTreeUtils.findNode(root, nodeId);
    if (target == null) return root;
    _targetNode = target;

    _oldActions = List<ComponentAction>.from(target.actions);

    final updated = ComponentTreeUtils.updateNodeInTree(root, nodeId, (node) {
      return node.copyWith(actions: newActions);
    });

    return updated ?? root;
  }

  @override
  ComponentNode undoTree(ComponentNode root) {
    if (_oldActions == null) return root;

    final updated = ComponentTreeUtils.updateNodeInTree(root, nodeId, (node) {
      return node.copyWith(actions: _oldActions!);
    });

    return updated ?? root;
  }
}

/// Command to import a new root node layout
class ImportLayoutCommand extends VisualBuilderCommand {
  final ComponentNode newRoot;
  ComponentNode? _oldRoot;

  ImportLayoutCommand({required this.newRoot});

  @override
  String get description => "Import Layout JSON";

  @override
  ComponentNode executeTree(ComponentNode root) {
    _oldRoot = root;
    return newRoot;
  }

  @override
  ComponentNode undoTree(ComponentNode root) {
    return _oldRoot ?? root;
  }
}
