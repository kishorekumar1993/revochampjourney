import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme.dart';
import '../../../../../../core/component_engine/models/component_node.dart';
import '../../../../../../core/component_engine/models/component_property.dart';
import '../../../../../../core/component_engine/registry/component_registry.dart';
import '../../../../application/visual_builder_controller.dart';
import '../../../../application/studio_providers.dart';

// --- SHARED PROPERTY EDITOR HELPERS ---

Widget _buildPropertyTextField({
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

Widget _buildPropertyDropdown({
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

Widget _buildPropertySwitch({
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

Widget _buildColorFieldWithPresets({
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

// --- STYLE & LAYOUT RESOLVING HELPERS ---

bool _shouldShowStyleProperty(String key, ComponentNode node, ComponentMetadata? meta) {
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

bool _shouldShowLayoutProperty(String key, ComponentNode node, ComponentMetadata? meta) {
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

dynamic _getStyleValue(String key, ComponentNode node, ComponentMetadata? meta, {dynamic fallback = ''}) {
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

// --- 1. GENERAL TAB ---

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
          _buildPropertyTextField(
            label: "Field ID / Name",
            value: props['fieldName'] ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'fieldName': val}),
          ),
          _buildPropertyTextField(
            label: "Label Text",
            value: props['label'] ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'label': val}),
          ),
          _buildPropertyTextField(
            label: "Hint / Placeholder",
            value: props['hint'] ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'hint': val}),
          ),
          _buildPropertySwitch(
            label: "Is Editable (Enabled)",
            value: props['enabled'] != false,
            onChanged: (val) => controller.updateNodeProperties(node.id, {'enabled': val}),
          ),
          _buildPropertySwitch(
            label: "Is Read Only",
            value: props['readOnly'] == true,
            onChanged: (val) => controller.updateNodeProperties(node.id, {'readOnly': val}),
          ),
          if (node.type == 'TextField') ...[
            _buildPropertySwitch(
              label: "Password Obscure",
              value: props['obscureText'] == true,
              onChanged: (val) => controller.updateNodeProperties(node.id, {'obscureText': val}),
            ),
            _buildPropertyDropdown(
              label: "Keyboard Input Type",
              value: props['keyboardType'] ?? 'text',
              options: const ['text', 'number', 'email', 'phone', 'url'],
              onChanged: (val) => controller.updateNodeProperties(node.id, {'keyboardType': val}),
            ),
          ],
          if (node.type == 'Slider') ...[
            _buildPropertyTextField(
              label: "Minimum Value",
              value: props['min']?.toString() ?? '0.0',
              onChanged: (val) => controller.updateNodeProperties(node.id, {'min': double.tryParse(val) ?? 0.0}),
            ),
            _buildPropertyTextField(
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
          _buildPropertyTextField(
            label: "Content Text",
            value: props['label'] ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'label': val}),
          ),
        ] else if (node.type == 'Image') ...[
          _buildPropertyTextField(
            label: "Image Source URL",
            value: _getStyleValue('src', node, meta)?.toString() ?? '',
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
    final currentIcon = _getStyleValue('icon', node, meta, fallback: 'info')?.toString() ?? 'info';
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

// --- 2. STYLE TAB ---

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
        if (_shouldShowStyleProperty('backgroundColor', node, meta))
          _buildColorFieldWithPresets(
            context: context,
            label: "Background Color (Hex)",
            value: _getStyleValue('backgroundColor', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'backgroundColor': val}),
          ),
        if (_shouldShowStyleProperty('gradientStart', node, meta))
          _buildColorFieldWithPresets(
            context: context,
            label: "Gradient Start Color (Hex)",
            value: _getStyleValue('gradientStart', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'gradientStart': val}),
          ),
        if (_shouldShowStyleProperty('gradientEnd', node, meta))
          _buildColorFieldWithPresets(
            context: context,
            label: "Gradient End Color (Hex)",
            value: _getStyleValue('gradientEnd', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'gradientEnd': val}),
          ),
        if (_shouldShowStyleProperty('borderColor', node, meta))
          _buildColorFieldWithPresets(
            context: context,
            label: "Border Color (Hex)",
            value: _getStyleValue('borderColor', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'borderColor': val}),
          ),
        if (_shouldShowStyleProperty('borderWidth', node, meta))
          _buildPropertyTextField(
            label: "Border Width (px)",
            value: _getStyleValue('borderWidth', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'borderWidth': double.tryParse(val)}),
          ),
        if (_shouldShowStyleProperty('color', node, meta))
          _buildColorFieldWithPresets(
            context: context,
            label: "Theme Color (Hex)",
            value: _getStyleValue('color', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'color': val}),
          ),
        if (_shouldShowStyleProperty('textColor', node, meta))
          _buildColorFieldWithPresets(
            context: context,
            label: "Text Color (Hex)",
            value: _getStyleValue('textColor', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'textColor': val}),
          ),
        if (_shouldShowStyleProperty('fontSize', node, meta))
          _buildPropertyTextField(
            label: "Font Size (pt)",
            value: _getStyleValue('fontSize', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'fontSize': double.tryParse(val)}),
          ),
        if (_shouldShowStyleProperty('fontWeight', node, meta))
          _buildPropertyDropdown(
            label: "Font Weight",
            value: _getStyleValue('fontWeight', node, meta, fallback: 'normal')?.toString() ?? 'normal',
            options: const ['normal', 'bold', 'w100', 'w300', 'w500', 'w700'],
            onChanged: (val) => controller.updateNodeProperties(node.id, {'fontWeight': val}),
          ),
        if (_shouldShowStyleProperty('padding', node, meta))
          _buildPropertyTextField(
            label: "Padding (All)",
            value: _getStyleValue('padding', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'padding': double.tryParse(val)}),
          ),
        if (_shouldShowStyleProperty('margin', node, meta))
          _buildPropertyTextField(
            label: "Margin (All)",
            value: _getStyleValue('margin', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'margin': double.tryParse(val)}),
          ),
        if (_shouldShowStyleProperty('borderRadius', node, meta))
          _buildPropertyTextField(
            label: "Border Radius (px)",
            value: _getStyleValue('borderRadius', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'borderRadius': double.tryParse(val)}),
          ),
        if (_shouldShowStyleProperty('width', node, meta))
          _buildPropertyTextField(
            label: "Width (px)",
            value: _getStyleValue('width', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'width': double.tryParse(val)}),
          ),
        if (_shouldShowStyleProperty('height', node, meta))
          _buildPropertyTextField(
            label: "Height (px)",
            value: _getStyleValue('height', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'height': double.tryParse(val)}),
          ),
        if (_shouldShowStyleProperty('elevation', node, meta))
          _buildPropertyTextField(
            label: "Elevation (Shadow)",
            value: _getStyleValue('elevation', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'elevation': double.tryParse(val)}),
          ),
      ],
    );
  }
}

