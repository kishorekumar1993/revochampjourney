import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme.dart';
import '../../data/models.dart';
import '../providers/journey_provider.dart';

class RevoPropertiesPanel extends ConsumerStatefulWidget {
  const RevoPropertiesPanel({super.key});

  @override
  ConsumerState<RevoPropertiesPanel> createState() => _RevoPropertiesPanelState();
}

class _RevoPropertiesPanelState extends ConsumerState<RevoPropertiesPanel> {
  String _activeTab = 'Editor';
  final _jsonController = TextEditingController();
  bool _isValidJson = true;
  String _jsonError = '';
  bool _showJsonConfig = false;

  // Section collapse states to prevent scrolling ("crawling")
  bool _showGeneralSettings = true;
  bool _showStateFlags = false;
  bool _showValidations = false;
  bool _showDataOptions = false;
  bool _showEnterpriseSettings = false;
  bool _showDataComponentSettings = true;
  bool _showLayoutComponentSettings = true;

  // Inner API Config tab: 0 = Endpoint, 1 = Payload, 2 = Response Mapping & Test Data
  int _apiTabIndex = 0;

  // Track syntax validation messages locally to show warnings without breaking state
  String? _headersError;
  String? _testDataError;

  bool _testingApi = false;
  String? _apiTestResult;
  bool _apiTestSuccess = false;

