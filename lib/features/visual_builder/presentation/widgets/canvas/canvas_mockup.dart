import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/component_engine/renderer/component_renderer.dart';
import '../../../../../../core/component_engine/models/component_node.dart';
import '../../../application/visual_builder_controller.dart';

class DeviceMockup extends ConsumerWidget {
  final ComponentNode rootNode;
  final bool isDesignMode;
  final double canvasWidth;
  final double canvasHeight;
  final VisualBuilderController controller;

  const DeviceMockup({
    super.key,
    required this.rootNode,
    required this.isDesignMode,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.controller,
  });

  Widget _buildStatusBar({required bool darkTheme}) {
    final textColor = darkTheme ? Colors.white : Colors.black87;
    final iconColor = darkTheme ? Colors.white.withValues(alpha: 0.7) : Colors.black45;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '9:41',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          Row(
            children: [
              Icon(Icons.wifi, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Icon(Icons.signal_cellular_4_bar, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Icon(Icons.battery_full, size: 14, color: iconColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrowserHeader() {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9), // Light grey macOS-style header
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // macOS style traffic light dots
          Row(
            children: [
              Container(
                width: 11, height: 11,
                decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Container(
                width: 11, height: 11,
                decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Container(
                width: 11, height: 11,
                decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Navigation controls
          const Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: Colors.black38),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.black12),
          const SizedBox(width: 12),
          const Icon(Icons.refresh_rounded, size: 16, color: Colors.black38),
          const SizedBox(width: 16),
          // Address Bar
          Expanded(
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 11, color: Colors.black26),
                  const SizedBox(width: 6),
                  Text(
                    'revochamp.com/crm-dashboard',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.black87,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 60), // offset spacer to center URL
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = canvasWidth < 600;
    final isTablet = canvasWidth >= 600 && canvasWidth < 1024;
    final isDesktop = canvasWidth >= 1024;
    
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
      onAddChild: (parent, type, {targetIndex, slotName}) => controller.addChildNode(parent.id, type, targetIndex: targetIndex, slotName: slotName),
    );

    // Only wrap non-Scaffold roots in a scroll view with padding.
    Widget bodyContent;
    if (isScaffold) {
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
          // Simulated status bar for mobile and tablet designs.
          if (isMobile || isTablet)
            Positioned(
              top: 0, left: 0, right: 0,
              child: _buildStatusBar(darkTheme: false),
            ),

          // Main content area.
          Positioned.fill(
            top: (isMobile || isTablet) ? 28 : 0,
            bottom: isMobile ? 20 : (isTablet ? 12 : 0),
            child: bodyContent,
          ),

          // Simulated home indicator bar.
          if (isMobile || isTablet)
            Positioned(
              bottom: 4, left: 0, right: 0,
              child: Center(
                child: Container(
                  width: isMobile ? 120 : 160,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
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

    // Outer device frame wrapper based on device type.
    Widget framedWidget;

    if (isDesktop) {
      framedWidget = Container(
        width: canvasWidth + 4,
        height: canvasHeight + 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            children: [
              _buildBrowserHeader(),
              Expanded(child: canvasContent),
            ],
          ),
        ),
      );
    } else if (isTablet) {
      framedWidget = Container(
        width: canvasWidth + 32,
        height: canvasHeight + 32,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24), // Sleek iPad bezel
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF0F0F12), width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                canvasContent,
                // Top bezel front camera dot
                Positioned(
                  top: 6,
                  left: 0, right: 0,
                  child: Center(
                    child: Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // isMobile
      framedWidget = Container(
        width: canvasWidth + 24,
        height: canvasHeight + 24,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24), // Sleek iPhone bezel
          borderRadius: BorderRadius.circular(48),
          border: Border.all(color: const Color(0xFF0F0F12), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 35,
              spreadRadius: 2,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: Stack(
              children: [
                canvasContent,
                // Dynamic Island pill
                Positioned(
                  top: 5,
                  left: 0, right: 0,
                  child: Center(
                    child: Container(
                      width: 90, height: 18,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isDesignMode) {
      return DragTarget<Object>(
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
              borderRadius: BorderRadius.circular(isDesktop ? 14 : (isTablet ? 34 : 50)),
            ),
            child: framedWidget,
          );
        },
      );
    }

    return framedWidget;
  }
}
