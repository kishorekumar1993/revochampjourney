import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/codegenerator/getx/getx_layout_generator.dart';
import '../../../../../../core/component_engine/models/component_node.dart';
import '../../../../../../core/component_engine/registry/component_registry.dart';
import '../../../application/visual_builder_controller.dart';
import 'studio_panel_wrapper.dart';

enum CodeTab {
  getXView,
  getXController,
  jsonStructure,
  legacyUI,
}

class RevoGeneratedCodePanel extends ConsumerStatefulWidget {
  const RevoGeneratedCodePanel({super.key});

  @override
  ConsumerState<RevoGeneratedCodePanel> createState() => _RevoGeneratedCodePanelState();
}

class _RevoGeneratedCodePanelState extends ConsumerState<RevoGeneratedCodePanel> {
  CodeTab _activeTab = CodeTab.getXView;

  @override
  Widget build(BuildContext context) {
    final activeStepId = ref.watch(visualBuilderProvider.select((s) => s.activeStepId));
    final rootNode = ref.watch(builderRootNodeProvider);

    final stepId = activeStepId.isNotEmpty ? activeStepId : 'screen';
    final className = '${stepId[0].toUpperCase()}${stepId.substring(1)}Form';
    final fileName = '${stepId.toLowerCase()}_form';

    // 1. Generate code based on active tab
    String codeContent = '';
    switch (_activeTab) {
      case CodeTab.getXView:
        try {
          codeContent = GetxLayoutGenerator.generateView(rootNode, className, fileName);
        } catch (e) {
          codeContent = '// Error generating GetX View:\n$e';
        }
        break;
      case CodeTab.getXController:
        try {
          codeContent = GetxLayoutGenerator.generateController(rootNode, className);
        } catch (e) {
          codeContent = '// Error generating GetX Controller:\n$e';
        }
        break;
      case CodeTab.jsonStructure:
        try {
          const encoder = JsonEncoder.withIndent('  ');
          codeContent = encoder.convert(rootNode.toJson());
        } catch (e) {
          codeContent = '// Error formatting JSON:\n$e';
        }
        break;
      case CodeTab.legacyUI:
        codeContent = _generateLegacyUI(activeStepId, rootNode);
        break;
    }

    return RevoStudioPanelWrapper(
      title: "Generated UI Code",
      subtitle: "Real-time Clean Architecture Flutter code",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab Selector Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: RevoTheme.sidebarBackground,
              border: Border(bottom: BorderSide(color: RevoTheme.cardBorder, width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton("GetX View", CodeTab.getXView),
                  _buildTabButton("GetX Controller", CodeTab.getXController),
                  _buildTabButton("JSON Structure", CodeTab.jsonStructure),
                  _buildTabButton("Legacy Dump", CodeTab.legacyUI),
                ],
              ),
            ),
          ),

          // Code Window Header with Copy Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF141522),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    const Icon(Icons.circle, size: 8, color: Colors.amberAccent),
                    const SizedBox(width: 4),
                    const Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                    const SizedBox(width: 12),
                    Text(
                      _getTabHeaderTitle(stepId),
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _copyToClipboard(context, codeContent),
                  icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.greenAccent),
                  label: Text(
                    "Copy Code",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    backgroundColor: Colors.greenAccent.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),

          // Main Code Box
          Expanded(
            child: Container(
              color: const Color(0xFF090A10),
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: SelectableText(
                  codeContent,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 12,
                    color: const Color(0xFFE2E8F0),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, CodeTab tab) {
    final isSelected = tab == _activeTab;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTab = tab;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? RevoTheme.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? RevoTheme.primaryLight : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? RevoTheme.primaryLight : RevoTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  String _getTabHeaderTitle(String stepId) {
    switch (_activeTab) {
      case CodeTab.getXView:
        return 'lib/getx_layout/features/.../${stepId.toLowerCase()}_form_view.dart';
      case CodeTab.getXController:
        return 'lib/getx_layout/features/.../${stepId.toLowerCase()}_form_controller.dart';
      case CodeTab.jsonStructure:
        return '${stepId.toLowerCase()}_layout.json';
      case CodeTab.legacyUI:
        return '${stepId.toLowerCase()}_legacy_dump.dart';
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
            const SizedBox(width: 8),
            Text("Code copied to clipboard!", style: GoogleFonts.inter(color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF1E1B4B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _generateLegacyUI(String activeStepId, ComponentNode rootNode) {
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
        final slotChild = node.slots[slotName] ?? (slotName == 'child' ? (node.children.isNotEmpty ? node.children.first : null) : null);
        if (slotChild == null) continue;
        buffer.writeln("$indent  $slotName: ");
        _dumpNodeCode(slotChild, buffer, "$indent    ");
        if (slotName == 'child' && node.slots['child'] == null && node.children.length > 1) {
          buffer.writeln("$indent  // Warning: ${node.type} had ${node.children.length} legacy children; only the first was emitted.");
        }
      }
    } else if ((meta == null || meta.slotNames.isEmpty || !meta.slotNames.contains('child')) && node.children.isNotEmpty) {
      buffer.writeln("$indent  children: [");
      for (final child in node.children) {
        _dumpNodeCode(child, buffer, "$indent    ");
      }
      buffer.writeln("$indent  ],");
    }
    buffer.writeln("$indent),");
  }
}
