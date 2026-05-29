import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/component_engine/models/component_node.dart';
import '../../../core/component_engine/models/component_action.dart';
import '../../../core/component_engine/registry/component_registry.dart';
import '../../journey_builder/application/controllers/journey_controller.dart';
import '../../journey_builder/domain/entities/journey_models.dart';
import '../integration/journey_visual_adapter.dart';

class VisualBuilderState {
  final ComponentNode rootNode;
  final ComponentNode? selectedNode;
  final ComponentNode? hoveredNode;
  final double canvasWidth;
  final double canvasHeight;
  final double canvasScale;
  final bool isDesignMode;
  final String activeStepId;
  final List<ComponentNode> past;
  final List<ComponentNode> future;

  VisualBuilderState({
    required this.rootNode,
    this.selectedNode,
    this.hoveredNode,
    this.canvasWidth = 412,
    this.canvasHeight = 915,
    this.canvasScale = 1.0,
    this.isDesignMode = true,
    required this.activeStepId,
    this.past = const [],
    this.future = const [],
  });

  VisualBuilderState copyWith({
    ComponentNode? rootNode,
    ComponentNode? selectedNode,
    ComponentNode? hoveredNode,
    double? canvasWidth,
    double? canvasHeight,
    double? canvasScale,
    bool? isDesignMode,
    String? activeStepId,
    List<ComponentNode>? past,
    List<ComponentNode>? future,
    bool clearSelected = false,
  }) {
    return VisualBuilderState(
      rootNode: rootNode ?? this.rootNode,
      selectedNode: clearSelected ? null : (selectedNode ?? this.selectedNode),
      hoveredNode: hoveredNode ?? this.hoveredNode,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      canvasScale: canvasScale ?? this.canvasScale,
      isDesignMode: isDesignMode ?? this.isDesignMode,
      activeStepId: activeStepId ?? this.activeStepId,
      past: past ?? this.past,
      future: future ?? this.future,
    );
  }
}

class VisualBuilderController extends StateNotifier<VisualBuilderState> {
  final Ref _ref;
  ComponentNode? _clipboardNode;
  Timer? _hoverDebounce;

  VisualBuilderController(this._ref)
      : super(VisualBuilderState(
          rootNode: ComponentNode(
            id: 'root-scaffold',
            type: 'Column',
            properties: {
              'mainAxisAlignment': 'start',
              'crossAxisAlignment': 'stretch',
            },
            children: [],
            actions: [],
          ),
          activeStepId: '',
        )) {
    // Listen to changes in the active step ID
    _ref.listen<String>(activeStepIdProvider, (prev, next) {
      if (next.isNotEmpty) {
        _loadStepFromJourney(next);
      }
    });

    // Listen to changes in the journey config to reload when steps are modified or imported.
    // Use a lightweight check (step count + first step id + active step id) instead of
    // serializing the entire tree to JSON on every config change.
    _ref.listen<JourneyConfig>(journeyConfigProvider, (prev, next) {
      final activeStepId = _ref.read(activeStepIdProvider);
      if (activeStepId.isNotEmpty) {
        final stepIndex = next.steps.indexWhere((s) => s.id == activeStepId);
        if (stepIndex != -1) {
          final step = next.steps[stepIndex];
          // Only reload if the layout root id or type changed (cheap check).
          final incomingRootId = (step.screenLayout as Map?)?.entries
              .firstWhere((e) => e.key == 'id', orElse: () => const MapEntry('id', ''))
              .value
              ?.toString() ?? '';
          if (incomingRootId != state.rootNode.id) {
            _loadStepFromJourney(activeStepId);
          }
        } else {
          _loadStepFromJourney(activeStepId);
        }
      } else if (next.steps.isNotEmpty) {
        _loadStepFromJourney(next.steps.first.id);
      }
    });

    // Initial load if active step is already selected
    final activeStep = _ref.read(activeStepIdProvider);
    if (activeStep.isNotEmpty) {
      _loadStepFromJourney(activeStep);
    } else {
      final journeyConfig = _ref.read(journeyConfigProvider);
      if (journeyConfig.steps.isNotEmpty) {
        _loadStepFromJourney(journeyConfig.steps.first.id);
      }
    }
  }

  void selectNode(ComponentNode? node) {
    state = state.copyWith(selectedNode: node, clearSelected: node == null);
  }

