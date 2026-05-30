import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme.dart';
import '../../../../../../core/component_engine/models/component_node.dart';
import '../../../../application/visual_builder_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RevoValidationTab — Per-component validation rules for form fields.
// ─────────────────────────────────────────────────────────────────────────────

class RevoValidationTab extends StatelessWidget {
  final ComponentNode node;
  final VisualBuilderController controller;

  const RevoValidationTab({
    super.key,
    required this.node,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final props = node.properties;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Field Validation Rules", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: RevoTheme.textPrimary)),
        const SizedBox(height: 12),
        _buildSwitch(
          label: "Field is Required",
          value: props['required'] == true,
          onChanged: (val) => controller.updateNodeProperties(node.id, {'required': val}),
        ),
        _buildTextField(
          label: "Regex Validation Pattern",
          value: props['regexPattern'] ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'regexPattern': val}),
        ),
        _buildTextField(
          label: "Min Characters Limit",
          value: props['minLength']?.toString() ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'minLength': int.tryParse(val)}),
        ),
        _buildTextField(
          label: "Max Characters Limit",
          value: props['maxLength']?.toString() ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'maxLength': int.tryParse(val)}),
        ),
        _buildTextField(
          label: "Error Message",
          value: props['errorMessage'] ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'errorMessage': val}),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: TextField(
              controller: TextEditingController(text: value)
                ..selection = TextSelection.fromPosition(TextPosition(offset: value.length)),
              onChanged: onChanged,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: RevoTheme.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: RevoTheme.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: RevoTheme.cardBorder),
                ),
              ),
              style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textPrimary, fontWeight: FontWeight.w500)),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF5B4FCF),
            activeTrackColor: const Color(0xFF5B4FCF).withValues(alpha: 0.5),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RevoValidationsSummaryView — Summary panel showing validations across
// all nodes in the current layout (used in the top-level toggle).
// ─────────────────────────────────────────────────────────────────────────────

class RevoValidationsSummaryView extends StatelessWidget {
  final ComponentNode rootNode;

  const RevoValidationsSummaryView({super.key, required this.rootNode});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> validators = [];
    _gatherValidations(rootNode, validators);

    if (validators.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "No field validation criteria set on this screen layout.",
            style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: validators.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final val = validators[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: RevoTheme.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: RevoTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.gpp_maybe_rounded, color: Color(0xFF5B4FCF), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      val['id'] ?? '',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: RevoTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Required:", style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary)),
                  Text(
                    val['required'] == true ? "YES" : "NO",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: val['required'] == true ? Colors.green : RevoTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              if (val['regex'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Regex Rule:", style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary)),
                    Expanded(
                      child: Text(
                        val['regex'],
                        style: GoogleFonts.sourceCodePro(fontSize: 10, color: const Color(0xFF5B4FCF)),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (val['bounds'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Length Bounds:", style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary)),
                    Text(val['bounds'], style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textPrimary)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _gatherValidations(ComponentNode node, List<Map<String, dynamic>> list) {
    final props = node.properties;
    if (node.type == 'TextField' || node.type == 'Dropdown') {
      final isReq = props['required'] == true;
      final regex = props['regexPattern']?.toString() ?? '';
      final min = props['minLength'];
      final max = props['maxLength'];

      if (isReq || regex.isNotEmpty || min != null || max != null) {
        String bounds = '';
        if (min != null && max != null) {
          bounds = '$min-$max chars';
        } else if (min != null) {
          bounds = 'min $min chars';
        } else if (max != null) {
          bounds = 'max $max chars';
        }

        list.add({
          'id': props['fieldName'] ?? node.id,
          'required': isReq,
          'regex': regex.isNotEmpty ? regex : null,
          'bounds': bounds.isNotEmpty ? bounds : null,
        });
      }
    }

    for (final child in node.children) {
      _gatherValidations(child, list);
    }
  }
}
