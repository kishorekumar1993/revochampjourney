import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme.dart';
import '../../../application/visual_builder_controller.dart';

import 'studio_panel_wrapper.dart';

// 6. Action Flow sidebar panel listing node actions
class RevoActionFlowPanel extends ConsumerWidget {
  const RevoActionFlowPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedNode = ref.watch(builderSelectedNodeProvider);

    return RevoStudioPanelWrapper(
      title: "Action Flow Editor",
      subtitle: "Visual workflow actions for components",
      child: selectedNode == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "Select a component on the canvas to configure its actions flow.",
                  style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  "Event Triggers",
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // Triggers visual action editor on bottom sheet
                  },
                  icon: const Icon(Icons.alt_route_rounded, color: Colors.white),
                  label: const Text("Open Action Workflow Canvas", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
    );
  }
}

