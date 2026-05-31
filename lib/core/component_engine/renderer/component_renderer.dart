// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/component_node.dart';
import '../models/component_property.dart';
import '../registry/component_registry.dart';
import '../validation/nesting_validator.dart';
import '../../../features/visual_builder/application/visual_builder_controller.dart';
import '../../../features/visual_builder/application/studio_providers.dart';
import '../../../features/journey_builder/application/controllers/journey_controller.dart';
import 'component_renderer_layouts.dart';
import 'component_renderer_inputs.dart';
import 'component_renderer_basic.dart';

class RenderContext {
  final bool isDesignMode;
  final ComponentNode? parentNode;
  final ComponentNode? selectedNode;
  final ComponentNode? hoveredNode;
  final void Function(ComponentNode?)? onSelect;
  final void Function(ComponentNode?)? onHover;
  final void Function(ComponentNode)? onDelete;
  final void Function(ComponentNode)? onDuplicate;
  final void Function(ComponentNode, ComponentNode, int)? onMoveChild;
  final void Function(ComponentNode, String, {int? targetIndex, String? slotName})? onAddChild;
  final Map<String, dynamic> formValues;
  final void Function(String, dynamic)? onFormValueChanged;
  final bool insideScrollable;
  final ThemeTokens? themeTokens;

  RenderContext({
    required this.isDesignMode,
    this.parentNode,
    this.selectedNode,
    this.hoveredNode,
    this.onSelect,
    this.onHover,
    this.onDelete,
    this.onDuplicate,
    this.onMoveChild,
    this.onAddChild,
    required this.formValues,
    this.onFormValueChanged,
    required this.insideScrollable,
    this.themeTokens,
  });

  List<Widget> renderChildren(ComponentNode node, {bool propagateScrollable = false}) {
    if (node.children.isEmpty && isDesignMode) {
      return [ComponentRenderer.buildEmptyPlaceholder(node, onAddChild: onAddChild)];
    }
    return node.children
        .map(
          (child) => ComponentRenderer.render(
            child,
            isDesignMode: isDesignMode,
            parentNode: node,
            selectedNode: selectedNode,
            hoveredNode: hoveredNode,
            onSelect: onSelect,
            onHover: onHover,
            onDelete: onDelete,
            onDuplicate: onDuplicate,
            onMoveChild: onMoveChild,
            onAddChild: onAddChild,
            formValues: formValues,
            onFormValueChanged: onFormValueChanged,
            insideScrollable: propagateScrollable ? true : insideScrollable,
          ),
        )
        .toList();
  }
}

class ComponentRendererWidget extends ConsumerWidget {
  final ComponentNode node;
  final ComponentNode? parentNode;
  final bool insideScrollable;
  final bool? overrideIsDesignMode;
  final Map<String, dynamic>? overrideFormValues;
  final void Function(String, dynamic)? overrideOnFormValueChanged;
  
  final void Function(ComponentNode?)? overrideOnSelect;
  final void Function(ComponentNode?)? overrideOnHover;
  final void Function(ComponentNode)? overrideOnDelete;
  final void Function(ComponentNode)? overrideOnDuplicate;
  final void Function(ComponentNode, ComponentNode, int)? overrideOnMoveChild;
  final void Function(ComponentNode, String, {int? targetIndex, String? slotName})? overrideOnAddChild;

