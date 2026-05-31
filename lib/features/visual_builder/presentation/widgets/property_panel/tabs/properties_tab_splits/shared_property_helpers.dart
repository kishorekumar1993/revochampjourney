import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/core/component_engine/models/component_node.dart';
import 'package:revojourneytryone/core/component_engine/registry/component_registry.dart';
import 'package:revojourneytryone/features/visual_builder/application/visual_builder_controller.dart';

// ── HEX COLOR PARSERS ────────────────────────────────────────────────────────

Color hexToColor(String hex) {
  String cleanHex = hex.trim().replaceAll('#', '');
  if (cleanHex.isEmpty) return Colors.transparent;
  try {
    if (cleanHex.length == 6) {
      return Color(int.parse('FF$cleanHex', radix: 16));
    } else if (cleanHex.length == 8) {
      return Color(int.parse(cleanHex, radix: 16));
    }
  } catch (_) {}
  return Colors.transparent;
}

String colorToHex(Color color, {bool includeAlpha = false}) {
  if (includeAlpha) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  } else {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}

// ── BASIC UI HELPERS ──────────────────────────────────────────────────────────

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

// ── MODERN COLOR PICKER WITH HSL SLIDERS & PRESET PALETTES ─────────────────

class ModernColorPicker extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final void Function(String, String)? onGradientSelected;

  const ModernColorPicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onGradientSelected,
  });

  @override
  State<ModernColorPicker> createState() => _ModernColorPickerState();
}

class _ModernColorPickerState extends State<ModernColorPicker> {
  late HSLColor _hslColor;
  late double _opacity;
  late TextEditingController _textController;
  bool _isExpanded = false;

  final List<String> _brandPresets = const [
    '#5B4FCF', // Indigo
    '#10B981', // Emerald
    '#F59E0B', // Amber
    '#3B82F6', // Blue
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#EC4899', // Cyber Pink
    '#1E1E2F', // Dark slate
  ];

  final List<String> _neutralPresets = const [
    '#F8FAFC', // Slate-50
    '#E2E8F0', // Slate-200
    '#94A3B8', // Slate-400
    '#64748B', // Slate-500
    '#475569', // Slate-600
    '#334155', // Slate-700
    '#1E293B', // Slate-800
    '#0F172A', // Slate-900
  ];

  final List<Map<String, String>> _gradientPresets = const [
    {'name': 'Cosmic Dusk', 'start': '#5B4FCF', 'end': '#EC4899'},
    {'name': 'Cyber Neon', 'start': '#00F2FE', 'end': '#4FACFE'},
    {'name': 'Sunset Glow', 'start': '#FF512F', 'end': '#DD2476'},
    {'name': 'Ocean Breeze', 'start': '#11998E', 'end': '#38EF7D'},
    {'name': 'Warm Flame', 'start': '#F6D365', 'end': '#FDA085'},
    {'name': 'Deep Space', 'start': '#0F2027', 'end': '#2C5364'},
  ];

