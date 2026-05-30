import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/component_engine/models/component_node.dart';
import 'package:revojourneytryone/features/visual_builder/application/visual_builder_controller.dart';
import 'package:revojourneytryone/features/visual_builder/application/studio_providers.dart';
import 'shared_property_helpers.dart';

class RevoDataBindingTab extends ConsumerWidget {
  final ComponentNode node;
  final VisualBuilderController controller;

  const RevoDataBindingTab({
    super.key,
    required this.node,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bindings = node.bindings;
    final variables = ref.watch(appVariablesProvider);
    final varNames = variables.map((v) => v.name).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Variable & API Bindings", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        buildPropertyDropdown(
          label: "Bind to State Variable",
          value: bindings['variable'] ?? 'None',
          options: ['None', ...varNames],
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(bindings)..['variable'] = val;
            controller.updateNodeProperties(node.id, {'bindings': upd});
          },
        ),
        buildPropertyTextField(
          label: "Bind Response API Path",
          value: bindings['apiPath'] ?? '',
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(bindings)..['apiPath'] = val;
            controller.updateNodeProperties(node.id, {'bindings': upd});
          },
        ),
      ],
    );
  }
}
