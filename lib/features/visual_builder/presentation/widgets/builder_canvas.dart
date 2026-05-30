import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/component_engine/renderer/component_renderer.dart';
import '../../../../core/component_engine/models/component_node.dart';
import '../../application/visual_builder_controller.dart';

/// The main canvas widget — uses granular providers so different zones only
/// rebuild when their specific slice of state changes.
class RevoBuilderCanvas extends ConsumerWidget {
  const RevoBuilderCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: RevoTheme.background,
      child: Column(
        children: [
          // Toolbar — only rebuilds when scale/size/history/mode changes.
          const _CanvasToolbar(),

          // Canvas workspace — rebuilds on tree, selection, hover, or mode changes.
          const Expanded(child: _CanvasWorkspace()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar — watches only size, scale, history, and mode.
// ─────────────────────────────────────────────────────────────────────────────
class _CanvasToolbar extends ConsumerWidget {
  const _CanvasToolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasSize = ref.watch(builderCanvasSizeProvider);
    final history = ref.watch(builderHistoryProvider);
    final isDesignMode = ref.watch(builderDesignModeProvider);
    final controller = ref.read(visualBuilderProvider.notifier);

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
              _ToolbarIconButton(
                icon: Icons.phone_android_rounded,
                tooltip: 'Phone (Pixel 7 Pro)',
                isSelected: canvasSize.width == 412,
                onPressed: () => controller.setCanvasSize(412, 915),
              ),
              _ToolbarIconButton(
                icon: Icons.tablet_rounded,
                tooltip: 'Tablet (iPad Pro)',
                isSelected: canvasSize.width == 1024,
                onPressed: () => controller.setCanvasSize(1024, 1366),
              ),
              _ToolbarIconButton(
                icon: Icons.laptop_chromebook_rounded,
                tooltip: 'Desktop (Web App)',
                isSelected: canvasSize.width == 1440,
                onPressed: () => controller.setCanvasSize(1440, 900),
              ),
              const SizedBox(width: 12),
              Text(
                '${canvasSize.width.toInt()} x ${canvasSize.height.toInt()}',
                style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),

          // Zoom & Scale
          Row(
            children: [
              _ToolbarIconButton(
                icon: Icons.zoom_out_rounded,
                tooltip: 'Zoom Out',
                onPressed: () => controller.setCanvasScale((canvasSize.scale - 0.1).clamp(0.3, 2.0)),
              ),
              Text(
                '${(canvasSize.scale * 100).toInt()}%',
                style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
              _ToolbarIconButton(
                icon: Icons.zoom_in_rounded,
                tooltip: 'Zoom In',
                onPressed: () => controller.setCanvasScale((canvasSize.scale + 0.1).clamp(0.3, 2.0)),
              ),
              const SizedBox(width: 8),
              _ToolbarIconButton(
                icon: Icons.restart_alt_rounded,
                tooltip: 'Reset Zoom',
                onPressed: () => controller.setCanvasScale(1.0),
              ),
            ],
          ),

          // Undo / Redo + Mode toggle
          Row(
            children: [
              _ToolbarIconButton(
                icon: Icons.undo_rounded,
                tooltip: 'Undo',
                onPressed: history.canUndo ? () => controller.undo() : null,
              ),
              _ToolbarIconButton(
                icon: Icons.redo_rounded,
                tooltip: 'Redo',
                onPressed: history.canRedo ? () => controller.redo() : null,
              ),
              const SizedBox(width: 16),
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
                    _ModeButton(
                      label: 'Design',
                      isSelected: isDesignMode,
                      onPressed: () { if (!isDesignMode) controller.toggleDesignMode(); },
                    ),
                    _ModeButton(
                      label: 'Preview',
                      isSelected: !isDesignMode,
                      onPressed: () { if (isDesignMode) controller.toggleDesignMode(); },
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Canvas Workspace — watches rootNode, mode, size.
// ─────────────────────────────────────────────────────────────────────────────
class _CanvasWorkspace extends ConsumerWidget {
  const _CanvasWorkspace();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasSize = ref.watch(builderCanvasSizeProvider);
    final rootNode = ref.watch(builderRootNodeProvider);
    final isDesignMode = ref.watch(builderDesignModeProvider);
    final controller = ref.read(visualBuilderProvider.notifier);

    return InteractiveViewer(
      minScale: 0.2,
      maxScale: 3.0,
      boundaryMargin: const EdgeInsets.all(500),
      child: Center(
        child: Transform.scale(
          scale: canvasSize.scale,
          child: _DeviceMockup(
            rootNode: rootNode,
            isDesignMode: isDesignMode,
            canvasWidth: canvasSize.width,
            canvasHeight: canvasSize.height,
            controller: controller,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Device Mockup Frame
// ─────────────────────────────────────────────────────────────────────────────
class _DeviceMockup extends ConsumerWidget {
  final ComponentNode rootNode;
  final bool isDesignMode;
  final double canvasWidth;
  final double canvasHeight;
  final VisualBuilderController controller;

  const _DeviceMockup({
    required this.rootNode,
    required this.isDesignMode,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = canvasWidth < 600;
    final isScaffold = rootNode.type == 'Scaffold';
    final isSelected = ref.watch(visualBuilderProvider.select((s) => s.selectedNode?.id == rootNode.id));

    // Build the rendered content.
    Widget renderedContent = ComponentRenderer.render(
      rootNode,
      isDesignMode: isDesignMode,
      onSelect: controller.selectNode,
      onHover: controller.hoverNode,
      onDelete: (node) => controller.deleteNode(node.id),
      onDuplicate: (node) => controller.duplicateNode(node.id),
      onMoveChild: controller.moveChildNode,
      onAddChild: (parent, type, {targetIndex}) => controller.addChildNode(parent.id, type, targetIndex: targetIndex),
    );

    // Only wrap non-Scaffold roots in a scroll view with padding.
    Widget bodyContent;
    if (isScaffold) {
      // Scaffold fills the whole frame — no extra padding.
      bodyContent = renderedContent;
    } else {
      bodyContent = SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [renderedContent],
        ),
      );
    }

    Widget canvasContent = Container(
      color: Colors.white,
      width: canvasWidth,
      height: canvasHeight,
      child: Stack(
        children: [
          // Simulated status bar for mobile designs.
          if (isMobile)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('9:30', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                    const Row(
                      children: [
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

          // Main content area.
          Positioned.fill(
            top: isMobile ? 32 : 0,
            bottom: isMobile ? 20 : 0,
            child: bodyContent,
          ),

          // Simulated home indicator bar for mobile.
          if (isMobile)
            Positioned(
              bottom: 4, left: 0, right: 0,
              child: Center(
                child: Container(
                  width: 140,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // If design mode, make the root canvas itself a drop target.
    if (isDesignMode) {
      final innerContent = canvasContent;
      canvasContent = DragTarget<Object>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) {
          final data = details.data;
          if (data is String) {
            controller.addChildNode(rootNode.id, data);
          } else if (data is ComponentNode) {
            controller.moveChildNode(rootNode, data, rootNode.children.length);
          }
        },
        builder: (context, candidateData, _) {
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
                BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 12)),
              ],
            ),
            child: innerContent,
          );
        },
      );
    }

    // Outer device frame wrapper.
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        borderRadius: BorderRadius.circular(isMobile ? 36 : 8),
        border: Border.all(color: const Color(0xFF1E1E2F), width: isMobile ? 12 : 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 24 : 6),
        child: canvasContent,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable toolbar widgets
// ─────────────────────────────────────────────────────────────────────────────
class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback? onPressed;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    this.isSelected = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: isSelected
            ? const Color(0xFF5B4FCF)
            : onPressed == null
                ? RevoTheme.textSecondary.withValues(alpha: 0.3)
                : RevoTheme.textSecondary,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        splashRadius: 16,
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ModeButton({required this.label, required this.isSelected, required this.onPressed});

  @override
  Widget build(BuildContext context) {
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
}