  @override
  void initState() {
    super.initState();
    _parseColor();
    _textController = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant ModernColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _parseColor();
      if (_textController.text.toLowerCase() != widget.value.toLowerCase()) {
        _textController.text = widget.value;
      }
    }
  }

  void _parseColor() {
    final color = hexToColor(widget.value);
    _hslColor = HSLColor.fromColor(color);
    _opacity = color.opacity;
  }

  void _updateColor(HSLColor newHsl, double newOpacity) {
    setState(() {
      _hslColor = newHsl;
      _opacity = newOpacity;
    });
    final color = newHsl.toColor().withValues(alpha: newOpacity);
    final hex = colorToHex(color, includeAlpha: newOpacity < 1.0);
    _textController.text = hex;
    widget.onChanged(hex);
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = _hslColor.toColor().withValues(alpha: _opacity);

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Color Circle Preview
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: RevoTheme.cardBorder, width: 2),
                    boxShadow: [
                      BoxShadow(color: activeColor.withValues(alpha: 0.3), blurRadius: 4, spreadRadius: 1),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 24,
                        child: TextField(
                          controller: _textController,
                          onChanged: (val) {
                            final col = hexToColor(val);
                            if (col != Colors.transparent) {
                              setState(() {
                                _hslColor = HSLColor.fromColor(col);
                                _opacity = col.opacity;
                              });
                              widget.onChanged(val);
                            }
                          },
                          style: GoogleFonts.sourceCodePro(fontSize: 11, color: RevoTheme.textPrimary, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintText: "#HEXCOLOR",
                            hintStyle: GoogleFonts.sourceCodePro(fontSize: 11, color: RevoTheme.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle Button for Custom HSL Sliders
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less_rounded : Icons.tune_rounded,
                    size: 16,
                    color: _isExpanded ? const Color(0xFF5B4FCF) : RevoTheme.textSecondary,
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ),

          // Presets Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Presets
                Row(
                  children: _brandPresets.map((hex) {
                    final color = hexToColor(hex);
                    final isSel = widget.value.toLowerCase().replaceAll('#', '') == hex.toLowerCase().replaceAll('#', '');
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _updateColor(HSLColor.fromColor(color), 1.0);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          height: 18,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSel ? const Color(0xFF5B4FCF) : Colors.grey.withValues(alpha: 0.2),
                              width: isSel ? 1.8 : 1.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                // Neutral Presets
                Row(
                  children: _neutralPresets.map((hex) {
                    final color = hexToColor(hex);
                    final isSel = widget.value.toLowerCase().replaceAll('#', '') == hex.toLowerCase().replaceAll('#', '');
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _updateColor(HSLColor.fromColor(color), 1.0);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          height: 18,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSel ? const Color(0xFF5B4FCF) : Colors.grey.withValues(alpha: 0.2),
                              width: isSel ? 1.8 : 1.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Double Gradient Presets (Optional)
          if (widget.onGradientSelected != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 10.0, bottom: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "PREMIUM GRADIENTS Presets (1-Click Apply)",
                    style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF5B4FCF), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 2.4,
                    ),
                    itemCount: _gradientPresets.length,
                    itemBuilder: (context, index) {
                      final grad = _gradientPresets[index];
                      final startCol = hexToColor(grad['start']!);
                      final endCol = hexToColor(grad['end']!);
                      return Tooltip(
                        message: grad['name'],
                        child: InkWell(
                          onTap: () => widget.onGradientSelected!(grad['start']!, grad['end']!),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [startCol, endCol],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: RevoTheme.cardBorder),
                            ),
                            child: Center(
                              child: Text(
                                grad['name']!,
                                style: GoogleFonts.inter(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold, shadows: [
                                  const Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 1)),
                                ]),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],

          // Sliders panel
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RevoTheme.cardBg.withValues(alpha: 0.5),
                border: Border(top: BorderSide(color: RevoTheme.cardBorder)),
              ),
              child: Column(
                children: [
                  // HUE Slider
                  _buildSliderRow(
                    label: "Hue",
                    value: _hslColor.hue,
                    min: 0.0,
                    max: 360.0,
                    trackWidget: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.red,
                            Colors.yellow,
                            Colors.green,
                            Colors.cyan,
                            Colors.blue,
                            Colors.purple,
                            Colors.red,
                          ],
                        ),
                      ),
                    ),
                    onChanged: (val) => _updateColor(_hslColor.withHue(val), _opacity),
                  ),
                  const SizedBox(height: 12),
                  // SATURATION Slider
                  _buildSliderRow(
                    label: "Saturation",
                    value: _hslColor.saturation,
                    min: 0.0,
                    max: 1.0,
                    trackWidget: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [
                            HSLColor.fromAHSL(1.0, _hslColor.hue, 0.0, _hslColor.lightness).toColor(),
                            HSLColor.fromAHSL(1.0, _hslColor.hue, 1.0, _hslColor.lightness).toColor(),
                          ],
                        ),
                      ),
                    ),
                    onChanged: (val) => _updateColor(_hslColor.withSaturation(val), _opacity),
                  ),
                  const SizedBox(height: 12),
                  // LIGHTNESS Slider
                  _buildSliderRow(
                    label: "Lightness",
                    value: _hslColor.lightness,
                    min: 0.0,
                    max: 1.0,
                    trackWidget: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black,
                            HSLColor.fromAHSL(1.0, _hslColor.hue, _hslColor.saturation, 0.5).toColor(),
                            Colors.white,
                          ],
                        ),
                      ),
                    ),
                    onChanged: (val) => _updateColor(_hslColor.withLightness(val), _opacity),
                  ),
                  const SizedBox(height: 12),
                  // OPACITY Slider
                  _buildSliderRow(
                    label: "Opacity",
                    value: _opacity,
                    min: 0.0,
                    max: 1.0,
                    trackWidget: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [
                            _hslColor.toColor().withValues(alpha: 0.0),
                            _hslColor.toColor().withValues(alpha: 1.0),
                          ],
                        ),
                      ),
                    ),
                    onChanged: (val) => _updateColor(_hslColor, val),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required Widget trackWidget,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
            Text(
              max == 1.0 ? "${(value * 100).toInt()}%" : "${value.toInt()}°",
              style: GoogleFonts.sourceCodePro(fontSize: 10, color: RevoTheme.textPrimary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.center,
          children: [
            trackWidget,
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── SCHEMA-DRIVEN PROPERTY FIELD GENERATORS ─────────────────────────────────

Widget buildDynamicPropertyField(String key, ComponentNode node, VisualBuilderController controller) {
  final val = node.properties[key];

  switch (key) {
    case 'fieldName':
      return buildPropertyTextField(
        label: "Field ID / Name",
        value: val?.toString() ?? '',
        onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: newVal}),
      );
    case 'label':
      return buildPropertyTextField(
        label: node.type == 'Text' || node.type == 'Button' ? "Content Text" : "Label Text",
        value: val?.toString() ?? '',
        onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: newVal}),
      );
    case 'hint':
      return buildPropertyTextField(
        label: "Hint / Placeholder",
        value: val?.toString() ?? '',
        onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: newVal}),
      );
    case 'enabled':
      return buildPropertySwitch(
        label: "Is Enabled",
        value: val != false,
        onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: newVal}),
      );
    case 'readOnly':
      return buildPropertySwitch(
        label: "Is Read Only",
        value: val == true,
        onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: newVal}),
      );
    case 'obscureText':
      return buildPropertySwitch(
        label: "Password Obscure",
        value: val == true,
        onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: newVal}),
      );
    case 'keyboardType':
      return buildPropertyDropdown(
        label: "Keyboard Input Type",
        value: val?.toString() ?? 'text',
        options: const ['text', 'number', 'email', 'phone', 'url'],
        onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: newVal}),
      );
    case 'min':
      return buildPropertyTextField(
        label: "Minimum Value",
        value: val?.toString() ?? '0.0',
        onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: double.tryParse(newVal) ?? 0.0}),
      );
    case 'max':
      return buildPropertyTextField(
        label: "Maximum Value",
        value: val?.toString() ?? '100.0',
        onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: double.tryParse(newVal) ?? 100.0}),
      );
    case 'length':
      return buildPropertyTextField(
        label: "Character Length",
        value: val?.toString() ?? '6',
        onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: int.tryParse(newVal) ?? 6}),
      );
    case 'options':
    case 'steps':
    case 'items':
    case 'columns':
      final listLabel = key.substring(0, 1).toUpperCase() + key.substring(1);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            "Configure $listLabel Items",
            style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._buildOptionsListEditor(key, node, controller),
        ],
      );
    case 'currentIndex':
    case 'index':
      return buildPropertyTextField(
        label: key == 'currentIndex' ? "Active Tab Index" : "Active Stack Index",
        value: val?.toString() ?? '0',
        onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: int.tryParse(newVal) ?? 0}),
      );
    case 'title':
      return buildPropertyTextField(
        label: "Title Text",
        value: val?.toString() ?? '',
        onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: newVal}),
      );
    case 'isCircular':
      return buildPropertySwitch(
        label: "Circular Indicator",
        value: val != false,
        onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: newVal}),
      );
    case 'fit':
      return buildPropertyDropdown(
        label: "Image BoxFit",
        value: val?.toString() ?? 'cover',
        options: const ['cover', 'contain', 'fill', 'fitWidth', 'fitHeight', 'none'],
        onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: newVal}),
      );
    case 'src':
      return buildPropertyTextField(
        label: "Image Source URL",
        value: val?.toString() ?? '',
        onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: newVal}),
      );
    case 'icon':
      return _buildIconSelector(node, controller);
    default:
      return buildPropertyTextField(
        label: key.substring(0, 1).toUpperCase() + key.substring(1),
        value: val?.toString() ?? '',
        onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: newVal}),
      );
  }
}

