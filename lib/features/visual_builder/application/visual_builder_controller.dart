import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/component_engine/models/component_node.dart';
import '../../../core/component_engine/models/component_action.dart';
import '../../../core/component_engine/registry/component_registry.dart';
import '../../journey_builder/application/controllers/journey_controller.dart';
import '../../journey_builder/domain/entities/journey_models.dart';
import '../integration/journey_visual_adapter.dart';
import 'visual_builder_commands.dart';
import 'visual_builder_logger.dart';

class VisualBuilderState {
  final ComponentNode rootNode;
  final ComponentNode? selectedNode;
  final ComponentNode? hoveredNode;
  final double canvasWidth;
  final double canvasHeight;
  final double canvasScale;
  final bool isDesignMode;
  final String activeStepId;
  final List<VisualBuilderCommand> past;
  final List<VisualBuilderCommand> future;

  VisualBuilderState({
    required this.rootNode,
    this.selectedNode,
    this.hoveredNode,
    this.canvasWidth = 1440,
    this.canvasHeight = 900,
    this.canvasScale = 0.7,
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
    List<VisualBuilderCommand>? past,
    List<VisualBuilderCommand>? future,
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
  static VisualBuilderController? activeInstance;

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
    activeInstance = this;
    StudioCommand.activeController = this;
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

  void toggleOrientation() {
    state = state.copyWith(
      canvasWidth: state.canvasHeight,
      canvasHeight: state.canvasWidth,
    );
  }

  void resetCanvas() {
    state = state.copyWith(
      canvasWidth: 1440,
      canvasHeight: 900,
      canvasScale: 1.0,
    );
  }

  // --- Tree Manipulation & Undo/Redo ---

  void executeCommand(VisualBuilderCommand command) {
    try {
      VisualBuilderLogger.log('Command', 'Executing ${command.runtimeType}...');
      final nextRoot = command.executeTree(state.rootNode);

      ComponentNode? nextSelected;
      if (command.selectedNodeIdAfterExecute != null) {
        nextSelected = _findNode(nextRoot, command.selectedNodeIdAfterExecute!);
      }

      final updatedPast = [...state.past, command];
      state = state.copyWith(
        past: updatedPast.length > 30 ? updatedPast.sublist(updatedPast.length - 30) : updatedPast,
        rootNode: nextRoot,
        selectedNode: nextSelected,
        clearSelected: nextSelected == null,
        future: [],
      );
      _syncWithJourney();
      VisualBuilderLogger.log('Command', 'Successfully executed ${command.runtimeType}. Past history size: ${state.past.length}.');
    } catch (e, stack) {
      VisualBuilderLogger.log('Command', 'Failed to execute ${command.runtimeType}', level: LogLevel.error, error: e, stackTrace: stack);
    }
  }

  void undo() {
    if (state.past.isEmpty) {
      VisualBuilderLogger.log('Command', 'Undo requested, but history is empty.', level: LogLevel.warning);
      return;
    }
    final command = state.past.last;
    try {
      VisualBuilderLogger.log('Command', 'Undoing ${command.runtimeType}...');
      final prevRoot = command.undoTree(state.rootNode);

      ComponentNode? nextSelected;
      if (command.selectedNodeIdAfterUndo != null) {
        nextSelected = _findNode(prevRoot, command.selectedNodeIdAfterUndo!);
      }

      final updatedPast = state.past.sublist(0, state.past.length - 1);
      final updatedFuture = [command, ...state.future];

      state = state.copyWith(
        past: updatedPast,
        rootNode: prevRoot,
        selectedNode: nextSelected,
        clearSelected: nextSelected == null,
        future: updatedFuture,
      );
      _syncWithJourney();
      VisualBuilderLogger.log('Command', 'Successfully undid ${command.runtimeType}. Past history size: ${state.past.length}.');
    } catch (e, stack) {
      VisualBuilderLogger.log('Command', 'Failed to undo ${command.runtimeType}', level: LogLevel.error, error: e, stackTrace: stack);
    }
  }

  void undoSpecificCommand(VisualBuilderCommand command) {
    if (state.past.isNotEmpty && state.past.last == command) {
      undo();
      return;
    }
    try {
      VisualBuilderLogger.log('Command', 'Undoing specific ${command.runtimeType}...');
      final prevRoot = command.undoTree(state.rootNode);

      ComponentNode? nextSelected;
      if (command.selectedNodeIdAfterUndo != null) {
        nextSelected = _findNode(prevRoot, command.selectedNodeIdAfterUndo!);
      }

      state = state.copyWith(
        rootNode: prevRoot,
        selectedNode: nextSelected,
        clearSelected: nextSelected == null,
        past: state.past.where((c) => c != command).toList(),
      );
      _syncWithJourney();
      VisualBuilderLogger.log('Command', 'Successfully undid specific ${command.runtimeType}.');
    } catch (e, stack) {
      VisualBuilderLogger.log('Command', 'Failed to undo specific command ${command.runtimeType}', level: LogLevel.error, error: e, stackTrace: stack);
    }
  }

  void redo() {
    if (state.future.isEmpty) {
      VisualBuilderLogger.log('Command', 'Redo requested, but future history is empty.', level: LogLevel.warning);
      return;
    }
    final command = state.future.first;
    try {
      VisualBuilderLogger.log('Command', 'Redoing ${command.runtimeType}...');
      final nextRoot = command.executeTree(state.rootNode);

      ComponentNode? nextSelected;
      if (command.selectedNodeIdAfterExecute != null) {
        nextSelected = _findNode(nextRoot, command.selectedNodeIdAfterExecute!);
      }

      final updatedFuture = state.future.sublist(1);
      final updatedPast = [...state.past, command];

      state = state.copyWith(
        past: updatedPast,
        rootNode: nextRoot,
        selectedNode: nextSelected,
        clearSelected: nextSelected == null,
        future: updatedFuture,
      );
      _syncWithJourney();
      VisualBuilderLogger.log('Command', 'Successfully redid ${command.runtimeType}. Past history size: ${state.past.length}.');
    } catch (e, stack) {
      VisualBuilderLogger.log('Command', 'Failed to redo ${command.runtimeType}', level: LogLevel.error, error: e, stackTrace: stack);
    }
  }

  void addChildNode(String parentId, String componentType, {int? targetIndex}) {
    final meta = ComponentRegistry.getByType(componentType);
    if (meta == null) return;

    final newNode = ComponentNode(
      id: 'node_${DateTime.now().millisecondsSinceEpoch}_${(100 + (100 * (newNodeIndex++ % 9))).toInt()}',
      type: componentType,
      properties: Map<String, dynamic>.from(meta.defaultProperties),
      children: [],
      actions: [],
    );

    executeCommand(AddWidgetCommand(
      parentId: parentId,
      node: newNode,
      index: targetIndex,
    ));
  }

  static int newNodeIndex = 0;

  void moveChildNode(ComponentNode parent, ComponentNode child, int targetIndex) {
    executeCommand(MoveWidgetCommand(
      nodeId: child.id,
      newParentId: parent.id,
      newIndex: targetIndex,
    ));
  }

  void deleteNode(String nodeId) {
    if (nodeId == state.rootNode.id) return; // cannot delete root
    executeCommand(DeleteWidgetCommand(nodeId: nodeId));
  }

  void duplicateNode(String nodeId) {
    final target = _findNode(state.rootNode, nodeId);
    if (target == null) return;

    final duplicate = _deepCloneNodeWithNewIds(target);
    final parent = _findParentNode(state.rootNode, nodeId);
    if (parent == null) return;

    final index = parent.children.indexWhere((c) => c.id == nodeId);
    executeCommand(AddWidgetCommand(
      parentId: parent.id,
      node: duplicate,
      index: index + 1,
    ));
  }

  void copyNode(ComponentNode node) {
    _clipboardNode = node;
  }

  void pasteNode(String parentId) {
    if (_clipboardNode == null) return;
    final duplicate = _deepCloneNodeWithNewIds(_clipboardNode!);
    executeCommand(AddWidgetCommand(
      parentId: parentId,
      node: duplicate,
    ));
  }

  void updateNodeProperties(String nodeId, Map<String, dynamic> props) {
    final newProps = <String, dynamic>{};
    final newStyles = <String, dynamic>{};

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

    executeCommand(UpdatePropertyCommand(
      nodeId: nodeId,
      newProperties: newProps,
      newStyles: newStyles,
    ));
  }

  void updateNodeActions(String nodeId, List<ComponentAction> actions) {
    executeCommand(UpdateActionsCommand(
      nodeId: nodeId,
      newActions: actions,
    ));
  }

  // --- JSON import/export ---

  bool importFromJson(String jsonStr) {
    try {
      VisualBuilderLogger.log('JSON', 'Importing layout from JSON...');
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      final node = ComponentNode.fromJson(decoded);
      executeCommand(ImportLayoutCommand(newRoot: node));
      selectNode(null);
      VisualBuilderLogger.log('JSON', 'Successfully imported layout from JSON.');
      return true;
    } catch (e, stack) {
      VisualBuilderLogger.log('JSON', 'Failed to import layout from JSON', level: LogLevel.error, error: e, stackTrace: stack);
      return false;
    }
  }

  String exportToJson() {
    try {
      VisualBuilderLogger.log('JSON', 'Exporting layout to JSON...');
      final exported = const JsonEncoder.withIndent('  ').convert(state.rootNode.toJson());
      VisualBuilderLogger.log('JSON', 'Successfully exported layout to JSON. Size: ${exported.length} characters.');
      return exported;
    } catch (e, stack) {
      VisualBuilderLogger.log('JSON', 'Failed to export layout to JSON', level: LogLevel.error, error: e, stackTrace: stack);
      rethrow;
    }
  }

  // --- Step Synchronization Logic ---

  void _loadStepFromJourney(String stepId) {
    try {
      VisualBuilderLogger.log('Sync', 'Loading step layout for stepId: $stepId...');
      final journeyConfig = _ref.read(journeyConfigProvider);
      var stepIndex = journeyConfig.steps.indexWhere((s) => s.id == stepId);

      // Fallback to first step if activeStepId is invalid/not found
      if (stepIndex == -1 && journeyConfig.steps.isNotEmpty) {
        VisualBuilderLogger.log('Sync', 'StepId $stepId not found in journey config, falling back to first step.', level: LogLevel.warning);
        stepIndex = 0;
        stepId = journeyConfig.steps.first.id;
        Future.microtask(() {
          _ref.read(activeStepIdProvider.notifier).state = stepId;
        });
      }

      if (stepIndex == -1) {
        VisualBuilderLogger.log('Sync', 'No steps available in journey config to load.', level: LogLevel.warning);
        return;
      }

      final step = journeyConfig.steps[stepIndex];
      final tree = JourneyVisualAdapter.createTreeFromJourneyStep(step);
      state = VisualBuilderState(
        rootNode: tree,
        activeStepId: stepId,
      );
      VisualBuilderLogger.log('Sync', 'Successfully loaded step layout. Root node ID: ${tree.id}, children count: ${tree.children.length}.');
    } catch (e, stack) {
      VisualBuilderLogger.log('Sync', 'Error loading step layout for stepId: $stepId', level: LogLevel.error, error: e, stackTrace: stack);
    }
  }

  void _syncWithJourney() {
    if (state.activeStepId.isEmpty) {
      VisualBuilderLogger.log('Sync', 'Synchronization skipped: activeStepId is empty.', level: LogLevel.warning);
      return;
    }

    try {
      VisualBuilderLogger.log('Sync', 'Synchronizing layout to journey stepId: ${state.activeStepId}...');
      final fields = JourneyVisualAdapter.extractFields(state.rootNode);
      final layoutJson = state.rootNode.toJson();

      _ref.read(journeyConfigProvider.notifier).updateStepLayout(
            state.activeStepId,
            layoutJson,
            fields,
          );
      VisualBuilderLogger.log('Sync', 'Successfully synchronized layout. Fields count: ${fields.length}.');
    } catch (e, stack) {
      VisualBuilderLogger.log('Sync', 'Error synchronizing layout to journey stepId: ${state.activeStepId}', level: LogLevel.error, error: e, stackTrace: stack);
    }
  }

  // --- Tree Traversals Helper Functions ---

  ComponentNode? findNodeById(String id) {
    return _findNode(state.rootNode, id);
  }

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