  const ComponentRendererWidget({
    required ValueKey<String> super.key,
    required this.node,
    this.parentNode,
    this.insideScrollable = false,
    this.overrideIsDesignMode,
    this.overrideFormValues,
    this.overrideOnFormValueChanged,
    this.overrideOnSelect,
    this.overrideOnHover,
    this.overrideOnDelete,
    this.overrideOnDuplicate,
    this.overrideOnMoveChild,
    this.overrideOnAddChild,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDesignMode = overrideIsDesignMode ?? ref.watch(builderDesignModeProvider);
    final themeTokens = ref.watch(themeTokensProvider).tokens;
    
    final isSelected = ref.watch(visualBuilderProvider.select((s) => s.selectedNode?.id == node.id));
    final isHovered = ref.watch(visualBuilderProvider.select((s) => s.hoveredNode?.id == node.id));
    
    final Map<String, dynamic> formValues = overrideFormValues ?? ref.watch(formValuesProvider);
    final controller = ref.read(visualBuilderProvider.notifier);

    final onSelect = overrideOnSelect ?? (ComponentNode? n) => controller.selectNode(n);
    final onHover = overrideOnHover ?? (ComponentNode? n) => controller.hoverNode(n);
    final onDelete = overrideOnDelete ?? (ComponentNode n) => controller.deleteNode(n.id);
    final onDuplicate = overrideOnDuplicate ?? (ComponentNode n) => controller.duplicateNode(n.id);
    final onMoveChild = overrideOnMoveChild ?? (ComponentNode parent, ComponentNode child, int idx) => controller.moveChildNode(parent, child, idx);
    // FIX: onAddChild now supports slotName parameter for slot-based widgets
    final onAddChild = overrideOnAddChild ?? (ComponentNode parent, String type, {int? targetIndex, String? slotName}) => controller.addChildNode(parent.id, type, targetIndex: targetIndex, slotName: slotName);
    final onFormValueChanged = overrideOnFormValueChanged ?? (String field, dynamic val) {
      ref.read(formValuesProvider.notifier).updateValue(field, val);
    };

    double currentWidth = MediaQuery.of(context).size.width;
    try {
      final simulatedWidth = ref.watch(visualBuilderProvider.select((s) => s.canvasWidth));
      if (simulatedWidth > 0) {
        currentWidth = simulatedWidth;
      }
    } catch (_) {}

    final isMobile = currentWidth < 600;
    final isTablet = currentWidth >= 600 && currentWidth < 1024;
    final isDesktop = currentWidth >= 1024;

    final resp = node.responsive;
    if (resp.isNotEmpty) {
      final isVisible = (isMobile && resp['visibleOnMobile'] != false) ||
                        (isTablet && resp['visibleOnTablet'] != false) ||
                        (isDesktop && resp['visibleOnDesktop'] != false);
      if (!isVisible) {
        return const SizedBox.shrink();
      }
    }

    Widget coreWidget = ComponentRenderer.buildWidget(
      node,
      isDesignMode: isDesignMode,
      parentNode: parentNode,
      selectedNode: ref.read(visualBuilderProvider).selectedNode,
      hoveredNode: ref.read(visualBuilderProvider).hoveredNode,
      onSelect: onSelect,
      onHover: onHover,
      onDelete: onDelete,
      onDuplicate: onDuplicate,
      onMoveChild: onMoveChild,
      onAddChild: onAddChild,
      formValues: formValues,
      onFormValueChanged: onFormValueChanged,
      insideScrollable: insideScrollable,
      themeTokens: themeTokens,
    );

    coreWidget = ComponentRenderer.applyPaddingAndSizing(coreWidget, node);
    coreWidget = ComponentRenderer.applyDecoration(coreWidget, node);

    // FIX: Do NOT AbsorbPointer the entire coreWidget — that blocks nested DragTargets.
    // Instead we only block tap gestures at the core level via GestureDetector with
    // HitTestBehavior. We let pointer events pass through to inner DragTargets.

    Widget resultWidget;

    if (isDesignMode) {
      const nonDraggableTypes = {
        'Scaffold',
      };

      if (nonDraggableTypes.contains(node.type)) {
        final decorated = Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF5B4FCF)
                  : isHovered
                      ? const Color(0xFF9E95F5)
                      : Colors.transparent,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: coreWidget,
        );
        resultWidget = ComponentRenderer.applyMargin(
          GestureDetector(
            onTap: () {
              onSelect(node);
            },
            behavior: HitTestBehavior.translucent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                decorated,
                if (isSelected)
                  Positioned(
                    top: -24,
                    left: 0,
                    child: Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5B4FCF),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            node.type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              onDelete(node);
                            },
                            child: const Icon(
                              Icons.delete_forever_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          node,
        );
      } else {
        final meta = ComponentRegistry.getByType(node.type);
        final isSlotBased = meta != null && meta.slotNames.isNotEmpty;
        final isMultiChild = meta != null && !isSlotBased && (meta.maxChildren == null);
        final canAcceptChildren = meta?.canHaveChildren ?? false;

        // FIX: Use IgnorePointer only for leaf/input widgets that shouldn't intercept
        // drag events. Container-like widgets must pass pointer events through.
        Widget displayWidget = coreWidget;
        // Only block tap-like interactions on leaf widgets, not containers
        if (!canAcceptChildren) {
          displayWidget = IgnorePointer(ignoringSemantics: false, child: coreWidget);
        }

        Widget interactiveWrapper = MouseRegion(
          onEnter: (_) {
            onHover(node);
          },
          onExit: (_) {
            if (ref.read(visualBuilderProvider).hoveredNode?.id == node.id) {
              onHover(null);
            }
          },
          child: GestureDetector(
            onTap: () {
              onSelect(node);
            },
            behavior: HitTestBehavior.translucent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF5B4FCF)
                          : isHovered
                              ? const Color(0xFF9E95F5)
                              : Colors.transparent,
                      width: isSelected ? 2.0 : 1.5,
                    ),
                  ),
                  child: displayWidget,
                ),
                if (isSelected)
                  Positioned(
                    top: -24,
                    left: 0,
                    child: Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5B4FCF),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            node.type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              onDuplicate(node);
                            },
                            child: const Icon(
                              Icons.copy_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              onDelete(node);
                            },
                            child: const Icon(
                              Icons.delete_forever_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );

