import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/component_engine/models/component_node.dart';
import '../../../../core/component_engine/registry/component_registry.dart';
import '../../../../core/component_engine/validation/nesting_validator.dart';
import '../../application/visual_builder_controller.dart';
import '../../application/studio_providers.dart';

class RevoComponentTree extends ConsumerStatefulWidget {
  const RevoComponentTree({super.key});

  @override
  ConsumerState<RevoComponentTree> createState() => _RevoComponentTreeState();
}

class _RevoComponentTreeState extends ConsumerState<RevoComponentTree> {
  final Set<String> _collapsedNodes = {};
  String? _draggingNodeId;
  String _searchQuery = '';

  bool _doesNodeMatchSearch(ComponentNode node, String query) {
    if (query.isEmpty) return true;
    final typeMatch = node.type.toLowerCase().contains(query.toLowerCase());
    final labelMatch = node.properties['label']?.toString().toLowerCase().contains(query.toLowerCase()) ?? false;
    final fieldMatch = node.properties['fieldName']?.toString().toLowerCase().contains(query.toLowerCase()) ?? false;
    if (typeMatch || labelMatch || fieldMatch) return true;

    for (final child in node.children) {
      if (_doesNodeMatchSearch(child, query)) return true;
    }
    for (final slotChild in node.slots.values) {
      if (slotChild != null && _doesNodeMatchSearch(slotChild, query)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final rootNode = ref.watch(builderRootNodeProvider);
    final selectedNode = ref.watch(builderSelectedNodeProvider);
    final controller = ref.read(visualBuilderProvider.notifier);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(left: BorderSide(color: RevoTheme.cardBorder)),
      ),
      child: Column(
        children: [
          // Tree Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Widget Tree Explorer",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: RevoTheme.textPrimary,
                      ),
                    ),
                    Icon(Icons.account_tree_outlined, color: RevoTheme.textSecondary, size: 16),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search widgets...",
                    hintStyle: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
                    prefixIcon: Icon(Icons.search_rounded, size: 14, color: RevoTheme.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    filled: true,
                    fillColor: RevoTheme.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: RevoTheme.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: RevoTheme.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFF5B4FCF)),
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Tree
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _buildTreeNodes(rootNode, 0, selectedNode, controller, null, rootNode),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTreeNodes(
    ComponentNode node,
    int depth,
    ComponentNode? selectedNode,
    VisualBuilderController controller,
    ComponentNode? parentNode,
    ComponentNode treeRoot,
  ) {
    if (_searchQuery.isNotEmpty && !_doesNodeMatchSearch(node, _searchQuery)) {
      return [];
    }

    final List<Widget> list = [];
    final isSelected = selectedNode?.id == node.id;
    final isCollapsed = _searchQuery.isNotEmpty
        ? false
        : _collapsedNodes.contains(node.id);
    final meta = ComponentRegistry.getByType(node.type);
    final hasChildren = node.children.isNotEmpty || (meta != null && meta.slotNames.isNotEmpty);

    // Resolve name
    String labelSuffix = '';
    if (node.properties.containsKey('fieldName')) {
      labelSuffix = ' [${node.properties['fieldName']}]';
    } else if (node.properties.containsKey('label')) {
      labelSuffix = ' [${node.properties['label']}]';
    }

    final icon = meta?.icon ?? Icons.help_outline;
    final warnings = NestingValidator.validateNode(node);

    // Drag-and-drop feedback or drop target
    final dragTargetWidget = DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        final draggedId = details.data;
        final draggedNode = controller.findNodeById(draggedId);
        if (draggedNode == null) return false;
        return NestingValidator.validateDrop(node, draggedNode, null, root: treeRoot).success;
      },
      onAcceptWithDetails: (details) {
        final draggedId = details.data;
        final draggedNode = controller.findNodeById(draggedId);
        if (draggedNode != null) {
          controller.moveChildNode(node, draggedNode, node.children.length);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isOver = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isOver ? 32 : 0,
          margin: EdgeInsets.only(left: 12.0 + (depth * 16.0)),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: const Color(0x1F5B4FCF),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF5B4FCF), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.subdirectory_arrow_right_rounded, size: 14, color: Color(0xFF5B4FCF)),
                const SizedBox(width: 6),
                Text(
                  "Move into ${node.type}",
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5B4FCF), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );

    final nodeItemWidget = Draggable<String>(
      data: node.id,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF5B4FCF),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                node.type,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildNodeRow(node, depth, isSelected, isCollapsed, hasChildren, icon, labelSuffix, controller, warnings),
      ),
      onDragStarted: () {
        ref.read(canvasIsDraggingProvider.notifier).state = true;
        setState(() {
          _draggingNodeId = node.id;
        });
      },
      onDragEnd: (details) {
        ref.read(canvasIsDraggingProvider.notifier).state = false;
        setState(() {
          _draggingNodeId = null;
        });
      },
      child: _buildNodeRow(node, depth, isSelected, isCollapsed, hasChildren, icon, labelSuffix, controller, warnings),
    );

    // If dragging another node, show drop indicators between nodes
    if (_draggingNodeId != null && _draggingNodeId != node.id && parentNode != null) {
      final indexInParent = parentNode.children.indexOf(node);
      list.add(
        DragTarget<String>(
          onWillAcceptWithDetails: (details) {
            return details.data != _draggingNodeId;
          },
          onAcceptWithDetails: (details) {
            final draggedId = details.data;
            final draggedNode = controller.findNodeById(draggedId);
            if (draggedNode != null) {
              controller.moveChildNode(parentNode, draggedNode, indexInParent);
            }
          },
          builder: (context, candidateData, rejectedData) {
            final isOver = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isOver ? 16 : 4,
              margin: EdgeInsets.only(left: 12.0 + (depth * 16.0), right: 12.0),
              decoration: BoxDecoration(
                color: isOver ? const Color(0xFF5B4FCF) : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),
      );
    }

    list.add(nodeItemWidget);
    list.add(dragTargetWidget);

    if (hasChildren && !isCollapsed) {
      if (meta != null && meta.slotNames.isNotEmpty) {
        for (final slotName in meta.slotNames) {
          final slotChild = node.slots[slotName];
          final slotHeaderWidget = Padding(
            key: ValueKey('${node.id}_slot_hdr_$slotName'),
            padding: EdgeInsets.only(left: 12.0 + ((depth + 1) * 16.0), right: 12.0, top: 2, bottom: 2),
            child: DragTarget<String>(
              onWillAcceptWithDetails: (details) {
                final draggedId = details.data;
                final draggedNode = controller.findNodeById(draggedId);
                if (draggedNode == null) return false;
                return NestingValidator.validateDrop(node, draggedNode, slotName, root: treeRoot).success;
              },
              onAcceptWithDetails: (details) {
                final draggedId = details.data;
                final draggedNode = controller.findNodeById(draggedId);
                if (draggedNode != null) {
                  controller.moveChildNode(node, draggedNode, -1, slotName: slotName);
                }
              },
              builder: (context, candidateData, rejectedData) {
                final isOver = candidateData.isNotEmpty;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOver ? const Color(0x335B4FCF) : const Color(0x0A5B4FCF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isOver ? const Color(0xFF5B4FCF) : const Color(0x205B4FCF),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        slotName == 'appBar'
                            ? Icons.web_asset_rounded
                            : (slotName == 'body'
                                ? Icons.article_outlined
                                : (slotName == 'bottomNavigationBar'
                                    ? Icons.menu_rounded
                                    : Icons.widgets_outlined)),
                        size: 14,
                        color: RevoTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '[$slotName]',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: RevoTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (slotChild == null)
                        Text(
                          'Drop Widget Here',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: RevoTheme.textSecondary.withValues(alpha: 0.7),
                          ),
                        )
                      else
                        const Icon(Icons.check_circle_rounded, size: 10, color: Colors.green),
                    ],
                  ),
                );
              },
            ),
          );
          list.add(slotHeaderWidget);

          if (slotChild != null) {
            list.addAll(_buildTreeNodes(slotChild, depth + 2, selectedNode, controller, node, treeRoot));
          }
        }
      }

      for (final child in node.children) {
        list.addAll(_buildTreeNodes(child, depth + 1, selectedNode, controller, node, treeRoot));
      }
      if (_draggingNodeId != null) {
        final isChildDragged = node.children.any((c) => c.id == _draggingNodeId);
        if (!isChildDragged && node.id != _draggingNodeId && !_isDescendant(_draggingNodeId!, node)) {
          list.add(
            DragTarget<String>(
              onWillAcceptWithDetails: (details) {
                if (details.data == _draggingNodeId) return false;
                final draggedNode = controller.findNodeById(details.data);
                if (draggedNode == null) return false;
                return NestingValidator.validateDrop(node, draggedNode, null, root: treeRoot).success;
              },
              onAcceptWithDetails: (details) {
                final draggedId = details.data;
                final draggedNode = controller.findNodeById(draggedId);
                if (draggedNode != null) {
                  controller.moveChildNode(node, draggedNode, node.children.length);
                }
              },
              builder: (context, candidateData, rejectedData) {
                final isOver = candidateData.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: isOver ? 24 : 6,
                  margin: EdgeInsets.only(left: 12.0 + ((depth + 1) * 16.0), right: 12.0),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: isOver ? const Color(0x1F5B4FCF) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: isOver ? Border.all(color: const Color(0xFF5B4FCF)) : null,
                  ),
                  child: isOver
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            "Add to end of ${node.type}",
                            style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF5B4FCF), fontWeight: FontWeight.bold),
                          ),
                        )
                      : null,
                );
              },
            ),
          );
        }
      }
    }

    return list;
  }

  bool _isDescendant(String ancestorId, ComponentNode targetNode) {
    if (targetNode.children.isEmpty && targetNode.slots.isEmpty) return false;
    for (final child in targetNode.children) {
      if (child.id == ancestorId) return true;
      if (_isDescendant(ancestorId, child)) return true;
    }
    for (final slotChild in targetNode.slots.values) {
      if (slotChild != null) {
        if (slotChild.id == ancestorId) return true;
        if (_isDescendant(ancestorId, slotChild)) return true;
      }
    }
    return false;
  }

  Widget _buildNodeRow(
    ComponentNode node,
    int depth,
    bool isSelected,
    bool isCollapsed,
    bool hasChildren,
    IconData icon,
    String labelSuffix,
    VisualBuilderController controller,
    List<String> warnings,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => controller.selectNode(node),
        hoverColor: const Color(0x0C5B4FCF),
        child: Container(
          color: isSelected ? const Color(0x1F5B4FCF) : Colors.transparent,
          padding: EdgeInsets.only(
            left: 12.0 + (depth * 16.0),
            right: 12.0,
            top: 6.0,
            bottom: 6.0,
          ),
          child: Row(
            children: [
              // Expand / Collapse arrow
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isCollapsed) {
                      _collapsedNodes.remove(node.id);
                    } else {
                      _collapsedNodes.add(node.id);
                    }
                  });
                },
                child: Opacity(
                  opacity: hasChildren ? 1.0 : 0.0,
                  child: Icon(
                    isCollapsed ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_down,
                    size: 16,
                    color: RevoTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Drag Handle
              Icon(Icons.drag_indicator_rounded, size: 14, color: RevoTheme.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(width: 4),

              // Icon type
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.textSecondary,
              ),
              const SizedBox(width: 8),

              // Label
              Expanded(
                child: Row(
                  children: [
                    Text(
                      node.type,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.textPrimary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        labelSuffix,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: RevoTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Quick operations
              if (warnings.isNotEmpty) ...[
                Tooltip(
                  message: warnings.join('\n'),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 14),
                ),
                const SizedBox(width: 8),
              ],
              if (isSelected) ...[
                GestureDetector(
                  onTap: () => controller.duplicateNode(node.id),
                  child: Tooltip(
                    message: "Duplicate",
                    child: Icon(Icons.copy_rounded, color: RevoTheme.textSecondary, size: 12),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => controller.deleteNode(node.id),
                  child: Tooltip(
                    message: "Delete",
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