  void hoverNode(ComponentNode? node) {
    // Debounce hover updates — only rebuild if the hovered node actually changed.
    // This prevents a full canvas rebuild on every single pixel of mouse movement.
    if (state.hoveredNode?.id == node?.id) return;
    _hoverDebounce?.cancel();
    _hoverDebounce = Timer(const Duration(milliseconds: 60), () {
      if (mounted) state = state.copyWith(hoveredNode: node);
    });
  }

  @override
  void dispose() {
    _hoverDebounce?.cancel();
    super.dispose();
  }

  void toggleDesignMode() {
    state = state.copyWith(isDesignMode: !state.isDesignMode);
  }

  void setCanvasSize(double width, double height) {
    state = state.copyWith(canvasWidth: width, canvasHeight: height);
  }

  void setCanvasScale(double scale) {
    state = state.copyWith(canvasScale: scale);
  }

  // --- Tree Manipulation & Undo/Redo ---

  void _pushHistory(ComponentNode nextRoot) {
    // Keep max 20 history entries to save memory on large trees.
    final updatedPast = [...state.past, state.rootNode];
    state = state.copyWith(
      past: updatedPast.length > 20 ? updatedPast.sublist(updatedPast.length - 20) : updatedPast,
      rootNode: nextRoot,
      future: [],
    );
    _syncWithJourney();
  }

  void undo() {
    if (state.past.isEmpty) return;
    final prev = state.past.last;
    final updatedPast = state.past.sublist(0, state.past.length - 1);
    final updatedFuture = [state.rootNode, ...state.future];

    state = state.copyWith(
      past: updatedPast,
      rootNode: prev,
      future: updatedFuture,
    );
    _syncWithJourney();
  }

  void redo() {
    if (state.future.isEmpty) return;
    final next = state.future.first;
    final updatedFuture = state.future.sublist(1);
    final updatedPast = [...state.past, state.rootNode];

    state = state.copyWith(
      past: updatedPast,
      rootNode: next,
      future: updatedFuture,
    );
    _syncWithJourney();
  }

  void addChildNode(String parentId, String componentType) {
    final meta = ComponentRegistry.getByType(componentType);
    if (meta == null) return;

    final newNode = ComponentNode(
      id: 'node_${DateTime.now().millisecondsSinceEpoch}_${(100 + (100 * (newNodeIndex++ % 9))).toInt()}',
      type: componentType,
      properties: Map<String, dynamic>.from(meta.defaultProperties),
      children: [],
      actions: [],
    );

    final updatedRoot = _addChildToParent(state.rootNode, parentId, newNode);
    if (updatedRoot != null) {
      _pushHistory(updatedRoot);
      selectNode(newNode);
    }
  }

  static int newNodeIndex = 0;

  void moveChildNode(ComponentNode parent, ComponentNode child, int targetIndex) {
    // Delete child from original position first
    final cleanRoot = _removeNode(state.rootNode, child.id);
    if (cleanRoot == null) return;

    // Add back to new parent at targetIndex
    final updatedRoot = _insertChildInParent(cleanRoot, parent.id, child, targetIndex);
    if (updatedRoot != null) {
      _pushHistory(updatedRoot);
      selectNode(child);
    }
  }

  void deleteNode(String nodeId) {
    if (nodeId == state.rootNode.id) return; // cannot delete root
    final updatedRoot = _removeNode(state.rootNode, nodeId);
    if (updatedRoot != null) {
      _pushHistory(updatedRoot);
      if (state.selectedNode?.id == nodeId) {
        selectNode(null);
      }
    }
  }

  void duplicateNode(String nodeId) {
    final target = _findNode(state.rootNode, nodeId);
    if (target == null) return;

    final duplicate = _deepCloneNodeWithNewIds(target);
    final parent = _findParentNode(state.rootNode, nodeId);
    if (parent == null) return;

    final index = parent.children.indexWhere((c) => c.id == nodeId);
    final updatedRoot = _insertChildInParent(state.rootNode, parent.id, duplicate, index + 1);
    if (updatedRoot != null) {
      _pushHistory(updatedRoot);
      selectNode(duplicate);
    }
  }

  void copyNode(ComponentNode node) {
    _clipboardNode = node;
  }

