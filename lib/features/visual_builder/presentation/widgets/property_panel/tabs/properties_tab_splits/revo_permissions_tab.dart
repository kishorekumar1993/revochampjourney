import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/component_engine/models/component_node.dart';
import 'package:revojourneytryone/features/visual_builder/application/visual_builder_controller.dart';
import 'shared_property_helpers.dart';

class RevoPermissionsTab extends ConsumerWidget {
  final ComponentNode node;
  final VisualBuilderController controller;

  const RevoPermissionsTab({
    super.key,
    required this.node,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final props = node.properties;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Permissions & Roles", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        buildPropertyDropdown(
          label: "Minimum Access Role",
          value: props['role'] ?? 'guest',
          options: const ['guest', 'user', 'admin'],
          onChanged: (val) => controller.updateNodeProperties(node.id, {'role': val}),
        ),
      ],
    );
  }
}
