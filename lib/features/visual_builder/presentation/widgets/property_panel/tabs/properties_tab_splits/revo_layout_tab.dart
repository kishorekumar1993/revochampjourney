import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/component_engine/models/component_node.dart';
import 'package:revojourneytryone/core/component_engine/registry/component_registry.dart';
import 'package:revojourneytryone/features/visual_builder/application/visual_builder_controller.dart';
import 'shared_property_helpers.dart';

class RevoLayoutTab extends ConsumerWidget {
  final ComponentNode node;
  final VisualBuilderController controller;

  const RevoLayoutTab({
    super.key,
    required this.node,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = ComponentRegistry.getByType(node.type);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (shouldShowLayoutProperty('mainAxisAlignment', node, meta))
          buildPropertyDropdown(
            label: "Main Axis Alignment",
            value: getStyleValue('mainAxisAlignment', node, meta, fallback: 'start')?.toString() ?? 'start',
            options: const ['start', 'center', 'end', 'space_between', 'space_around', 'space_evenly'],
            onChanged: (val) => controller.updateNodeProperties(node.id, {'mainAxisAlignment': val}),
          ),
        if (shouldShowLayoutProperty('crossAxisAlignment', node, meta))
          buildPropertyDropdown(
            label: "Cross Axis Alignment",
            value: getStyleValue('crossAxisAlignment', node, meta, fallback: 'center')?.toString() ?? 'center',
            options: const ['start', 'center', 'end', 'stretch'],
            onChanged: (val) => controller.updateNodeProperties(node.id, {'crossAxisAlignment': val}),
          ),
        if (shouldShowLayoutProperty('spacing', node, meta))
          buildPropertyTextField(
            label: "Spacing (Gap)",
            value: getStyleValue('spacing', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'spacing': double.tryParse(val)}),
          ),
      ],
    );
  }
}
