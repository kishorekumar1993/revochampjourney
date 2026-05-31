import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme.dart';
import '../../../application/visual_builder_controller.dart';
import 'studio_panel_wrapper.dart';

class RevoResponsivePanel extends ConsumerStatefulWidget {
  const RevoResponsivePanel({super.key});

  @override
  ConsumerState<RevoResponsivePanel> createState() => _RevoResponsivePanelState();
}

class _RevoResponsivePanelState extends ConsumerState<RevoResponsivePanel> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    final builderState = ref.read(visualBuilderProvider);
    _widthController = TextEditingController(text: builderState.canvasWidth.toInt().toString());
    _heightController = TextEditingController(text: builderState.canvasHeight.toInt().toString());
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _onWidthSubmitted(String val, double currentHeight) {
    final width = double.tryParse(val) ?? 1440.0;
    final clampedWidth = width.clamp(320.0, 3840.0);
    ref.read(visualBuilderProvider.notifier).setCanvasSize(clampedWidth, currentHeight);
    _widthController.text = clampedWidth.toInt().toString();
  }

  void _onHeightSubmitted(String val, double currentWidth) {
    final height = double.tryParse(val) ?? 900.0;
    final clampedHeight = height.clamp(320.0, 2160.0);
    ref.read(visualBuilderProvider.notifier).setCanvasSize(currentWidth, clampedHeight);
    _heightController.text = clampedHeight.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final builderState = ref.watch(visualBuilderProvider);
    final controller = ref.read(visualBuilderProvider.notifier);

    // Watcher to keep inputs in sync with toolbar or external changes
    ref.listen<VisualBuilderState>(visualBuilderProvider, (prev, next) {
      if (prev?.canvasWidth != next.canvasWidth) {
        _widthController.text = next.canvasWidth.toInt().toString();
      }
      if (prev?.canvasHeight != next.canvasHeight) {
        _heightController.text = next.canvasHeight.toInt().toString();
      }
    });

    final phonePresets = [
      {'name': 'iPhone 14', 'width': 390.0, 'height': 844.0, 'icon': Icons.phone_iphone_rounded},
      {'name': 'Pixel 7 Pro', 'width': 412.0, 'height': 915.0, 'icon': Icons.phone_android_rounded},
      {'name': 'iPhone SE', 'width': 320.0, 'height': 568.0, 'icon': Icons.phone_iphone_rounded},
    ];

    final tabletPresets = [
      {'name': 'iPad Pro 11"', 'width': 834.0, 'height': 1194.0, 'icon': Icons.tablet_mac_rounded},
      {'name': 'iPad Pro 12.9"', 'width': 1024.0, 'height': 1366.0, 'icon': Icons.tablet_rounded},
    ];

    final desktopPresets = [
      {'name': 'MacBook Air', 'width': 1280.0, 'height': 800.0, 'icon': Icons.laptop_mac_rounded},
      {'name': 'Desktop (Web)', 'width': 1440.0, 'height': 900.0, 'icon': Icons.desktop_windows_rounded},
      {'name': 'Ultra Wide (4K)', 'width': 1920.0, 'height': 1080.0, 'icon': Icons.tv_rounded},
    ];

    final cssBreakpoints = [
      {'label': 'SM', 'desc': 'Mobile', 'width': 640.0, 'height': 800.0},
      {'label': 'MD', 'desc': 'Tablet', 'width': 768.0, 'height': 1024.0},
      {'label': 'LG', 'desc': 'Laptop', 'width': 1024.0, 'height': 768.0},
      {'label': 'XL', 'desc': 'Desktop', 'width': 1280.0, 'height': 800.0},
      {'label': '2XL', 'desc': 'Ultra', 'width': 1536.0, 'height': 900.0},
    ];

    final isLandscape = builderState.canvasWidth > builderState.canvasHeight;

    return RevoStudioPanelWrapper(
      title: "Responsive Studio",
      subtitle: "Configure preview viewport and breakpoints",
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section 1: Custom Dimensions & Orientation
          _sectionHeader("CANVAS DIMENSIONS"),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _dimensionInput(
                  label: "Width",
                  controller: _widthController,
                  onSubmitted: (val) => _onWidthSubmitted(val, builderState.canvasHeight),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dimensionInput(
                  label: "Height",
                  controller: _heightController,
                  onSubmitted: (val) => _onHeightSubmitted(val, builderState.canvasWidth),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.toggleOrientation(),
                  icon: Icon(isLandscape ? Icons.screen_lock_portrait_rounded : Icons.screen_lock_landscape_rounded, size: 14),
                  label: Text(isLandscape ? "Landscape" : "Portrait", style: const TextStyle(fontSize: 10)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B4FCF).withValues(alpha: 0.1),
                    foregroundColor: const Color(0xFF5B4FCF),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => controller.resetCanvas(),
                  icon: const Icon(Icons.restart_alt_rounded, size: 14),
                  label: const Text("Reset View", style: TextStyle(fontSize: 10)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: RevoTheme.cardBorder),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Sliders for quick resize
          _sectionHeader("CUSTOM RESIZING"),
          const SizedBox(height: 8),
          _customSlider(
            label: "Width Resizer",
            value: builderState.canvasWidth,
            min: 320.0,
            max: 2000.0,
            onChanged: (val) {
              controller.setCanvasSize(val.roundToDouble(), builderState.canvasHeight);
            },
          ),
          _customSlider(
            label: "Height Resizer",
            value: builderState.canvasHeight,
            min: 320.0,
            max: 1600.0,
            onChanged: (val) {
              controller.setCanvasSize(builderState.canvasWidth, val.roundToDouble());
            },
          ),

          const SizedBox(height: 16),
          // Section 2: CSS Breakpoints
          _sectionHeader("STANDARD CSS BREAKPOINTS"),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: cssBreakpoints.map((bp) {
              final isBpActive = builderState.canvasWidth == bp['width'];
              return ChoiceChip(
                label: Text("${bp['label']} (${bp['width']?.toString() ?? '0'}px)", style: GoogleFonts.inter(fontSize: 10)),
                selected: isBpActive,
                onSelected: (selected) {
                  if (selected) {
                    controller.setCanvasSize(bp['width'] as double, bp['height'] as double);
                  }
                },
                selectedColor: const Color(0xFF5B4FCF).withValues(alpha: 0.15),
                checkmarkColor: const Color(0xFF5B4FCF),
                labelStyle: TextStyle(
                  color: isBpActive ? const Color(0xFF5B4FCF) : RevoTheme.textPrimary,
                  fontWeight: isBpActive ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: RevoTheme.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: isBpActive ? const Color(0xFF5B4FCF) : RevoTheme.cardBorder),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          // Section 3: Zoom / Scaling
          _sectionHeader("CANVAS ZOOM SCALING"),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [50, 75, 100, 150, 200].map((zoom) {
              final double scale = zoom / 100.0;
              final isSelected = (builderState.canvasScale - scale).abs() < 0.05;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: OutlinedButton(
                    onPressed: () => controller.setCanvasScale(scale),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: isSelected ? const Color(0xFF5B4FCF) : Colors.transparent,
                      foregroundColor: isSelected ? Colors.white : RevoTheme.textSecondary,
                      side: BorderSide(color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text("$zoom%", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          // Section 4: Device Presets List
          _sectionHeader("PHONES PRESETS"),
          ...phonePresets.map((dev) => _deviceTile(dev, builderState, controller)),

          const SizedBox(height: 12),
          _sectionHeader("TABLETS PRESETS"),
          ...tabletPresets.map((dev) => _deviceTile(dev, builderState, controller)),

          const SizedBox(height: 12),
          _sectionHeader("DESKTOPS PRESETS"),
          ...desktopPresets.map((dev) => _deviceTile(dev, builderState, controller)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: RevoTheme.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _dimensionInput({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 32,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: onSubmitted,
            style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textPrimary),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              filled: true,
              fillColor: RevoTheme.cardBg,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: RevoTheme.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: RevoTheme.primaryLight),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _customSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 9, color: RevoTheme.textSecondary)),
              Text("${value.toInt()} px", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: RevoTheme.primaryLight)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: RevoTheme.primaryLight,
              inactiveTrackColor: RevoTheme.cardBorder,
              thumbColor: RevoTheme.primary,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceTile(
    Map<String, dynamic> dev,
    VisualBuilderState state,
    VisualBuilderController controller,
  ) {
    final double devWidth = dev['width'] as double;
    final double devHeight = dev['height'] as double;
    final isSelected = state.canvasWidth == devWidth && state.canvasHeight == devHeight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Material(
        color: isSelected ? const Color(0x155B4FCF) : RevoTheme.cardBg.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            controller.setCanvasSize(devWidth, devHeight);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.cardBorder.withValues(alpha: 0.5),
                width: isSelected ? 1.2 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  dev['icon'] as IconData,
                  size: 14,
                  color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dev['name'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "${devWidth.toInt()} x ${devHeight.toInt()} px",
                        style: GoogleFonts.inter(fontSize: 8.5, color: RevoTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 12,
                    color: Color(0xFF5B4FCF),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