  void pasteNode(String parentId) {
    if (_clipboardNode == null) return;
    final duplicate = _deepCloneNodeWithNewIds(_clipboardNode!);
    final updatedRoot = _addChildToParent(state.rootNode, parentId, duplicate);
    if (updatedRoot != null) {
      _pushHistory(updatedRoot);
      selectNode(duplicate);
    }
  }

  void updateNodeProperties(String nodeId, Map<String, dynamic> props) {
    final updatedRoot = _updateNodeInTree(state.rootNode, nodeId, (node) {
      final newProps = Map<String, dynamic>.from(node.properties);
      final newStyles = Map<String, dynamic>.from(node.styles);

      // Must match the full style key list in component_node.dart fromJson migration.
      const styleKeys = {
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
      };

      for (final entry in props.entries) {
        if (styleKeys.contains(entry.key)) {
          newStyles[entry.key] = entry.value;
        } else {
          newProps[entry.key] = entry.value;
        }
      }

      return node.copyWith(properties: newProps, styles: newStyles);
    });
    if (updatedRoot != null) {
      _pushHistory(updatedRoot);
      // Refresh active selected node property fields
      final updatedSelected = _findNode(updatedRoot, nodeId);
      if (updatedSelected != null) {
        selectNode(updatedSelected);
      }
    }
  }

  void updateNodeActions(String nodeId, List<ComponentAction> actions) {
    final updatedRoot = _updateNodeInTree(state.rootNode, nodeId, (node) {
      return node.copyWith(actions: actions);
    });
    if (updatedRoot != null) {
      _pushHistory(updatedRoot);
      final updatedSelected = _findNode(updatedRoot, nodeId);
      if (updatedSelected != null) {
        selectNode(updatedSelected);
      }
    }
  }

  // --- JSON import/export ---

  bool importFromJson(String jsonStr) {
    try {
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      final node = ComponentNode.fromJson(decoded);
      _pushHistory(node);
      selectNode(null);
      return true;
    } catch (_) {
      return false;
    }
  }

  String exportToJson() {
    return const JsonEncoder.withIndent('  ').convert(state.rootNode.toJson());
  }

  // --- Step Synchronization Logic ---

  void _loadStepFromJourney(String stepId) {
    final journeyConfig = _ref.read(journeyConfigProvider);
    var stepIndex = journeyConfig.steps.indexWhere((s) => s.id == stepId);

    // Fallback to first step if activeStepId is invalid/not found
    if (stepIndex == -1 && journeyConfig.steps.isNotEmpty) {
      stepIndex = 0;
      stepId = journeyConfig.steps.first.id;
      Future.microtask(() {
        _ref.read(activeStepIdProvider.notifier).state = stepId;
      });
    }

    if (stepIndex == -1) return;

    final step = journeyConfig.steps[stepIndex];
    state = VisualBuilderState(
      rootNode: JourneyVisualAdapter.createTreeFromJourneyStep(step),
      activeStepId: stepId,
    );
  }

  void _syncWithJourney() {
    if (state.activeStepId.isEmpty) return;

    final fields = JourneyVisualAdapter.extractFields(state.rootNode);
    final layoutJson = state.rootNode.toJson();

    _ref.read(journeyConfigProvider.notifier).updateStepLayout(
          state.activeStepId,
          layoutJson,
          fields,
        );
  }

  // --- Tree Traversals Helper Functions ---

  ComponentNode? _findNode(ComponentNode current, String id) {
    if (current.id == id) return current;
    for (final child in current.children) {
      final found = _findNode(child, id);
      if (found != null) return found;
    }
    return null;
  }

  ComponentNode? _findParentNode(ComponentNode current, String childId) {
    for (final child in current.children) {
      if (child.id == childId) return current;
      final found = _findParentNode(child, childId);
      if (found != null) return found;
    }
    return null;
  }

  ComponentNode? _addChildToParent(ComponentNode current, String parentId, ComponentNode newNode) {
    if (current.id == parentId) {
      return current.copyWith(children: [...current.children, newNode]);
    }
    final List<ComponentNode> updatedChildren = [];
    bool modified = false;
    for (final child in current.children) {
      final res = _addChildToParent(child, parentId, newNode);
      if (res != null) {
        updatedChildren.add(res);
        modified = true;
      } else {
        updatedChildren.add(child);
      }
    }
    return modified ? current.copyWith(children: updatedChildren) : null;
  }

