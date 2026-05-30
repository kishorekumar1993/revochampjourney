import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/component_engine/models/component_node.dart';
import 'package:revojourneytryone/features/visual_builder/application/visual_builder_controller.dart';
import 'shared_property_helpers.dart';

class RevoAnimationTab extends ConsumerWidget {
  final ComponentNode node;
  final VisualBuilderController controller;

  const RevoAnimationTab({
    super.key,
    required this.node,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animations = node.animations;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Micro-Animations Setup", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        buildPropertyDropdown(
          label: "Animation Type",
          value: animations['type'] ?? 'none',
          options: const ['none', 'fade', 'slide', 'scale'],
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(animations)..['type'] = val;
            controller.updateNodeProperties(node.id, {'animations': upd});
          },
        ),
        buildPropertyTextField(
          label: "Animation Duration (ms)",
          value: animations['duration']?.toString() ?? '300',
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(animations)..['duration'] = int.tryParse(val) ?? 300;
            controller.updateNodeProperties(node.id, {'animations': upd});
          },
        ),
      ],
    );
  }
}
