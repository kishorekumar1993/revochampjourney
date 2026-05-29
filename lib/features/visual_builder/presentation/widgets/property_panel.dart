import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/component_engine/models/component_property.dart';
import '../../../../core/theme.dart';
import '../../../../core/component_engine/models/component_node.dart';
import '../../../../core/component_engine/models/component_action.dart';
import '../../../../core/component_engine/registry/component_registry.dart';
import '../../application/visual_builder_controller.dart';

class RevoPropertyPanel extends ConsumerStatefulWidget {
  const RevoPropertyPanel({super.key});

  @override
  ConsumerState<RevoPropertyPanel> createState() => _RevoPropertyPanelState();
}

class _RevoPropertyPanelState extends ConsumerState<RevoPropertyPanel> {
  @override
  Widget build(BuildContext context) {
    final builderState = ref.watch(visualBuilderProvider);
    final selectedNode = builderState.selectedNode;

    if (selectedNode == null) {
      return _buildNoSelectionPlaceholder();
    }

    final meta = ComponentRegistry.getByType(selectedNode.type);
    final isForm = meta?.category == ComponentCategory.form;
    final isLayout = meta?.category == ComponentCategory.layout;

    // Define active tabs based on category
    final tabs = [
      const Tab(text: "General"),
      const Tab(text: "Style"),
      if (isLayout) const Tab(text: "Layout"),
      if (isForm) const Tab(text: "Validation"),
      const Tab(text: "Actions"),
      if (selectedNode.type == 'Dropdown') const Tab(text: "API"),
    ];

    final controller = ref.read(visualBuilderProvider.notifier);

    return DefaultTabController(
      key: ValueKey('${selectedNode.id}_${tabs.length}'),
      length: tabs.length,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: RevoTheme.sidebarBackground,
          border: Border(left: BorderSide(color: RevoTheme.cardBorder)),
        ),
        child: Column(
          children: [
            // Selection Header
            Container(
              padding: const EdgeInsets.all(16.0),
              color: RevoTheme.sidebarBackground,
              child: Row(
                children: [
                  Icon(meta?.icon ?? Icons.settings_rounded, color: const Color(0xFF5B4FCF), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedNode.type,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: RevoTheme.textPrimary,
                          ),
                        ),
                        Text(
                          "ID: ${selectedNode.id}",
                          style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // TabBar
            TabBar(
              isScrollable: true,
              labelColor: const Color(0xFF5B4FCF),
              unselectedLabelColor: RevoTheme.textSecondary,
              indicatorColor: const Color(0xFF5B4FCF),
              labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
              tabs: tabs,
            ),
            const Divider(height: 1),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  _buildGeneralTab(selectedNode, controller),
                  _buildStyleTab(selectedNode, controller),
                  if (isLayout) _buildLayoutTab(selectedNode, controller),
                  if (isForm) _buildValidationTab(selectedNode, controller),
                  _buildActionsTab(selectedNode, controller),
                  if (selectedNode.type == 'Dropdown') _buildApiTab(selectedNode, controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSelectionPlaceholder() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(left: BorderSide(color: RevoTheme.cardBorder)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0x0C5B4FCF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
                  color: Color(0xFF5B4FCF),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Select Component",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: RevoTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Click on any item on the canvas to configure its layout, style, actions, and validation settings.",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: RevoTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Tab 1: General Properties ---
  Widget _buildGeneralTab(ComponentNode node, VisualBuilderController controller) {
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
              options: ['text', 'number', 'email', 'phone', 'url'],
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
            value: props['src'] ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'src': val}),
          ),
        ] else if (node.type == 'Icon' || node.type == 'IconButton' || node.type == 'FloatingButton') ...[
          _buildIconSelector(node, controller),
        ],
      ],
    );
  }

  // --- Tab 2: Styles Properties ---
  Widget _buildStyleTab(ComponentNode node, VisualBuilderController controller) {
    final props = node.properties;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (props.containsKey('backgroundColor'))
          _buildColorFieldWithPresets(
            label: "Background Color (Hex)",
            value: props['backgroundColor'] ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'backgroundColor': val}),
          ),
        if (props.containsKey('color'))
          _buildColorFieldWithPresets(
            label: "Theme Color (Hex)",
            value: props['color'] ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'color': val}),
          ),
        if (props.containsKey('textColor'))
          _buildColorFieldWithPresets(
            label: "Text Color (Hex)",
            value: props['textColor'] ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'textColor': val}),
          ),
        if (props.containsKey('fontSize'))
          _buildPropertyTextField(
            label: "Font Size (pt)",
            value: props['fontSize']?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'fontSize': double.tryParse(val)}),
          ),
        if (props.containsKey('fontWeight'))
          _buildPropertyDropdown(
            label: "Font Weight",
            value: props['fontWeight'] ?? 'normal',
            options: ['normal', 'bold', 'w100', 'w300', 'w500', 'w700'],
            onChanged: (val) => controller.updateNodeProperties(node.id, {'fontWeight': val}),
          ),
        if (props.containsKey('padding'))
          _buildPropertyTextField(
            label: "Padding (All)",
            value: props['padding']?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'padding': double.tryParse(val)}),
          ),
        if (props.containsKey('margin'))
          _buildPropertyTextField(
            label: "Margin (All)",
            value: props['margin']?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'margin': double.tryParse(val)}),
          ),
        if (props.containsKey('borderRadius'))
          _buildPropertyTextField(
            label: "Border Radius (px)",
            value: props['borderRadius']?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'borderRadius': double.tryParse(val)}),
          ),
        if (props.containsKey('width'))
          _buildPropertyTextField(
            label: "Width (px)",
            value: props['width']?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'width': double.tryParse(val)}),
          ),
        if (props.containsKey('height'))
          _buildPropertyTextField(
            label: "Height (px)",
            value: props['height']?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'height': double.tryParse(val)}),
          ),
      ],
    );
  }

  // --- Tab 3: Layout Properties (Layout Containers only) ---
  Widget _buildLayoutTab(ComponentNode node, VisualBuilderController controller) {
    final props = node.properties;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (props.containsKey('mainAxisAlignment'))
          _buildPropertyDropdown(
            label: "Main Axis Alignment",
            value: props['mainAxisAlignment'] ?? 'start',
            options: ['start', 'center', 'end', 'space_between', 'space_around', 'space_evenly'],
            onChanged: (val) => controller.updateNodeProperties(node.id, {'mainAxisAlignment': val}),
          ),
        if (props.containsKey('crossAxisAlignment'))
          _buildPropertyDropdown(
            label: "Cross Axis Alignment",
            value: props['crossAxisAlignment'] ?? 'center',
            options: ['start', 'center', 'end', 'stretch'],
            onChanged: (val) => controller.updateNodeProperties(node.id, {'crossAxisAlignment': val}),
          ),
        if (props.containsKey('spacing'))
          _buildPropertyTextField(
            label: "Spacing (Gap)",
            value: props['spacing']?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'spacing': double.tryParse(val)}),
          ),
      ],
    );
  }

  // --- Tab 4: Validation (Forms only) ---
  Widget _buildValidationTab(ComponentNode node, VisualBuilderController controller) {
    final props = node.properties;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPropertySwitch(
          label: "Field is Required",
          value: props['required'] == true,
          onChanged: (val) => controller.updateNodeProperties(node.id, {'required': val}),
        ),
        _buildPropertyTextField(
          label: "Regex Validation Pattern",
          value: props['regexPattern'] ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'regexPattern': val}),
        ),
        _buildPropertyTextField(
          label: "Min Characters Limit",
          value: props['minLength']?.toString() ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'minLength': int.tryParse(val)}),
        ),
        _buildPropertyTextField(
          label: "Max Characters Limit",
          value: props['maxLength']?.toString() ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'maxLength': int.tryParse(val)}),
        ),
        _buildPropertyTextField(
          label: "Error message details",
          value: props['errorMessage'] ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'errorMessage': val}),
        ),
      ],
    );
  }

  // --- Tab 5: Actions Editor ---
  Widget _buildActionsTab(ComponentNode node, VisualBuilderController controller) {
    final actions = node.actions;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Action Flow Pipeline",
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        if (actions.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RevoTheme.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: Column(
              children: [
                Text("No actions configured", style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    final defaultAction = ComponentAction(
                      event: 'onTap',
                      steps: [ActionStep(type: 'validate')],
                    );
                    controller.updateNodeActions(node.id, [defaultAction]);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B4FCF),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text("Add onTap Trigger", style: GoogleFonts.inter(fontSize: 11, color: Colors.white)),
                ),
              ],
            ),
          )
        else
          ...actions.map((act) {
            return Card(
              color: RevoTheme.cardBg,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: RevoTheme.cardBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Trigger: ${act.event}", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 14),
                          onPressed: () => controller.updateNodeActions(node.id, []),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 6),
                    ...List.generate(act.steps.length, (i) {
                      final step = act.steps[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0x0C5B4FCF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${i + 1}. ${step.type.toUpperCase()}",
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF5B4FCF)),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded, size: 12, color: RevoTheme.textSecondary),
                              onPressed: () {
                                final list = List<ActionStep>.from(act.steps)..removeAt(i);
                                controller.updateNodeActions(node.id, [act.copyWith(steps: list)]);
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    // Add Action Step Dropdown menu
                    PopupMenuButton<String>(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF5B4FCF)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, size: 12, color: Color(0xFF5B4FCF)),
                            const SizedBox(width: 4),
                            Text("Add Step", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5B4FCF))),
                          ],
                        ),
                      ),
                      onSelected: (val) {
                        final list = List<ActionStep>.from(act.steps)..add(ActionStep(type: val));
                        controller.updateNodeActions(node.id, [act.copyWith(steps: list)]);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'validate', child: Text("Validate Fields")),
                        const PopupMenuItem(value: 'api', child: Text("Call API service")),
                        const PopupMenuItem(value: 'navigate', child: Text("Navigate Screen")),
                        const PopupMenuItem(value: 'saveToken', child: Text("Save Data Token")),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // --- Tab 6: API Integration ---
  Widget _buildApiTab(ComponentNode node, VisualBuilderController controller) {
    final props = node.properties;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Remote API Data Connector",
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        _buildPropertyTextField(
          label: "Endpoint URL",
          value: props['apiUrl'] ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'apiUrl': val}),
        ),
        _buildPropertyDropdown(
          label: "HTTP Method",
          value: props['apiMethod'] ?? 'GET',
          options: ['GET', 'POST'],
          onChanged: (val) => controller.updateNodeProperties(node.id, {'apiMethod': val}),
        ),
        _buildPropertyTextField(
          label: "Response List Array Key (e.g. data.users)",
          value: props['responseListKey'] ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'responseListKey': val}),
        ),
        _buildPropertyTextField(
          label: "Item Label key",
          value: props['labelKey'] ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'labelKey': val}),
        ),
        _buildPropertyTextField(
          label: "Item Value key",
          value: props['valueKey'] ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'valueKey': val}),
        ),
      ],
    );
  }

  // --- Forms Inputs Elements Builders ---

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
            activeTrackColor: const Color(0xFF5B4FCF).withOpacity(0.5),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // --- Premium Extra Builders ---

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

  Widget _buildColorFieldWithPresets({
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
                        color: isSelected ? const Color(0xFF5B4FCF) : Colors.grey.withOpacity(0.3),
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

  Widget _buildIconSelector(ComponentNode node, VisualBuilderController controller) {
    final currentIcon = node.properties['icon'] ?? 'info';
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
