import '../models/component_node.dart';
import '../registry/component_registry.dart';

class ValidationResult {
  final bool success;
  final String? errorMessage;

  const ValidationResult._(this.success, this.errorMessage);

  const ValidationResult.success() : this._(true, null);

  const ValidationResult.failure(String message) : this._(false, message);
}

class NestingValidator {
  static String? effectiveSlotName(ComponentNode parent, String? slotName) {
    if (slotName != null) return slotName;
    final meta = ComponentRegistry.getByType(parent.type);
    if (meta == null || meta.slotNames.isEmpty) return null;
    if (meta.slotNames.contains('child')) return 'child';
    if (parent.type == 'Scaffold' && meta.slotNames.contains('body')) return 'body';
    return null;
  }

  static ValidationResult validateDrop(
    ComponentNode parent,
    ComponentNode child,
    String? slotName, {
    ComponentNode? root,
  }) {
    if (parent.id == child.id) {
      return const ValidationResult.failure('Cannot drop a widget into itself.');
    }

    if (_containsNode(child, parent.id)) {
      return const ValidationResult.failure('Cannot drop a parent into one of its descendants.');
    }

    final meta = ComponentRegistry.getByType(parent.type);
    if (meta == null) {
      return ValidationResult.failure('${parent.type} is not registered.');
    }

    if (!meta.allowsChildren) {
      return ValidationResult.failure('${parent.type} does not accept children.');
    }

    final effectiveSlot = effectiveSlotName(parent, slotName);
    if (meta.slotNames.isNotEmpty) {
      if (effectiveSlot == null || !meta.slotNames.contains(effectiveSlot)) {
        return ValidationResult.failure('${parent.type} requires one of these slots: ${meta.slotNames.join(', ')}.');
      }

      final allowed = meta.slotRestrictions?[effectiveSlot];
      if (allowed != null && !allowed.contains(child.type)) {
        return ValidationResult.failure('${child.type} cannot be dropped into ${parent.type}.$effectiveSlot.');
      }

      final existing = parent.slots[effectiveSlot];
      if (existing != null && existing.id != child.id) {
        return ValidationResult.failure('${parent.type}.$effectiveSlot already contains ${existing.type}.');
      }

      return const ValidationResult.success();
    }

    if (effectiveSlot != null) {
      return ValidationResult.failure('${parent.type} does not have a $effectiveSlot slot.');
    }

    final allowedChildTypes = meta.allowedChildTypes;
    if (allowedChildTypes != null && !allowedChildTypes.contains(child.type)) {
      return ValidationResult.failure('${parent.type} cannot contain ${child.type}.');
    }

    final maxChildren = meta.maxChildren;
    if (maxChildren != null) {
      final alreadyChild = parent.children.any((node) => node.id == child.id);
      final currentCount = parent.children.length;
      if (!alreadyChild && currentCount >= maxChildren) {
        return ValidationResult.failure('${parent.type} can contain at most $maxChildren child widget${maxChildren == 1 ? '' : 's'}.');
      }
    }

    if (root != null && !_containsNode(root, parent.id)) {
      return const ValidationResult.failure('Parent does not exist in the current tree.');
    }

    return const ValidationResult.success();
  }

  static List<String> validateNode(ComponentNode node) {
    final warnings = <String>[];
    final meta = ComponentRegistry.getByType(node.type);
    if (meta == null) return warnings;

    if (!meta.allowsChildren && (node.children.isNotEmpty || node.slots.values.any((slot) => slot != null))) {
      warnings.add('${node.type} does not accept children');
    }

    if (meta.maxChildren != null && meta.slotNames.isEmpty && node.children.length > meta.maxChildren!) {
      warnings.add('${node.type} contains ${node.children.length} children');
    }

    if (meta.singleChildWidget) {
      final slotChild = node.slots['child'];
      final count = node.children.length + (slotChild == null ? 0 : 1);
      if (count > 1) {
        warnings.add('${node.type} contains $count children');
      }
    }

    if (node.type == 'Scaffold' && node.slots['body'] == null) {
      warnings.add('Scaffold body missing');
    }
    if (node.type == 'AppBar' && node.slots['title'] == null && (node.properties['title'] == null || node.properties['title'].toString().isEmpty)) {
      warnings.add('AppBar title missing');
    }

    for (final child in node.children) {
      warnings.addAll(validateNode(child));
    }
    for (final child in node.slots.values) {
      if (child != null) warnings.addAll(validateNode(child));
    }
    warnings.addAll(node.migrationWarnings);

    return warnings;
  }

  static bool _containsNode(ComponentNode node, String id) {
    if (node.id == id) return true;
    for (final child in node.children) {
      if (_containsNode(child, id)) return true;
    }
    for (final child in node.slots.values) {
      if (child != null && _containsNode(child, id)) return true;
    }
    return false;
  }
}
