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
    final stylesList = meta?.stylesList ?? [];

    if (stylesList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "This component does not have any schema-defined styling properties.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: stylesList.map((key) => buildDynamicStyleField(context, key, node, controller)).toList(),
    );
  }
}
