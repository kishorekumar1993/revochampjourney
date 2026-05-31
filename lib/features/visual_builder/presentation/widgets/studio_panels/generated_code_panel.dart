import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/component_engine/models/component_node.dart';
import '../../../../../../core/component_engine/registry/component_registry.dart';

import '../../../application/visual_builder_controller.dart';
import 'studio_panel_wrapper.dart';

class RevoGeneratedCodePanel extends ConsumerWidget {
  const RevoGeneratedCodePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeStepId = ref.watch(visualBuilderProvider.select((s) => s.activeStepId));
    final rootNode = ref.watch(builderRootNodeProvider);

    String generateUI() {
      if (activeStepId.isEmpty) return '// Select a screen step to generate code.';
      final buffer = StringBuffer();
      buffer.writeln("import 'package:flutter/material.dart';");
      buffer.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';\n");
      buffer.writeln("class ${activeStepId[0].toUpperCase()}${activeStepId.substring(1)}Screen extends ConsumerWidget {");
      buffer.writeln("  const ${activeStepId[0].toUpperCase()}${activeStepId.substring(1)}Screen({super.key});\n");
      buffer.writeln("  @override");
      buffer.writeln("  Widget build(BuildContext context, WidgetRef ref) {");
      buffer.writeln("    return Scaffold(");
      buffer.writeln("      appBar: AppBar(title: const Text('${activeStepId.toUpperCase()} SCREEN')),");
      buffer.writeln("      body: SingleChildScrollView(");
      buffer.writeln("        child: Padding(");
      buffer.writeln("          padding: const EdgeInsets.all(16.0),");
      buffer.writeln("          child: Column(");
      buffer.writeln("            children: [");
      _dumpNodeCode(rootNode, buffer, "              ");
      buffer.writeln("            ],");
      buffer.writeln("          ),");
      buffer.writeln("        ),");
      buffer.writeln("      ),");
      buffer.writeln("    );");
      buffer.writeln("  }");
      buffer.writeln("}");
      return buffer.toString();
    }

    return RevoStudioPanelWrapper(
      title: "Generated UI Code",
      subtitle: "Real-time Clean Architecture Flutter code",
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: SelectableText(
                  generateUI(),
                  style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.greenAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _dumpNodeCode(ComponentNode node, StringBuffer buffer, String indent) {
    buffer.writeln("$indent// Widget: ${node.type} (${node.id})");
    buffer.writeln("$indent${node.type}(");
    node.properties.forEach((key, val) {
      if (val != null && val is! List && val is! Map) {
        final valStr = val is String ? "'${val.replaceAll("'", "\\'")}'" : val;
        buffer.writeln("$indent  $key: $valStr,");
      }
    });
    final meta = ComponentRegistry.getByType(node.type);
    if (meta != null && meta.slotNames.isNotEmpty) {
      for (final slotName in meta.slotNames) {
        final slotChild = node.slots[slotName];
        if (slotChild == null) continue;
        buffer.writeln("$indent  $slotName: ");
        _dumpNodeCode(slotChild, buffer, "$indent    ");
      }
    } else if (node.children.isNotEmpty) {
      buffer.writeln("$indent  children: [");
      for (final child in node.children) {
        _dumpNodeCode(child, buffer, "$indent    ");
      }
      buffer.writeln("$indent  ],");
    }
    buffer.writeln("$indent),");
  }
}
