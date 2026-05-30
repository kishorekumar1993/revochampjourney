import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/theme.dart';
import '../../../application/visual_builder_controller.dart';
import 'studio_panel_wrapper.dart';

// 8. Responsive configuration panel
class RevoResponsivePanel extends ConsumerWidget {
  const RevoResponsivePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builderState = ref.watch(visualBuilderProvider);
    final controller = ref.read(visualBuilderProvider.notifier);

    final devices = [
      {'name': 'Mobile (iPhone 14)', 'width': 390.0, 'height': 844.0, 'icon': Icons.phone_iphone_rounded},
      {'name': 'Tablet (iPad Pro 11)', 'width': 834.0, 'height': 1194.0, 'icon': Icons.tablet_mac_rounded},
      {'name': 'Desktop (MacBook Air)', 'width': 1280.0, 'height': 800.0, 'icon': Icons.laptop_chromebook_rounded},
    ];

    return RevoStudioPanelWrapper(
      title: "Responsive Canvas",
      subtitle: "Change canvas preview breakpoints",
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final dev = devices[index];
          final isSelected = builderState.canvasWidth == dev['width'];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Card(
              color: isSelected ? const Color(0x1F5B4FCF) : RevoTheme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.cardBorder,
                ),
              ),
              child: ListTile(
                onTap: () {
                  controller.setCanvasSize(dev['width'] as double, dev['height'] as double);
                },
                leading: Icon(
                  dev['icon'] as IconData,
                  color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.textSecondary,
                ),
                title: Text(
                  dev['name'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  "${dev['width']} x ${dev['height']} px",
                  style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

