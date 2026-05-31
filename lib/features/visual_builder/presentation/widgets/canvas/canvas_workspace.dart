import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme.dart';
import '../../../application/visual_builder_controller.dart';
import 'canvas_mockup.dart';

class CanvasWorkspace extends ConsumerWidget {
  const CanvasWorkspace({super.key});

  Widget _buildViewportTag(String breakpointLabel, double width, double height, bool isLandscape) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RevoTheme.primary.withValues(alpha: 0.4), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            width < 600
                ? Icons.phone_android_rounded
                : (width < 1024 ? Icons.tablet_mac_rounded : Icons.laptop_mac_rounded),
            size: 12,
            color: RevoTheme.primaryLight,
          ),
          const SizedBox(width: 8),
          Text(
            "$breakpointLabel (${width.toInt()} × ${height.toInt()} px) • ${isLandscape ? 'Landscape' : 'Portrait'}",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: RevoTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasSize = ref.watch(builderCanvasSizeProvider);
    final rootNode = ref.watch(builderRootNodeProvider);
    final isDesignMode = ref.watch(builderDesignModeProvider);
    final controller = ref.read(visualBuilderProvider.notifier);

    // Determine breakpoint tag details for Design Mode
    String breakpointLabel;
    if (canvasSize.width < 600) {
      breakpointLabel = "Mobile • SM";
    } else if (canvasSize.width < 1024) {
      breakpointLabel = "Tablet • MD";
    } else if (canvasSize.width < 1440) {
      breakpointLabel = "Laptop • LG";
    } else {
      breakpointLabel = "Desktop • XL";
    }

    final isLandscape = canvasSize.width > canvasSize.height;

    // In preview mode, render Mobile, Tablet, Desktop side-by-side!
    Widget canvasChild;
    if (isDesignMode) {
      canvasChild = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewportTag(breakpointLabel, canvasSize.width, canvasSize.height, isLandscape),
          DeviceMockup(
            rootNode: rootNode,
            isDesignMode: true,
            canvasWidth: canvasSize.width,
            canvasHeight: canvasSize.height,
            controller: controller,
          ),
        ],
      );
    } else {
      // Preview Mode: Multi-device frames rendered side-by-side
      canvasChild = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Mobile Preview
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildViewportTag("Mobile Preview • SM", 390, 844, false),
              DeviceMockup(
                rootNode: rootNode,
                isDesignMode: false,
                canvasWidth: 390,
                canvasHeight: 844,
                controller: controller,
              ),
            ],
          ),
          const SizedBox(width: 48),
          // 2. Tablet Preview
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildViewportTag("Tablet Preview • MD", 834, 1194, false),
              DeviceMockup(
                rootNode: rootNode,
                isDesignMode: false,
                canvasWidth: 834,
                canvasHeight: 1194,
                controller: controller,
              ),
            ],
          ),
          const SizedBox(width: 48),
          // 3. Desktop Preview
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildViewportTag("Desktop Preview • XL", 1440, 900, true),
              DeviceMockup(
                rootNode: rootNode,
                isDesignMode: false,
                canvasWidth: 1440,
                canvasHeight: 900,
                controller: controller,
              ),
            ],
          ),
        ],
      );
    }

    return InteractiveViewer(
      minScale: 0.1, // Zoom out more to see all preview frames
      maxScale: 3.0,
      boundaryMargin: const EdgeInsets.all(2000),
      constrained: false, // Turn off constraint forcing so the canvas lays out unconstrained!
      child: Center(
        child: Transform.scale(
          scale: canvasSize.scale,
          child: Padding(
            padding: const EdgeInsets.all(80.0), // Generous padding so we can pan around comfortably
            child: canvasChild,
          ),
        ),
      ),
    );
  }
}
