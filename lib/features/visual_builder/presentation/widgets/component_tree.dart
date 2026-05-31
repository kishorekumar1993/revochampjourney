import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/component_engine/models/component_node.dart';
import '../../../../core/component_engine/registry/component_registry.dart';
import '../../application/visual_builder_controller.dart';

class RevoComponentTree extends ConsumerStatefulWidget {
  const RevoComponentTree({super.key});

  @override
  ConsumerState<RevoComponentTree> createState() => _RevoComponentTreeState();
}

class _RevoComponentTreeState extends ConsumerState<RevoComponentTree> {
  final Set<String> _collapsedNodes = {};

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Component Tree",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: RevoTheme.textPrimary,
                  ),
                ),
                Icon(Icons.account_tree_outlined, color: RevoTheme.textSecondary, size: 16),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Tree
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _buildTreeNodes(rootNode, 0, selectedNode, controller),
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
  ) {
    final List<Widget> list = [];
    final isSelected = selectedNode?.id == node.id;
    final isCollapsed = _collapsedNodes.contains(node.id);
    final hasChildren = node.children.isNotEmpty;

    // Resolve name
    String labelSuffix = '';
    if (node.properties.containsKey('fieldName')) {
      labelSuffix = ' [${node.properties['fieldName']}]';
    } else if (node.properties.containsKey('label')) {
      labelSuffix = ' [${node.properties['label']}]';
    }

    final meta = ComponentRegistry.getByType(node.type);
    final icon = meta?.icon ?? Icons.help_outline;

    list.add(
      MouseRegion(
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
      ),
    );

    if (hasChildren && !isCollapsed) {
      for (final child in node.children) {
        list.addAll(_buildTreeNodes(child, depth + 1, selectedNode, controller));
      }
    }

    return list;
  }
}