  ComponentNode? _insertChildInParent(ComponentNode current, String parentId, ComponentNode newNode, int index) {
    if (current.id == parentId) {
      final List<ComponentNode> list = List.from(current.children);
      if (index >= 0 && index <= list.length) {
        list.insert(index, newNode);
      } else {
        list.add(newNode);
      }
      return current.copyWith(children: list);
    }
    final List<ComponentNode> updatedChildren = [];
    bool modified = false;
    for (final child in current.children) {
      final res = _insertChildInParent(child, parentId, newNode, index);
      if (res != null) {
        updatedChildren.add(res);
        modified = true;
      } else {
        updatedChildren.add(child);
      }
    }
    return modified ? current.copyWith(children: updatedChildren) : null;
  }

  ComponentNode? _removeNode(ComponentNode current, String targetId) {
    if (current.id == targetId) return null;
    final List<ComponentNode> updatedChildren = [];
    bool modified = false;
    for (final child in current.children) {
      final res = _removeNode(child, targetId);
      if (res == null) {
        modified = true; // removed
      } else {
        updatedChildren.add(res);
        if (res.id != child.id || res.children.length != child.children.length) {
          modified = true; // modified somewhere below
        }
      }
    }
    return modified ? current.copyWith(children: updatedChildren) : current;
  }

  ComponentNode? _updateNodeInTree(ComponentNode current, String id, ComponentNode Function(ComponentNode) updateFn) {
    if (current.id == id) {
      return updateFn(current);
    }
    final List<ComponentNode> updatedChildren = [];
    bool modified = false;
    for (final child in current.children) {
      final res = _updateNodeInTree(child, id, updateFn);
      if (res != null) {
        updatedChildren.add(res);
        if (res.id != child.id || res.properties != child.properties || res.children.length != child.children.length) {
          modified = true;
        }
      } else {
        updatedChildren.add(child);
      }
    }
    return modified ? current.copyWith(children: updatedChildren) : current;
  }

  ComponentNode _deepCloneNodeWithNewIds(ComponentNode origin) {
    final newId = 'node_${DateTime.now().millisecondsSinceEpoch}_${(100 + (100 * (newNodeIndex++ % 9))).toInt()}';
    return ComponentNode(
      id: newId,
      type: origin.type,
      properties: Map<String, dynamic>.from(origin.properties),
      children: origin.children.map((c) => _deepCloneNodeWithNewIds(c)).toList(),
      actions: origin.actions.map((a) => a.copyWith()).toList(),
    );
  }
}

// ── Main Provider ──────────────────────────────────────────────────────────
final visualBuilderProvider = StateNotifierProvider<VisualBuilderController, VisualBuilderState>((ref) {
  return VisualBuilderController(ref);
});

// ── Granular Derived Providers ─────────────────────────────────────────────
// Use these in widgets instead of watching the whole state.
// Each only triggers a rebuild when its specific slice changes.

/// Root node tree — rebuilds on any tree structural change.
final builderRootNodeProvider = Provider<ComponentNode>((ref) {
  return ref.watch(visualBuilderProvider.select((s) => s.rootNode));
});

/// Selected node — rebuilds only when selection changes.
final builderSelectedNodeProvider = Provider<ComponentNode?>((ref) {
  return ref.watch(visualBuilderProvider.select((s) => s.selectedNode));
});

/// Hovered node — rebuilds only when hover changes (debounced in controller).
final builderHoveredNodeProvider = Provider<ComponentNode?>((ref) {
  return ref.watch(visualBuilderProvider.select((s) => s.hoveredNode));
});

/// Design/Preview mode — rebuilds only on mode toggle.
final builderDesignModeProvider = Provider<bool>((ref) {
  return ref.watch(visualBuilderProvider.select((s) => s.isDesignMode));
});

/// Canvas dimensions — rebuilds only when size/scale changes.
final builderCanvasSizeProvider = Provider<({double width, double height, double scale})>((ref) {
  return ref.watch(visualBuilderProvider.select((s) => (width: s.canvasWidth, height: s.canvasHeight, scale: s.canvasScale)));
});

/// Undo/Redo availability — rebuilds only when history changes.
final builderHistoryProvider = Provider<({bool canUndo, bool canRedo})>((ref) {
  return ref.watch(visualBuilderProvider.select((s) => (canUndo: s.past.isNotEmpty, canRedo: s.future.isNotEmpty)));
});

