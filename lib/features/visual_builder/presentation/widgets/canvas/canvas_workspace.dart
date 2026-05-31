import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme.dart';
import '../../../application/visual_builder_controller.dart';
import 'canvas_mockup.dart';

class CanvasWorkspace extends ConsumerStatefulWidget {
  const CanvasWorkspace({super.key});

  @override
  ConsumerState<CanvasWorkspace> createState() => _CanvasWorkspaceState();
}

class _CanvasWorkspaceState extends ConsumerState<CanvasWorkspace> {
  late TransformationController _transformationController;
  bool _isInitialized = false;
  bool? _wasDesignMode;
  double? _lastMaxWidth;
  double? _lastMaxHeight;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Widget _buildViewportTag(String breakpointLabel, double width, double height, bool isLandscape, {required bool isDesignMode}) {
    final bgColor = isDesignMode
        ? RevoTheme.cardBg
        : const Color(0xFF1E293B).withValues(alpha: 0.85);
    final borderColor = isDesignMode
        ? RevoTheme.primary.withValues(alpha: 0.4)
        : const Color(0x33A78BFA);
    final textColor = isDesignMode
        ? RevoTheme.textPrimary
        : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
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
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canvasSize = ref.watch(builderCanvasSizeProvider);
    final rootNode = ref.watch(builderRootNodeProvider);
    final isDesignMode = ref.watch(builderDesignModeProvider);
    final controller = ref.read(visualBuilderProvider.notifier);

    // Track design/preview mode toggles to reset the controller initialization
    if (_wasDesignMode != isDesignMode) {
      _isInitialized = false;
      _lastMaxWidth = null;
      _lastMaxHeight = null;
      _wasDesignMode = isDesignMode;
    }

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

    // Design Mode View
    if (isDesignMode) {
      final designCanvas = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewportTag(breakpointLabel, canvasSize.width, canvasSize.height, isLandscape, isDesignMode: true),
          DeviceMockup(
            rootNode: rootNode,
            isDesignMode: true,
            canvasWidth: canvasSize.width,
            canvasHeight: canvasSize.height,
            controller: controller,
          ),
        ],
      );

      return Container(
        color: const Color(0xFFF1F5F9),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
            child: designCanvas,
          ),
        ),
      );
    }

    // Preview Mode View: Multi-device frames rendered side-by-side
    final previewCanvas = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Mobile Preview
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildViewportTag("Mobile Preview • SM", 390, 844, false, isDesignMode: false),
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
            _buildViewportTag("Tablet Preview • MD", 834, 1194, false, isDesignMode: false),
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
            _buildViewportTag("Desktop Preview • XL", 1440, 900, true, isDesignMode: false),
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

    // Multi-device bounding box dimensions (including device borders & headers)
    const double contentWidth = 2820.0;
    const double contentHeight = 1300.0;
    const double paddingVal = 80.0;

    const double totalWidth = contentWidth + (paddingVal * 2);
    const double totalHeight = contentHeight + (paddingVal * 2);

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Color(0xFF1E293B), // Slate 800
            Color(0xFF0B0F19), // Deep Slate 950
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!_isInitialized || _lastMaxWidth != constraints.maxWidth || _lastMaxHeight != constraints.maxHeight) {
            _lastMaxWidth = constraints.maxWidth;
            _lastMaxHeight = constraints.maxHeight;

            final double viewportWidth = constraints.maxWidth;
            final double viewportHeight = constraints.maxHeight;

            // Fit the layout with some margins
            final double scaleX = (viewportWidth * 0.95) / totalWidth;
            final double scaleY = (viewportHeight * 0.95) / totalHeight;
            double initialScale = scaleX < scaleY ? scaleX : scaleY;
            initialScale = initialScale.clamp(0.05, 1.2);

            // Calculate centering translation
            final double childScaledWidth = totalWidth * initialScale;
            final double childScaledHeight = totalHeight * initialScale;

            final double translateX = (viewportWidth - childScaledWidth) / 2;
            final double translateY = (viewportHeight - childScaledHeight) / 2;

            _transformationController.value = Matrix4.identity()
              ..translate(translateX, translateY)
              ..scale(initialScale);
            _isInitialized = true;
          }

          return InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.02,
            maxScale: 3.0,
            boundaryMargin: const EdgeInsets.all(800),
            constrained: false,
            panEnabled: true,
            scaleEnabled: true,
            child: Container(
              width: totalWidth,
              height: totalHeight,
              color: Colors.transparent,
              child: Stack(
                children: [
                  // Faint grid background that scales and pans with devices
                  const Positioned.fill(
                    child: CustomPaint(
                      painter: GridPainter(),
                    ),
                  ),
                  Positioned(
                    left: paddingVal,
                    top: paddingVal,
                    width: contentWidth,
                    height: contentHeight,
                    child: previewCanvas,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  const GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x07FFFFFF) // faint greyish grid lines
      ..strokeWidth = 1.0;

    const double step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