        Widget dragSource = Draggable<ComponentNode>(
          data: node,
          onDragStarted: () => ref.read(canvasIsDraggingProvider.notifier).state = true,
          onDragEnd: (_) => ref.read(canvasIsDraggingProvider.notifier).state = false,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF5B4FCF).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                node.type,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: interactiveWrapper),
          child: interactiveWrapper,
        );

        Widget designWidget = dragSource;

        // FIX: Build drop zones properly based on widget type.
        // - Slot-based single-child (Container, Card, Center, Padding...) → handled by SlotDragTarget
        //   inside the renderer, so we only show child-area drop if no slot child yet.
        // - Multi-child (Column, Row, Stack, Wrap...) → full-area drop + top/bottom edge zones.
        // - Leaf widgets (Button, Text, etc.) → only top/bottom sibling drop zones.

        if (canAcceptChildren || parentNode != null) {
          designWidget = Stack(
            clipBehavior: Clip.none,
            children: [
              designWidget,

              // ── Multi-child container drop zone (Column, Row, Stack, Wrap, ListView, etc.) ──
              if (canAcceptChildren && isMultiChild)
                Positioned.fill(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final isDragging = ref.watch(canvasIsDraggingProvider);
                      if (!isDragging) return const SizedBox.shrink();
                      return DragTarget<Object>(
                        onWillAcceptWithDetails: (details) {
                          final data = details.data;
                          final droppedNode = ComponentRenderer._dropDataToNode(data);
                          if (droppedNode == null) return false;
                          // Don't accept self
                          if (data is ComponentNode && data.id == node.id) return false;
                          return NestingValidator.validateDrop(node, droppedNode, null).success;
                        },
                        onAcceptWithDetails: (details) {
                          final data = details.data;
                          if (data is String) {
                            onAddChild.call(node, data);
                          } else if (data is ComponentNode) {
                            onMoveChild(node, data, node.children.length);
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          final isOver = candidateData.isNotEmpty;
                          return Container(
                            decoration: BoxDecoration(
                              color: isOver ? const Color(0x1F5B4FCF) : Colors.transparent,
                              border: isOver
                                  ? Border.all(color: const Color(0xFF5B4FCF), width: 2, strokeAlign: BorderSide.strokeAlignOutside)
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

              // ── Single-child slot drop zone (Container, Card, Center, Padding...) ──
              // Only show when the slot is empty (no child yet)
              if (canAcceptChildren && isSlotBased && meta.slotNames.contains('child'))
                Positioned.fill(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final isDragging = ref.watch(canvasIsDraggingProvider);
                      // Only show drop overlay when dragging AND the slot is empty
                      final slotFilled = node.slots['child'] != null;
                      if (!isDragging || slotFilled) return const SizedBox.shrink();
                      return DragTarget<Object>(
                        onWillAcceptWithDetails: (details) {
                          final data = details.data;
                          final droppedNode = ComponentRenderer._dropDataToNode(data);
                          if (droppedNode == null) return false;
                          if (data is ComponentNode && data.id == node.id) return false;
                          return NestingValidator.validateDrop(node, droppedNode, 'child').success;
                        },
                        onAcceptWithDetails: (details) {
                          final data = details.data;
                          // For String type (from palette), add to the 'child' slot
                          if (data is String) {
                            onAddChild.call(node, data, slotName: 'child');
                          }
                        },
                        builder: (context, candidateData, _) {
                          final isOver = candidateData.isNotEmpty;
                          return Container(
                            decoration: BoxDecoration(
                              color: isOver ? const Color(0x1F5B4FCF) : Colors.transparent,
                              border: isOver
                                  ? Border.all(color: const Color(0xFF5B4FCF), width: 2, strokeAlign: BorderSide.strokeAlignOutside)
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

              // ── Top drop zone: insert BEFORE this node (sibling drop) ──
              if (parentNode != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 16,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final isDragging = ref.watch(canvasIsDraggingProvider);
                      if (!isDragging) return const SizedBox.shrink();
                      return DragTarget<Object>(
                        onWillAcceptWithDetails: (details) {
                          final data = details.data;
                          if (data is ComponentNode && data.id == node.id) return false;
                          // Only allow sibling drops into multi-child parents
                          final parentMeta = ComponentRegistry.getByType(parentNode!.type);
                          if (parentMeta == null) return false;
                          final droppedNode = ComponentRenderer._dropDataToNode(data);
                          if (droppedNode == null) return false;
                          return NestingValidator.validateDrop(parentNode!, droppedNode, null).success;
                        },
                        onAcceptWithDetails: (details) {
                          final data = details.data;
                          final idx = parentNode!.children.indexWhere((c) => c.id == node.id);
                          if (idx != -1) {
                            if (data is String) {
                              onAddChild.call(parentNode!, data, targetIndex: idx);
                            } else if (data is ComponentNode) {
                              onMoveChild(parentNode!, data, idx);
                            }
                          }
                        },
                        builder: (context, candidateData, _) {
                          final isOver = candidateData.isNotEmpty;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(color: Colors.transparent),
                              if (isOver)
                                const Positioned(
                                  top: 0, left: 0, right: 0,
                                  child: _DropLineIndicator(position: _DropLinePosition.top),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),

              // ── Bottom drop zone: insert AFTER this node (sibling drop) ──
              if (parentNode != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 16,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final isDragging = ref.watch(canvasIsDraggingProvider);
                      if (!isDragging) return const SizedBox.shrink();
                      return DragTarget<Object>(
                        onWillAcceptWithDetails: (details) {
                          final data = details.data;
                          if (data is ComponentNode && data.id == node.id) return false;
                          final parentMeta = ComponentRegistry.getByType(parentNode!.type);
                          if (parentMeta == null) return false;
                          final droppedNode = ComponentRenderer._dropDataToNode(data);
                          if (droppedNode == null) return false;
                          return NestingValidator.validateDrop(parentNode!, droppedNode, null).success;
                        },
                        onAcceptWithDetails: (details) {
                          final data = details.data;
                          final idx = parentNode!.children.indexWhere((c) => c.id == node.id);
                          if (idx != -1) {
                            if (data is String) {
                              onAddChild.call(parentNode!, data, targetIndex: idx + 1);
                            } else if (data is ComponentNode) {
                              onMoveChild(parentNode!, data, idx + 1);
                            }
                          }
                        },
                        builder: (context, candidateData, _) {
                          final isOver = candidateData.isNotEmpty;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(color: Colors.transparent),
                              if (isOver)
                                const Positioned(
                                  bottom: 0, left: 0, right: 0,
                                  child: _DropLineIndicator(position: _DropLinePosition.bottom),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          );
        }

        resultWidget = ComponentRenderer.applyMargin(designWidget, node);
      }
    } else {
      resultWidget = ComponentRenderer.applyMargin(coreWidget, node);
    }

    if (parentNode == null || node.type == 'Scaffold') {
      final primaryHex = themeTokens.primaryColor.replaceAll('#', '').padLeft(8, 'FF');
      final secondaryHex = themeTokens.secondaryColor.replaceAll('#', '').padLeft(8, 'FF');
      final bgHex = themeTokens.backgroundColor.replaceAll('#', '').padLeft(8, 'FF');
      final cardHex = themeTokens.cardColor.replaceAll('#', '').padLeft(8, 'FF');
      final textHex = themeTokens.textPrimaryColor.replaceAll('#', '').padLeft(8, 'FF');

      final primary = Color(int.parse(primaryHex, radix: 16));
      final secondary = Color(int.parse(secondaryHex, radix: 16));
      final bg = Color(int.parse(bgHex, radix: 16));
      final cardColor = Color(int.parse(cardHex, radix: 16));
      final textColor = Color(int.parse(textHex, radix: 16));

      final brightness = themeTokens.isDarkMode ? Brightness.dark : Brightness.light;

      TextTheme txtTheme;
      try {
        txtTheme = GoogleFonts.getTextTheme(themeTokens.fontFamily);
      } catch (_) {
        txtTheme = const TextTheme();
      }

      final appTheme = ThemeData(
        brightness: brightness,
        colorScheme: ColorScheme(
          brightness: brightness,
          primary: primary,
          onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
          secondary: secondary,
          onSecondary: brightness == Brightness.dark ? Colors.black : Colors.white,
          surface: bg,
          onSurface: textColor,
          error: Colors.red,
          onError: Colors.white,
        ),
        cardColor: cardColor,
        textTheme: txtTheme,
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(themeTokens.borderRadius),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: themeTokens.inputStyle == 'outline'
              ? OutlineInputBorder(borderRadius: BorderRadius.circular(themeTokens.borderRadius))
              : themeTokens.inputStyle == 'underline'
                  ? const UnderlineInputBorder()
                  : const OutlineInputBorder(),
          filled: themeTokens.inputStyle == 'filled',
        ),
      );

      resultWidget = Theme(
        data: appTheme,
        child: resultWidget,
      );
    }

    return resultWidget;
  }
}

class ComponentRenderer {
  static Widget render(
    ComponentNode node, {
    required bool isDesignMode,
    ComponentNode? parentNode,
    ComponentNode? selectedNode,
    ComponentNode? hoveredNode,
    void Function(ComponentNode?)? onSelect,
    void Function(ComponentNode?)? onHover,
    void Function(ComponentNode)? onDelete,
    void Function(ComponentNode)? onDuplicate,
    void Function(ComponentNode, ComponentNode, int)? onMoveChild,
    void Function(ComponentNode, String, {int? targetIndex, String? slotName})? onAddChild,
    Map<String, dynamic> formValues = const {},
    void Function(String, dynamic)? onFormValueChanged,
    bool insideScrollable = false,
  }) {
    return ComponentRendererWidget(
      key: ValueKey(node.id),
      node: node,
      parentNode: parentNode,
      insideScrollable: insideScrollable,
      overrideIsDesignMode: isDesignMode,
      overrideFormValues: formValues,
      overrideOnFormValueChanged: onFormValueChanged,
      overrideOnSelect: onSelect,
      overrideOnHover: onHover,
      overrideOnDelete: onDelete,
      overrideOnDuplicate: onDuplicate,
      overrideOnMoveChild: onMoveChild,
      overrideOnAddChild: onAddChild,
    );
  }

  static dynamic getStyle(ComponentNode node, String key) {
    if (node.styles.containsKey(key)) return node.styles[key];
    return node.properties[key];
  }

  static Widget buildWidget(
    ComponentNode node, {
    required bool isDesignMode,
    ComponentNode? parentNode,
    ComponentNode? selectedNode,
    ComponentNode? hoveredNode,
    void Function(ComponentNode?)? onSelect,
    void Function(ComponentNode?)? onHover,
    void Function(ComponentNode)? onDelete,
    void Function(ComponentNode)? onDuplicate,
    void Function(ComponentNode, ComponentNode, int)? onMoveChild,
    void Function(ComponentNode, String, {int? targetIndex, String? slotName})? onAddChild,
    Map<String, dynamic> formValues = const {},
    void Function(String, dynamic)? onFormValueChanged,
    bool insideScrollable = false,
    ThemeTokens? themeTokens,
  }) {
    final ctx = RenderContext(
      isDesignMode: isDesignMode,
      parentNode: parentNode,
      selectedNode: selectedNode,
      hoveredNode: hoveredNode,
      onSelect: onSelect,
      onHover: onHover,
      onDelete: onDelete,
      onDuplicate: onDuplicate,
      onMoveChild: onMoveChild,
      onAddChild: onAddChild,
      formValues: formValues,
      onFormValueChanged: onFormValueChanged,
      insideScrollable: insideScrollable,
      themeTokens: themeTokens,
    );

    final type = node.type;

    const layoutTypes = {
      'Container', 'Row', 'Column', 'Stack', 'Wrap', 'GridView', 'ListView',
      'Card', 'SizedBox', 'Spacer', 'Expanded', 'Flexible', 'SafeArea',
      'Tabs', 'Drawer', 'NavigationBar', 'Scaffold', 'SingleChildScrollView',
      'Carousel', 'BottomNavigationBar', 'BottomNavigationBarItem',
      'Table', 'Stepper', 'Timeline', 'Chart',
      'Center', 'Padding', 'Align', 'Opacity', 'Transform', 'Positioned',
      'AspectRatio', 'GestureDetector', 'InkWell', 'AppBar',
      'ListTile', 'AlertDialog', 'TabBarView',
    };

    const inputTypes = {
      'TextField', 'Dropdown', 'Radio', 'Checkbox', 'DatePicker', 'Switch',
      'Slider', 'FilePicker', 'OTP', 'Search'
    };

    const basicTypes = {
      'Button', 'IconButton', 'FloatingButton', 'Text', 'Image', 'Icon',
      'Divider', 'Avatar', 'Chip', 'Badge', 'Progress'
    };

    if (layoutTypes.contains(type)) {
      return ComponentRendererLayouts.buildLayout(node, ctx);
    } else if (inputTypes.contains(type)) {
      return ComponentRendererInputs.buildInput(node, ctx);
    } else if (basicTypes.contains(type)) {
      return ComponentRendererBasic.buildBasic(node, ctx);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.red[50],
      child: Text('Unsupported Component Type: ${node.type}'),
    );
  }

  static Widget buildEmptyPlaceholder(
    ComponentNode node, {
    void Function(ComponentNode, String, {int? targetIndex, String? slotName})? onAddChild,
  }) {
    final isWrapOrRow = node.type == 'Wrap' || node.type == 'Row';
    return DragTarget<Object>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        if (onAddChild == null) return;
        final data = details.data;
        final meta = ComponentRegistry.getByType(node.type);
        final isSlotBased = meta != null && meta.slotNames.isNotEmpty && meta.slotNames.contains('child');
        if (data is String) {
          onAddChild(node, data, slotName: isSlotBased ? 'child' : null);
        }
        // ComponentNode drop handled by parent's DragTarget
      },
      builder: (context, candidateData, _) {
        final isOver = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: isWrapOrRow ? 150 : double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isOver
                ? const Color(0xFF5B4FCF).withValues(alpha: 0.12)
                : const Color(0xFF5B4FCF).withValues(alpha: 0.04),
            border: Border.all(
              color: isOver
                  ? const Color(0xFF5B4FCF)
                  : const Color(0xFF5B4FCF).withValues(alpha: 0.2),
              style: BorderStyle.solid,
              width: isOver ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_to_photos_rounded,
                color: const Color(0xFF5B4FCF).withValues(alpha: isOver ? 0.9 : 0.5),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                'Empty ${node.type}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5B4FCF).withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Drag components here',
                style: TextStyle(
                  fontSize: 9,
                  color: const Color(0xFF5B4FCF).withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget buildSlotPlaceholder(
    ComponentNode node,
    String slotName,
  ) {
    return Container(
      height: slotName == 'appBar' ? 56 : (slotName == 'bottomNavigationBar' ? 60 : 80),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF5B4FCF).withValues(alpha: 0.04),
        border: Border.all(
          color: const Color(0xFF5B4FCF).withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF5B4FCF)),
            const SizedBox(width: 6),
            Text(
              '${_slotLabel(slotName)} Slot - Drop Widget Here',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5B4FCF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool canAcceptChildren(String type) {
    final meta = ComponentRegistry.getByType(type);
    return meta?.canHaveChildren ?? false;
  }

  static String _slotLabel(String slotName) {
    if (slotName.isEmpty) return slotName;
    return '${slotName[0].toUpperCase()}${slotName.substring(1)}';
  }

  static ComponentNode? _dropDataToNode(Object? data) {
    if (data is ComponentNode) return data;
    if (data is String) {
      // Handle reusable prefix
      final typeName = data.startsWith('reusable_') ? data : data;
      final meta = ComponentRegistry.getByType(typeName);
      if (meta == null && !data.startsWith('reusable_')) return null;
      return ComponentNode(
        id: '__drag_preview_$data',
        type: data.startsWith('reusable_') ? 'Container' : data,
        properties: const {},
        children: const [],
        actions: const [],
      );
    }
    return null;
  }

  static IconData getIconByName(String name) {
    switch (name.toLowerCase()) {
      case 'spa':
        return Icons.spa;
      case 'child_care':
        return Icons.child_care;
      case 'children':
        return Icons.child_care;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'accessibility':
        return Icons.accessibility;
      case 'sentiment_satisfied':
        return Icons.sentiment_satisfied;
      case 'medical_services':
        return Icons.medical_services;
      case 'psychology':
        return Icons.psychology;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'healing':
        return Icons.healing;
      case 'medication':
        return Icons.medication;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'monitor_heart':
        return Icons.monitor_heart;
      case 'biotech':
        return Icons.biotech;
      case 'science':
        return Icons.science;
      case 'add':
        return Icons.add;
      case 'add_circle':
        return Icons.add_circle_outline;
      case 'star':
        return Icons.star;
      case 'star_outline':
        return Icons.star_outline;
      case 'info':
        return Icons.info_outline;
      case 'home':
        return Icons.home_outlined;
      case 'home_filled':
        return Icons.home;
      case 'settings':
        return Icons.settings;
      case 'settings_outline':
        return Icons.settings_outlined;
      case 'person':
        return Icons.person_outline;
      case 'person_filled':
        return Icons.person;
      case 'email':
        return Icons.mail_outline;
      case 'phone':
        return Icons.phone_android;
      case 'lock':
        return Icons.lock_outline;
      case 'lock_open':
        return Icons.lock_open_outlined;
      case 'check':
        return Icons.check;
      case 'check_circle':
        return Icons.check_circle_outline;
      case 'close':
        return Icons.close;
      case 'arrow_forward':
        return Icons.arrow_forward;
      case 'arrow_back':
        return Icons.arrow_back;
      case 'arrow_drop_down':
        return Icons.arrow_drop_down;
      case 'arrow_drop_up':
        return Icons.arrow_drop_up;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'local_pizza':
        return Icons.local_pizza;
      case 'restaurant':
        return Icons.restaurant;
      case 'set_meal':
        return Icons.set_meal;
      case 'cake':
        return Icons.cake;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'eco':
        return Icons.eco;
      case 'fastfood':
        return Icons.fastfood;
      case 'local_bar':
        return Icons.local_bar;
      case 'local_dining':
        return Icons.local_dining;
      case 'local_drink':
        return Icons.local_drink;
      case 'lunch_dining':
        return Icons.lunch_dining;
      case 'dinner_dining':
        return Icons.dinner_dining;
      case 'breakfast_dining':
        return Icons.breakfast_dining;
      case 'icecream':
        return Icons.icecream;
      case 'sports':
        return Icons.sports;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'sports_basketball':
        return Icons.sports_basketball;
      case 'sports_tennis':
        return Icons.sports_tennis;
      case 'pool':
        return Icons.pool;
      case 'directions_run':
        return Icons.directions_run;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'directions_car':
        return Icons.directions_car;
      case 'flight':
        return Icons.flight;
      case 'hotel':
        return Icons.hotel;
      case 'beach_access':
        return Icons.beach_access;
      case 'nature':
        return Icons.nature;
      case 'park':
        return Icons.park;
      case 'chat':
        return Icons.chat_outlined;
      case 'chat_filled':
        return Icons.chat;
      case 'forum':
        return Icons.forum_outlined;
      case 'message':
        return Icons.message_outlined;
      case 'mail':
        return Icons.mail_outlined;
      case 'contact_mail':
        return Icons.contact_mail_outlined;
      case 'contact_phone':
        return Icons.contact_phone_outlined;
      case 'call':
        return Icons.call;
      case 'video_call':
        return Icons.video_call;
      case 'sms':
        return Icons.sms_outlined;
      case 'mark_chat_read':
        return Icons.mark_chat_read_outlined;
      case 'laptop':
        return Icons.laptop;
      case 'checkroom':
        return Icons.checkroom;
      case 'smartphone':
        return Icons.smartphone;
      case 'kitchen':
        return Icons.kitchen;
      case 'microwave':
        return Icons.microwave;
      case 'bolt':
        return Icons.bolt;
      case 'search':
        return Icons.search;
      case 'menu':
        return Icons.menu;
      case 'favorite':
        return Icons.favorite;
      case 'favorite_outline':
        return Icons.favorite_border;
      case 'notifications':
        return Icons.notifications;
      case 'notifications_outline':
        return Icons.notifications_none;
      case 'edit':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      case 'share':
        return Icons.share_outlined;
      case 'camera':
        return Icons.camera_alt_outlined;
      case 'image':
        return Icons.image_outlined;
      case 'filter':
        return Icons.filter_list;
      case 'sort':
        return Icons.sort;
      case 'dashboard':
        return Icons.dashboard_outlined;
      case 'chart':
        return Icons.bar_chart;
      case 'pie_chart':
        return Icons.pie_chart_outline;
      case 'logout':
        return Icons.logout;
      case 'login':
        return Icons.login;
      case 'account':
        return Icons.account_circle_outlined;
      case 'calendar':
        return Icons.calendar_today;
      case 'location':
        return Icons.location_on_outlined;
      case 'payment':
        return Icons.payment;
      case 'credit_card':
        return Icons.credit_card;
      case 'download':
        return Icons.download_outlined;
      case 'upload':
        return Icons.upload_outlined;
      case 'refresh':
        return Icons.refresh;
      case 'more_horiz':
        return Icons.more_horiz;
      case 'more_vert':
        return Icons.more_vert;
      case 'visibility':
        return Icons.visibility_outlined;
      case 'visibility_off':
        return Icons.visibility_off_outlined;
      case 'send':
        return Icons.send;
      case 'attach':
        return Icons.attach_file;
      case 'copy':
        return Icons.copy_outlined;
      case 'paste':
        return Icons.paste_outlined;
      case 'done':
        return Icons.done;
      case 'done_all':
        return Icons.done_all;
      case 'help':
        return Icons.help_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'error':
        return Icons.error_outline;
      case 'wifi':
        return Icons.wifi;
      case 'bluetooth':
        return Icons.bluetooth;
      case 'battery':
        return Icons.battery_full;
      case 'speed':
        return Icons.speed;
      case 'tune':
        return Icons.tune;
      case 'cloud':
        return Icons.cloud_outlined;
      case 'cloud_download':
        return Icons.cloud_download_outlined;
      case 'cloud_upload':
        return Icons.cloud_upload_outlined;
      case 'security':
        return Icons.security;
      case 'verified':
        return Icons.verified;
      case 'new_releases':
        return Icons.new_releases;
      case 'trending_up':
        return Icons.trending_up;
      case 'trending_down':
        return Icons.trending_down;
      case 'swap_horiz':
        return Icons.swap_horiz;
      case 'swap_vert':
        return Icons.swap_vert;
      case 'compare_arrows':
        return Icons.compare_arrows;
      case 'remove_shopping_cart':
        return Icons.remove_shopping_cart;
      case 'storefront':
        return Icons.storefront;
      case 'store':
        return Icons.store;
      case 'delivery_dining':
        return Icons.delivery_dining;
      case 'two_wheeler':
        return Icons.two_wheeler;
      case 'electric_bike':
        return Icons.electric_bike;
      case 'directions_bike':
        return Icons.directions_bike;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'inventory':
        return Icons.inventory_2_outlined;
      case 'manage_accounts':
        return Icons.manage_accounts;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'payments':
        return Icons.payments_outlined;
      case 'money':
        return Icons.money;
      case 'percent':
        return Icons.percent;
      case 'discount':
        return Icons.discount_outlined;
      case 'thumb_up':
        return Icons.thumb_up_outlined;
      case 'thumb_down':
        return Icons.thumb_down_outlined;
      case 'bookmark':
        return Icons.bookmark_border;
      case 'bookmark_filled':
        return Icons.bookmark;
      case 'history':
        return Icons.history;
      case 'repeat':
        return Icons.repeat;
      case 'close_fullscreen':
        return Icons.close_fullscreen;
      case 'fullscreen':
        return Icons.fullscreen;
      case 'open_in_new':
        return Icons.open_in_new;
      case 'link':
        return Icons.link;
      case 'qr_code':
        return Icons.qr_code_2;
      case 'barcode':
        return Icons.barcode_reader;
      default:
        return Icons.category_outlined;
    }
  }

  static Widget applyPaddingAndSizing(Widget widget, ComponentNode node) {
    const selfSizedTypes = {
      'Container', 'Card', 'Scaffold', 'SizedBox',
      'TextField', 'Dropdown', 'DatePicker', 'Search', 'FilePicker',
      'Expanded', 'Flexible', 'Spacer',
    };
    if (selfSizedTypes.contains(node.type)) return widget;

    Widget result = widget;

    final width = double.tryParse(
      node.styles['width']?.toString() ??
          node.properties['width']?.toString() ??
          '',
    );
    final height = double.tryParse(
      node.styles['height']?.toString() ??
          node.properties['height']?.toString() ??
          '',
    );

    final safeWidth = (width != null && width.isFinite && width > 0)
        ? width
        : null;
    final safeHeight = (height != null && height.isFinite && height > 0)
        ? height
        : null;

    if (safeWidth != null || safeHeight != null) {
      result = SizedBox(width: safeWidth, height: safeHeight, child: result);
    }

    final pad = PropertyParser.parsePadding(
      node.styles['padding'] ?? node.properties['padding'],
    );
    if (pad != EdgeInsets.zero) {
      result = Padding(padding: pad, child: result);
    }

    return result;
  }

  static Widget applyDecoration(Widget widget, ComponentNode node) {
    if (node.type == 'Scaffold' ||
        node.type == 'Container' ||
        node.type == 'Card' ||
        node.type == 'SizedBox') {
      return widget;
    }

    final bg = PropertyParser.parseColor(
      node.styles['backgroundColor'] ?? node.properties['backgroundColor'],
    );
    final radius = double.tryParse(
      node.styles['borderRadius']?.toString() ??
          node.properties['borderRadius']?.toString() ??
          '',
    );

    if (bg != null || radius != null) {
      return Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius != null ? BorderRadius.circular(radius) : null,
        ),
        child: widget,
      );
    }

    return widget;
  }

  static Widget applyMargin(Widget widget, ComponentNode node) {
    if (node.type == 'Container' ||
        node.type == 'Card' ||
        node.type == 'Scaffold') {
      return widget;
    }

    final marg = PropertyParser.parsePadding(
      node.styles['margin'] ?? node.properties['margin'],
    );
    if (marg != EdgeInsets.zero) {
      return Padding(padding: marg, child: widget);
    }

    final isFormElement =
        node.type == 'TextField' ||
        node.type == 'Dropdown' ||
        node.type == 'Radio' ||
        node.type == 'Checkbox' ||
        node.type == 'DatePicker' ||
        node.type == 'Switch' ||
        node.type == 'Slider' ||
        node.type == 'FilePicker' ||
        node.type == 'OTP' ||
        node.type == 'Search' ||
        node.type == 'Button';
    if (isFormElement) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: widget,
      );
    }

    return widget;
  }
}

class RevoCarouselWidget extends StatefulWidget {
  final List<Widget> children;
  final double height;
  final double viewportFraction;
  final bool autoPlay;

  const RevoCarouselWidget({
    super.key,
    required this.children,
    this.height = 180,
    this.viewportFraction = 0.9,
    this.autoPlay = true,
  });

  @override
  State<RevoCarouselWidget> createState() => _RevoCarouselWidgetState();
}

class _RevoCarouselWidgetState extends State<RevoCarouselWidget> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: widget.viewportFraction,
    );
    if (widget.autoPlay && widget.children.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!mounted) return;
        final nextPage = (_currentPage + 1) % widget.children.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.children.length,
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: widget.children[index],
          );
        },
      ),
    );
  }
}

enum _DropLinePosition { top, bottom }

class _DropLineIndicator extends StatelessWidget {
  final _DropLinePosition position;
  const _DropLineIndicator({required this.position});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: position == _DropLinePosition.top ? 0 : null,
            bottom: position == _DropLinePosition.bottom ? 0 : null,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF5B4FCF),
                borderRadius: BorderRadius.circular(2),
                boxShadow: const [
                  BoxShadow(color: Color(0x3F5B4FCF), blurRadius: 4, spreadRadius: 1),
                ],
              ),
            ),
          ),
          Positioned(
            top: position == _DropLinePosition.top ? -3 : null,
            bottom: position == _DropLinePosition.bottom ? -3 : null,
            left: -4,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF5B4FCF),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SlotDragTarget extends ConsumerWidget {
  final ComponentNode parentNode;
  final String slotName;
  final Widget child;

  const SlotDragTarget({
    required this.parentNode,
    required this.slotName,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDesignMode = ref.watch(builderDesignModeProvider);
    if (!isDesignMode) return child;

    final controller = ref.read(visualBuilderProvider.notifier);

    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        final droppedNode = ComponentRenderer._dropDataToNode(data);
        if (droppedNode == null) return false;
        return NestingValidator.validateDrop(parentNode, droppedNode, slotName).success;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data is String) {
          controller.addChildNode(parentNode.id, data, slotName: slotName);
        } else if (data is ComponentNode) {
          controller.moveChildNode(parentNode, data, -1, slotName: slotName);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isOver = candidateData.isNotEmpty;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (isOver)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0x225B4FCF),
                    border: Border.all(color: const Color(0xFF5B4FCF), width: 2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
