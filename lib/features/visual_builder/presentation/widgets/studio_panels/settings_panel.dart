import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme.dart';

import 'studio_panel_wrapper.dart';

// 9. Project Settings panel
class RevoSettingsPanel extends StatelessWidget {
  const RevoSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return RevoStudioPanelWrapper(
      title: "Settings Studio",
      subtitle: "Visual builder settings and patterns",
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDropdown(
            label: "Export Code Pattern",
            value: "Clean Architecture",
            options: ["Clean Architecture", "MVC Pattern", "MVVM Pattern"],
            onChanged: (val) {},
          ),
          _buildDropdown(
            label: "State Management Pattern",
            value: "Riverpod v3",
            options: ["Riverpod v3", "GetX Controller", "BLoC Provider"],
            onChanged: (val) {},
          ),
          const SizedBox(height: 12),
          const Text(
            "Visual Guidelines",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text("Show Layout Outlines", style: TextStyle(fontSize: 12)),
            value: true,
            onChanged: (val) {},
          ),
          SwitchListTile(
            title: const Text("Snapping Grid Layout", style: TextStyle(fontSize: 12)),
            value: false,
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }
}

// --- Common UI helper widgets ---


Widget _buildDropdown({
  required String label,
  required String value,
  required List<String> options,
  required ValueChanged<String?> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : options.first,
          onChanged: onChanged,
          isDense: true,
          style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          items: options
              .map((opt) => DropdownMenuItem(
                    value: opt,
                    child: Text(opt),
                  ))
              .toList(),
        ),
      ],
    ),
  );
}