List<Widget> _buildOptionsListEditor(String key, ComponentNode node, VisualBuilderController controller) {
  final List<dynamic> rawOptions = node.properties[key] ?? [];
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
                    controller.updateNodeProperties(node.id, {key: updated});
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
                controller.updateNodeProperties(node.id, {key: updated});
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
          final updated = List<String>.from(options)..add('Item ${options.length + 1}');
          controller.updateNodeProperties(node.id, {key: updated});
        },
        icon: const Icon(Icons.add, size: 14, color: Color(0xFF5B4FCF)),
        label: Text("Add Item", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5B4FCF), fontWeight: FontWeight.bold)),
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
    case 'add': return Icons.add;
    case 'star': return Icons.star;
    case 'info': return Icons.info_outline;
    case 'home': return Icons.home_outlined;
    case 'settings': return Icons.settings;
    case 'person': return Icons.person_outline;
    case 'email': return Icons.mail_outline;
    case 'phone': return Icons.phone_android;
    case 'lock': return Icons.lock_outline;
    case 'check': return Icons.check;
    case 'close': return Icons.close;
    case 'arrow_forward': return Icons.arrow_forward;
    case 'arrow_back': return Icons.arrow_back;
    default: return Icons.category_outlined;
  }
}

// ── SCHEMA-DRIVEN STYLE FIELD GENERATORS ───────────────────────────────────

