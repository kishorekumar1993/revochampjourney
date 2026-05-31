import 'package:flutter_test/flutter_test.dart';
import 'package:revojourneytryone/core/component_engine/models/component_node.dart';
import 'package:revojourneytryone/core/component_engine/models/component_action.dart';
import 'package:revojourneytryone/features/visual_builder/application/visual_builder_commands.dart';

void main() {
  group('VisualBuilderCommand Tests', () {
    late ComponentNode root;

    setUp(() {
      root = ComponentNode(
        id: 'root-scaffold',
        type: 'Column',
        properties: {},
        children: [
          ComponentNode(
            id: 'child-1',
            type: 'Container',
            properties: {'width': 100.0},
            children: [],
            actions: [],
          ),
          ComponentNode(
            id: 'child-2',
            type: 'Text',
            properties: {'text': 'Hello'},
            children: [],
            actions: [],
          ),
        ],
        actions: [],
      );
    });

    test('AddWidgetCommand adds and undoes correctly', () {
      final newNode = ComponentNode(
        id: 'child-new',
        type: 'Image',
        properties: {},
        children: [],
        actions: [],
      );

      final cmd = AddWidgetCommand(
        parentId: 'root-scaffold',
        node: newNode,
        index: 1, // insert in middle
      );

      // Execute
      final afterExec = cmd.executeTree(root);
      expect(afterExec.children.length, 3);
      expect(afterExec.children[1].id, 'child-new');
      expect(afterExec.children[1].type, 'Image');

      // Undo
      final afterUndo = cmd.undoTree(afterExec);
      expect(afterUndo.children.length, 2);
      expect(afterUndo.children[0].id, 'child-1');
      expect(afterUndo.children[1].id, 'child-2');
    });

    test('DeleteWidgetCommand deletes and restores at original index on undo', () {
      final cmd = DeleteWidgetCommand(nodeId: 'child-1');

      // Execute
      final afterExec = cmd.executeTree(root);
      expect(afterExec.children.length, 1);
      expect(afterExec.children[0].id, 'child-2');

      // Undo
      final afterUndo = cmd.undoTree(afterExec);
      expect(afterUndo.children.length, 2);
      expect(afterUndo.children[0].id, 'child-1'); // restores at index 0
      expect(afterUndo.children[0].properties['width'], 100.0);
      expect(afterUndo.children[1].id, 'child-2');
    });

    test('MoveWidgetCommand moves and undoes correctly', () {
      // Structure: root -> [ child-1 [child-inner], child-2 ]
      root.children[0].children.add(
        ComponentNode(
          id: 'child-inner',
          type: 'Icon',
          properties: {},
          children: [],
          actions: [],
        ),
      );

      final cmd = MoveWidgetCommand(
        nodeId: 'child-inner',
        newParentId: 'root-scaffold',
        newIndex: 1,
      );

      // Execute: moves child-inner from child-1 to root at index 1
      final afterExec = cmd.executeTree(root);
      expect(afterExec.children.length, 3);
      expect(afterExec.children[1].id, 'child-inner');
      expect(afterExec.children[0].children.length, 0);

      // Undo: moves child-inner back to child-1
      final afterUndo = cmd.undoTree(afterExec);
      expect(afterUndo.children.length, 2);
      expect(afterUndo.children[0].slots['child']?.id, 'child-inner');
      expect(afterUndo.children[0].children.length, 0);
    });

    test('MoveWidgetCommand can move an existing node into a child slot', () {
      final cmd = MoveWidgetCommand(
        nodeId: 'child-2',
        newParentId: 'child-1',
        newIndex: -1,
        slotName: 'child',
      );

      final afterExec = cmd.executeTree(root);
      expect(afterExec.children.length, 1);
      expect(afterExec.children[0].id, 'child-1');
      expect(afterExec.children[0].slots['child']?.id, 'child-2');

      final afterUndo = cmd.undoTree(afterExec);
      expect(afterUndo.children.length, 2);
      expect(afterUndo.children[0].slots['child'], isNull);
      expect(afterUndo.children[1].id, 'child-2');
    });

    test('legacy direct container child can be converted into a named child slot', () {
      final legacyParent = ComponentNode(
        id: 'legacy-container',
        type: 'Container',
        properties: {},
        children: [
          ComponentNode(
            id: 'legacy-child',
            type: 'Text',
            properties: {'text': 'Legacy'},
            children: [],
            actions: [],
          ),
        ],
        slots: {'child': null},
        actions: [],
      );

      final updated = ComponentTreeUtils.insertChildInParent(
        legacyParent,
        'legacy-container',
        legacyParent.children.first,
        -1,
        slotName: 'child',
      );

      expect(updated, isNotNull);
      expect(updated!.children, isEmpty);
      expect(updated.slots['child']?.id, 'legacy-child');
    });

    test('MoveWidgetCommand preserves nested child changes below grandchildren', () {
      final nestedRoot = ComponentNode(
        id: 'root',
        type: 'Column',
        properties: {},
        actions: [],
        children: [
          ComponentNode(
            id: 'outer',
            type: 'Column',
            properties: {},
            actions: [],
            children: [
              ComponentNode(
                id: 'inner',
                type: 'Column',
                properties: {},
                actions: [],
                children: [
                  ComponentNode(
                    id: 'leaf',
                    type: 'Text',
                    properties: {},
                    children: [],
                    actions: [],
                  ),
                ],
              ),
            ],
          ),
          ComponentNode(
            id: 'target',
            type: 'Column',
            properties: {},
            children: [],
            actions: [],
          ),
        ],
      );

      final cmd = MoveWidgetCommand(
        nodeId: 'leaf',
        newParentId: 'target',
        newIndex: 0,
      );

      final afterExec = cmd.executeTree(nestedRoot);
      expect(afterExec.children[0].children[0].children, isEmpty);
      expect(afterExec.children[1].children.single.id, 'leaf');
    });

    test('UpdatePropertyCommand updates and undoes correctly', () {
      final cmd = UpdatePropertyCommand(
        nodeId: 'child-2',
        newProperties: {'text': 'Goodbye'},
        newStyles: {'color': 'red'},
      );

      // Execute
      final afterExec = cmd.executeTree(root);
      final target = afterExec.children[1];
      expect(target.properties['text'], 'Goodbye');
      expect(target.styles['color'], 'red');

      // Undo
      final afterUndo = cmd.undoTree(afterExec);
      final originalTarget = afterUndo.children[1];
      expect(originalTarget.properties['text'], 'Hello');
      expect(originalTarget.styles.containsKey('color'), false);
    });

    test('UpdateActionsCommand updates and undoes actions correctly', () {
      final newAction = ComponentAction(
        event: 'onTap',
        steps: [
          ActionStep(
            id: 'act-step-1',
            type: 'navigate',
          ),
        ],
      );

      final cmd = UpdateActionsCommand(
        nodeId: 'child-1',
        newActions: [newAction],
      );

      // Execute
      final afterExec = cmd.executeTree(root);
      expect(afterExec.children[0].actions.length, 1);
      expect(afterExec.children[0].actions[0].event, 'onTap');
      expect(afterExec.children[0].actions[0].steps[0].id, 'act-step-1');

      // Undo
      final afterUndo = cmd.undoTree(afterExec);
      expect(afterUndo.children[0].actions.isEmpty, true);
    });
  });
}
