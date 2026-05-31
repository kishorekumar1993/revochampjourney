import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/component_engine/models/component_node.dart';
import 'package:revojourneytryone/features/visual_builder/application/visual_builder_controller.dart';
import 'shared_property_helpers.dart';

class RevoResponsiveTab extends ConsumerWidget {
  final ComponentNode node;
  final VisualBuilderController controller;

  const RevoResponsiveTab({
    super.key,
    required this.node,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = node.responsive;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Responsive View Visibility", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        buildPropertySwitch(
          label: "Visible on Mobile 📱",
          value: responsive['visibleOnMobile'] != false,
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(responsive)..['visibleOnMobile'] = val;
            controller.updateNodeProperties(node.id, {'responsive': upd});
          },
        ),
        buildPropertySwitch(
          label: "Visible on Tablet 📟",
          value: responsive['visibleOnTablet'] != false,
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(responsive)..['visibleOnTablet'] = val;
            controller.updateNodeProperties(node.id, {'responsive': upd});
          },
        ),
        buildPropertySwitch(
          label: "Visible on Desktop 💻",
          value: responsive['visibleOnDesktop'] != false,
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(responsive)..['visibleOnDesktop'] = val;
            controller.updateNodeProperties(node.id, {'responsive': upd});
          },
        ),
      ],
    );
  }
}