  @override
  void initState() {
    super.initState();
    // Initialize text editor with current config state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = ref.read(journeyConfigProvider);
      _jsonController.text = _beautifyJson(config.toJson());
    });
  }

  String _beautifyJson(Map<String, dynamic> jsonMap) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(jsonMap);
  }

  void _onJsonTextChanged(String val, WidgetRef ref) {
    if (val.trim().isEmpty) return;
    try {
      json.decode(val);
      final success = ref.read(journeyConfigProvider.notifier).updateFromJson(val);
      setState(() {
        _isValidJson = success;
        _jsonError = success ? '' : 'Schema mismatch or invalid keys';
      });
    } catch (e) {
      setState(() {
        _isValidJson = false;
        _jsonError = e.toString();
      });
    }
  }

  void _beautifyText() {
    try {
      final decoded = json.decode(_jsonController.text);
      setState(() {
        _jsonController.text = _beautifyJson(decoded);
        _isValidJson = true;
        _jsonError = '';
      });
    } catch (e) {
      setState(() {
        _isValidJson = false;
        _jsonError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final config = ref.watch(journeyConfigProvider);
    final activeStepId = ref.watch(activeStepIdProvider);
    final selectedFieldId = ref.watch(selectedFieldIdProvider);

    // Sync JSON text field if updated visually
    ref.listen<JourneyConfig>(journeyConfigProvider, (prev, next) {
      try {
        final currentTextDecoded = json.encode(json.decode(_jsonController.text));
        final nextDecoded = json.encode(next.toJson());
        if (currentTextDecoded != nextDecoded) {
          _jsonController.text = _beautifyJson(next.toJson());
        }
      } catch (_) {
        _jsonController.text = _beautifyJson(next.toJson());
      }
    });

    // Find the highlighted field in the active step
    JourneyField? selectedField;
    final stepIndex = config.steps.indexWhere((s) => s.id == activeStepId);
    if (stepIndex != -1) {
      final step = config.steps[stepIndex];
      selectedField = _findFieldById(step.fields, selectedFieldId);
    }

    final isRadioOrSelectionOrDivider = selectedField?.type == 'radio' ||
        selectedField?.type == 'checkbox' ||
        selectedField?.type == 'switch' ||
        selectedField?.type == 'divider';
    final supportsOptions = selectedField?.type == 'dropdown' ||
        selectedField?.type == 'api_dropdown' ||
        selectedField?.type == 'radio' ||
        selectedField?.type == 'multi_select';

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(
          left: BorderSide(color: RevoTheme.cardBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          // 1. JSON Configuration Segment (Collapsible)
          InkWell(
            onTap: () => setState(() => _showJsonConfig = !_showJsonConfig),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _showJsonConfig
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_right_rounded,
                        color: RevoTheme.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "JSON Config Code",
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _showJsonConfig ? RevoTheme.primaryLight : RevoTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (_showJsonConfig)
                    Container(
                      height: 26,
                      decoration: BoxDecoration(
                        color: RevoTheme.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Row(
                        children: [
                          _buildTabButton("Editor", _activeTab == 'Editor'),
                          _buildTabButton("Preview", _activeTab == 'Preview'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Code text area
          if (_showJsonConfig)
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: _activeTab == 'Editor'
                    ? Container(
                        decoration: BoxDecoration(
                          color: RevoTheme.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isValidJson ? RevoTheme.cardBorder : Colors.redAccent.withValues(alpha:0.5),
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Format: JSON", style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.copy_all_rounded, size: 14, color: RevoTheme.textSecondary),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("JSON Copied!")),
                                        );
                                      },
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.fullscreen_rounded, size: 14, color: RevoTheme.textSecondary),
                                      onPressed: () {},
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: TextField(
                                controller: _jsonController,
                                maxLines: null,
                                expands: true,
                                style: GoogleFonts.sourceCodePro(fontSize: 11, color: Colors.greenAccent),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) => _onJsonTextChanged(val, ref),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _isValidJson 
                                        ? RevoTheme.secondary.withValues(alpha:0.15) 
                                        : Colors.redAccent.withValues(alpha:0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _isValidJson ? "Valid JSON" : "Invalid JSON",
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: _isValidJson ? RevoTheme.secondary : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: _beautifyText,
                                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
                                      child: Text("Beautify", style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.primaryLight)),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            if (!_isValidJson && _jsonError.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                _jsonError,
                                style: GoogleFonts.inter(fontSize: 9, color: Colors.redAccent),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ]
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Text(
                          _jsonController.text,
                          style: GoogleFonts.sourceCodePro(fontSize: 11, color: RevoTheme.textSecondary),
                        ),
                      ),
              ),
            ),

          if (_showJsonConfig)
            Divider(color: RevoTheme.cardBorder, height: 16),

          // 2. Component Properties Segment
          Expanded(
            flex: _showJsonConfig ? 5 : 1,
            child: selectedField == null
                ? Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note_rounded, size: 36, color: RevoTheme.textSecondary.withValues(alpha:0.5)),
                          const SizedBox(height: 12),
                          Text(
                            "Select a component from the canvas grid to start customizing its properties.",
                            style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Heading Title
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: RevoTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: RevoTheme.cardBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedField.label.isNotEmpty ? selectedField.label : "Unnamed Field",
                                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "ID: ${selectedField.id}",
                                      style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: RevoTheme.primary.withValues(alpha:0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: RevoTheme.primaryLight.withValues(alpha:0.4)),
                                ),
                                child: Text(
                                  selectedField.type.toUpperCase(),
                                  style: GoogleFonts.inter(fontSize: 9, color: RevoTheme.primaryLight, fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Section 1: General Settings (Collapsible)
                        _buildCollapsibleSection(
                          title: "General Settings",
                          accentColor: RevoTheme.primaryLight,
                          icon: Icons.tune_rounded,
                          isExpanded: _showGeneralSettings,
                          onToggle: () => setState(() => _showGeneralSettings = !_showGeneralSettings),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _PropertyTextField(
                                    label: "Field ID",
                                    initialValue: selectedField.id,
                                    onChanged: (val) {
                                      final updated = selectedField!.copy()..id = val.trim();
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateFieldInStep(activeStepId, selectedField.id, updated);
                                      ref.read(selectedFieldIdProvider.notifier).state = val.trim();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _PropertyDropdownField(
                                    label: "Type",
                                    currentValue: selectedField.type,
                                    items: const [
                                      'text',
                                      'textarea',
                                      'number',
                                      'dropdown',
                                      'api_dropdown',
                                      'radio',
                                      'checkbox',
                                      'switch',
                                      'date',
                                      'time',
                                      'datetime',
                                      'file',
                                      'image',
                                      'otp',
                                      'phone',
                                      'multi_select',
                                      'table_grid',
                                      'repeater',
                                      'timeline',
                                      'row',
                                      'formula',
                                      'section',
                                      'card',
                                      'tabs',
                                      'accordion',
                                      'divider'
                                    ],
                                    onChanged: (val) {
                                      final updated = selectedField!.copy()..type = val;
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateFieldInStep(activeStepId, selectedField.id, updated);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _PropertyTextField(
                                    label: "Label Text",
                                    initialValue: selectedField.label,
                                    onChanged: (val) {
                                      final updated = selectedField!.copy()..label = val.trim();
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateFieldInStep(activeStepId, selectedField.id, updated);
                                    },
                                  ),
                                ),
                                if (!isRadioOrSelectionOrDivider) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _PropertyTextField(
                                      label: "Metadata Type",
                                      initialValue: selectedField.fieldtype ?? '',
                                      hint: "e.g. text, select",
                                      onChanged: (val) {
                                        final updated = selectedField!.copy()..fieldtype = val.trim().isEmpty ? null : val.trim();
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateFieldInStep(activeStepId, selectedField.id, updated);
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (!isRadioOrSelectionOrDivider) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _PropertyTextField(
                                      label: "Placeholder",
                                      initialValue: selectedField.placeholder ?? '',
                                      onChanged: (val) {
                                        final updated = selectedField!.copy()..placeholder = val.trim().isEmpty ? null : val.trim();
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateFieldInStep(activeStepId, selectedField.id, updated);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _PropertyTextField(
                                      label: "Hint Text",
                                      initialValue: selectedField.hintText ?? '',
                                      onChanged: (val) {
                                        final updated = selectedField!.copy()..hintText = val.trim().isEmpty ? null : val.trim();
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateFieldInStep(activeStepId, selectedField.id, updated);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            _PropertyTextField(
                              label: "Default Value / Initial Value",
                              initialValue: selectedField.defaultValue ?? '',
                              hint: "Initial value of the field",
                              onChanged: (val) {
                                final updated = selectedField!.copy()..defaultValue = val.trim().isEmpty ? null : val.trim();
                                ref.read(journeyConfigProvider.notifier)
                                    .updateFieldInStep(activeStepId, selectedField.id, updated);
                              },
                            ),
                          ],
                        ),

                        // Section 2: Visibility & Status Flags (Collapsible)
                        _buildCollapsibleSection(
                          title: "State & Visibility Flags",
                          accentColor: RevoTheme.success,
                          icon: Icons.visibility_outlined,
                          isExpanded: _showStateFlags,
                          onToggle: () => setState(() => _showStateFlags = !_showStateFlags),
                          children: [
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 2.8,
                              children: [
                                _buildCompactSwitchTile(
                                  label: "Required",
                                  value: selectedField.required,
                                  onChanged: (val) {
                                    final updated = selectedField!.copy()..required = val;
                                    ref.read(journeyConfigProvider.notifier)
                                        .updateFieldInStep(activeStepId, selectedField.id, updated);
                                  },
                                ),
                                _buildCompactSwitchTile(
                                  label: "Visible",
                                  value: selectedField.visible,
                                  onChanged: (val) {
                                    final updated = selectedField!.copy()..visible = val;
                                    ref.read(journeyConfigProvider.notifier)
                                        .updateFieldInStep(activeStepId, selectedField.id, updated);
                                  },
                                ),
                                _buildCompactSwitchTile(
                                  label: "Read Only",
                                  value: selectedField.readOnly,
                                  onChanged: (val) {
                                    final updated = selectedField!.copy()..readOnly = val;
                                    ref.read(journeyConfigProvider.notifier)
                                        .updateFieldInStep(activeStepId, selectedField.id, updated);
                                  },
                                ),
                                _buildCompactSwitchTile(
                                  label: "Disabled",
                                  value: selectedField.disable,
                                  onChanged: (val) {
                                    final updated = selectedField!.copy()..disable = val;
                                    ref.read(journeyConfigProvider.notifier)
                                        .updateFieldInStep(activeStepId, selectedField.id, updated);
                                  },
                                ),
                                _buildCompactSwitchTile(
                                  label: "Hidden",
                                  value: selectedField.hidden,
                                  onChanged: (val) {
                                    final updated = selectedField!.copy()..hidden = val;
                                    ref.read(journeyConfigProvider.notifier)
                                        .updateFieldInStep(activeStepId, selectedField.id, updated);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        if (_isDataComponent(selectedField.type))
                          _buildDataComponentProperties(selectedField, activeStepId),

                        if (_isLayoutComponent(selectedField.type))
                          _buildLayoutComponentProperties(selectedField, activeStepId),

                        _buildEnterpriseFieldProperties(selectedField, activeStepId),

                        if (!isRadioOrSelectionOrDivider)
                          _buildCollapsibleSection(
                            title: "Validations & Input Config",
                            accentColor: RevoTheme.warning,
                            icon: Icons.gpp_maybe_outlined,
                            isExpanded: _showValidations,
                            onToggle: () => setState(() => _showValidations = !_showValidations),
                            children: [
                              _PropertyTextField(
                                label: "Validation Pattern (Regex)",
                                initialValue: selectedField.validationPattern ?? '',
                                hint: "e.g. ^[0-9]{10}\$ or Letters only",
                                onChanged: (val) {
                                  final updated = selectedField!.copy()..validationPattern = val.trim().isEmpty ? null : val.trim();
                                  ref.read(journeyConfigProvider.notifier)
                                      .updateFieldInStep(activeStepId, selectedField.id, updated);
                                },
                              ),
                              const SizedBox(height: 10),
                              _PropertyTextField(
                                label: "Validation Error Message",
                                initialValue: selectedField.errorMessage ?? '',
                                hint: "Message shown on validation failure",
                                onChanged: (val) {
                                  final updated = selectedField!.copy()..errorMessage = val.trim().isEmpty ? null : val.trim();
                                  ref.read(journeyConfigProvider.notifier)
                                      .updateFieldInStep(activeStepId, selectedField.id, updated);
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _PropertyTextField(
                                      label: "Min Length",
                                      initialValue: selectedField.minLength?.toString() ?? '',
                                      hint: "e.g. 2",
                                      onChanged: (val) {
                                        final parsed = int.tryParse(val.trim());
                                        final updated = selectedField!.copy()..minLength = parsed;
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateFieldInStep(activeStepId, selectedField.id, updated);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _PropertyTextField(
                                      label: "Max Length",
                                      initialValue: selectedField.maxLength?.toString() ?? '',
                                      hint: "e.g. 50",
                                      onChanged: (val) {
                                        final parsed = int.tryParse(val.trim());
                                        final updated = selectedField!.copy()..maxLength = parsed;
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateFieldInStep(activeStepId, selectedField.id, updated);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _PropertyDropdownField(
                                      label: "Keyboard Type",
                                      currentValue: selectedField.keyboardType ?? 'text',
                                      items: const ['text', 'number', 'email', 'phone', 'datetime'],
                                      onChanged: (val) {
                                        final updated = selectedField!.copy()..keyboardType = val;
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateFieldInStep(activeStepId, selectedField.id, updated);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _PropertyDropdownField(
                                      label: "Input Action",
                                      currentValue: selectedField.textInputAction ?? 'done',
                                      items: const ['done', 'next', 'search', 'none', 'go', 'send'],
                                      onChanged: (val) {
                                        final updated = selectedField!.copy()..textInputAction = val;
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateFieldInStep(activeStepId, selectedField.id, updated);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _PropertyDropdownField(
                                label: "Text Capitalization",
                                currentValue: selectedField.textCapitalization ?? 'none',
                                items: const ['none', 'characters', 'words', 'sentences'],
                                onChanged: (val) {
                                  final updated = selectedField!.copy()..textCapitalization = val;
                                  ref.read(journeyConfigProvider.notifier)
                                      .updateFieldInStep(activeStepId, selectedField.id, updated);
                                },
                              ),
                              const SizedBox(height: 12),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 2.8,
                                children: [
                                  _buildCompactSwitchTile(
                                    label: "Obscure Text",
                                    value: selectedField.obscureText,
                                    onChanged: (val) {
                                      final updated = selectedField!.copy()..obscureText = val;
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateFieldInStep(activeStepId, selectedField.id, updated);
                                    },
                                  ),
                                  _buildCompactSwitchTile(
                                    label: "Autocorrect",
                                    value: selectedField.autocorrect,
                                    onChanged: (val) {
                                      final updated = selectedField!.copy()..autocorrect = val;
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateFieldInStep(activeStepId, selectedField.id, updated);
                                    },
                                  ),
                                  _buildCompactSwitchTile(
                                    label: "Suggestions",
                                    value: selectedField.enableSuggestions,
                                    onChanged: (val) {
                                      final updated = selectedField!.copy()..enableSuggestions = val;
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateFieldInStep(activeStepId, selectedField.id, updated);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),

                        // Section 4: Options & API Config (Collapsible)
                        if (supportsOptions)
                          _buildCollapsibleSection(
                            title: "Options & API Config",
                            accentColor: RevoTheme.accent,
                            icon: Icons.api_rounded,
                            isExpanded: _showDataOptions,
                            onToggle: () => setState(() => _showDataOptions = !_showDataOptions),
                            children: [
                              _buildDataSourceSelector(selectedField, activeStepId),
                              
                              if (selectedField.useStaticOptions) ...[
                                _buildStaticOptionsList(selectedField, activeStepId),
                              ] else ...[
                                // API integration Tabbed Selector
                                _buildApiTabBar(),
                                
                                if (_apiTabIndex == 0) ...[
                                  // 1. Endpoint settings
                                  _PropertyTextField(
                                    label: "API URL Path",
                                    initialValue: selectedField.dropdownApiUrl ?? '',
                                    hint: "https://api.example.com/dropdown-data",
                                    onChanged: (val) {
                                      final updated = selectedField!.copy()..dropdownApiUrl = val.trim().isEmpty ? null : val.trim();
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateFieldInStep(activeStepId, selectedField.id, updated);
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _buildMethodSelector(selectedField, activeStepId),
                                  const SizedBox(height: 10),
                                  _PropertyTextField(
                                    label: "URL / Query Parameter Key",
                                    initialValue: selectedField.apiParam ?? '',
                                    hint: "e.g. tenantId or searchKey",
                                    onChanged: (val) {
                                      final updated = selectedField!.copy()..apiParam = val.trim().isEmpty ? null : val.trim();
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateFieldInStep(activeStepId, selectedField.id, updated);
                                    },
                                  ),
                                ] else if (_apiTabIndex == 1) ...[
                                  // 2. Headers & Request Body payload
                                  _PropertyTextField(
                                    label: "API Headers (JSON Map)",
                                    initialValue: selectedField.dropdownApiHeaders != null ? json.encode(selectedField.dropdownApiHeaders) : '',
                                    hint: '{"Authorization": "Bearer token", "Accept": "application/json"}',
                                    maxLines: 3,
                                    onChanged: (val) {
                                      setState(() {
                                        _headersError = _validateJsonMap(val);
                                      });
                                      if (_headersError == null) {
                                        try {
                                          if (val.trim().isEmpty) {
                                            final updated = selectedField!.copy()..dropdownApiHeaders = null;
                                            ref.read(journeyConfigProvider.notifier)
                                                .updateFieldInStep(activeStepId, selectedField.id, updated);
                                          } else {
                                            final decoded = json.decode(val);
                                            if (decoded is Map) {
                                              final updatedMap = Map<String, dynamic>.from(decoded);
                                              final updated = selectedField!.copy()..dropdownApiHeaders = updatedMap;
                                              ref.read(journeyConfigProvider.notifier)
                                                  .updateFieldInStep(activeStepId, selectedField.id, updated);
                                            }
                                          }
                                        } catch (_) {}
                                      }
                                    },
                                  ),
                                  if (_headersError != null) ...[
                                    const SizedBox(height: 4),
                                    Text(_headersError!, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 10)),
                                  ],
                                  const SizedBox(height: 10),
                                  _PropertyTextField(
                                    label: "Request Body (JSON String)",
                                    initialValue: selectedField.dropdownApiBody ?? '',
                                    hint: '{"status": "active", "filter": "users"}',
                                    maxLines: 3,
                                    onChanged: (val) {
                                      final updated = selectedField!.copy()..dropdownApiBody = val.trim().isEmpty ? null : val.trim();
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateFieldInStep(activeStepId, selectedField.id, updated);
                                    },
                                  ),
                                ] else ...[
                                  // 3. Mapping & Test Data
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _PropertyTextField(
                                          label: "Value Key",
                                          initialValue: selectedField.dropdownkey ?? 'id',
                                          hint: "e.g. id, code",
                                          onChanged: (val) {
                                            final updated = selectedField!.copy()..dropdownkey = val.trim().isEmpty ? null : val.trim();
                                            ref.read(journeyConfigProvider.notifier)
                                                .updateFieldInStep(activeStepId, selectedField.id, updated);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _PropertyTextField(
                                          label: "Display Value Key",
                                          initialValue: selectedField.dropdownValue ?? 'title',
                                          hint: "e.g. title, name",
                                          onChanged: (val) {
                                            final updated = selectedField!.copy()..dropdownValue = val.trim().isEmpty ? null : val.trim();
                                            ref.read(journeyConfigProvider.notifier)
                                                .updateFieldInStep(activeStepId, selectedField.id, updated);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _PropertyTextField(
                                    label: "List Key (optional)",
                                    initialValue: selectedField.dropdownListKey ?? '',
                                    hint: "e.g. data.items, result",
                                    onChanged: (val) {
                                      final updated = selectedField!.copy()..dropdownListKey = val.trim().isEmpty ? null : val.trim();
                                      ref.read(journeyConfigProvider.notifier)
                                          .updateFieldInStep(activeStepId, selectedField.id, updated);
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _PropertyTextField(
                                    label: "Response JSON Data (Test/Preloaded)",
                                    initialValue: selectedField.dropdowndata != null ? json.encode(selectedField.dropdowndata) : '',
                                    hint: '[{"id": 1, "title": "Option One"}, {"id": 2, "title": "Option Two"}]',
                                    maxLines: 4,
                                    onChanged: (val) {
                                      setState(() {
                                        _testDataError = _validateJsonResponseData(val);
                                      });
                                      if (_testDataError == null) {
                                        try {
                                          if (val.trim().isEmpty) {
                                            final updated = selectedField!.copy()..dropdowndata = null;
                                            ref.read(journeyConfigProvider.notifier)
                                                .updateFieldInStep(activeStepId, selectedField.id, updated);
                                          } else {
                                            final decoded = json.decode(val);
                                            if (decoded is List) {
                                              final updatedList = decoded.map((item) {
                                                return item is Map ? Map<String, dynamic>.from(item) : item;
                                              }).toList();
                                              final updated = selectedField!.copy()..dropdowndata = updatedList;
                                              ref.read(journeyConfigProvider.notifier)
                                                  .updateFieldInStep(activeStepId, selectedField.id, updated);
                                            } else if (decoded is Map) {
                                              final updatedMap = Map<String, dynamic>.from(decoded);
                                              final updated = selectedField!.copy()..dropdowndata = updatedMap;
                                              ref.read(journeyConfigProvider.notifier)
                                                  .updateFieldInStep(activeStepId, selectedField.id, updated);
                                            }
                                          }
                                        } catch (_) {}
                                      }
                                    },
                                  ),
                                  if (_testDataError != null) ...[
                                    const SizedBox(height: 4),
                                    Text(_testDataError!, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 10)),
                                  ],
                                  const SizedBox(height: 10),
                                  Text(
                                    "Live Response Parsing Preview:",
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildResponsePreview(selectedField),
                                ],
                                
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: RevoTheme.cardBg,
                                          foregroundColor: RevoTheme.textPrimary,
                                          side: BorderSide(color: RevoTheme.primaryLight.withValues(alpha:0.5)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        onPressed: _testingApi ? null : () async {
                                          setState(() {
                                            _testingApi = true;
                                            _apiTestResult = null;
                                          });
                                          
                                          final hasUrl = selectedField!.dropdownApiUrl != null && selectedField.dropdownApiUrl!.isNotEmpty;
                                          if (!hasUrl) {
                                            setState(() {
                                              _testingApi = false;
                                              _apiTestSuccess = false;
                                              _apiTestResult = "Error: API URL Path is required to test.";
                                            });
                                            return;
                                          }
                                          
                                          try {
                                            final url = Uri.parse(selectedField.dropdownApiUrl!);
                                            final method = (selectedField.dropdownApiMethod ?? 'GET').toUpperCase();
                                            
                                            final Map<String, String> headers = {};
                                            if (selectedField.dropdownApiHeaders != null) {
                                              selectedField.dropdownApiHeaders!.forEach((k, v) {
                                                headers[k] = v.toString();
                                              });
                                            }
                                            if (!headers.containsKey('Content-Type') && method != 'GET') {
                                              headers['Content-Type'] = 'application/json';
                                            }

                                            final body = selectedField.dropdownApiBody;

                                            http.Response response;
                                            if (method == 'POST') {
                                              response = await http.post(url, headers: headers, body: body);
                                            } else if (method == 'PUT') {
                                              response = await http.put(url, headers: headers, body: body);
                                            } else if (method == 'DELETE') {
                                              response = await http.delete(url, headers: headers, body: body);
                                            } else {
                                              response = await http.get(url, headers: headers);
                                            }

                                            if (response.statusCode >= 200 && response.statusCode < 300) {
                                              final decoded = json.decode(response.body);
                                              
                                              dynamic normalizedData;
                                              if (decoded is List) {
                                                normalizedData = decoded.map((e) => e is Map ? Map<String, dynamic>.from(e) : e).toList();
                                              } else if (decoded is Map) {
                                                normalizedData = Map<String, dynamic>.from(decoded);
                                              } else {
                                                normalizedData = decoded;
                                              }

                                              final updated = selectedField.copy()..dropdowndata = normalizedData;
                                              ref.read(journeyConfigProvider.notifier)
                                                  .updateFieldInStep(activeStepId, selectedField.id, updated);
                                              
                                              final options = updated.getResolvedOptions();
                                              setState(() {
                                                _testingApi = false;
                                                _apiTestSuccess = true;
                                                _apiTestResult = "Connection successful!\nStatus: ${response.statusCode}\nParsed ${options.length} option(s) successfully and saved to state.";
                                              });
                                            } else {
                                              setState(() {
                                                _testingApi = false;
                                                _apiTestSuccess = false;
                                                _apiTestResult = "HTTP Error: Status ${response.statusCode}\nResponse: ${response.body}";
                                              });
                                            }
                                          } catch (e) {
                                            setState(() {
                                              _testingApi = false;
                                              _apiTestSuccess = false;
                                              _apiTestResult = "API Test failed: ${e.toString()}";
                                            });
                                          }
                                        },
                                        icon: _testingApi 
                                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Icon(Icons.bolt_rounded, size: 14),
                                        label: Text("Test Connection", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: RevoTheme.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("API config for '${selectedField!.label}' saved successfully!"),
                                              backgroundColor: RevoTheme.secondary,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                                        label: Text("Submit Config", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_apiTestResult != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _apiTestSuccess 
                                          ? Colors.greenAccent.withValues(alpha:0.08) 
                                          : Colors.redAccent.withValues(alpha:0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _apiTestSuccess 
                                            ? Colors.greenAccent.withValues(alpha:0.3) 
                                            : Colors.redAccent.withValues(alpha:0.3),
                                      ),
                                    ),
                                    child: Text(
                                      _apiTestResult!,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: _apiTestSuccess ? Colors.greenAccent : Colors.redAccent,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ]
                              ],
                            ],
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required Color accentColor,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isExpanded ? accentColor.withValues(alpha:0.2) : RevoTheme.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: isExpanded ? accentColor : RevoTheme.textSecondary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isExpanded ? accentColor : RevoTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                    color: isExpanded ? accentColor : RevoTheme.textSecondary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(color: RevoTheme.cardBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isDataComponent(String type) {
    return const {'table_grid', 'repeater', 'timeline'}.contains(type);
  }

  JourneyField? _findFieldById(List<JourneyField> fields, String? fieldId) {
    if (fieldId == null) return null;
    for (final field in fields) {
      if (field.id == fieldId) return field;
      final nested = field.nestedFields;
      if (nested != null && nested.isNotEmpty) {
        final match = _findFieldById(nested, fieldId);
        if (match != null) return match;
      }
    }
    return null;
  }

  bool _isLayoutComponent(String type) {
    return const {'section', 'card', 'tabs', 'accordion'}.contains(type);
  }

  Map<String, dynamic> _componentConfig(JourneyField field) {
    final config = Map<String, dynamic>.from(field.componentConfig ?? {});
    switch (field.type) {
      case 'table_grid':
        return {
          'columns': [
            {'label': '#', 'fieldId': 'rowIndex', 'type': 'number', 'required': false},
            {'label': 'Registration No.', 'fieldId': 'registrationNo', 'type': 'text', 'required': true},
            {'label': 'Manufacturer', 'fieldId': 'manufacturer', 'type': 'dropdown', 'required': true},
          ],
          'allowAddRow': true,
          'allowEditRow': true,
          'allowDeleteRow': true,
          'allowViewRow': true,
          'inlineEdit': true,
          'bulkSelection': true,
          'exportCsv': true,
          'search': true,
          'sorting': true,
          'filtering': true,
          'stickyColumns': true,
          'dataSource': 'manual',
          'gridApiUrl': '',
          'gridApiMethod': 'GET',
          'gridApiHeaders': {},
          'gridApiBody': '',
          'gridApiListKey': 'data',
          'apiPagination': false,
          'dynamicRowValidation': true,
          'rowActions': ['view', 'edit', 'delete'],
          'minRows': 0,
          'maxRows': 10,
          'pagination': true,
          'rowsPerPage': 10,
          'apiPageParam': 'page',
          'apiPageSizeParam': 'limit',
          ...config,
        };
      case 'repeater':
        return {
          'itemLabel': 'Item',
          'addButtonLabel': 'Add Item',
          'fields': [
            {'label': 'Name', 'fieldId': 'name', 'type': 'text', 'required': true},
            {'label': 'Value', 'fieldId': 'value', 'type': 'text', 'required': false},
          ],
          'minItems': 0,
          'maxItems': 5,
          'allowAdd': true,
          'allowRemove': true,
          'allowReorder': true,
          'showItemIndex': true,
          'collapsibleItems': true,
          'layout': 'singleColumn',
          ...config,
        };
      case 'timeline':
        return {
          'orientation': 'vertical',
          'markerStyle': 'numbered',
          'showTimestamp': true,
          'showConnector': true,
          'allowFutureSteps': true,
          'defaultStatus': 'pending',
          'itemsSource': 'static',
          'titleField': 'title',
          'dateField': 'date',
          'statusField': 'status',
          'items': [
            {'title': 'Started', 'description': 'Journey started', 'status': 'completed'},
            {'title': 'In Progress', 'description': 'Current step', 'status': 'active'},
            {'title': 'Completed', 'description': 'Final state', 'status': 'pending'},
          ],
          ...config,
        };
      case 'section':
        return {
          'headingLevel': 'H2',
          'collapsible': false,
          'defaultExpanded': true,
          'showDivider': true,
          'padding': 'medium',
          ...config,
        };
      case 'card':
        return {
          'variant': 'outlined',
          'showHeader': true,
          'showFooter': false,
          'padding': 'medium',
          ...config,
        };
      case 'tabs':
        return {
          'variant': 'underline',
          'alignment': 'start',
          'persistActiveTab': true,
          'tabs': ['Tab 1', 'Tab 2'],
          ...config,
        };
      case 'accordion':
        return {
          'allowMultipleOpen': false,
          'defaultExpanded': false,
          'iconPosition': 'right',
          'variant': 'bordered',
          ...config,
        };
      default:
        return config;
    }
  }

  void _updateComponentConfig(JourneyField field, String activeStepId, String key, dynamic value) {
    final updatedConfig = _componentConfig(field)..[key] = value;
    final updated = field.copy()..componentConfig = updatedConfig;
    ref.read(journeyConfigProvider.notifier).updateFieldInStep(activeStepId, field.id, updated);
  }

  int _intConfig(Map<String, dynamic> config, String key, int fallback) {
    final value = config[key];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  bool _boolConfig(Map<String, dynamic> config, String key, bool fallback) {
    final value = config[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  Map<String, dynamic>? _tryJsonMap(String value) {
    if (value.trim().isEmpty) return null;
    final decoded = json.decode(value);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  }

  List<Map<String, dynamic>>? _tryJsonMapList(String value) {
    if (value.trim().isEmpty) return null;
    final decoded = json.decode(value);
    if (decoded is! List) return null;
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<String>? _csvToList(String value) {
    final list = value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return list.isEmpty ? null : list;
  }

  void _updateEnterpriseField(JourneyField field, String activeStepId, void Function(JourneyField updated) mutate) {
    final updated = field.copy();
    mutate(updated);
    ref.read(journeyConfigProvider.notifier).updateFieldInStep(activeStepId, field.id, updated);
  }

  Widget _buildEnterpriseFieldProperties(JourneyField field, String activeStepId) {
    return _buildCollapsibleSection(
      title: "Enterprise Field Rules",
      accentColor: RevoTheme.primaryLight,
      icon: Icons.account_tree_outlined,
      isExpanded: _showEnterpriseSettings,
      onToggle: () => setState(() => _showEnterpriseSettings = !_showEnterpriseSettings),
      children: [
        Row(
          children: [
            Expanded(
              child: _PropertyTextField(
                label: "Group ID",
                initialValue: field.groupId ?? '',
                hint: "customerDetails",
                onChanged: (val) => _updateEnterpriseField(field, activeStepId, (updated) => updated.groupId = val.trim().isEmpty ? null : val.trim()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PropertyTextField(
                label: "Section ID",
                initialValue: field.sectionId ?? '',
                hint: "kyc",
                onChanged: (val) => _updateEnterpriseField(field, activeStepId, (updated) => updated.sectionId = val.trim().isEmpty ? null : val.trim()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildCompactSwitchTile(
          label: "Repeatable Group",
          value: field.repeatableGroup,
          onChanged: (val) => _updateEnterpriseField(field, activeStepId, (updated) => updated.repeatableGroup = val),
        ),
        const SizedBox(height: 10),
        _PropertyTextField(
          label: "Formula / Calculated Value",
          initialValue: field.formula ?? '',
          hint: "sum(lineItems.amount)",
          onChanged: (val) => _updateEnterpriseField(field, activeStepId, (updated) => updated.formula = val.trim().isEmpty ? null : val.trim()),
        ),
        const SizedBox(height: 10),
        _PropertyTextField(
          label: "Dynamic Expression",
          initialValue: field.expression ?? '',
          hint: "age >= 18 && country == 'IN'",
          onChanged: (val) => _updateEnterpriseField(field, activeStepId, (updated) => updated.expression = val.trim().isEmpty ? null : val.trim()),
        ),
        const SizedBox(height: 10),
        _PropertyTextField(
          label: "Dynamic Default Expression",
          initialValue: field.defaultValueExpression ?? '',
          hint: "currentUser.email",
          onChanged: (val) => _updateEnterpriseField(field, activeStepId, (updated) => updated.defaultValueExpression = val.trim().isEmpty ? null : val.trim()),
        ),
        const SizedBox(height: 10),
        _PropertyTextField(
          label: "Depends On",
          initialValue: field.dependsOn ?? '',
          hint: "country",
          onChanged: (val) => _updateEnterpriseField(field, activeStepId, (updated) => updated.dependsOn = val.trim().isEmpty ? null : val.trim()),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PropertyTextField(
                label: "Visible Roles",
                initialValue: field.visibleForRoles?.join(', ') ?? '',
                hint: "admin, maker",
                onChanged: (val) => _updateEnterpriseField(field, activeStepId, (updated) => updated.visibleForRoles = _csvToList(val)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PropertyTextField(
                label: "Editable Roles",
                initialValue: field.editableForRoles?.join(', ') ?? '',
                hint: "admin, checker",
                onChanged: (val) => _updateEnterpriseField(field, activeStepId, (updated) => updated.editableForRoles = _csvToList(val)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _PropertyTextField(
          label: "Async Validation JSON",
          initialValue: field.asyncValidation == null ? '' : json.encode(field.asyncValidation),
          hint: '{"url": "/validate-pan", "method": "POST"}',
          maxLines: 3,
          onChanged: (val) {
            try {
              final parsed = _tryJsonMap(val);
              _updateEnterpriseField(field, activeStepId, (updated) => updated.asyncValidation = parsed);
            } catch (_) {}
          },
        ),
        const SizedBox(height: 10),
        _PropertyTextField(
          label: "Cascade Config JSON",
          initialValue: field.cascadeConfig == null ? '' : json.encode(field.cascadeConfig),
          hint: '{"parentField": "country", "param": "countryId"}',
          maxLines: 3,
          onChanged: (val) {
            try {
              final parsed = _tryJsonMap(val);
              _updateEnterpriseField(field, activeStepId, (updated) => updated.cascadeConfig = parsed);
            } catch (_) {}
          },
        ),
        const SizedBox(height: 10),
        _PropertyTextField(
          label: "Localization JSON",
          initialValue: field.localization == null ? '' : json.encode(field.localization),
          hint: '{"en": {"label": "Name"}, "hi": {"label": "Naam"}}',
          maxLines: 3,
          onChanged: (val) {
            try {
              final parsed = _tryJsonMap(val);
              _updateEnterpriseField(field, activeStepId, (updated) => updated.localization = parsed);
            } catch (_) {}
          },
        ),
        const SizedBox(height: 10),
        _PropertyTextField(
          label: "Conditional Validations JSON",
          initialValue: field.conditionalValidations == null ? '' : json.encode(field.conditionalValidations),
          hint: '[{"if": "age < 18", "type": "required", "message": "Guardian required"}]',
          maxLines: 3,
          onChanged: (val) {
            try {
              final parsed = _tryJsonMapList(val);
              _updateEnterpriseField(field, activeStepId, (updated) => updated.conditionalValidations = parsed);
            } catch (_) {}
          },
        ),
      ],
    );
  }

  Future<void> _testGridApiConnection(JourneyField field, String activeStepId) async {
    final config = _componentConfig(field);
    final urlText = config['gridApiUrl']?.toString().trim() ?? '';
    if (urlText.isEmpty) {
      setState(() {
        _apiTestSuccess = false;
        _apiTestResult = "Error: Grid API URL is required.";
      });
      return;
    }

    setState(() {
      _testingApi = true;
      _apiTestResult = null;
    });

    try {
      final uri = _gridApiUri(urlText, config);
      final method = (config['gridApiMethod']?.toString() ?? 'GET').toUpperCase();
      final headers = _gridApiHeaders(config['gridApiHeaders']);
      if (!headers.containsKey('Content-Type') && method != 'GET') {
        headers['Content-Type'] = 'application/json';
      }
      final bodyText = config['gridApiBody']?.toString().trim() ?? '';
      final body = bodyText.isEmpty ? null : bodyText;

      http.Response response;
      if (method == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else if (method == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else if (method == 'DELETE') {
        response = await http.delete(uri, headers: headers, body: body);
      } else {
        response = await http.get(uri, headers: headers);
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        setState(() {
          _testingApi = false;
          _apiTestSuccess = false;
          _apiTestResult = "HTTP Error: Status ${response.statusCode}\nResponse: ${response.body}";
        });
        return;
      }

      final decoded = json.decode(response.body);
      final rows = _extractGridRows(decoded, config['gridApiListKey']?.toString() ?? '');
      final updatedConfig = {
        ...config,
        'gridApiSampleData': rows,
        'dataSource': 'api',
      };
      final updated = field.copy()
        ..api = true
        ..dropdownApiUrl = urlText
        ..dropdownApiMethod = method
        ..dropdownApiHeaders = headers
        ..dropdownApiBody = body
        ..dropdownListKey = config['gridApiListKey']?.toString()
        ..dropdowndata = rows
        ..componentConfig = updatedConfig;
      ref.read(journeyConfigProvider.notifier).updateFieldInStep(activeStepId, field.id, updated);

      setState(() {
        _testingApi = false;
        _apiTestSuccess = true;
        _apiTestResult = "Connection successful!\nStatus: ${response.statusCode}\nParsed ${rows.length} grid row(s) and saved sample data.";
      });
    } catch (e) {
      setState(() {
        _testingApi = false;
        _apiTestSuccess = false;
        _apiTestResult = "Grid API test failed: ${e.toString()}";
      });
    }
  }

  void _submitGridApiConfig(JourneyField field, String activeStepId) {
    final config = _componentConfig(field);
    final sampleData = config['gridApiSampleData'];
    final updated = field.copy()
      ..api = true
      ..dropdownApiUrl = config['gridApiUrl']?.toString()
      ..dropdownApiMethod = config['gridApiMethod']?.toString()
      ..dropdownApiHeaders = _gridApiHeaders(config['gridApiHeaders'])
      ..dropdownApiBody = config['gridApiBody']?.toString()
      ..dropdownListKey = config['gridApiListKey']?.toString()
      ..dropdowndata = sampleData
      ..componentConfig = {...config, 'dataSource': 'api'};
    ref.read(journeyConfigProvider.notifier).updateFieldInStep(activeStepId, field.id, updated);
    setState(() {
      _apiTestSuccess = true;
      _apiTestResult = "Grid API config submitted and saved for code generation.";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Grid API config for '${field.label}' submitted."), backgroundColor: RevoTheme.secondary),
    );
  }

  Uri _gridApiUri(String urlText, Map<String, dynamic> config) {
    final uri = Uri.parse(urlText);
    if (config['apiPagination'] != true) return uri;
    final pageParam = config['apiPageParam']?.toString() ?? 'page';
    final sizeParam = config['apiPageSizeParam']?.toString() ?? 'limit';
    final rowsPerPage = config['rowsPerPage']?.toString() ?? '10';
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      if (pageParam.isNotEmpty) pageParam: '1',
      if (sizeParam.isNotEmpty) sizeParam: rowsPerPage,
    });
  }

  Map<String, String> _gridApiHeaders(dynamic rawHeaders) {
    final headers = <String, String>{};
    if (rawHeaders is Map) {
      rawHeaders.forEach((key, value) => headers[key.toString()] = value.toString());
    }
    return headers;
  }

  List<Map<String, dynamic>> _extractGridRows(dynamic decoded, String listKey) {
    dynamic source = decoded;
    if (decoded is Map && listKey.trim().isNotEmpty) {
      source = _readJsonPath(decoded, listKey) ?? decoded[listKey];
    }
    if (source is! List && decoded is Map) {
      for (final key in ['data', 'items', 'results', 'rows']) {
        if (decoded[key] is List) {
          source = decoded[key];
          break;
        }
      }
    }
    if (source is! List) return <Map<String, dynamic>>[];
    return source.map<Map<String, dynamic>>((item) {
      if (item is Map) return Map<String, dynamic>.from(item);
      return {'value': item.toString()};
    }).toList();
  }

  dynamic _readJsonPath(dynamic source, String path) {
    if (path.trim().isEmpty) return null;
    dynamic cursor = source;
    for (final part in path.split('.')) {
      if (cursor is Map) {
        cursor = cursor[part];
      } else {
        return null;
      }
    }
    return cursor;
  }

  Widget _buildDataComponentProperties(JourneyField field, String activeStepId) {
    switch (field.type) {
      case 'table_grid':
        return _buildTableGridProperties(field, activeStepId);
      case 'repeater':
        return _buildRepeaterProperties(field, activeStepId);
      case 'timeline':
        return _buildTimelineProperties(field, activeStepId);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTableGridProperties(JourneyField field, String activeStepId) {
    final config = _componentConfig(field);
    final columns = (config['columns'] as List)
        .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
        .where((item) => item.isNotEmpty)
        .toList();

    return _buildCollapsibleSection(
      title: "Table / Grid Properties",
      accentColor: RevoTheme.accent,
      icon: Icons.table_chart_outlined,
      isExpanded: _showDataComponentSettings,
      onToggle: () => setState(() => _showDataComponentSettings = !_showDataComponentSettings),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Columns", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary)),
            TextButton.icon(
              onPressed: () {
                final updatedColumns = List<Map<String, dynamic>>.from(columns);
                final next = updatedColumns.length + 1;
                updatedColumns.add({
                  'label': 'Column $next',
                  'fieldId': 'column$next',
                  'type': 'text',
                  'required': false,
                  'sortable': true,
                  'filterable': true,
                  'sticky': false,
                });
                _updateComponentConfig(field, activeStepId, 'columns', updatedColumns);
              },
              icon: const Icon(Icons.add_rounded, size: 14),
              label: Text("Add Column", style: GoogleFonts.inter(fontSize: 10)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...columns.asMap().entries.map((entry) {
          final index = entry.key;
          final column = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: RevoTheme.sidebarBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PropertyTextField(
                        label: "Label",
                        initialValue: column['label']?.toString() ?? '',
                        onChanged: (val) {
                          final updatedColumns = List<Map<String, dynamic>>.from(columns);
                          updatedColumns[index] = {...column, 'label': val.trim()};
                          _updateComponentConfig(field, activeStepId, 'columns', updatedColumns);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PropertyTextField(
                        label: "Field ID",
                        initialValue: column['fieldId']?.toString() ?? '',
                        onChanged: (val) {
                          final updatedColumns = List<Map<String, dynamic>>.from(columns);
                          updatedColumns[index] = {...column, 'fieldId': val.trim()};
                          _updateComponentConfig(field, activeStepId, 'columns', updatedColumns);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _PropertyDropdownField(
                        label: "Type",
                        currentValue: column['type']?.toString() ?? 'text',
                        items: const ['text', 'number', 'dropdown', 'date', 'checkbox'],
                        onChanged: (val) {
                          final updatedColumns = List<Map<String, dynamic>>.from(columns);
                          updatedColumns[index] = {...column, 'type': val};
                          _updateComponentConfig(field, activeStepId, 'columns', updatedColumns);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactSwitchTile(
                        label: "Required",
                        value: column['required'] == true,
                        onChanged: (val) {
                          final updatedColumns = List<Map<String, dynamic>>.from(columns);
                          updatedColumns[index] = {...column, 'required': val};
                          _updateComponentConfig(field, activeStepId, 'columns', updatedColumns);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactSwitchTile(
                        label: "Sticky",
                        value: column['sticky'] == true,
                        onChanged: (val) {
                          final updatedColumns = List<Map<String, dynamic>>.from(columns);
                          updatedColumns[index] = {...column, 'sticky': val};
                          _updateComponentConfig(field, activeStepId, 'columns', updatedColumns);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      onPressed: columns.length <= 1
                          ? null
                          : () {
                              final updatedColumns = List<Map<String, dynamic>>.from(columns)..removeAt(index);
                              _updateComponentConfig(field, activeStepId, 'columns', updatedColumns);
                            },
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: [
            _buildCompactSwitchTile(label: "Allow Add", value: _boolConfig(config, 'allowAddRow', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'allowAddRow', val)),
            _buildCompactSwitchTile(label: "Inline Edit", value: _boolConfig(config, 'inlineEdit', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'inlineEdit', val)),
            _buildCompactSwitchTile(label: "Allow Delete", value: _boolConfig(config, 'allowDeleteRow', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'allowDeleteRow', val)),
            _buildCompactSwitchTile(label: "Bulk Select", value: _boolConfig(config, 'bulkSelection', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'bulkSelection', val)),
            _buildCompactSwitchTile(label: "Export CSV", value: _boolConfig(config, 'exportCsv', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'exportCsv', val)),
            _buildCompactSwitchTile(label: "Search", value: _boolConfig(config, 'search', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'search', val)),
            _buildCompactSwitchTile(label: "Sorting", value: _boolConfig(config, 'sorting', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'sorting', val)),
            _buildCompactSwitchTile(label: "Filtering", value: _boolConfig(config, 'filtering', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'filtering', val)),
            _buildCompactSwitchTile(label: "Sticky Columns", value: _boolConfig(config, 'stickyColumns', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'stickyColumns', val)),
            _buildCompactSwitchTile(label: "Pagination", value: _boolConfig(config, 'pagination', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'pagination', val)),
            _buildCompactSwitchTile(label: "API Pagination", value: _boolConfig(config, 'apiPagination', false), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'apiPagination', val)),
            _buildCompactSwitchTile(label: "Row Validation", value: _boolConfig(config, 'dynamicRowValidation', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'dynamicRowValidation', val)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _numberConfigField(field, activeStepId, config, 'minRows', 'Min Rows', 0)),
            const SizedBox(width: 8),
            Expanded(child: _numberConfigField(field, activeStepId, config, 'maxRows', 'Max Rows', 10)),
            const SizedBox(width: 8),
            Expanded(child: _numberConfigField(field, activeStepId, config, 'rowsPerPage', 'Rows/Page', 10)),
          ],
        ),
        const SizedBox(height: 10),
        _PropertyTextField(
          label: "Row Actions",
          initialValue: (config['rowActions'] is List ? (config['rowActions'] as List).join(', ') : config['rowActions']?.toString()) ?? '',
          hint: "view, edit, delete, duplicate",
          onChanged: (val) {
            final actions = val
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList();
            _updateComponentConfig(field, activeStepId, 'rowActions', actions);
          },
        ),
        const SizedBox(height: 10),
        _PropertyDropdownField(
          label: "Data Source",
          currentValue: config['dataSource']?.toString() ?? 'manual',
          items: const ['manual', 'api'],
          onChanged: (val) => _updateComponentConfig(field, activeStepId, 'dataSource', val),
        ),
        if ((config['dataSource']?.toString() ?? 'manual') == 'api') ...[
          const SizedBox(height: 10),
          _PropertyTextField(
            label: "Grid API URL",
            initialValue: config['gridApiUrl']?.toString() ?? '',
            hint: "https://api.example.com/users",
            onChanged: (val) => _updateComponentConfig(field, activeStepId, 'gridApiUrl', val.trim()),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PropertyDropdownField(
                  label: "Grid API Method",
                  currentValue: config['gridApiMethod']?.toString() ?? 'GET',
                  items: const ['GET', 'POST', 'PUT', 'DELETE'],
                  onChanged: (val) => _updateComponentConfig(field, activeStepId, 'gridApiMethod', val),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PropertyTextField(
                  label: "Response List Key",
                  initialValue: config['gridApiListKey']?.toString() ?? '',
                  hint: "data.items",
                  onChanged: (val) => _updateComponentConfig(field, activeStepId, 'gridApiListKey', val.trim()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PropertyTextField(
            label: "Grid API Headers (JSON)",
            initialValue: config['gridApiHeaders'] == null || (config['gridApiHeaders'] is Map && (config['gridApiHeaders'] as Map).isEmpty)
                ? ''
                : json.encode(config['gridApiHeaders']),
            hint: '{"Authorization": "Bearer token"}',
            maxLines: 3,
            onChanged: (val) {
              try {
                final decoded = val.trim().isEmpty ? <String, dynamic>{} : json.decode(val);
                if (decoded is Map) {
                  _updateComponentConfig(field, activeStepId, 'gridApiHeaders', Map<String, dynamic>.from(decoded));
                }
              } catch (_) {}
            },
          ),
          const SizedBox(height: 10),
          _PropertyTextField(
            label: "Grid API Body (JSON)",
            initialValue: config['gridApiBody']?.toString() ?? '',
            hint: '{"status": "active"}',
            maxLines: 3,
            onChanged: (val) => _updateComponentConfig(field, activeStepId, 'gridApiBody', val.trim()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RevoTheme.cardBg,
                    foregroundColor: RevoTheme.textPrimary,
                    side: BorderSide(color: RevoTheme.primaryLight.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _testingApi ? null : () => _testGridApiConnection(field, activeStepId),
                  icon: _testingApi
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.bolt_rounded, size: 14),
                  label: Text("Test Connection", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RevoTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _submitGridApiConfig(field, activeStepId),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                  label: Text("Submit Config", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          if (_apiTestResult != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _apiTestSuccess ? Colors.greenAccent.withValues(alpha: 0.08) : Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _apiTestSuccess ? Colors.greenAccent.withValues(alpha: 0.25) : Colors.redAccent.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                _apiTestResult!,
                style: GoogleFonts.inter(fontSize: 10, color: _apiTestSuccess ? Colors.greenAccent : Colors.redAccent),
              ),
            ),
          ],
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PropertyTextField(
                label: "API Page Param",
                initialValue: config['apiPageParam']?.toString() ?? 'page',
                onChanged: (val) => _updateComponentConfig(field, activeStepId, 'apiPageParam', val.trim()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PropertyTextField(
                label: "API Size Param",
                initialValue: config['apiPageSizeParam']?.toString() ?? 'limit',
                onChanged: (val) => _updateComponentConfig(field, activeStepId, 'apiPageSizeParam', val.trim()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRepeaterProperties(JourneyField field, String activeStepId) {
    final config = _componentConfig(field);
    final fields = (config['fields'] as List)
        .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
        .where((item) => item.isNotEmpty)
        .toList();
    return _buildCollapsibleSection(
      title: "Repeater Properties",
      accentColor: RevoTheme.accent,
      icon: Icons.view_week_outlined,
      isExpanded: _showDataComponentSettings,
      onToggle: () => setState(() => _showDataComponentSettings = !_showDataComponentSettings),
      children: [
        Row(
          children: [
            Expanded(child: _textConfigField(field, activeStepId, config, 'itemLabel', 'Item Label')),
            const SizedBox(width: 8),
            Expanded(child: _textConfigField(field, activeStepId, config, 'addButtonLabel', 'Add Button')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _numberConfigField(field, activeStepId, config, 'minItems', 'Min Items', 0)),
            const SizedBox(width: 8),
            Expanded(child: _numberConfigField(field, activeStepId, config, 'maxItems', 'Max Items', 5)),
          ],
        ),
        const SizedBox(height: 10),
        _PropertyDropdownField(
          label: "Layout",
          currentValue: config['layout']?.toString() ?? 'singleColumn',
          items: const ['singleColumn', 'twoColumn', 'compact', 'cardList'],
          onChanged: (val) => _updateComponentConfig(field, activeStepId, 'layout', val),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Repeated Fields", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary)),
            TextButton.icon(
              onPressed: () {
                final updatedFields = List<Map<String, dynamic>>.from(fields);
                final next = updatedFields.length + 1;
                updatedFields.add({'label': 'Field $next', 'fieldId': 'field$next', 'type': 'text', 'required': false});
                _updateComponentConfig(field, activeStepId, 'fields', updatedFields);
              },
              icon: const Icon(Icons.add_rounded, size: 14),
              label: Text("Add Field", style: GoogleFonts.inter(fontSize: 10)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...fields.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: RevoTheme.sidebarBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PropertyTextField(
                        label: "Label",
                        initialValue: item['label']?.toString() ?? '',
                        onChanged: (val) {
                          final updatedFields = List<Map<String, dynamic>>.from(fields);
                          updatedFields[index] = {...item, 'label': val.trim()};
                          _updateComponentConfig(field, activeStepId, 'fields', updatedFields);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PropertyTextField(
                        label: "Field ID",
                        initialValue: item['fieldId']?.toString() ?? '',
                        onChanged: (val) {
                          final updatedFields = List<Map<String, dynamic>>.from(fields);
                          updatedFields[index] = {...item, 'fieldId': val.trim()};
                          _updateComponentConfig(field, activeStepId, 'fields', updatedFields);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _PropertyDropdownField(
                        label: "Type",
                        currentValue: item['type']?.toString() ?? 'text',
                        items: const ['text', 'number', 'dropdown', 'date', 'checkbox', 'file'],
                        onChanged: (val) {
                          final updatedFields = List<Map<String, dynamic>>.from(fields);
                          updatedFields[index] = {...item, 'type': val};
                          _updateComponentConfig(field, activeStepId, 'fields', updatedFields);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactSwitchTile(
                        label: "Required",
                        value: item['required'] == true,
                        onChanged: (val) {
                          final updatedFields = List<Map<String, dynamic>>.from(fields);
                          updatedFields[index] = {...item, 'required': val};
                          _updateComponentConfig(field, activeStepId, 'fields', updatedFields);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      onPressed: fields.length <= 1
                          ? null
                          : () {
                              final updatedFields = List<Map<String, dynamic>>.from(fields)..removeAt(index);
                              _updateComponentConfig(field, activeStepId, 'fields', updatedFields);
                            },
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: [
            _buildCompactSwitchTile(label: "Allow Add", value: _boolConfig(config, 'allowAdd', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'allowAdd', val)),
            _buildCompactSwitchTile(label: "Allow Remove", value: _boolConfig(config, 'allowRemove', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'allowRemove', val)),
            _buildCompactSwitchTile(label: "Allow Reorder", value: _boolConfig(config, 'allowReorder', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'allowReorder', val)),
            _buildCompactSwitchTile(label: "Show Index", value: _boolConfig(config, 'showItemIndex', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'showItemIndex', val)),
            _buildCompactSwitchTile(label: "Collapsible", value: _boolConfig(config, 'collapsibleItems', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'collapsibleItems', val)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineProperties(JourneyField field, String activeStepId) {
    final config = _componentConfig(field);
    final items = (config['items'] as List)
        .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
        .where((item) => item.isNotEmpty)
        .toList();
    return _buildCollapsibleSection(
      title: "Timeline Properties",
      accentColor: RevoTheme.accent,
      icon: Icons.format_list_bulleted_rounded,
      isExpanded: _showDataComponentSettings,
      onToggle: () => setState(() => _showDataComponentSettings = !_showDataComponentSettings),
      children: [
        Row(
          children: [
            Expanded(
              child: _PropertyDropdownField(
                label: "Orientation",
                currentValue: config['orientation']?.toString() ?? 'vertical',
                items: const ['vertical', 'horizontal'],
                onChanged: (val) => _updateComponentConfig(field, activeStepId, 'orientation', val),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PropertyDropdownField(
                label: "Marker Style",
                currentValue: config['markerStyle']?.toString() ?? 'numbered',
                items: const ['numbered', 'dot', 'icon'],
                onChanged: (val) => _updateComponentConfig(field, activeStepId, 'markerStyle', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PropertyDropdownField(
                label: "Default Status",
                currentValue: config['defaultStatus']?.toString() ?? 'pending',
                items: const ['pending', 'active', 'completed', 'failed'],
                onChanged: (val) => _updateComponentConfig(field, activeStepId, 'defaultStatus', val),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PropertyDropdownField(
                label: "Items Source",
                currentValue: config['itemsSource']?.toString() ?? 'static',
                items: const ['static', 'api', 'journeySteps'],
                onChanged: (val) => _updateComponentConfig(field, activeStepId, 'itemsSource', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _textConfigField(field, activeStepId, config, 'titleField', 'Title Key')),
            const SizedBox(width: 8),
            Expanded(child: _textConfigField(field, activeStepId, config, 'dateField', 'Date Key')),
            const SizedBox(width: 8),
            Expanded(child: _textConfigField(field, activeStepId, config, 'statusField', 'Status Key')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Static Timeline Items", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary)),
            TextButton.icon(
              onPressed: () {
                final updatedItems = List<Map<String, dynamic>>.from(items);
                final next = updatedItems.length + 1;
                updatedItems.add({'title': 'Step $next', 'description': 'Timeline item', 'status': 'pending'});
                _updateComponentConfig(field, activeStepId, 'items', updatedItems);
              },
              icon: const Icon(Icons.add_rounded, size: 14),
              label: Text("Add Item", style: GoogleFonts.inter(fontSize: 10)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: RevoTheme.sidebarBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PropertyTextField(
                        label: "Title",
                        initialValue: item['title']?.toString() ?? '',
                        onChanged: (val) {
                          final updatedItems = List<Map<String, dynamic>>.from(items);
                          updatedItems[index] = {...item, 'title': val.trim()};
                          _updateComponentConfig(field, activeStepId, 'items', updatedItems);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PropertyDropdownField(
                        label: "Status",
                        currentValue: item['status']?.toString() ?? 'pending',
                        items: const ['pending', 'active', 'completed', 'failed'],
                        onChanged: (val) {
                          final updatedItems = List<Map<String, dynamic>>.from(items);
                          updatedItems[index] = {...item, 'status': val};
                          _updateComponentConfig(field, activeStepId, 'items', updatedItems);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      onPressed: items.length <= 1
                          ? null
                          : () {
                              final updatedItems = List<Map<String, dynamic>>.from(items)..removeAt(index);
                              _updateComponentConfig(field, activeStepId, 'items', updatedItems);
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _PropertyTextField(
                  label: "Description",
                  initialValue: item['description']?.toString() ?? '',
                  onChanged: (val) {
                    final updatedItems = List<Map<String, dynamic>>.from(items);
                    updatedItems[index] = {...item, 'description': val.trim()};
                    _updateComponentConfig(field, activeStepId, 'items', updatedItems);
                  },
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: [
            _buildCompactSwitchTile(label: "Timestamp", value: _boolConfig(config, 'showTimestamp', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'showTimestamp', val)),
            _buildCompactSwitchTile(label: "Connector", value: _boolConfig(config, 'showConnector', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'showConnector', val)),
            _buildCompactSwitchTile(label: "Future Steps", value: _boolConfig(config, 'allowFutureSteps', true), onChanged: (val) => _updateComponentConfig(field, activeStepId, 'allowFutureSteps', val)),
          ],
        ),
      ],
    );
  }

  Widget _buildLayoutComponentProperties(JourneyField field, String activeStepId) {
    final config = _componentConfig(field);
    return _buildCollapsibleSection(
      title: "Layout Properties",
      accentColor: RevoTheme.primaryLight,
      icon: Icons.dashboard_customize_outlined,
      isExpanded: _showLayoutComponentSettings,
      onToggle: () => setState(() => _showLayoutComponentSettings = !_showLayoutComponentSettings),
      children: [
        if (field.type == 'section') ...[
          Row(
            children: [
              Expanded(
                child: _PropertyDropdownField(
                  label: "Heading Level",
                  currentValue: config['headingLevel']?.toString() ?? 'H2',
                  items: const ['H1', 'H2', 'H3', 'H4'],
                  onChanged: (val) => _updateComponentConfig(field, activeStepId, 'headingLevel', val),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _paddingConfigField(field, activeStepId, config)),
            ],
          ),
          const SizedBox(height: 10),
          _layoutSwitches(field, activeStepId, config, const ['collapsible', 'defaultExpanded', 'showDivider']),
        ] else if (field.type == 'card') ...[
          Row(
            children: [
              Expanded(
                child: _PropertyDropdownField(
                  label: "Variant",
                  currentValue: config['variant']?.toString() ?? 'outlined',
                  items: const ['outlined', 'filled', 'elevated'],
                  onChanged: (val) => _updateComponentConfig(field, activeStepId, 'variant', val),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _paddingConfigField(field, activeStepId, config)),
            ],
          ),
          const SizedBox(height: 10),
          _layoutSwitches(field, activeStepId, config, const ['showHeader', 'showFooter']),
        ] else if (field.type == 'tabs') ...[
          Row(
            children: [
              Expanded(
                child: _PropertyDropdownField(
                  label: "Variant",
                  currentValue: config['variant']?.toString() ?? 'underline',
                  items: const ['underline', 'boxed', 'pills'],
                  onChanged: (val) => _updateComponentConfig(field, activeStepId, 'variant', val),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PropertyDropdownField(
                  label: "Alignment",
                  currentValue: config['alignment']?.toString() ?? 'start',
                  items: const ['start', 'center', 'end'],
                  onChanged: (val) => _updateComponentConfig(field, activeStepId, 'alignment', val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _textConfigField(field, activeStepId, config, 'tabsCsv', 'Tabs CSV', fallback: (config['tabs'] as List?)?.join(', ') ?? 'Tab 1, Tab 2'),
          const SizedBox(height: 10),
          _layoutSwitches(field, activeStepId, config, const ['persistActiveTab']),
        ] else if (field.type == 'accordion') ...[
          Row(
            children: [
              Expanded(
                child: _PropertyDropdownField(
                  label: "Variant",
                  currentValue: config['variant']?.toString() ?? 'bordered',
                  items: const ['bordered', 'filled', 'plain'],
                  onChanged: (val) => _updateComponentConfig(field, activeStepId, 'variant', val),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PropertyDropdownField(
                  label: "Icon Position",
                  currentValue: config['iconPosition']?.toString() ?? 'right',
                  items: const ['left', 'right'],
                  onChanged: (val) => _updateComponentConfig(field, activeStepId, 'iconPosition', val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _layoutSwitches(field, activeStepId, config, const ['allowMultipleOpen', 'defaultExpanded']),
        ],
      ],
    );
  }

  Widget _textConfigField(
    JourneyField field,
    String activeStepId,
    Map<String, dynamic> config,
    String key,
    String label, {
    String? fallback,
  }) {
    return _PropertyTextField(
      label: label,
      initialValue: config[key]?.toString() ?? fallback ?? '',
      onChanged: (val) {
        if (key == 'tabsCsv') {
          final tabs = val.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
          _updateComponentConfig(field, activeStepId, 'tabs', tabs);
        } else {
          _updateComponentConfig(field, activeStepId, key, val.trim());
        }
      },
    );
  }

  Widget _numberConfigField(JourneyField field, String activeStepId, Map<String, dynamic> config, String key, String label, int fallback) {
    return _PropertyTextField(
      label: label,
      initialValue: _intConfig(config, key, fallback).toString(),
      onChanged: (val) => _updateComponentConfig(field, activeStepId, key, int.tryParse(val.trim()) ?? fallback),
    );
  }

  Widget _paddingConfigField(JourneyField field, String activeStepId, Map<String, dynamic> config) {
    return _PropertyDropdownField(
      label: "Padding",
      currentValue: config['padding']?.toString() ?? 'medium',
      items: const ['none', 'small', 'medium', 'large'],
      onChanged: (val) => _updateComponentConfig(field, activeStepId, 'padding', val),
    );
  }

  Widget _layoutSwitches(JourneyField field, String activeStepId, Map<String, dynamic> config, List<String> keys) {
    String labelFor(String key) {
      switch (key) {
        case 'defaultExpanded':
          return 'Expanded';
        case 'showDivider':
          return 'Divider';
        case 'showHeader':
          return 'Header';
        case 'showFooter':
          return 'Footer';
        case 'persistActiveTab':
          return 'Persist Tab';
        case 'allowMultipleOpen':
          return 'Multi Open';
        default:
          return key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}').trim();
      }
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.8,
      children: keys
          .map(
            (key) => _buildCompactSwitchTile(
              label: labelFor(key),
              value: _boolConfig(config, key, false),
              onChanged: (val) => _updateComponentConfig(field, activeStepId, key, val),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTabButton(String text, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _activeTab = text),
      borderRadius: BorderRadius.circular(4),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? RevoTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isSelected ? Colors.white : RevoTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSwitchTile({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            height: 20,
            child: FittedBox(
              child: Switch(
                value: value,
                activeTrackColor: RevoTheme.primaryLight.withValues(alpha:0.5),
                activeColor: RevoTheme.primaryLight,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSourceSelector(JourneyField field, String activeStepId) {
    final useStatic = field.useStaticOptions;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                final updated = field.copy()..useStaticOptions = true;
                ref.read(journeyConfigProvider.notifier)
                    .updateFieldInStep(activeStepId, field.id, updated);
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: useStatic ? RevoTheme.primary.withValues(alpha:0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: useStatic ? RevoTheme.primaryLight.withValues(alpha:0.5) : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    "Static Options",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: useStatic ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                final updated = field.copy()..useStaticOptions = false;
                ref.read(journeyConfigProvider.notifier)
                    .updateFieldInStep(activeStepId, field.id, updated);
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: !useStatic ? RevoTheme.primary.withValues(alpha:0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: !useStatic ? RevoTheme.primaryLight.withValues(alpha:0.5) : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    "API Integration",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: !useStatic ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticOptionsList(JourneyField field, String activeStepId) {
    final options = field.staticOptions ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Static Options Builder",
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        ...options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final keyStr = option['key'] ?? '';
          final valStr = option['value'] ?? '';
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _PropertyTextField(
                    label: "Key",
                    initialValue: keyStr,
                    onChanged: (newKey) {
                      final updatedList = List<Map<String, String>>.from(options);
                      updatedList[index] = {'key': newKey.trim(), 'value': valStr};
                      final updated = field.copy()..staticOptions = updatedList;
                      ref.read(journeyConfigProvider.notifier)
                          .updateFieldInStep(activeStepId, field.id, updated);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 5,
                  child: _PropertyTextField(
                    label: "Value",
                    initialValue: valStr,
                    onChanged: (newVal) {
                      final updatedList = List<Map<String, String>>.from(options);
                      updatedList[index] = {'key': keyStr, 'value': newVal};
                      final updated = field.copy()..staticOptions = updatedList;
                      ref.read(journeyConfigProvider.notifier)
                          .updateFieldInStep(activeStepId, field.id, updated);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                    onPressed: () {
                      final updatedList = List<Map<String, String>>.from(options)..removeAt(index);
                      final updated = field.copy()..staticOptions = updatedList;
                      ref.read(journeyConfigProvider.notifier)
                          .updateFieldInStep(activeStepId, field.id, updated);
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: RevoTheme.cardBg,
            minimumSize: const Size(double.infinity, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: RevoTheme.cardBorder),
            ),
          ),
          onPressed: () {
            final updatedList = List<Map<String, String>>.from(options);
            final newIdx = updatedList.length + 1;
            updatedList.add({'key': newIdx.toString(), 'value': 'Option $newIdx'});
            final updated = field.copy()..staticOptions = updatedList;
            ref.read(journeyConfigProvider.notifier)
                .updateFieldInStep(activeStepId, field.id, updated);
          },
          icon: const Icon(Icons.add_rounded, size: 12),
          label: Text("Add New Option", style: GoogleFonts.inter(fontSize: 10)),
        ),
      ],
    );
  }

  Widget _buildApiTabBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Row(
        children: [
          _buildApiTabButton("Endpoint", 0),
          _buildApiTabButton("Payload", 1),
          _buildApiTabButton("Response Map", 2),
        ],
      ),
    );
  }

  Widget _buildApiTabButton(String label, int index) {
    final isSelected = _apiTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _apiTabIndex = index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? RevoTheme.primary.withValues(alpha:0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? RevoTheme.primaryLight.withValues(alpha:0.3) : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isSelected ? RevoTheme.primaryLight : RevoTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodSelector(JourneyField field, String activeStepId) {
    final methods = ["GET", "POST", "PUT", "DELETE"];
    final currentMethod = field.dropdownApiMethod ?? "GET";
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("API HTTP Method", style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary)),
        const SizedBox(height: 4),
        Row(
          children: methods.map((method) {
            final isSelected = currentMethod.toUpperCase() == method;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: InkWell(
                  onTap: () {
                    final updated = field.copy()..dropdownApiMethod = method;
                    ref.read(journeyConfigProvider.notifier)
                        .updateFieldInStep(activeStepId, field.id, updated);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? RevoTheme.primary.withValues(alpha:0.15) : RevoTheme.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? RevoTheme.primaryLight : RevoTheme.cardBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        method,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String? _validateJsonMap(String val) {
    if (val.trim().isEmpty) return null;
    try {
      final decoded = json.decode(val);
      if (decoded is! Map) return "Must be a valid JSON Object (e.g. {\"key\": \"value\"})";
      return null;
    } catch (e) {
      return "Invalid JSON syntax: ${e.toString()}";
    }
  }

  String? _validateJsonResponseData(String val) {
    if (val.trim().isEmpty) return null;
    try {
      final decoded = json.decode(val);
      if (decoded is! List && decoded is! Map) {
        return "Must be a valid JSON Array or Object response.";
      }
      return null;
    } catch (e) {
      return "Invalid JSON syntax: ${e.toString()}";
    }
  }

  Widget _buildResponsePreview(JourneyField field) {
    final data = field.dropdowndata;
    final displayKey = field.dropdownValue ?? 'title';
    
    if (data == null || data.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: RevoTheme.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: RevoTheme.cardBorder),
        ),
        child: Text(
          "Enter mock/test response JSON array in the field above to see live dropdown parse preview.",
          style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontStyle: FontStyle.italic),
        ),
      );
    }
    
    try {
      final parsedOptions = field.getResolvedOptions();
      if (parsedOptions.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withValues(alpha:0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.orangeAccent.withValues(alpha:0.25)),
          ),
          child: Text(
            "Parsed 0 options. Double-check if the Display Key '$displayKey' matches properties in your JSON.",
            style: GoogleFonts.inter(fontSize: 10, color: Colors.orangeAccent),
          ),
        );
      }
      
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withValues(alpha:0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.greenAccent.withValues(alpha:0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 12),
                const SizedBox(width: 4),
                Text(
                  "Parsed ${parsedOptions.length} option(s) successfully:",
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: parsedOptions.map((opt) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: RevoTheme.background,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: RevoTheme.cardBorder),
                  ),
                  child: Text(
                    opt,
                    style: GoogleFonts.inter(fontSize: 9, color: Colors.white70),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    } catch (e) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.redAccent.withValues(alpha:0.25)),
        ),
        child: Text(
          "Parsing error: ${e.toString()}",
          style: GoogleFonts.inter(fontSize: 10, color: Colors.redAccent),
        ),
      );
    }
  }
}

// Stateful text field wrapper that isolates editing state, preventing rebuild lags
// and cursor selection reset bugs.
class _PropertyTextField extends StatefulWidget {
  final String label;
  final String initialValue;
  final String? hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _PropertyTextField({
    required this.label,
    required this.initialValue,
    this.hint,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  State<_PropertyTextField> createState() => _PropertyTextFieldState();
}

class _PropertyTextFieldState extends State<_PropertyTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _PropertyTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && widget.initialValue != _controller.text) {
      final selection = _controller.selection;
      _controller.text = widget.initialValue;
      try {
        _controller.selection = selection;
      } catch (_) {
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: RevoTheme.background,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: RevoTheme.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: RevoTheme.primaryLight, width: 1.5),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textPrimary),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}

class _PropertyDropdownField extends StatelessWidget {
  final String label;
  final String currentValue;
  final List<String> items;
  final ValueChanged<String>? onChanged;

  const _PropertyDropdownField({
    required this.label,
    required this.currentValue,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: RevoTheme.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: RevoTheme.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(currentValue) ? currentValue : items.first,
              isExpanded: true,
              dropdownColor: RevoTheme.cardBg,
              style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textPrimary),
              icon: Icon(Icons.arrow_drop_down, color: RevoTheme.textSecondary, size: 18),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null && onChanged != null) {
                  onChanged!(val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