// --- 3. LAYOUT TAB ---

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
        if (_shouldShowLayoutProperty('mainAxisAlignment', node, meta))
          _buildPropertyDropdown(
            label: "Main Axis Alignment",
            value: _getStyleValue('mainAxisAlignment', node, meta, fallback: 'start')?.toString() ?? 'start',
            options: const ['start', 'center', 'end', 'space_between', 'space_around', 'space_evenly'],
            onChanged: (val) => controller.updateNodeProperties(node.id, {'mainAxisAlignment': val}),
          ),
        if (_shouldShowLayoutProperty('crossAxisAlignment', node, meta))
          _buildPropertyDropdown(
            label: "Cross Axis Alignment",
            value: _getStyleValue('crossAxisAlignment', node, meta, fallback: 'center')?.toString() ?? 'center',
            options: const ['start', 'center', 'end', 'stretch'],
            onChanged: (val) => controller.updateNodeProperties(node.id, {'crossAxisAlignment': val}),
          ),
        if (_shouldShowLayoutProperty('spacing', node, meta))
          _buildPropertyTextField(
            label: "Spacing (Gap)",
            value: _getStyleValue('spacing', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'spacing': double.tryParse(val)}),
          ),
      ],
    );
  }
}

// --- 4. RESPONSIVE TAB ---

class RevoResponsiveTab extends ConsumerWidget {
  final ComponentNode node;
  final VisualBuilderController controller;

  const RevoResponsiveTab({
    super.key,
    required this.node,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = node.responsive;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Responsive View Breakpoints", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        _buildPropertySwitch(
          label: "Visible on Mobile",
          value: responsive['mobile'] != false,
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(responsive)..['mobile'] = val;
            controller.updateNodeProperties(node.id, {'responsive': upd});
          },
        ),
        _buildPropertySwitch(
          label: "Visible on Tablet",
          value: responsive['tablet'] != false,
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(responsive)..['tablet'] = val;
            controller.updateNodeProperties(node.id, {'responsive': upd});
          },
        ),
        _buildPropertySwitch(
          label: "Visible on Desktop",
          value: responsive['desktop'] != false,
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(responsive)..['desktop'] = val;
            controller.updateNodeProperties(node.id, {'responsive': upd});
          },
        ),
      ],
    );
  }
}

// --- 5. DATA BINDING TAB ---

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
        _buildPropertyDropdown(
          label: "Bind to State Variable",
          value: bindings['variable'] ?? 'None',
          options: ['None', ...varNames],
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(bindings)..['variable'] = val;
            controller.updateNodeProperties(node.id, {'bindings': upd});
          },
        ),
        _buildPropertyTextField(
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

// --- 6. ANIMATION TAB ---

class RevoAnimationTab extends ConsumerWidget {
  final ComponentNode node;
  final VisualBuilderController controller;

  const RevoAnimationTab({
    super.key,
    required this.node,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animations = node.animations;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Micro-Animations Setup", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        _buildPropertyDropdown(
          label: "Animation Type",
          value: animations['type'] ?? 'none',
          options: const ['none', 'fade', 'slide', 'scale'],
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(animations)..['type'] = val;
            controller.updateNodeProperties(node.id, {'animations': upd});
          },
        ),
        _buildPropertyTextField(
          label: "Animation Duration (ms)",
          value: animations['duration']?.toString() ?? '300',
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(animations)..['duration'] = int.tryParse(val) ?? 300;
            controller.updateNodeProperties(node.id, {'animations': upd});
          },
        ),
      ],
    );
  }
}

// --- 7. PERMISSIONS TAB ---

class RevoPermissionsTab extends ConsumerWidget {
  final ComponentNode node;
  final VisualBuilderController controller;

  const RevoPermissionsTab({
    super.key,
    required this.node,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final props = node.properties;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Permissions & Roles", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        _buildPropertyDropdown(
          label: "Minimum Access Role",
          value: props['role'] ?? 'guest',
          options: const ['guest', 'user', 'admin'],
          onChanged: (val) => controller.updateNodeProperties(node.id, {'role': val}),
        ),
      ],
    );
  }
}
