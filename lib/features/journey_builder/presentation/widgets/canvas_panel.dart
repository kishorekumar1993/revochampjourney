import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme.dart';
import '../../data/models.dart';
import '../providers/journey_provider.dart';

class RevoCanvasPanel extends ConsumerStatefulWidget {
  const RevoCanvasPanel({super.key});

  @override
  ConsumerState<RevoCanvasPanel> createState() => _RevoCanvasPanelState();
}

class _RevoCanvasPanelState extends ConsumerState<RevoCanvasPanel> {
  String _activeTab = 'Design';
  bool _isMobilePreview = true;
  bool _showPreview = false;

  bool _testingStepApi = false;
  int? _testingStepApiIndex;
  String? _stepApiTestResult;
  bool _stepApiTestSuccess = false;

  late final Map<String, Widget Function(JourneyField, String)> _previewRegistry;
  late final Map<String, Widget Function(JourneyField, Map<String, dynamic>)> _mockupRegistry;

  @override
  void initState() {
    super.initState();
    _previewRegistry = {
      'dropdown': _previewDropdown,
      'api_dropdown': _previewDropdown,
      'radio': _previewRadio,
      'checkbox': _previewCheckbox,
      'switch': _previewSwitch,
      'date': _previewDate,
      'time': _previewDate,
      'datetime': _previewDate,
      'file': _previewFile,
      'image': _previewFile,
      'textarea': _previewTextarea,
      'number': _previewNumber,
      'table_grid': (f, _) => _buildTableGridPreview(f),
      'repeater': (f, _) => _buildRepeaterPreview(f),
      'timeline': (f, _) => _buildTimelinePreview(f),
      'section': (f, sid) => _buildNestedCanvasPreview(f, Icons.view_agenda_outlined, sid),
      'card': (f, sid) => _buildNestedCanvasPreview(f, Icons.crop_square_rounded, sid),
      'tabs': (f, sid) => _buildNestedTabsCanvasPreview(f, sid),
      'accordion': (f, sid) => _buildNestedCanvasPreview(f, Icons.unfold_more_rounded, sid),
      'row': (f, sid) => _buildNestedRowCanvasPreview(f, sid),
      'formula': (f, _) => _buildPreviewBox(child: Text(f.formula ?? f.defaultValue ?? 'Calculated value', style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.primaryLight))),
      'divider': (f, _) => Divider(color: RevoTheme.cardBorder),
    };

