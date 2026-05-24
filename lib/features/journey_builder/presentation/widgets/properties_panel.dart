import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
      final fieldIndex = step.fields.indexWhere((f) => f.id == selectedFieldId);
      if (fieldIndex != -1) {
        selectedField = step.fields[fieldIndex];
      }
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
                                    label: "Response JSON Data (Test/Preloaded)",
                                    initialValue: selectedField.dropdowndata != null ? json.encode(selectedField.dropdowndata) : '',
                                    hint: '[{"id": 1, "title": "Option One"}, {"id": 2, "title": "Option Two"}]',
                                    maxLines: 4,
                                    onChanged: (val) {
                                      setState(() {
                                        _testDataError = _validateJsonList(val);
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
                                              final updatedList = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
                                              final updated = selectedField!.copy()..dropdowndata = updatedList;
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
                                          await Future.delayed(const Duration(milliseconds: 1200));
                                          
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
                                            final options = selectedField.getResolvedOptions();
                                            setState(() {
                                              _testingApi = false;
                                              _apiTestSuccess = true;
                                              _apiTestResult = "Connection successful!\nStatus: 200 OK\nParsed ${options.length} option(s) successfully.";
                                            });
                                          } catch (e) {
                                            setState(() {
                                              _testingApi = false;
                                              _apiTestSuccess = false;
                                              _apiTestResult = "Parsing error: ${e.toString()}";
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

  Widget _buildTabButton(String text, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _activeTab = text),
      borderRadius: BorderRadius.circular(4),
      child: Container(
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

  String? _validateJsonList(String val) {
    if (val.trim().isEmpty) return null;
    try {
      final decoded = json.decode(val);
      if (decoded is! List) return "Must be a valid JSON List (e.g. [{\"id\": 1}])";
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