Widget buildDynamicStyleField(BuildContext context, String key, ComponentNode node, VisualBuilderController controller) {
  final meta = ComponentRegistry.getByType(node.type);
  final val = getStyleValue(key, node, meta);

  // If color key, render our premium ModernColorPicker
  final colorKeys = ['backgroundColor', 'gradientStart', 'gradientEnd', 'borderColor', 'color', 'textColor'];
  if (colorKeys.contains(key)) {
    String label = '';
    switch (key) {
      case 'backgroundColor': label = 'Background Color'; break;
      case 'gradientStart': label = 'Gradient Start Color'; break;
      case 'gradientEnd': label = 'Gradient End Color'; break;
      case 'borderColor': label = 'Border Color'; break;
      case 'color': label = 'Theme Color'; break;
      case 'textColor': label = 'Text Color'; break;
    }
    return ModernColorPicker(
      label: label,
      value: val?.toString() ?? '',
      onChanged: (newHex) => controller.updateNodeProperties(node.id, {key: newHex}),
      onGradientSelected: (key == 'backgroundColor') ? (startHex, endHex) {
        controller.updateNodeProperties(node.id, {
          'gradientStart': startHex,
          'gradientEnd': endHex,
        });
      } : null,
    );
  }

  // If enum dropdown key
  if (key == 'fontWeight') {
    return buildPropertyDropdown(
      label: "Font Weight",
      value: val?.toString() ?? 'normal',
      options: const ['normal', 'bold', 'w100', 'w300', 'w500', 'w700'],
      onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: newVal}),
    );
  }
  if (key == 'mainAxisAlignment') {
    return buildPropertyDropdown(
      label: "Main Axis Alignment",
      value: val?.toString() ?? 'start',
      options: const ['start', 'center', 'end', 'spaceBetween', 'spaceAround', 'spaceEvenly'],
      onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: newVal}),
    );
  }
  if (key == 'crossAxisAlignment') {
    return buildPropertyDropdown(
      label: "Cross Axis Alignment",
      value: val?.toString() ?? 'center',
      options: const ['start', 'center', 'end', 'stretch', 'baseline'],
      onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: newVal}),
    );
  }
  if (key == 'alignment') {
    return buildPropertyDropdown(
      label: "Alignment Position",
      value: val?.toString() ?? 'center',
      options: const ['center', 'topLeft', 'topCenter', 'topRight', 'bottomLeft', 'bottomCenter', 'bottomRight'],
      onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: newVal}),
    );
  }

  // Numeric text fields
  String label = '';
  switch (key) {
    case 'width': label = 'Width (px)'; break;
    case 'height': label = 'Height (px)'; break;
    case 'padding': label = 'Padding (All)'; break;
    case 'margin': label = 'Margin (All)'; break;
    case 'borderRadius': label = 'Border Radius (px)'; break;
    case 'borderWidth': label = 'Border Width (px)'; break;
    case 'elevation': label = 'Elevation (Shadow)'; break;
    case 'spacing': label = 'Spacing'; break;
    case 'runSpacing': label = 'Run Spacing'; break;
    default:
      label = key.substring(0, 1).toUpperCase() + key.substring(1);
  }

  return buildPropertyTextField(
    label: label,
    value: val?.toString() ?? '',
    onChanged: (newVal) => controller.updateNodeProperties(node.id, {key: double.tryParse(newVal)}),
  );
}

// ── GET COLOR & STYLE FALLBACKS ─────────────────────────────────────────────

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
