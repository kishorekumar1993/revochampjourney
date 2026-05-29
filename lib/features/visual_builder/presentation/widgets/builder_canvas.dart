import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/component_engine/renderer/component_renderer.dart';
import '../../../../core/component_engine/models/component_node.dart';
import '../../application/visual_builder_controller.dart';

class RevoBuilderCanvas extends ConsumerWidget {
  const RevoBuilderCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builderState = ref.watch(visualBuilderProvider);
    final controller = ref.read(visualBuilderProvider.notifier);

    final scale = builderState.canvasScale;

    return Expanded(
      child: Container(
        color: RevoTheme.background,
        child: Column(
          children: [
            // Canvas Toolbar
            _buildCanvasToolbar(context, ref, builderState, controller),

            // Canvas Workspace
            Expanded(
              child: InteractiveViewer(
                minScale: 0.2,
                maxScale: 3.0,
                boundaryMargin: const EdgeInsets.all(500),
                child: Center(
                  child: Transform.scale(
                    scale: scale,
                    child: _buildDeviceMockup(context, ref, builderState, controller),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasToolbar(
    BuildContext context,
    WidgetRef ref,
    VisualBuilderState state,
    VisualBuilderController controller,
  ) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(bottom: BorderSide(color: RevoTheme.cardBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Device Presets
          Row(
            children: [
              _buildToolbarIconButton(
                icon: Icons.phone_android_rounded,
                tooltip: "Phone (Pixel 7 Pro)",
                isSelected: state.canvasWidth == 412,
                onPressed: () => controller.setCanvasSize(412, 915),
              ),
              _buildToolbarIconButton(
                icon: Icons.tablet_rounded,
                tooltip: "Tablet (iPad Pro)",
                isSelected: state.canvasWidth == 1024,
                onPressed: () => controller.setCanvasSize(1024, 1366),
              ),
              _buildToolbarIconButton(
                icon: Icons.laptop_chromebook_rounded,
                tooltip: "Desktop (Web App)",
                isSelected: state.canvasWidth == 1440,
                onPressed: () => controller.setCanvasSize(1440, 900),
              ),
              const SizedBox(width: 12),
              Text(
                "${state.canvasWidth.toInt()} x ${state.canvasHeight.toInt()}",
                style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),

          // Zoom & Scale
          Row(
            children: [
              _buildToolbarIconButton(
                icon: Icons.zoom_out_rounded,
                tooltip: "Zoom Out",
                onPressed: () => controller.setCanvasScale((state.canvasScale - 0.1).clamp(0.3, 2.0)),
              ),
              Text(
                "${(state.canvasScale * 100).toInt()}%",
                style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
              _buildToolbarIconButton(
                icon: Icons.zoom_in_rounded,
                tooltip: "Zoom In",
                onPressed: () => controller.setCanvasScale((state.canvasScale + 0.1).clamp(0.3, 2.0)),
              ),
              const SizedBox(width: 8),
              _buildToolbarIconButton(
                icon: Icons.restart_alt_rounded,
                tooltip: "Reset Zoom",
                onPressed: () => controller.setCanvasScale(1.0),
              ),
            ],
          ),

          // Modes (Design / Preview) and Undo / Redo
          Row(
            children: [
              // Undo/Redo
              _buildToolbarIconButton(
                icon: Icons.undo_rounded,
                tooltip: "Undo",
                onPressed: state.past.isEmpty ? null : () => controller.undo(),
              ),
              _buildToolbarIconButton(
                icon: Icons.redo_rounded,
                tooltip: "Redo",
                onPressed: state.future.isEmpty ? null : () => controller.redo(),
              ),
              const SizedBox(width: 16),

              // Design/Preview Switch
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: RevoTheme.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: RevoTheme.cardBorder),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    _buildModeButton(
                      label: "Design",
                      isSelected: state.isDesignMode,
                      onPressed: () {
                        if (!state.isDesignMode) controller.toggleDesignMode();
                      },
                    ),
                    _buildModeButton(
                      label: "Preview",
                      isSelected: !state.isDesignMode,
                      onPressed: () {
                        if (state.isDesignMode) controller.toggleDesignMode();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarIconButton({
    required IconData icon,
    required String tooltip,
    bool isSelected = false,
    VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: isSelected
            ? const Color(0xFF5B4FCF)
            : onPressed == null
                ? RevoTheme.textSecondary.withValues(alpha:0.3)
                : RevoTheme.textSecondary,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        splashRadius: 16,
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF5B4FCF) : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : RevoTheme.textSecondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildDeviceMockup(
    BuildContext context,
    WidgetRef ref,
    VisualBuilderState state,
    VisualBuilderController controller,
  ) {
    final rootNode = state.rootNode;
    final isSelected = state.selectedNode?.id == rootNode.id;

    Widget canvasContent = Container(
      color: Colors.white,
      width: state.canvasWidth,
      height: state.canvasHeight,
      child: Stack(
        children: [
          // Simulated Status bar for mobile designs
          if (state.canvasWidth < 600)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "9:30",
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.wifi, size: 14, color: Colors.black),
                        SizedBox(width: 4),
                        Icon(Icons.signal_cellular_4_bar, size: 14, color: Colors.black),
                        SizedBox(width: 4),
                        Icon(Icons.battery_full, size: 14, color: Colors.black),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Main screen scrolling body
          Positioned.fill(
            top: state.canvasWidth < 600 ? 32 : 0,
            bottom: state.canvasWidth < 600 ? 24 : 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ComponentRenderer.render(
                    rootNode,
                    isDesignMode: state.isDesignMode,
                    selectedNode: state.selectedNode,
                    hoveredNode: state.hoveredNode,
                    onSelect: controller.selectNode,
                    onHover: controller.hoverNode,
                    onDelete: (node) => controller.deleteNode(node.id),
                    onDuplicate: (node) => controller.duplicateNode(node.id),
                    onMoveChild: controller.moveChildNode,
                    onAddChild: (parent, type) => controller.addChildNode(parent.id, type),
                  ),
                ],
              ),
            ),
          ),

          // Simulated home indicator for mobile designs
          if (state.canvasWidth < 600)
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 140,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha:0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // If design mode, root node (column/layout) itself is a drop target!
    if (state.isDesignMode) {
      canvasContent = DragTarget<Object>(
        onWillAcceptWithDetails: (details) => true,
        onAcceptWithDetails: (details) {
          final data = details.data;
          if (data is String) {
            controller.addChildNode(rootNode.id, data);
          } else if (data is ComponentNode) {
            controller.moveChildNode(rootNode, data, rootNode.children.length);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isOver = candidateData.isNotEmpty;
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isOver
                    ? const Color(0xFF5B4FCF)
                    : isSelected
                        ? const Color(0xFF5B4FCF)
                        : Colors.transparent,
                width: 2.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                )
              ],
            ),
            child: canvasContent,
          );
        },
      );
    }

    // Outer device frame wrapper
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        borderRadius: BorderRadius.circular(state.canvasWidth < 600 ? 36 : 8),
        border: Border.all(color: const Color(0xFF1E1E2F), width: state.canvasWidth < 600 ? 12 : 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(state.canvasWidth < 600 ? 24 : 6),
        child: canvasContent,
      ),
    );
  }
}
