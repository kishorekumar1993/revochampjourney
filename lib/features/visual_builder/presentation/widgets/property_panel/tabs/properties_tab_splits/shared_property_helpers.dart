import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/core/component_engine/models/component_node.dart';
import 'package:revojourneytryone/core/component_engine/models/component_property.dart';
import 'package:revojourneytryone/core/component_engine/registry/component_registry.dart';

Widget buildPropertyTextField({
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
            controller: TextEditingController(text: value)..selection = TextSelection.fromPosition(TextPosition(offset: value.length)),
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: RevoTheme.cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)),
            ),
            style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary),
          ),
        ),
      ],
    ),
  );
}

Widget buildPropertyDropdown({
  required String label,
  required String value,
  required List<String> options,
  required ValueChanged<String?> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: RevoTheme.cardBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: RevoTheme.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(value) ? value : options.first,
              dropdownColor: RevoTheme.cardBg,
              isExpanded: true,
              style: GoogleFonts.inter(color: RevoTheme.textPrimary, fontSize: 12),
              items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildPropertySwitch({
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

Widget buildColorFieldWithPresets({
  required BuildContext context,
  required String label,
  required String value,
  required ValueChanged<String> onChanged,
}) {
  final List<String> presets = [
    '#5B4FCF', // Indigo
    '#10B981', // Emerald
    '#EF4444', // Red
    '#F59E0B', // Amber
    '#3B82F6', // Blue
    '#1E1E2F', // Dark slate
    '#FFFFFF', // White
  ];

  return Padding(
    padding: const EdgeInsets.only(bottom: 14.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: TextEditingController(text: value)..selection = TextSelection.fromPosition(TextPosition(offset: value.length)),
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: RevoTheme.cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)),
                  ),
                  style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: PropertyParser.parseColor(value) ?? Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: RevoTheme.cardBorder, width: 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((colorHex) {
              final color = PropertyParser.parseColor(colorHex)!;
              final isSelected = value.toLowerCase().replaceAll('#', '') == colorHex.toLowerCase().replaceAll('#', '');
              return GestureDetector(
                onTap: () => onChanged(colorHex),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF5B4FCF) : Colors.grey.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

bool shouldShowStyleProperty(String key, ComponentNode node, ComponentMetadata? meta) {
  if (node.properties.containsKey(key) || node.styles.containsKey(key)) {
    return true;
  }
  if (meta != null && meta.defaultProperties.containsKey(key)) {
    return true;
  }
  final type = node.type;
  switch (key) {
    case 'width':
    case 'height':
      return type == 'Container' || type == 'SizedBox' || type == 'Image' || type == 'Card';
    case 'backgroundColor':
      return type == 'Container' || type == 'Card' || type == 'Button' || type == 'FloatingButton' || type == 'Chip' || type == 'Badge';
    case 'gradientStart':
    case 'gradientEnd':
      return type == 'Container' || type == 'Card';
    case 'padding':
    case 'margin':
      return type == 'Container' || type == 'Card' || type == 'Row' || type == 'Column' || type == 'ListView' || type == 'GridView' || type == 'Wrap';
    case 'borderRadius':
      return type == 'Container' || type == 'Card' || type == 'Button' || type == 'Image';
    case 'borderColor':
    case 'borderWidth':
      return type == 'Container' || type == 'Card';
    case 'color':
      return type == 'Icon' || type == 'IconButton' || type == 'Progress';
    case 'textColor':
      return type == 'Text' || type == 'Button' || type == 'Chip' || type == 'Badge';
    case 'fontSize':
      return type == 'Text' || type == 'Icon' || type == 'IconButton';
    case 'fontWeight':
      return type == 'Text';
    case 'elevation':
      return type == 'Card' || type == 'Container' || type == 'Button';
  }
  return false;
}

bool shouldShowLayoutProperty(String key, ComponentNode node, ComponentMetadata? meta) {
  if (node.properties.containsKey(key) || node.styles.containsKey(key)) {
    return true;
  }
  if (meta != null && meta.defaultProperties.containsKey(key)) {
    return true;
  }
  final type = node.type;
  switch (key) {
    case 'mainAxisAlignment':
    case 'crossAxisAlignment':
      return type == 'Row' || type == 'Column';
    case 'spacing':
      return type == 'Row' || type == 'Column' || type == 'Wrap' || type == 'GridView' || type == 'ListView';
  }
  return false;
}

dynamic getStyleValue(String key, ComponentNode node, ComponentMetadata? meta, {dynamic fallback = ''}) {
  if (node.styles.containsKey(key)) {
    return node.styles[key] ?? fallback;
  }
  if (node.properties.containsKey(key)) {
    return node.properties[key] ?? fallback;
  }
  if (meta != null && meta.defaultProperties.containsKey(key)) {
    return meta.defaultProperties[key] ?? fallback;
  }
  return fallback;
}
