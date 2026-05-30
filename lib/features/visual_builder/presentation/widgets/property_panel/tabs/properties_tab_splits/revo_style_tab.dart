import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/component_engine/models/component_node.dart';
import 'package:revojourneytryone/core/component_engine/registry/component_registry.dart';
import 'package:revojourneytryone/features/visual_builder/application/visual_builder_controller.dart';
import 'shared_property_helpers.dart';

class RevoStyleTab extends ConsumerWidget {
  final ComponentNode node;
  final VisualBuilderController controller;

  const RevoStyleTab({
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
        if (shouldShowStyleProperty('backgroundColor', node, meta))
          buildColorFieldWithPresets(
            context: context,
            label: "Background Color (Hex)",
            value: getStyleValue('backgroundColor', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'backgroundColor': val}),
          ),
        if (shouldShowStyleProperty('gradientStart', node, meta))
          buildColorFieldWithPresets(
            context: context,
            label: "Gradient Start Color (Hex)",
            value: getStyleValue('gradientStart', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'gradientStart': val}),
          ),
        if (shouldShowStyleProperty('gradientEnd', node, meta))
          buildColorFieldWithPresets(
            context: context,
            label: "Gradient End Color (Hex)",
            value: getStyleValue('gradientEnd', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'gradientEnd': val}),
          ),
        if (shouldShowStyleProperty('borderColor', node, meta))
          buildColorFieldWithPresets(
            context: context,
            label: "Border Color (Hex)",
            value: getStyleValue('borderColor', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'borderColor': val}),
          ),
        if (shouldShowStyleProperty('borderWidth', node, meta))
          buildPropertyTextField(
            label: "Border Width (px)",
            value: getStyleValue('borderWidth', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'borderWidth': double.tryParse(val)}),
          ),
        if (shouldShowStyleProperty('color', node, meta))
          buildColorFieldWithPresets(
            context: context,
            label: "Theme Color (Hex)",
            value: getStyleValue('color', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'color': val}),
          ),
        if (shouldShowStyleProperty('textColor', node, meta))
          buildColorFieldWithPresets(
            context: context,
            label: "Text Color (Hex)",
            value: getStyleValue('textColor', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'textColor': val}),
          ),
        if (shouldShowStyleProperty('fontSize', node, meta))
          buildPropertyTextField(
            label: "Font Size (pt)",
            value: getStyleValue('fontSize', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'fontSize': double.tryParse(val)}),
          ),
        if (shouldShowStyleProperty('fontWeight', node, meta))
          buildPropertyDropdown(
            label: "Font Weight",
            value: getStyleValue('fontWeight', node, meta, fallback: 'normal')?.toString() ?? 'normal',
            options: const ['normal', 'bold', 'w100', 'w300', 'w500', 'w700'],
            onChanged: (val) => controller.updateNodeProperties(node.id, {'fontWeight': val}),
          ),
        if (shouldShowStyleProperty('padding', node, meta))
          buildPropertyTextField(
            label: "Padding (All)",
            value: getStyleValue('padding', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'padding': double.tryParse(val)}),
          ),
        if (shouldShowStyleProperty('margin', node, meta))
          buildPropertyTextField(
            label: "Margin (All)",
            value: getStyleValue('margin', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'margin': double.tryParse(val)}),
          ),
        if (shouldShowStyleProperty('borderRadius', node, meta))
          buildPropertyTextField(
            label: "Border Radius (px)",
            value: getStyleValue('borderRadius', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'borderRadius': double.tryParse(val)}),
          ),
        if (shouldShowStyleProperty('width', node, meta))
          buildPropertyTextField(
            label: "Width (px)",
            value: getStyleValue('width', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'width': double.tryParse(val)}),
          ),
        if (shouldShowStyleProperty('height', node, meta))
          buildPropertyTextField(
            label: "Height (px)",
            value: getStyleValue('height', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'height': double.tryParse(val)}),
          ),
        if (shouldShowStyleProperty('elevation', node, meta))
          buildPropertyTextField(
            label: "Elevation (Shadow)",
            value: getStyleValue('elevation', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'elevation': double.tryParse(val)}),
          ),
      ],
    );
  }
}
