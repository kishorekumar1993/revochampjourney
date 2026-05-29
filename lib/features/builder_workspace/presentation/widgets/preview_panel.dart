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

  @override
  Widget build(BuildContext context) {
    final builderState = ref.watch(visualBuilderProvider);
    final rootNode = builderState.rootNode;

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Row(
        children: [
          // Left Side: Live Preview Device
          Expanded(
            flex: 3,
            child: Container(
              color: RevoTheme.background,
              child: Center(
                child: Container(
                  width: 412,
                  height: 915,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: const Color(0xFF1E1E2F), width: 12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Status Bar Mockup
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

                        // Rendered Interactive Screen
                        Positioned.fill(
                          top: 32,
                          bottom: 24,
                          child: SingleChildScrollView(
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
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Home Indicator Mockup
                        Positioned(
                          bottom: 6,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 140,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
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
            ),
          ),

          // Vertical divider
          VerticalDivider(color: RevoTheme.cardBorder, width: 1),

          // Right Side: Form State Diagnostic Panel
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
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
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
}