    _mockupRegistry = {
      'divider': (f, _) => Divider(color: RevoTheme.cardBorder),
      'dropdown': _mockupDropdown,
      'api_dropdown': _mockupApiDropdown,
      'radio': _mockupRadio,
      'checkbox': _mockupCheckbox,
      'switch': _mockupSwitch,
      'date': _mockupDate,
      'time': _mockupDate,
      'datetime': _mockupDate,
      'file': _mockupFile,
      'image': _mockupFile,
      'otp': _mockupOtp,
      'phone': _mockupPhone,
      'table_grid': (f, _) => _buildCompactTablePreview(f),
      'repeater': (f, _) => _buildCompactRepeaterPreview(f),
      'timeline': (f, _) => _buildCompactTimelinePreview(f),
      'section': (f, values) => _buildCompactNestedPreview(f, Icons.view_agenda_outlined, values),
      'card': (f, values) => _buildCompactNestedPreview(f, Icons.crop_square_rounded, values),
      'tabs': (f, values) => _buildCompactNestedTabsPreview(f, values),
      'accordion': (f, values) => _buildCompactNestedPreview(f, Icons.unfold_more_rounded, values),
      'row': (f, values) => _buildCompactNestedRowPreview(f, values),
      'formula': (f, _) => _buildCompactComponentShell(Icons.functions_rounded, f.formula ?? "Calculated value"),
    };
  }

  final List<Map<String, dynamic>> _componentGroups = [
    {
      'title': 'FORM COMPONENTS',
      'items': [
        {'type': 'text', 'label': 'Text Field', 'icon': Icons.text_fields_rounded},
        {'type': 'dropdown', 'label': 'Dropdown', 'icon': Icons.arrow_drop_down_circle_outlined},
        {'type': 'radio', 'label': 'Radio', 'icon': Icons.radio_button_checked_rounded},
        {'type': 'checkbox', 'label': 'Checkbox', 'icon': Icons.check_box_outlined},
        {'type': 'date', 'label': 'Date Picker', 'icon': Icons.calendar_today_rounded},
        {'type': 'file', 'label': 'File Upload', 'icon': Icons.cloud_upload_outlined},
        {'type': 'textarea', 'label': 'Text Area', 'icon': Icons.notes_rounded},
        {'type': 'number', 'label': 'Number', 'icon': Icons.pin_outlined},
        {'type': 'switch', 'label': 'Switch', 'icon': Icons.toggle_on_outlined},
      ],
    },
    {
      'title': 'DATA COMPONENTS',
      'items': [
        {'type': 'table_grid', 'label': 'Table / Grid', 'icon': Icons.table_chart_outlined},
        {'type': 'repeater', 'label': 'Repeater', 'icon': Icons.view_week_outlined},
        {'type': 'timeline', 'label': 'Timeline', 'icon': Icons.format_list_bulleted_rounded},
      ],
    },
    {
      'title': 'LAYOUT COMPONENTS',
      'items': [
        {'type': 'section', 'label': 'Section', 'icon': Icons.view_agenda_outlined},
        {'type': 'card', 'label': 'Card', 'icon': Icons.crop_square_rounded},
        {'type': 'tabs', 'label': 'Tabs', 'icon': Icons.tab_rounded},
        {'type': 'accordion', 'label': 'Accordion', 'icon': Icons.unfold_more_rounded},
      ],
    },
  ];

  Map<String, dynamic> _componentDefaults(String fieldType) {
    switch (fieldType) {
      case 'dropdown':
        return {'label': 'Dropdown', 'placeholder': 'Select an option', 'options': ['Option 1', 'Option 2']};
      case 'radio':
        return {'label': 'Radio Group', 'options': ['Option 1', 'Option 2']};
      case 'checkbox':
        return {'label': 'Checkbox', 'defaultValue': 'false'};
      case 'date':
        return {'label': 'Date Picker', 'placeholder': 'DD/MM/YYYY'};
      case 'file':
        return {'label': 'File Upload', 'placeholder': 'Upload file'};
      case 'textarea':
        return {'label': 'Text Area', 'placeholder': 'Enter details'};
      case 'number':
        return {'label': 'Number', 'placeholder': 'Enter number', 'keyboardType': 'number'};
      case 'switch':
        return {'label': 'Switch', 'defaultValue': 'false'};
      case 'table_grid':
        return {
          'label': 'Table / Grid',
          'placeholder': 'Manage tabular data',
          'componentConfig': {
            'columns': [
              {'label': 'Name', 'fieldId': 'name', 'type': 'text', 'required': true, 'sortable': true, 'filterable': true, 'sticky': true},
              {'label': 'Age', 'fieldId': 'age', 'type': 'number', 'required': false, 'sortable': true, 'filterable': true, 'sticky': false},
            ],
            'rowActions': ['edit', 'delete'],
            'allowAddRow': true,
            'allowDeleteRow': true,
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
            'pagination': true,
            'rowsPerPage': 10,
          },
        };
      case 'repeater':
        return {'label': 'Repeater', 'placeholder': 'Repeat a field group'};
      case 'timeline':
        return {'label': 'Timeline', 'placeholder': 'Show journey milestones'};
      case 'section':
        return {'label': 'Section', 'placeholder': 'Group related components'};
      case 'card':
        return {'label': 'Card', 'placeholder': 'Card content container'};
      case 'tabs':
        return {'label': 'Tabs', 'placeholder': 'Organize content into tabs'};
      case 'accordion':
        return {'label': 'Accordion', 'placeholder': 'Expandable content'};
      default:
        return {'label': 'Text Field', 'placeholder': 'Enter details'};
    }
  }

  void _addField(String fieldType) {
    final activeStepId = ref.read(activeStepIdProvider);
    final fieldId = "field_${DateTime.now().millisecondsSinceEpoch}";
    final defaults = _componentDefaults(fieldType);
    final newField = JourneyField.fromJson({
      'id': fieldId,
      'label': defaults['label'],
      'type': fieldType,
      'required': false,
      'placeholder': defaults['placeholder'],
      'options': defaults['options'],
      'defaultValue': defaults['defaultValue'],
      'keyboardType': defaults['keyboardType'],
      'componentConfig': defaults['componentConfig'],
    });
    ref.read(journeyConfigProvider.notifier).addFieldToStep(activeStepId, newField);
    ref.read(selectedFieldIdProvider.notifier).state = fieldId;
  }

  void _duplicateField(JourneyField field) {
    final activeStepId = ref.read(activeStepIdProvider);
    final newFieldId = "field_${DateTime.now().millisecondsSinceEpoch}";
    final duplicated = field.copyWith(
      id: newFieldId,
      label: "${field.label} (Copy)",
    );
    ref.read(journeyConfigProvider.notifier).addFieldToStep(activeStepId, duplicated);
    ref.read(selectedFieldIdProvider.notifier).state = newFieldId;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final activeStepId = ref.watch(activeStepIdProvider);
    
    final step = ref.watch(journeyConfigProvider.select((config) =>
        config.steps.firstWhereOrNull((s) => s.id == activeStepId)
    ));
    
    final activeStepIndex = ref.watch(journeyConfigProvider.select((config) =>
        config.steps.indexWhere((s) => s.id == activeStepId)
    ));
    
    final previousStepId = ref.watch(journeyConfigProvider.select((config) {
      final idx = config.steps.indexWhere((s) => s.id == activeStepId);
      return (idx > 0) ? config.steps[idx - 1].id : null;
    }));
    
    final nextStepId = ref.watch(journeyConfigProvider.select((config) {
      final idx = config.steps.indexWhere((s) => s.id == activeStepId);
      return (idx >= 0 && idx < config.steps.length - 1) ? config.steps[idx + 1].id : null;
    }));

    if (step == null || activeStepIndex == -1) {
      return Expanded(
        child: Center(
          child: Text(
            "Select or create a step to begin building.",
            style: GoogleFonts.inter(color: RevoTheme.textSecondary),
          ),
        ),
      );
    }

    final selectedFieldId = ref.watch(selectedFieldIdProvider);
    final formValues = ref.watch(formValuesProvider);

    return Expanded(
      child: Container(
        color: RevoTheme.background,
        child: Column(
          children: [
            // Panel Header
            _buildHeader(context, step, activeStepIndex, previousStepId, nextStepId),

            // Tabs sub-bar
            _buildTabBar(step),

            // Workspace Layout
            Expanded(
              child: Row(
                children: [
                  // 1. ToolBox Palette
                  _CanvasToolbox(
                    componentGroups: _componentGroups,
                    onAddField: _addField,
                  ),

                  // 2. Editor Canvas
                  _buildCanvas(step, selectedFieldId),

                  // 3. Mobile/Desktop Live simulator view
                  if (_showPreview)
                    _buildLivePreview(step, formValues, previousStepId, nextStepId),
                ],
              ),
            ),

            // Step Configurations (bottom bar)
            _CanvasBottomStats(step: step),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, JourneyStep step, int index, String? previousStepId, String? nextStepId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Step ${index + 1}: ${step.title}",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: RevoTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: RevoTheme.secondary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: RevoTheme.secondary.withValues(alpha:0.4)),
                  ),
                  child: Text(
                    "Enabled",
                    style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.secondary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Screen switch
                  Container(
                    decoration: BoxDecoration(
                      color: RevoTheme.cardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildSwitchIconButton(
                          Icons.phone_android_rounded, 
                          _showPreview && _isMobilePreview, 
                          () => setState(() {
                            _showPreview = true;
                            _isMobilePreview = true;
                          }),
                        ),
                        _buildSwitchIconButton(
                          Icons.laptop_chromebook_rounded, 
                          _showPreview && !_isMobilePreview, 
                          () => setState(() {
                            _showPreview = true;
                            _isMobilePreview = false;
                          }),
                        ),
                        _buildSwitchIconButton(
                          Icons.visibility_off_rounded, 
                          !_showPreview, 
                          () => setState(() {
                            _showPreview = false;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Navigation buttons
                  OutlinedButton(
                    onPressed: previousStepId != null ? () {
                      ref.read(activeStepIdProvider.notifier).state = previousStepId;
                      ref.read(selectedFieldIdProvider.notifier).state = null;
                    } : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text("Back"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: nextStepId != null ? () {
                      ref.read(activeStepIdProvider.notifier).state = nextStepId;
                      ref.read(selectedFieldIdProvider.notifier).state = null;
                    } : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text("Next"),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Step Configuration Auto-Saved!"),
                          backgroundColor: RevoTheme.secondary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.cloud_done_rounded, size: 16),
                    label: const Text("Save Step"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchIconButton(IconData icon, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? RevoTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: isSelected ? Colors.white : RevoTheme.textSecondary),
      ),
    );
  }

  Widget _buildTabBar(JourneyStep step) {
    final tabs = [
      {'id': 'Design', 'label': 'Design Workspace', 'icon': Icons.design_services_outlined},
      {'id': 'Rules', 'label': 'Rules (${step.conditions.length})', 'icon': Icons.rule_rounded},
      {'id': 'Validations', 'label': 'Validations (${step.validations.length})', 'icon': Icons.gpp_maybe_rounded},
      {'id': 'API', 'label': 'API Calls (${step.apiCalls.length})', 'icon': Icons.api_rounded},
      {'id': 'Settings', 'label': 'Settings', 'icon': Icons.settings_rounded},
      {'id': 'Actions', 'label': 'Actions (${step.actions.length})', 'icon': Icons.flash_on_rounded},
    ];

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(
          bottom: BorderSide(color: RevoTheme.cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final isSelected = _activeTab == tab['id'];
            return InkWell(
              onTap: () => setState(() => _activeTab = tab['id'] as String),
              child: Container(
                height: 48,
                margin: const EdgeInsets.only(right: 32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: isSelected 
                      ? Border(bottom: BorderSide(color: RevoTheme.primary, width: 2))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 16,
                      color: isSelected ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tab['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? RevoTheme.textPrimary : RevoTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCanvas(JourneyStep step, String? selectedFieldId) {
    if (_activeTab == 'Rules') {
      return _buildRulesTab(step);
    } else if (_activeTab == 'Validations') {
      return _buildValidationsTab(step);
    } else if (_activeTab == 'API') {
      return _buildApiTab(step);
    } else if (_activeTab == 'Actions') {
      return _buildActionsTab(step);
    } else if (_activeTab == 'Settings') {
      return _buildSettingsTab(step);
    }

    return Expanded(
      flex: 3,
      child: DragTarget<String>(
        onAcceptWithDetails: (details) {
          _addField(details.data);
        },
        builder: (context, candidateData, rejectedData) {
          final isOver = candidateData.isNotEmpty;

          return Container(
            color: isOver ? RevoTheme.primary.withValues(alpha:0.08) : RevoTheme.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Canvas Header Title
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.description.isNotEmpty ? step.description : "Drag widgets here to build details",
                        style: GoogleFonts.inter(color: RevoTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // Canvas Fields list
                Expanded(
                  child: step.fields.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.art_track_rounded, size: 48, color: RevoTheme.cardBorder),
                              const SizedBox(height: 12),
                              Text(
                                "Drag tools here or click items to insert field",
                                style: GoogleFonts.inter(color: RevoTheme.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : Theme(
                          data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
                          child: ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: step.fields.length,
                            onReorder: (oldIndex, newIndex) {
                              ref.read(journeyConfigProvider.notifier)
                                  .reorderFieldsInStep(step.id, oldIndex, newIndex);
                            },
                            itemBuilder: (context, index) {
                              final field = step.fields[index];
                              final isSelected = field.id == selectedFieldId;

                              return InkWell(
                                key: ValueKey(field.id),
                                onTap: () {
                                  ref.read(selectedFieldIdProvider.notifier).state = field.id;
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: RevoTheme.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? Border.all(color: RevoTheme.primary, width: 1.5)
                                        : Border.all(color: RevoTheme.cardBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ReorderableDragStartListener(
                                            index: index,
                                            child: Icon(Icons.drag_indicator_rounded, color: RevoTheme.textSecondary),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        field.label,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (field.required)
                                                      const Text(" *", style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  field.placeholder ?? "No placeholder configured",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: RevoTheme.textSecondary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildCanvasComponentPreview(field, step.id),
                                      if (isSelected) ...[
                                        const SizedBox(height: 12),
                                        Divider(color: RevoTheme.cardBorder, height: 1),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: RevoTheme.primary.withValues(alpha:0.15),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: RevoTheme.primary.withValues(alpha:0.3)),
                                              ),
                                              child: Text(
                                                field.type.toUpperCase(),
                                                style: GoogleFonts.inter(
                                                  fontSize: 9,
                                                  color: RevoTheme.primaryLight,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.copy_rounded, size: 16, color: RevoTheme.primaryLight),
                                                  onPressed: () => _duplicateField(field),
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(8),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                                  onPressed: () {
                                                    ref.read(journeyConfigProvider.notifier)
                                                        .removeFieldFromStep(step.id, field.id);
                                                  },
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(8),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCanvasComponentPreview(JourneyField field, String stepId) {
    final builder = _previewRegistry[field.type.toLowerCase()];
    if (builder != null) return builder(field, stepId);
    return _previewDefault(field, stepId);
  }

  Widget _previewDefault(JourneyField field, String stepId) => _buildPreviewBox(child: Text(field.placeholder ?? 'Enter value', style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary)));
  Widget _previewTextarea(JourneyField field, String stepId) => _buildPreviewBox(height: 72, child: Align(alignment: Alignment.topLeft, child: Text(field.placeholder ?? 'Enter details', style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary))));
  Widget _previewNumber(JourneyField field, String stepId) => _buildPreviewBox(child: Text(field.placeholder ?? 'Enter number', style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary)));
  Widget _previewDate(JourneyField field, String stepId) => _buildPreviewBox(child: Row(children: [Expanded(child: Text(field.placeholder ?? (field.type == 'time' ? 'HH:MM' : 'DD/MM/YYYY'), style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary))), Icon(Icons.calendar_today_rounded, size: 16, color: RevoTheme.textSecondary)]));
  Widget _previewFile(JourneyField field, String stepId) => _buildPreviewBox(height: 68, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(field.type == 'image' ? Icons.image_outlined : Icons.cloud_upload_outlined, size: 20, color: RevoTheme.primaryLight), const SizedBox(height: 4), Text(field.placeholder ?? 'Upload file', style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary))]));
  Widget _previewCheckbox(JourneyField field, String stepId) => Row(children: [Icon(Icons.check_box_outline_blank_rounded, size: 18, color: RevoTheme.textSecondary), const SizedBox(width: 8), Expanded(child: Text(field.label, style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary)))]);
  Widget _previewSwitch(JourneyField field, String stepId) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(field.label, style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary))), Switch(value: field.defaultValue == 'true', onChanged: null)]);
  Widget _previewDropdown(JourneyField field, String stepId) => _buildPreviewBox(child: Row(children: [Expanded(child: Text(field.placeholder ?? 'Select an option', style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary), overflow: TextOverflow.ellipsis)), Icon(field.type == 'api_dropdown' ? Icons.cloud_sync_outlined : Icons.keyboard_arrow_down_rounded, size: 16, color: RevoTheme.textSecondary)]));
  Widget _previewRadio(JourneyField field, String stepId) => Wrap(spacing: 8, runSpacing: 8, children: (field.getResolvedOptions().isEmpty ? ['Option 1', 'Option 2'] : field.getResolvedOptions()).map((option) => Chip(label: Text(option, style: GoogleFonts.inter(fontSize: 11)), avatar: Icon(Icons.radio_button_unchecked_rounded, size: 14, color: RevoTheme.primaryLight), backgroundColor: RevoTheme.background, side: BorderSide(color: RevoTheme.cardBorder))).toList());

  Widget _buildPreviewBox({required Widget child, double height = 42}) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: child,
    );
  }


  Widget _buildTabsPreview() {
    return Row(
      children: ['Tab 1', 'Tab 2', 'Tab 3'].map((label) {
        final selected = label == 'Tab 1';
        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? RevoTheme.primary.withValues(alpha: 0.15) : RevoTheme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? RevoTheme.primaryLight : RevoTheme.cardBorder),
          ),
          child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: selected ? RevoTheme.primaryLight : RevoTheme.textSecondary)),
        );
      }).toList(),
    );
  }

  Widget _buildNestedCanvasPreview(JourneyField field, IconData icon, String stepId) {
    final children = field.nestedFields ?? const <JourneyField>[];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: RevoTheme.primaryLight),
              const SizedBox(width: 8),
              Expanded(child: Text(field.label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: RevoTheme.textPrimary))),
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...children.take(6).map((child) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => ref.read(selectedFieldIdProvider.notifier).state = child.id,
                          child: _buildCanvasComponentPreview(child, stepId),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 13, color: Colors.redAccent),
                        onPressed: () => ref.read(journeyConfigProvider.notifier)
                            .removeFieldFromNestedContainer(stepId, child.id),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                )),
          ],
          // Drop zone — drag toolbox items directly into this container
          DragTarget<String>(
            onAcceptWithDetails: (details) {
              final newFieldId = "field_${DateTime.now().millisecondsSinceEpoch}";
              final defaults = _componentDefaults(details.data);
              final newField = JourneyField.fromJson({
                'id': newFieldId,
                'label': defaults['label'],
                'type': details.data,
                'required': false,
                'placeholder': defaults['placeholder'],
                'options': defaults['options'],
                'defaultValue': defaults['defaultValue'],
                'componentConfig': defaults['componentConfig'],
              });
              ref.read(journeyConfigProvider.notifier)
                  .addFieldToNestedContainer(stepId, field.id, newField);
            },
            builder: (context, candidateData, _) {
              final isOver = candidateData.isNotEmpty;
              return Container(
                height: 28,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isOver
                      ? RevoTheme.primary.withValues(alpha: 0.12)
                      : RevoTheme.cardBg.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isOver ? RevoTheme.primaryLight : RevoTheme.cardBorder,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  isOver ? 'Drop here' : '+ drop field inside',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: isOver ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNestedRowCanvasPreview(JourneyField field, String stepId) {
    final children = field.nestedFields ?? const <JourneyField>[];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: children.take(4).map((child) {
        return SizedBox(
          width: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(child.label, style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => ref.read(selectedFieldIdProvider.notifier).state = child.id,
                child: _buildCanvasComponentPreview(child, stepId),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNestedTabsCanvasPreview(JourneyField field, String stepId) {
    final tabs = field.nestedFields ?? const <JourneyField>[];
    if (tabs.isEmpty) return _buildTabsPreview();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          children: tabs.map((tab) {
            final selected = tab == tabs.first;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? RevoTheme.primary.withValues(alpha: 0.15) : RevoTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? RevoTheme.primaryLight : RevoTheme.cardBorder),
              ),
              child: Text(tab.label, style: GoogleFonts.inter(fontSize: 10, color: selected ? RevoTheme.primaryLight : RevoTheme.textSecondary)),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        if (tabs.first.nestedFields != null)
          ...tabs.first.nestedFields!.take(3).map((child) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => ref.read(selectedFieldIdProvider.notifier).state = child.id,
                  child: _buildCanvasComponentPreview(child, stepId),
                ),
              )),
      ],
    );
  }

  Map<String, dynamic> _componentConfig(JourneyField field) {
    return Map<String, dynamic>.from(field.componentConfig ?? {});
  }

  List<Map<String, dynamic>> _configList(JourneyField field, String key, List<Map<String, dynamic>> fallback) {
    final value = _componentConfig(field)[key];
    if (value is List) {
      final parsed = value
          .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
          .where((item) => item.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }
    return fallback;
  }

  Widget _buildTableGridPreview(JourneyField field) {
    final columns = _configList(field, 'columns', [
      if (field.nestedFields != null && field.nestedFields!.isNotEmpty)
        ...field.nestedFields!.map((nested) => {'label': nested.label, 'fieldId': nested.id})
      else ...[
        {'label': '#'},
        {'label': 'Column A'},
        {'label': 'Action'},
      ],
    ]).take(4).toList();
    return Container(
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        children: List.generate(3, (row) {
          return Row(
            children: List.generate(columns.length, (col) {
              return Expanded(
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    border: Border(
                      right: col < 2 ? BorderSide(color: RevoTheme.cardBorder) : BorderSide.none,
                      bottom: row < 2 ? BorderSide(color: RevoTheme.cardBorder) : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    row == 0 ? (columns[col]['label']?.toString() ?? 'Column') : (col == columns.length - 1 ? 'Edit' : 'Value'),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: row == 0 ? FontWeight.w700 : FontWeight.w400,
                      color: row == 0 ? RevoTheme.textPrimary : RevoTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildRepeaterPreview(JourneyField field) {
    final config = _componentConfig(field);
    final fields = _configList(field, 'fields', [
      if (field.nestedFields != null && field.nestedFields!.isNotEmpty)
        ...field.nestedFields!.map((nested) => {'label': nested.label, 'fieldId': nested.id})
      else ...[
        {'label': 'Name'},
        {'label': 'Value'},
      ],
    ]).take(3).toList();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.view_week_outlined, size: 16, color: RevoTheme.primaryLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${config['itemLabel'] ?? 'Item'} 1",
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: RevoTheme.textPrimary),
                ),
              ),
              if (config['allowRemove'] != false) Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: fields
                .map(
                  (item) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                      decoration: BoxDecoration(
                        color: RevoTheme.cardBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: RevoTheme.cardBorder),
                      ),
                      child: Text(item['label']?.toString() ?? 'Field', style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary), overflow: TextOverflow.ellipsis),
                    ),
                  ),
                )
                .toList(),
          ),
          if (config['allowAdd'] != false) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("+ ${config['addButtonLabel'] ?? 'Add Item'}", style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.primaryLight, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelinePreview(JourneyField field) {
    final items = _configList(field, 'items', [
      {'title': 'Started', 'status': 'completed'},
      {'title': 'In Progress', 'status': 'active'},
      {'title': 'Completed', 'status': 'pending'},
    ]).take(4).toList();
    Color statusColor(String? status) {
      switch (status) {
        case 'completed':
          return RevoTheme.secondary;
        case 'active':
          return RevoTheme.primaryLight;
        case 'failed':
          return Colors.redAccent;
        default:
          return RevoTheme.textSecondary;
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        children: items.map((item) {
          final color = statusColor(item['status']?.toString());
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item['title']?.toString() ?? 'Timeline item', style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textPrimary), overflow: TextOverflow.ellipsis),
                ),
                Text(item['status']?.toString() ?? 'pending', style: GoogleFonts.inter(fontSize: 9, color: color)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRulesTab(JourneyStep step) {
    final allFields = ref.watch(journeyConfigProvider.select((config) => config.steps.expand((s) => s.fields).toList()));
    final allSteps = ref.watch(journeyConfigProvider.select((config) => config.steps));
    
    return Expanded(
      flex: 3,
      child: Container(
        color: RevoTheme.background,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Step Conditional Rules",
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Define conditions to show/hide/enable fields or branch steps dynamically.",
                      style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RevoTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    final defaultField = allFields.isNotEmpty ? allFields.first.id : "";
                    final newCondition = StepCondition(
                      type: "visibleIf",
                      field: defaultField,
                      operator: "equals",
                      value: "",
                    );
                    ref.read(journeyConfigProvider.notifier).addConditionToStep(step.id, newCondition);
                  },
                  icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  label: const Text("Add Rule"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: step.conditions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rule_folder_outlined, size: 48, color: RevoTheme.textSecondary.withValues(alpha:0.4)),
                          const SizedBox(height: 12),
                          Text(
                            "No conditional rules defined for this step.",
                            style: GoogleFonts.inter(color: RevoTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: step.conditions.length,
                      itemBuilder: (context, index) {
                        final condition = step.conditions[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: RevoTheme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: RevoTheme.cardBorder, width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Rule #${index + 1}",
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: RevoTheme.primaryLight),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      ref.read(journeyConfigProvider.notifier).removeConditionFromStep(step.id, index);
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // 1. Target field
                                  Expanded(
                                    flex: 3,
                                    child: _CanvasDropdownField(
                                      label: "If Field",
                                      value: condition.field,
                                      items: allFields.map((f) => f.id).toList(),
                                      fallback: "Select Field",
                                      onChanged: (val) {
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateConditionInStep(step.id, index, condition.copyWith(field: val));
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // 2. Action Type (visibleIf, etc.)
                                  Expanded(
                                    flex: 2,
                                    child: _CanvasDropdownField(
                                      label: "Action",
                                      value: condition.type,
                                      items: const ["visibleIf", "showIf", "enableIf", "nextStepIf"],
                                      fallback: "visibleIf",
                                      onChanged: (val) {
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateConditionInStep(step.id, index, condition.copyWith(type: val));
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // 3. Operator
                                  Expanded(
                                    flex: 2,
                                    child: _CanvasDropdownField(
                                      label: "Operator",
                                      value: condition.operator,
                                      items: const ["equals", "notEquals", "contains"],
                                      fallback: "equals",
                                      onChanged: (val) {
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateConditionInStep(step.id, index, condition.copyWith(operator: val));
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // 4. Value
                                  Expanded(
                                    flex: 3,
                                    child: _CanvasTextField(
                                      label: "Value",
                                      initialValue: condition.value,
                                      onChanged: (val) {
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateConditionInStep(step.id, index, condition.copyWith(value: val.trim()));
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (condition.type == 'nextStepIf') ...[
                                const SizedBox(height: 12),
                                _CanvasDropdownField(
                                  label: "Branch Target Step",
                                  value: condition.targetStep ?? "",
                                  items: allSteps.map((s) => s.id).toList(),
                                  fallback: "Select Target Step",
                                  onChanged: (val) {
                                    ref.read(journeyConfigProvider.notifier)
                                        .updateConditionInStep(step.id, index, condition.copyWith(targetStep: val));
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationsTab(JourneyStep step) {
    final allFields = step.fields;
    
    return Expanded(
      flex: 3,
      child: Container(
        color: RevoTheme.background,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Step Validations Builder",
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Define custom validation constraints, regex matches, or required fields for this step.",
                      style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RevoTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    final defaultField = allFields.isNotEmpty ? allFields.first.id : "";
                    final newValidation = StepValidation(
                      type: "required",
                      field: defaultField,
                      message: "This field is required",
                    );
                    ref.read(journeyConfigProvider.notifier).addValidationToStep(step.id, newValidation);
                  },
                  icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  label: const Text("Add Validation"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: step.validations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gpp_maybe_outlined, size: 48, color: RevoTheme.textSecondary.withValues(alpha:0.4)),
                          const SizedBox(height: 12),
                          Text(
                            "No custom validations configured for this step.",
                            style: GoogleFonts.inter(color: RevoTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: step.validations.length,
                      itemBuilder: (context, index) {
                        final validation = step.validations[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: RevoTheme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: RevoTheme.cardBorder, width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Validation #${index + 1}",
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: RevoTheme.primaryLight),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      ref.read(journeyConfigProvider.notifier).removeValidationFromStep(step.id, index);
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // 1. Field
                                  Expanded(
                                    flex: 3,
                                    child: _CanvasDropdownField(
                                      label: "Target Field",
                                      value: validation.field,
                                      items: allFields.map((f) => f.id).toList(),
                                      fallback: "Select Field",
                                      onChanged: (val) {
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateValidationInStep(step.id, index, validation.copyWith(field: val));
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // 2. Type
                                  Expanded(
                                    flex: 2,
                                    child: _CanvasDropdownField(
                                      label: "Validation Type",
                                      value: validation.type,
                                      items: const ["required", "regex", "async", "dependency"],
                                      fallback: "required",
                                      onChanged: (val) {
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateValidationInStep(step.id, index, validation.copyWith(type: val));
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // 3. Error message
                                  Expanded(
                                    flex: 5,
                                    child: _CanvasTextField(
                                      label: "Error Message",
                                      initialValue: validation.message,
                                      onChanged: (val) {
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateValidationInStep(step.id, index, validation.copyWith(message: val.trim()));
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (validation.type == 'regex') ...[
                                const SizedBox(height: 12),
                                _CanvasTextField(
                                  label: "Regex Pattern",
                                  initialValue: validation.regexPattern ?? "",
                                  hint: "e.g. ^[a-zA-Z]+\$ or ^[0-9]{6}\$",
                                  onChanged: (val) {
                                    ref.read(journeyConfigProvider.notifier)
                                        .updateValidationInStep(step.id, index, validation.copyWith(regexPattern: val.trim().isEmpty ? null : val.trim()));
                                  },
                                ),
                              ] else if (validation.type == 'async') ...[
                                const SizedBox(height: 12),
                                _CanvasTextField(
                                  label: "Async Validation URL Path",
                                  initialValue: validation.validationUrl ?? "",
                                  hint: "e.g. /api/v1/validate/pan-number or https://api.val.com/check",
                                  onChanged: (val) {
                                    ref.read(journeyConfigProvider.notifier)
                                        .updateValidationInStep(step.id, index, validation.copyWith(validationUrl: val.trim().isEmpty ? null : val.trim()));
                                  },
                                ),
                              ] else if (validation.type == 'dependency') ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _CanvasDropdownField(
                                        label: "Dependent Field ID",
                                        value: validation.dependentField ?? "",
                                        items: allFields.map((f) => f.id).where((id) => id != validation.field).toList(),
                                        fallback: "Select Dependent Field",
                                        onChanged: (val) {
                                          ref.read(journeyConfigProvider.notifier)
                                              .updateValidationInStep(step.id, index, validation.copyWith(dependentField: val.isEmpty ? null : val));
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _CanvasTextField(
                                        label: "Expected Value to Require Field",
                                        initialValue: validation.dependentValue ?? "",
                                        hint: "e.g. Married or Yes",
                                        onChanged: (val) {
                                          ref.read(journeyConfigProvider.notifier)
                                              .updateValidationInStep(step.id, index, validation.copyWith(dependentValue: val.trim().isEmpty ? null : val.trim()));
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiTab(JourneyStep step) {
    return Expanded(
      flex: 3,
      child: Container(
        color: RevoTheme.background,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Step API Integrations",
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Configure background REST API actions executed on step initialization or submit.",
                      style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RevoTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    final newApi = StepAPI(
                      method: "GET",
                      url: "",
                      description: "New Step API Call",
                    );
                    ref.read(journeyConfigProvider.notifier).addApiCallToStep(step.id, newApi);
                  },
                  icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  label: const Text("Add API Call"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: step.apiCalls.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.api_rounded, size: 48, color: RevoTheme.textSecondary.withValues(alpha:0.4)),
                          const SizedBox(height: 12),
                          Text(
                            "No background API calls configured for this step.",
                            style: GoogleFonts.inter(color: RevoTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: step.apiCalls.length,
                      itemBuilder: (context, index) {
                        final api = step.apiCalls[index];
                        final isTestingThis = _testingStepApi && _testingStepApiIndex == index;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: RevoTheme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: RevoTheme.cardBorder, width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "API Call #${index + 1}",
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: RevoTheme.primaryLight),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      ref.read(journeyConfigProvider.notifier).removeApiCallFromStep(step.id, index);
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // 1. Method selector
                                  Expanded(
                                    flex: 2,
                                    child: _CanvasDropdownField(
                                      label: "Method",
                                      value: api.method,
                                      items: const ["GET", "POST", "PUT", "DELETE"],
                                      fallback: "GET",
                                      onChanged: (val) {
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateApiCallInStep(step.id, index, api.copyWith(method: val));
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // 2. URL
                                  Expanded(
                                    flex: 6,
                                    child: _CanvasTextField(
                                      label: "Endpoint URL Path",
                                      initialValue: api.url,
                                      hint: "e.g. /api/v1/user/details or https://api.endpoint.com",
                                      onChanged: (val) {
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateApiCallInStep(step.id, index, api.copyWith(url: val.trim()));
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // 3. Description
                                  Expanded(
                                    flex: 4,
                                    child: _CanvasTextField(
                                      label: "Description / Action Label",
                                      initialValue: api.description,
                                      hint: "e.g. Fetch user balance",
                                      onChanged: (val) {
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateApiCallInStep(step.id, index, api.copyWith(description: val.trim()));
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _CanvasTextField(
                                      label: "Request Headers (JSON Map format)",
                                      initialValue: api.headers != null ? json.encode(api.headers) : "",
                                      hint: 'e.g. {"Authorization": "Bearer ..."}',
                                      onChanged: (val) {
                                        try {
                                          Map<String, dynamic>? newHeaders;
                                          if (val.trim().isEmpty) {
                                            newHeaders = null;
                                          } else {
                                            final decoded = json.decode(val);
                                            if (decoded is Map) newHeaders = Map<String, dynamic>.from(decoded);
                                          }
                                          ref.read(journeyConfigProvider.notifier)
                                              .updateApiCallInStep(step.id, index, api.copyWith(headers: newHeaders));
                                        } catch (_) {}
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _CanvasTextField(
                                      label: "Request Body Payload (JSON string)",
                                      initialValue: api.body ?? "",
                                      hint: 'e.g. {"userId": 123}',
                                      onChanged: (val) {
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateApiCallInStep(step.id, index, api.copyWith(body: val.trim().isEmpty ? null : val.trim()));
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: RevoTheme.cardBg,
                                      foregroundColor: RevoTheme.textPrimary,
                                      side: BorderSide(color: RevoTheme.primaryLight.withValues(alpha:0.4)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    onPressed: isTestingThis ? null : () async {
                                      setState(() {
                                        _testingStepApi = true;
                                        _testingStepApiIndex = index;
                                        _stepApiTestResult = null;
                                      });
                                      
                                      if (api.url.isEmpty) {
                                        setState(() {
                                          _testingStepApi = false;
                                          _stepApiTestSuccess = false;
                                          _stepApiTestResult = "Error: Endpoint URL Path is required to test.";
                                        });
                                        return;
                                      }
                                      
                                      try {
                                        final headersStr = api.headers?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? <String, String>{};
                                        final method = api.method.toUpperCase();
                                        final uri = Uri.parse(api.url);
                                        
                                        http.Response response;
                                        if (method == 'POST') {
                                          response = await http.post(uri, headers: headersStr, body: api.body);
                                        } else if (method == 'PUT') {
                                          response = await http.put(uri, headers: headersStr, body: api.body);
                                        } else if (method == 'DELETE') {
                                          response = await http.delete(uri, headers: headersStr, body: api.body);
                                        } else {
                                          response = await http.get(uri, headers: headersStr);
                                        }
                                        
                                        final responseBody = response.body.length > 200 
                                            ? '${response.body.substring(0, 200)}...' 
                                            : response.body;
                                        
                                        setState(() {
                                          _testingStepApi = false;
                                          _stepApiTestSuccess = response.statusCode >= 200 && response.statusCode < 300;
                                          _stepApiTestResult = "Status: ${response.statusCode} ${response.reasonPhrase}\nResponse:\n$responseBody";
                                        });
                                      } catch (e) {
                                        setState(() {
                                          _testingStepApi = false;
                                          _stepApiTestSuccess = false;
                                          _stepApiTestResult = "Error: Failed to connect.\n${e.toString()}";
                                        });
                                      }
                                    },
                                    icon: isTestingThis
                                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(Icons.bolt_rounded, size: 14),
                                    label: Text("Test Connection", style: GoogleFonts.inter(fontSize: 11)),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: RevoTheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("Step API #${index + 1} Configuration saved!"),
                                          backgroundColor: RevoTheme.secondary,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                                    label: Text("Submit Configuration", style: GoogleFonts.inter(fontSize: 11)),
                                  ),
                                ],
                              ),
                              if (_stepApiTestResult != null && _testingStepApiIndex == index) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: RevoTheme.background,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _stepApiTestSuccess 
                                          ? RevoTheme.success.withValues(alpha:0.3) 
                                          : RevoTheme.error.withValues(alpha:0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _stepApiTestResult!,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: _stepApiTestSuccess ? Colors.greenAccent : Colors.redAccent,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab(JourneyStep step) {
    final allSteps = ref.watch(journeyConfigProvider.select((config) => config.steps));
    final otherStepIds = allSteps.map((s) => s.id).where((id) => id != step.id).toList();
    
    return Expanded(
      flex: 3,
      child: Container(
        color: RevoTheme.background,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Step Details & Settings",
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                "Configure basic metadata and step flow transition configurations.",
                style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: RevoTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: RevoTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CanvasTextField(
                      label: "Step ID (Unique identifier)",
                      initialValue: step.id,
                      onChanged: (val) {
                        final clean = val.trim();
                        if (clean.isEmpty || clean == step.id) return;
                        
                        final exists = allSteps.any((s) => s.id == clean);
                        if (exists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Step ID must be unique!"), backgroundColor: Colors.redAccent),
                          );
                          return;
                        }
                        
                        final updated = step.copyWith(id: clean);
                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
                        ref.read(activeStepIdProvider.notifier).state = clean;
                      },
                    ),
                    const SizedBox(height: 16),
                    _CanvasTextField(
                      label: "Step Title",
                      initialValue: step.title,
                      onChanged: (val) {
                        final updated = step.copyWith(title: val.trim());
                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
                      },
                    ),
                    const SizedBox(height: 16),
                    _CanvasTextField(
                      label: "Step Description / Subtitle",
                      initialValue: step.description,
                      maxLines: 3,
                      onChanged: (val) {
                        final updated = step.copyWith(description: val.trim());
                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
                      },
                    ),
                    const SizedBox(height: 16),
                    _CanvasDropdownField(
                      label: "Next Flow Step ID",
                      value: step.nextStep ?? "",
                      items: otherStepIds,
                      fallback: "None (End of Journey)",
                      onChanged: (val) {
                        final updated = step.copyWith(nextStep: val.isEmpty ? null : val);
                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsTab(JourneyStep step) {
    return Expanded(
      flex: 3,
      child: Container(
        color: RevoTheme.background,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Step Lifecycle Actions",
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Trigger background behaviors, navigation, or popups when actions run.",
                      style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RevoTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    final newAction = StepAction(
                      trigger: "onSubmit",
                      actionType: "showBanner",
                      details: "Action details here",
                    );
                    ref.read(journeyConfigProvider.notifier).addActionToStep(step.id, newAction);
                  },
                  icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  label: const Text("Add Action"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: step.actions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flash_on_rounded, size: 48, color: RevoTheme.textSecondary.withValues(alpha:0.4)),
                          const SizedBox(height: 12),
                          Text(
                            "No step-level actions configured yet.",
                            style: GoogleFonts.inter(color: RevoTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: step.actions.length,
                      itemBuilder: (context, index) {
                        final action = step.actions[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: RevoTheme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: RevoTheme.cardBorder, width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Action #${index + 1}",
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: RevoTheme.primaryLight),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      ref.read(journeyConfigProvider.notifier).removeActionFromStep(step.id, index);
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _CanvasDropdownField(
                                      label: "Trigger Event",
                                      value: action.trigger,
                                      items: const ["onSubmit", "onFieldChange"],
                                      fallback: "onSubmit",
                                      onChanged: (val) {
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateActionInStep(step.id, index, action.copyWith(trigger: val));
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: _CanvasDropdownField(
                                      label: "Action Type",
                                      value: action.actionType,
                                      items: const ["apiCall", "navigate", "showBanner"],
                                      fallback: "showBanner",
                                      onChanged: (val) {
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateActionInStep(step.id, index, action.copyWith(actionType: val));
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 6,
                                    child: _CanvasTextField(
                                      label: "Action Details / Payload",
                                      initialValue: action.details,
                                      hint: "e.g. Save details or stepId",
                                      onChanged: (val) {
                                        ref.read(journeyConfigProvider.notifier)
                                            .updateActionInStep(step.id, index, action.copyWith(details: val.trim()));
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreview(JourneyStep step, Map<String, dynamic> formValues, String? previousStepId, String? nextStepId) {
    if (!_isMobilePreview) {
      // Laptop / Desktop Preview
      return Expanded(
        flex: 4, // Make it wider to display desktop format cleanly
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: RevoTheme.cardBorder, width: 1),
            ),
            color: RevoTheme.background,
          ),
          padding: const EdgeInsets.all(20.0),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Laptop screen bezel
                Container(
                  width: 480,
                  height: 330,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: RevoTheme.cardBorder, width: 8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Web browser window header
                      Container(
                        height: 28,
                        color: RevoTheme.sidebarBackground,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            // Dots
                            Row(
                              children: [
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.amberAccent, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // URL Address Bar
                            Expanded(
                              child: Container(
                                height: 18,
                                decoration: BoxDecoration(
                                  color: RevoTheme.background,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  children: [
                                    Icon(Icons.lock_outline_rounded, size: 10, color: RevoTheme.success),
                                    const SizedBox(width: 4),
                                    Text(
                                      "revojourneytryone.com/run/journey",
                                      style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary.withValues(alpha:0.7)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Browser Web Viewport
                      Expanded(
                        child: Container(
                          color: RevoTheme.background,
                          padding: const EdgeInsets.all(12),
                          alignment: Alignment.center,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Glassmorphic layout card matching runner_screen's width: 500 equivalent
                                Container(
                                  width: 360, // Mini responsive card inside simulator
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: RevoTheme.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: RevoTheme.cardBorder, width: 1),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1F000000),
                                        blurRadius: 12,
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        step.title,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: RevoTheme.textPrimary,
                                        ),
                                      ),
                                      if (step.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          step.description,
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            color: RevoTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      
                                      // Fields Mockups
                                      ...step.fields.map((field) {
                                        final isVisible = EngineHelper.isFieldVisible(field, formValues);
                                        if (!isVisible) return const SizedBox.shrink();

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 10.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (field.type != 'divider') ...[
                                                Row(
                                                  children: [
                                                    Text(
                                                      field.label,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 9,
                                                        color: RevoTheme.textSecondary,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    if (field.required)
                                                      const Text(" *", style: TextStyle(color: Colors.red, fontSize: 9)),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                              _buildMobileFieldMockup(field, formValues),
                                            ],
                                          ),
                                        );
                                      }),
                                      
                                      const SizedBox(height: 12),
                                      // Navigation Actions Mockup
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (previousStepId != null)
                                            OutlinedButton(
                                              onPressed: () {
                                                ref.read(activeStepIdProvider.notifier).state = previousStepId;
                                                ref.read(selectedFieldIdProvider.notifier).state = null;
                                              },
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: const Text("Back", style: TextStyle(fontSize: 9)),
                                            )
                                          else
                                            const SizedBox.shrink(),
                                          ElevatedButton(
                                            onPressed: () {
                                              if (nextStepId != null) {
                                                ref.read(activeStepIdProvider.notifier).state = nextStepId;
                                                ref.read(selectedFieldIdProvider.notifier).state = null;
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              nextStepId == null ? "Submit" : "Next",
                                              style: const TextStyle(fontSize: 9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Laptop Hinge and base plate
                Container(
                  width: 500,
                  height: 8,
                  decoration: BoxDecoration(
                    color: RevoTheme.isDark ? const Color(0xFF3A3A4E) : const Color(0xFFCBD5E1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ),
                Container(
                  width: 530,
                  height: 10,
                  decoration: BoxDecoration(
                    color: RevoTheme.isDark ? const Color(0xFF222234) : const Color(0xFF94A3B8),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: RevoTheme.isDark ? Colors.black38 : Colors.white60,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Default Mobile View
    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: RevoTheme.cardBorder, width: 1),
          ),
          color: RevoTheme.background,
        ),
        padding: const EdgeInsets.all(24.0),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            width: 250,
            height: 520,
            decoration: BoxDecoration(
              color: RevoTheme.isDark ? Colors.black : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: RevoTheme.isDark ? RevoTheme.cardBorder : const Color(0xFF334155), width: 8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                color: RevoTheme.background,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    // Mobile status indicator bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "9:41",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: RevoTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.wifi, size: 10, color: RevoTheme.textPrimary),
                            const SizedBox(width: 4),
                            Icon(Icons.signal_cellular_4_bar_rounded, size: 10, color: RevoTheme.textPrimary),
                            const SizedBox(width: 4),
                            Icon(Icons.battery_5_bar_rounded, size: 10, color: RevoTheme.textPrimary),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Screen Title
                    Text(
                      step.title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: RevoTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (step.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        step.description,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: RevoTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Fields Renders inside Simulator
                    Expanded(
                      child: ListView.builder(
                        itemCount: step.fields.length,
                        itemBuilder: (context, index) {
                          final field = step.fields[index];
                          final isVisible = EngineHelper.isFieldVisible(field, formValues);
                          if (!isVisible) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (field.type != 'divider') ...[
                                  Row(
                                    children: [
                                      Text(
                                        field.label,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: RevoTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (field.required)
                                        const Text(" *", style: TextStyle(color: Colors.red, fontSize: 10)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                _buildMobileFieldMockup(field, formValues),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Button actions inside simulator
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nextStepId != null) {
                            ref.read(activeStepIdProvider.notifier).state = nextStepId;
                            ref.read(selectedFieldIdProvider.notifier).state = null;
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          nextStepId == null ? "Submit" : "Next",
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFieldMockup(JourneyField field, Map<String, dynamic> formValues) {
    final builder = _mockupRegistry[field.type.toLowerCase()];
    if (builder != null) return builder(field, formValues);
    return _mockupDefault(field, formValues);
  }

  Widget _mockupDefault(JourneyField field, Map<String, dynamic> formValues) => SizedBox(height: field.type == 'textarea' ? 60 : 32, child: TextField(maxLines: field.type == 'textarea' ? 3 : 1, style: TextStyle(fontSize: 10, color: RevoTheme.textPrimary), decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), hintText: field.placeholder ?? "Enter value", hintStyle: TextStyle(fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5)), fillColor: RevoTheme.background, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.primaryLight))), onChanged: (val) => ref.read(formValuesProvider.notifier).updateValue(field.id, val)));
  Widget _mockupPhone(JourneyField field, Map<String, dynamic> formValues) => Row(children: [Container(height: 32, padding: const EdgeInsets.symmetric(horizontal: 6), decoration: BoxDecoration(color: RevoTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: RevoTheme.cardBorder)), alignment: Alignment.center, child: Text("🇮🇳 +91", style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary))), const SizedBox(width: 4), Expanded(child: SizedBox(height: 32, child: TextField(style: TextStyle(fontSize: 10, color: RevoTheme.textPrimary), decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), hintText: field.placeholder ?? "Enter mobile", hintStyle: TextStyle(fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5)), fillColor: RevoTheme.background, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.primaryLight))), onChanged: (val) => ref.read(formValuesProvider.notifier).updateValue(field.id, val))))]);
  Widget _mockupOtp(JourneyField field, Map<String, dynamic> formValues) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(6, (_) => Container(width: 28, height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: RevoTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: RevoTheme.cardBorder)), child: Text("-", style: TextStyle(fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha: 0.6))))));
  Widget _mockupFile(JourneyField field, Map<String, dynamic> formValues) => Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: RevoTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: RevoTheme.cardBorder)), child: Column(children: [Icon(field.type == 'image' ? Icons.image_outlined : Icons.cloud_upload_outlined, size: 18, color: RevoTheme.primaryLight), const SizedBox(height: 4), Text(field.placeholder ?? 'Upload file', style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary))]));
  Widget _mockupDate(JourneyField field, Map<String, dynamic> formValues) { final value = formValues[field.id]?.toString() ?? ''; return InkWell(onTap: () async { if (field.type == 'time') { final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now()); if (picked != null) ref.read(formValuesProvider.notifier).updateValue(field.id, picked.format(context)); return; } final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime(2100)); if (picked != null) { final formatted = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}"; ref.read(formValuesProvider.notifier).updateValue(field.id, formatted); } }, child: Container(height: 32, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: RevoTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: RevoTheme.cardBorder)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(value.isNotEmpty ? value : (field.placeholder ?? (field.type == 'time' ? "HH:MM" : "DD/MM/YYYY")), style: TextStyle(fontSize: 10, color: value.isNotEmpty ? RevoTheme.textPrimary : RevoTheme.textSecondary.withValues(alpha:0.5))), Icon(Icons.calendar_today_rounded, size: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5))]))); }
  Widget _mockupSwitch(JourneyField field, Map<String, dynamic> formValues) { final value = formValues[field.id]?.toString() ?? ''; final isSwitched = value == 'true'; return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(field.label, style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary)), Transform.scale(scale: 0.6, child: Switch(value: isSwitched, onChanged: (val) => ref.read(formValuesProvider.notifier).updateValue(field.id, val.toString())))]); }
  Widget _mockupCheckbox(JourneyField field, Map<String, dynamic> formValues) { final value = formValues[field.id]?.toString() ?? ''; final isChecked = value == 'true'; return InkWell(onTap: () => ref.read(formValuesProvider.notifier).updateValue(field.id, (!isChecked).toString()), child: Row(children: [Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, size: 14, color: isChecked ? RevoTheme.primaryLight : RevoTheme.textSecondary.withValues(alpha:0.5)), const SizedBox(width: 6), Expanded(child: Text(field.label, style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary)))])); }
  Widget _mockupRadio(JourneyField field, Map<String, dynamic> formValues) { final value = formValues[field.id]?.toString() ?? ''; final options = field.getResolvedOptions(); final displayOptions = options.isEmpty ? ["Option 1", "Option 2"] : options; return Wrap(spacing: 6, children: displayOptions.map((opt) { final isSelected = value == opt; return InkWell(onTap: () => ref.read(formValuesProvider.notifier).updateValue(field.id, opt), child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isSelected ? RevoTheme.primary : RevoTheme.background, borderRadius: BorderRadius.circular(4), border: Border.all(color: isSelected ? RevoTheme.primaryLight : RevoTheme.cardBorder)), child: Text(opt, style: TextStyle(fontSize: 8, color: isSelected ? Colors.white : RevoTheme.textSecondary, fontWeight: FontWeight.bold)))); }).toList()); }
  Widget _mockupApiDropdown(JourneyField field, Map<String, dynamic> formValues) => Container(height: 32, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: RevoTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: RevoTheme.cardBorder)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(field.dropdownApiUrl != null && field.dropdownApiUrl!.isNotEmpty ? "API: ${field.dropdownApiUrl}" : (field.placeholder ?? field.hintText ?? "Select (API Loaded)"), style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary.withValues(alpha:0.5), overflow: TextOverflow.ellipsis))), Icon(Icons.cloud_sync_outlined, size: 12, color: RevoTheme.primaryLight)]));
  Widget _mockupDropdown(JourneyField field, Map<String, dynamic> formValues) { final value = formValues[field.id]?.toString() ?? ''; final options = field.getResolvedOptions(); final displayOptions = options.isEmpty ? ["Option 1", "Option 2"] : options; return Container(height: 32, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: RevoTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: RevoTheme.cardBorder)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: displayOptions.contains(value) ? value : null, hint: Text(field.placeholder ?? field.hintText ?? "Select", style: TextStyle(fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5))), isExpanded: true, dropdownColor: RevoTheme.cardBg, style: TextStyle(fontSize: 10, color: RevoTheme.textPrimary), items: displayOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 10)))).toList(), onChanged: (val) { if (val != null) ref.read(formValuesProvider.notifier).updateValue(field.id, val); }))); }

  Widget _buildCompactComponentShell(IconData icon, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: RevoTheme.primaryLight),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNestedPreview(JourneyField field, IconData icon, Map<String, dynamic> formValues) {
    final children = field.nestedFields ?? const <JourneyField>[];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: RevoTheme.primaryLight),
              const SizedBox(width: 8),
              Expanded(child: Text(field.label, style: TextStyle(fontSize: 9, color: RevoTheme.textPrimary), overflow: TextOverflow.ellipsis)),
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...children.take(3).map((child) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildMobileFieldMockup(child, formValues),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactNestedRowPreview(JourneyField field, Map<String, dynamic> formValues) {
    final children = field.nestedFields ?? const <JourneyField>[];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: children.take(3).map((child) {
        return SizedBox(width: 120, child: _buildMobileFieldMockup(child, formValues));
      }).toList(),
    );
  }

  Widget _buildCompactNestedTabsPreview(JourneyField field, Map<String, dynamic> formValues) {
    final tabs = field.nestedFields ?? const <JourneyField>[];
    final labels = tabs.isEmpty ? ['Tab 1', 'Tab 2'] : tabs.map((tab) => tab.label).toList();
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: labels.map((tab) {
        final selected = tab == labels.first;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? RevoTheme.primary.withValues(alpha: 0.18) : RevoTheme.background,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: selected ? RevoTheme.primaryLight : RevoTheme.cardBorder),
          ),
          child: Text(tab, style: TextStyle(fontSize: 8, color: selected ? RevoTheme.primaryLight : RevoTheme.textSecondary)),
        );
      }).toList(),
    );
  }

  Widget _buildCompactTablePreview(JourneyField field) {
    final columns = _configList(field, 'columns', [
      if (field.nestedFields != null && field.nestedFields!.isNotEmpty)
        ...field.nestedFields!.map((nested) => {'label': nested.label, 'fieldId': nested.id})
      else ...[
        {'label': '#'},
        {'label': 'Label'},
        {'label': 'Act'},
      ],
    ]).take(3).toList();
    return Container(
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        children: List.generate(3, (row) {
          return Row(
            children: List.generate(columns.length, (col) {
              return Expanded(
                child: Container(
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      right: col < 2 ? BorderSide(color: RevoTheme.cardBorder) : BorderSide.none,
                      bottom: row < 2 ? BorderSide(color: RevoTheme.cardBorder) : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    row == 0 ? (columns[col]['label']?.toString() ?? 'Col') : (col == 0 ? '1' : 'Value'),
                    style: TextStyle(fontSize: 8, color: row == 0 ? RevoTheme.textPrimary : RevoTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildCompactRepeaterPreview(JourneyField field) {
    final config = _componentConfig(field);
    final fields = _configList(field, 'fields', [
      if (field.nestedFields != null && field.nestedFields!.isNotEmpty)
        ...field.nestedFields!.map((nested) => {'label': nested.label, 'fieldId': nested.id})
      else ...[
        {'label': 'Name'},
        {'label': 'Value'},
      ],
    ]).take(2).toList();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.view_week_outlined, size: 14, color: RevoTheme.primaryLight),
              const SizedBox(width: 6),
              Expanded(child: Text("${config['itemLabel'] ?? 'Item'} 1", style: TextStyle(fontSize: 9, color: RevoTheme.textPrimary))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: fields
                .map((item) => Expanded(
                      child: Container(
                        height: 24,
                        margin: const EdgeInsets.only(right: 4),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: RevoTheme.cardBg,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: RevoTheme.cardBorder),
                        ),
                        child: Text(item['label']?.toString() ?? 'Field', style: TextStyle(fontSize: 8, color: RevoTheme.textSecondary), overflow: TextOverflow.ellipsis),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTimelinePreview(JourneyField field) {
    final items = _configList(field, 'items', [
      {'title': 'Started', 'status': 'completed'},
      {'title': 'Current', 'status': 'active'},
      {'title': 'Done', 'status': 'pending'},
    ]).take(3).toList();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RevoTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: item['status'] == 'completed' ? RevoTheme.secondary : RevoTheme.primaryLight),
                      const SizedBox(width: 6),
                      Expanded(child: Text(item['title']?.toString() ?? 'Step', style: TextStyle(fontSize: 8, color: RevoTheme.textSecondary), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

}

class _CanvasToolbox extends StatelessWidget {
  final List<Map<String, dynamic>> componentGroups;
  final ValueChanged<String> onAddField;

  const _CanvasToolbox({
    Key? key,
    required this.componentGroups,
    required this.onAddField,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: RevoTheme.cardBorder, width: 1),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: componentGroups.expand<Widget>((group) {
          final items = group['items'] as List<Map<String, dynamic>>;
          return [
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                group['title'] as String,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: RevoTheme.textSecondary,
                ),
              ),
            ),
            ...items.map((item) {
              final type = item['type'] as String;
              return Draggable<String>(
                data: type,
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 112,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: RevoTheme.primary.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: RevoTheme.primaryLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item['icon'] as IconData, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item['label'] as String,
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: RevoTheme.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: RevoTheme.cardBorder),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onAddField(type),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      child: Row(
                        children: [
                          Icon(item['icon'] as IconData, size: 16, color: RevoTheme.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['label'] as String,
                              style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ];
        }).toList(),
      ),
    );
  }
}

class _CanvasBottomStats extends StatelessWidget {
  final JourneyStep step;

  const _CanvasBottomStats({Key? key, required this.step}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = [
      {'label': 'Validations', 'val': '${step.validations.length} Rules', 'icon': Icons.gpp_maybe_rounded, 'color': RevoTheme.warning},
      {'label': 'Conditions', 'val': '${step.conditions.length} Rules', 'icon': Icons.rule_rounded, 'color': RevoTheme.primaryLight},
      {'label': 'API Calls', 'val': '${step.apiCalls.length} Configured', 'icon': Icons.api_rounded, 'color': RevoTheme.accent},
      {'label': 'Actions', 'val': '${step.actions.length} Configured', 'icon': Icons.flash_on_rounded, 'color': RevoTheme.secondary},
    ];

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: RevoTheme.cardBorder, width: 1),
        ),
        color: RevoTheme.sidebarBackground,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: stats.map((stat) {
            final color = stat['color'] as Color;
            return Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RevoTheme.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: RevoTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(stat['icon'] as IconData, size: 24, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          stat['label'] as String,
                          style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stat['val'] as String,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CanvasDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final String fallback;
  final ValueChanged<String> onChanged;

  const _CanvasDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.fallback,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final list = ["", ...items];
    final current = list.contains(value) ? value : "";
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: RevoTheme.cardBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: RevoTheme.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              isExpanded: true,
              dropdownColor: RevoTheme.cardBg,
              style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textPrimary),
              icon: Icon(Icons.arrow_drop_down, color: RevoTheme.textSecondary, size: 18),
              items: list.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item.isEmpty ? fallback : item),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  onChanged(val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CanvasTextField extends StatefulWidget {
  final String label;
  final String initialValue;
  final String? hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _CanvasTextField({
    required this.label,
    required this.initialValue,
    this.hint,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  State<_CanvasTextField> createState() => _CanvasTextFieldState();
}

class _CanvasTextFieldState extends State<_CanvasTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _CanvasTextField oldWidget) {
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
        Text(widget.label, style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            filled: true,
            fillColor: RevoTheme.cardBg,
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
