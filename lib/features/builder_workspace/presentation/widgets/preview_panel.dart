import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/component_engine/renderer/component_renderer.dart';
import '../../../visual_builder/application/visual_builder_controller.dart';

class RevoPreviewPanel extends ConsumerStatefulWidget {
  const RevoPreviewPanel({super.key});

  @override
  ConsumerState<RevoPreviewPanel> createState() => _RevoPreviewPanelState();
}

class _RevoPreviewPanelState extends ConsumerState<RevoPreviewPanel> {
  final Map<String, dynamic> _formValues = {};
  String _deviceMode = 'mobile'; // 'mobile', 'tablet', 'desktop'

  @override
  Widget build(BuildContext context) {
    final builderState = ref.watch(visualBuilderProvider);
    final rootNode = builderState.rootNode;
    final controller = ref.read(visualBuilderProvider.notifier);
    final isFullPage = rootNode.type == 'Scaffold' || rootNode.type == 'Container';

    // Resolve mockup frame sizes
    double deviceW;
    double deviceH;
    double borderRadius;
    double borderWidth;

    switch (_deviceMode) {
      case 'tablet':
        deviceW = 768.0;
        deviceH = 1024.0;
        borderRadius = 24.0;
        borderWidth = 12.0;
        break;
      case 'desktop':
        deviceW = 1280.0;
        deviceH = 800.0;
        borderRadius = 12.0;
        borderWidth = 8.0;
        break;
      case 'mobile':
      default:
        deviceW = 390.0;
        deviceH = 844.0;
        borderRadius = 36.0;
        borderWidth = 12.0;
        break;
    }

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Row(
        children: [
          // Left Side: Live Preview Device Workspace
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Device Toolbar Selector
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: RevoTheme.sidebarBackground,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _deviceSelectorTab(
                        label: "Mobile 📱",
                        mode: 'mobile',
                        controller: controller,
                        deviceW: deviceW,
                        deviceH: deviceH,
                      ),
                      const SizedBox(width: 12),
                      _deviceSelectorTab(
                        label: "Tablet 📟",
                        mode: 'tablet',
                        controller: controller,
                        deviceW: deviceW,
                        deviceH: deviceH,
                      ),
                      const SizedBox(width: 12),
                      _deviceSelectorTab(
                        label: "Desktop 💻",
                        mode: 'desktop',
                        controller: controller,
                        deviceW: deviceW,
                        deviceH: deviceH,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Frame Viewport Canvas
                Expanded(
                  child: Container(
                    color: RevoTheme.background,
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableH = constraints.maxHeight;
                        final availableW = constraints.maxWidth;
                        final scale = (availableH / deviceH).clamp(0.2, 1.0).clamp(0.0, availableW / deviceW);

                        return Center(
                          child: Transform.scale(
                            scale: scale,
                            child: Container(
                              width: deviceW,
                              height: deviceH,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(borderRadius),
                                border: Border.all(color: const Color(0xFF1E1E2F), width: borderWidth),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 24,
                                    offset: Offset(0, 12),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(borderRadius - 4),
                                child: Stack(
                                  children: [
                                    // Base Screen Background
                                    const Positioned.fill(child: ColoredBox(color: Colors.white)),

                                    // Device OS Header Mockups
                                    if (_deviceMode == 'desktop')
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 36,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          color: const Color(0xFFF1F1F5),
                                          child: Row(
                                            children: [
                                              // Close/Min/Max browser dots
                                              const Icon(Icons.circle, size: 8, color: Colors.redAccent),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.circle, size: 8, color: Colors.amberAccent),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                                              const SizedBox(width: 12),
                                              // Simulated Browser Address Bar
                                              Expanded(
                                                child: Container(
                                                  height: 22,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  alignment: Alignment.centerLeft,
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  child: Text(
                                                    "https://revochamp.dev/preview",
                                                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600]),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
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

                                    // Main Render Frame Viewport (MediaQuery Overridden so ComponentRenderer responds layout-wise)
                                    Positioned.fill(
                                      top: _deviceMode == 'desktop' ? 36 : 32,
                                      bottom: _deviceMode == 'desktop' ? 0 : 24,
                                      child: MediaQuery(
                                        data: MediaQuery.of(context).copyWith(size: Size(deviceW, deviceH)),
                                        child: isFullPage
                                            ? ComponentRenderer.render(
                                                rootNode,
                                                isDesignMode: false,
                                                formValues: _formValues,
                                                onFormValueChanged: (field, val) {
                                                  setState(() {
                                                    _formValues[field] = val;
                                                  });
                                                },
                                                overrideWidth: deviceW,
                                              )
                                            : SingleChildScrollView(
                                                padding: const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    ComponentRenderer.render(
                                                      rootNode,
                                                      isDesignMode: false,
                                                      formValues: _formValues,
                                                      onFormValueChanged: (field, val) {
                                                        setState(() {
                                                          _formValues[field] = val;
                                                        });
                                                      },
                                                      overrideWidth: deviceW,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ),

                                    // OS Home Indicators (Mobile & Tablet)
                                    if (_deviceMode != 'desktop')
                                      Positioned(
                                        bottom: 6,
                                        left: 0,
                                        right: 0,
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
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Vertical Divider
          VerticalDivider(color: RevoTheme.cardBorder, width: 1),

          // Right Side: Form Diagnostic Panel
          Container(
            width: 320,
            color: RevoTheme.sidebarBackground,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Interactive Diagnostic",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: RevoTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Interact with fields in the preview mockup. Live form state binding values display below.",
                  style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  "Live Form Values",
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _formValues.isEmpty
                      ? Center(
                          child: Text(
                            "No inputs populated yet.\nType or click in form elements to see them update.",
                            style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          itemCount: _formValues.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final key = _formValues.keys.elementAt(index);
                            final val = _formValues[key];
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: RevoTheme.cardBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: RevoTheme.cardBorder),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      key,
                                      style: GoogleFonts.sourceCodePro(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF5B4FCF)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    val?.toString() ?? 'null',
                                    style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textPrimary),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceSelectorTab({
    required String label,
    required String mode,
    required VisualBuilderController controller,
    required double deviceW,
    required double deviceH,
  }) {
    final isSelected = _deviceMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _deviceMode = mode;
        });
        controller.setCanvasSize(deviceW, deviceH);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B4FCF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.cardBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : RevoTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
