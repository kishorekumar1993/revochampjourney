import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/core/component_engine/models/component_node.dart';
import 'package:revojourneytryone/core/component_engine/registry/component_registry.dart';
import 'package:revojourneytryone/features/visual_builder/application/visual_builder_controller.dart';
import 'shared_property_helpers.dart';

class RevoGeneralTab extends ConsumerWidget {
  final ComponentNode node;
  final VisualBuilderController controller;

  const RevoGeneralTab({
    super.key,
    required this.node,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final props = node.properties;
    final meta = ComponentRegistry.getByType(node.type);
    final isForm = meta?.category == ComponentCategory.form;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isForm) ...[
          buildPropertyTextField(
            label: "Field ID / Name",
            value: props['fieldName'] ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'fieldName': val}),
          ),
          buildPropertyTextField(
            label: "Label Text",
            value: props['label'] ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'label': val}),
          ),
          buildPropertyTextField(
            label: "Hint / Placeholder",
            value: props['hint'] ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'hint': val}),
          ),
          buildPropertySwitch(
            label: "Is Editable (Enabled)",
            value: props['enabled'] != false,
            onChanged: (val) => controller.updateNodeProperties(node.id, {'enabled': val}),
          ),
          buildPropertySwitch(
            label: "Is Read Only",
            value: props['readOnly'] == true,
            onChanged: (val) => controller.updateNodeProperties(node.id, {'readOnly': val}),
          ),
          if (node.type == 'TextField') ...[
            buildPropertySwitch(
              label: "Password Obscure",
              value: props['obscureText'] == true,
              onChanged: (val) => controller.updateNodeProperties(node.id, {'obscureText': val}),
            ),
            buildPropertyDropdown(
              label: "Keyboard Input Type",
              value: props['keyboardType'] ?? 'text',
              options: const ['text', 'number', 'email', 'phone', 'url'],
              onChanged: (val) => controller.updateNodeProperties(node.id, {'keyboardType': val}),
            ),
          ],
          if (node.type == 'Slider') ...[
            buildPropertyTextField(
              label: "Minimum Value",
              value: props['min']?.toString() ?? '0.0',
              onChanged: (val) => controller.updateNodeProperties(node.id, {'min': double.tryParse(val) ?? 0.0}),
            ),
            buildPropertyTextField(
              label: "Maximum Value",
              value: props['max']?.toString() ?? '100.0',
              onChanged: (val) => controller.updateNodeProperties(node.id, {'max': double.tryParse(val) ?? 100.0}),
            ),
          ],
          if (node.type == 'Dropdown' || node.type == 'Radio') ...[
            const SizedBox(height: 12),
            Text(
              "Configure Option Items",
              style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._buildOptionsListEditor(node, controller),
          ],
        ] else if (node.type == 'Text' || node.type == 'Button') ...[
          buildPropertyTextField(
            label: "Content Text",
            value: props['label'] ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'label': val}),
          ),
        ] else if (node.type == 'Image') ...[
          buildPropertyTextField(
            label: "Image Source URL",
            value: getStyleValue('src', node, meta)?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'src': val}),
          ),
        ] else if (node.type == 'Icon' || node.type == 'IconButton' || node.type == 'FloatingButton') ...[
          _buildIconSelector(node, controller),
        ],
      ],
    );
  }

  List<Widget> _buildOptionsListEditor(ComponentNode node, VisualBuilderController controller) {
    final List<dynamic> rawOptions = node.properties['options'] ?? [];
    final List<String> options = List<String>.from(rawOptions.map((e) => e.toString()));

    return [
      ...List.generate(options.length, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: TextEditingController(text: options[index])
                      ..selection = TextSelection.fromPosition(TextPosition(offset: options[index].length)),
                    onChanged: (val) {
                      final updated = List<String>.from(options);
                      updated[index] = val;
                      controller.updateNodeProperties(node.id, {'options': updated});
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      filled: true,
                      fillColor: RevoTheme.cardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)),
                    ),
                    style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                onPressed: () {
                  final updated = List<String>.from(options)..removeAt(index);
                  controller.updateNodeProperties(node.id, {'options': updated});
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        );
      }),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () {
            final updated = List<String>.from(options)..add('Option ${options.length + 1}');
            controller.updateNodeProperties(node.id, {'options': updated});
          },
          icon: const Icon(Icons.add, size: 14, color: Color(0xFF5B4FCF)),
          label: Text("Add Option Item", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5B4FCF), fontWeight: FontWeight.bold)),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
        ),
      ),
    ];
  }

  Widget _buildIconSelector(ComponentNode node, VisualBuilderController controller) {
    final meta = ComponentRegistry.getByType(node.type);
    final currentIcon = getStyleValue('icon', node, meta, fallback: 'info')?.toString() ?? 'info';
    final List<String> iconNames = [
      'add', 'star', 'info', 'home', 'settings',
      'person', 'email', 'phone', 'lock', 'check',
      'close', 'arrow_forward', 'arrow_back'
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Select Icon Asset", style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: iconNames.map((name) {
              final isSelected = currentIcon == name;
              return Tooltip(
                message: name,
                child: InkWell(
                  onTap: () => controller.updateNodeProperties(node.id, {'icon': name}),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0x1F5B4FCF) : RevoTheme.cardBg,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.cardBorder,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getIconByName(name),
                      size: 18,
                      color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getIconByName(String name) {
    switch (name.toLowerCase()) {
      case 'add':
        return Icons.add;
      case 'star':
        return Icons.star;
      case 'info':
        return Icons.info_outline;
      case 'home':
        return Icons.home_outlined;
      case 'settings':
        return Icons.settings;
      case 'person':
        return Icons.person_outline;
      case 'email':
        return Icons.mail_outline;
      case 'phone':
        return Icons.phone_android;
      case 'lock':
        return Icons.lock_outline;
      case 'check':
        return Icons.check;
      case 'close':
        return Icons.close;
      case 'arrow_forward':
        return Icons.arrow_forward;
      case 'arrow_back':
        return Icons.arrow_back;
      default:
        return Icons.category_outlined;
    }
  }
}
