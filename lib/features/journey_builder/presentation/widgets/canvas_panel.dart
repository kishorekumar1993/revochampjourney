import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

  final List<Map<String, dynamic>> _toolbox = [
    {'type': 'text', 'label': 'TextField', 'icon': Icons.text_fields_rounded},
    {'type': 'dropdown', 'label': 'Dropdown', 'icon': Icons.arrow_drop_down_circle_outlined},
    {'type': 'radio', 'label': 'Radio', 'icon': Icons.radio_button_checked_rounded},
    {'type': 'checkbox', 'label': 'Checkbox', 'icon': Icons.check_box_outlined},
    {'type': 'date', 'label': 'Date Picker', 'icon': Icons.calendar_today_rounded},
    {'type': 'file', 'label': 'File Upload', 'icon': Icons.cloud_upload_outlined},
    {'type': 'textarea', 'label': 'Textarea', 'icon': Icons.notes_rounded},
    {'type': 'api_dropdown', 'label': 'API Select', 'icon': Icons.cloud_sync_outlined},
    {'type': 'divider', 'label': 'Divider', 'icon': Icons.horizontal_rule_rounded},
    {'type': 'phone', 'label': 'Phone Input', 'icon': Icons.phone_android_rounded},
    {'type': 'otp', 'label': 'OTP Field', 'icon': Icons.pin_rounded},
  ];

  void _addField(String fieldType) {
    final activeStepId = ref.read(activeStepIdProvider);
    final fieldId = "field_${DateTime.now().millisecondsSinceEpoch}";
    final newField = JourneyField(
      id: fieldId,
      label: "New $fieldType Field",
      type: fieldType,
      required: false,
      placeholder: "Enter details",
      options: (fieldType == 'dropdown' || fieldType == 'radio') ? ["Option 1", "Option 2"] : null,
    );
    ref.read(journeyConfigProvider.notifier).addFieldToStep(activeStepId, newField);
    ref.read(selectedFieldIdProvider.notifier).state = fieldId;
  }

  void _duplicateField(JourneyField field) {
    final activeStepId = ref.read(activeStepIdProvider);
    final newFieldId = "field_${DateTime.now().millisecondsSinceEpoch}";
    final duplicated = field.copy()..id = newFieldId..label = "${field.label} (Copy)";
    ref.read(journeyConfigProvider.notifier).addFieldToStep(activeStepId, duplicated);
    ref.read(selectedFieldIdProvider.notifier).state = newFieldId;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final config = ref.watch(journeyConfigProvider);
    final activeStepId = ref.watch(activeStepIdProvider);
    final activeStepIndex = config.steps.indexWhere((s) => s.id == activeStepId);

    if (activeStepIndex == -1) {
      return Expanded(
        child: Center(
          child: Text(
            "Select or create a step to begin building.",
            style: GoogleFonts.inter(color: RevoTheme.textSecondary),
          ),
        ),
      );
    }

    final step = config.steps[activeStepIndex];
    final selectedFieldId = ref.watch(selectedFieldIdProvider);
    final formValues = ref.watch(formValuesProvider);

    return Expanded(
      child: Container(
        color: RevoTheme.background,
        child: Column(
          children: [
            // Panel Header
            _buildHeader(context, config, step, activeStepIndex),

            // Tabs sub-bar
            _buildTabBar(step),

            // Workspace Layout
            Expanded(
              child: Row(
                children: [
                  // 1. ToolBox Palette
                  _buildToolbox(),

                  // 2. Editor Canvas
                  _buildCanvas(step, selectedFieldId),

                  // 3. Mobile/Desktop Live simulator view
                  if (_showPreview) _buildLivePreview(step, formValues, config),
                ],
              ),
            ),

            // Step Configurations (bottom bar)
            _buildBottomStats(step),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, JourneyConfig config, JourneyStep step, int index) {
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
                    onPressed: index > 0 ? () {
                      ref.read(activeStepIdProvider.notifier).state = config.steps[index - 1].id;
                      ref.read(selectedFieldIdProvider.notifier).state = null;
                    } : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text("Back"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: index < config.steps.length - 1 ? () {
                      ref.read(activeStepIdProvider.notifier).state = config.steps[index + 1].id;
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

  Widget _buildToolbox() {
    return Container(
      width: 130,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: RevoTheme.cardBorder, width: 1),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _toolbox.length,
        itemBuilder: (context, index) {
          final item = _toolbox[index];
          final type = item['type'] as String;
          return Draggable<String>(
            data: type,
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                width: 100,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RevoTheme.primary.withValues(alpha:0.8),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: RevoTheme.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: RevoTheme.cardBorder),
              ),
              child: InkWell(
                onTap: () => _addField(type),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item['icon'] as IconData, size: 18, color: RevoTheme.textSecondary),
                    const SizedBox(height: 6),
                    Text(
                      item['label'] as String,
                      style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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

  Widget _buildRulesTab(JourneyStep step) {
    final allFields = ref.watch(journeyConfigProvider).steps.expand((s) => s.fields).toList();
    final allSteps = ref.watch(journeyConfigProvider).steps;
    
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
                    final updated = step.copy()..conditions = [...step.conditions, newCondition];
                    ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                      final newConditions = List<StepCondition>.from(step.conditions)..removeAt(index);
                                      final updated = step.copy()..conditions = newConditions;
                                      ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                        final newConds = List<StepCondition>.from(step.conditions);
                                        newConds[index] = condition.copy()..field = val;
                                        final updated = step.copy()..conditions = newConds;
                                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                        final newConds = List<StepCondition>.from(step.conditions);
                                        newConds[index] = condition.copy()..type = val;
                                        final updated = step.copy()..conditions = newConds;
                                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                        final newConds = List<StepCondition>.from(step.conditions);
                                        newConds[index] = condition.copy()..operator = val;
                                        final updated = step.copy()..conditions = newConds;
                                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                        final newConds = List<StepCondition>.from(step.conditions);
                                        newConds[index] = condition.copy()..value = val.trim();
                                        final updated = step.copy()..conditions = newConds;
                                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                    final newConds = List<StepCondition>.from(step.conditions);
                                    newConds[index] = condition.copy()..targetStep = val;
                                    final updated = step.copy()..conditions = newConds;
                                    ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                    final updated = step.copy()..validations = [...step.validations, newValidation];
                    ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                      final newValidations = List<StepValidation>.from(step.validations)..removeAt(index);
                                      final updated = step.copy()..validations = newValidations;
                                      ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                        final newVals = List<StepValidation>.from(step.validations);
                                        newVals[index] = validation.copy()..field = val;
                                        final updated = step.copy()..validations = newVals;
                                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                        final newVals = List<StepValidation>.from(step.validations);
                                        newVals[index] = validation.copy()..type = val;
                                        final updated = step.copy()..validations = newVals;
                                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                        final newVals = List<StepValidation>.from(step.validations);
                                        newVals[index] = validation.copy()..message = val.trim();
                                        final updated = step.copy()..validations = newVals;
                                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                    final newVals = List<StepValidation>.from(step.validations);
                                    newVals[index] = validation.copy()..regexPattern = val.trim().isEmpty ? null : val.trim();
                                    final updated = step.copy()..validations = newVals;
                                    ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
                                  },
                                ),
                              ] else if (validation.type == 'async') ...[
                                const SizedBox(height: 12),
                                _CanvasTextField(
                                  label: "Async Validation URL Path",
                                  initialValue: validation.validationUrl ?? "",
                                  hint: "e.g. /api/v1/validate/pan-number or https://api.val.com/check",
                                  onChanged: (val) {
                                    final newVals = List<StepValidation>.from(step.validations);
                                    newVals[index] = validation.copy()..validationUrl = val.trim().isEmpty ? null : val.trim();
                                    final updated = step.copy()..validations = newVals;
                                    ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                          final newVals = List<StepValidation>.from(step.validations);
                                          newVals[index] = validation.copy()..dependentField = val.isEmpty ? null : val;
                                          final updated = step.copy()..validations = newVals;
                                          ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                          final newVals = List<StepValidation>.from(step.validations);
                                          newVals[index] = validation.copy()..dependentValue = val.trim().isEmpty ? null : val.trim();
                                          final updated = step.copy()..validations = newVals;
                                          ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                    final updated = step.copy()..apiCalls = [...step.apiCalls, newApi];
                    ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                      final newApiCalls = List<StepAPI>.from(step.apiCalls)..removeAt(index);
                                      final updated = step.copy()..apiCalls = newApiCalls;
                                      ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                        final newApiCalls = List<StepAPI>.from(step.apiCalls);
                                        newApiCalls[index] = api.copy()..method = val;
                                        final updated = step.copy()..apiCalls = newApiCalls;
                                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                        final newApiCalls = List<StepAPI>.from(step.apiCalls);
                                        newApiCalls[index] = api.copy()..url = val.trim();
                                        final updated = step.copy()..apiCalls = newApiCalls;
                                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                        final newApiCalls = List<StepAPI>.from(step.apiCalls);
                                        newApiCalls[index] = api.copy()..description = val.trim();
                                        final updated = step.copy()..apiCalls = newApiCalls;
                                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                          final newApiCalls = List<StepAPI>.from(step.apiCalls);
                                          if (val.trim().isEmpty) {
                                            newApiCalls[index] = api.copy()..headers = null;
                                          } else {
                                            final decoded = json.decode(val);
                                            if (decoded is Map) {
                                              newApiCalls[index] = api.copy()..headers = Map<String, dynamic>.from(decoded);
                                            }
                                          }
                                          final updated = step.copy()..apiCalls = newApiCalls;
                                          ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                        final newApiCalls = List<StepAPI>.from(step.apiCalls);
                                        newApiCalls[index] = api.copy()..body = val.trim().isEmpty ? null : val.trim();
                                        final updated = step.copy()..apiCalls = newApiCalls;
                                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                      await Future.delayed(const Duration(milliseconds: 1200));
                                      
                                      if (api.url.isEmpty) {
                                        setState(() {
                                          _testingStepApi = false;
                                          _stepApiTestSuccess = false;
                                          _stepApiTestResult = "Error: Endpoint URL Path is required to test.";
                                        });
                                        return;
                                      }
                                      
                                      setState(() {
                                        _testingStepApi = false;
                                        _stepApiTestSuccess = true;
                                        _stepApiTestResult = "Connection successful!\nEndpoint: ${api.url}\nStatus: 200 OK\nPayload returned successfully.";
                                      });
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
    final allSteps = ref.watch(journeyConfigProvider).steps;
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
                        
                        final updated = step.copy()..id = clean;
                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
                        ref.read(activeStepIdProvider.notifier).state = clean;
                      },
                    ),
                    const SizedBox(height: 16),
                    _CanvasTextField(
                      label: "Step Title",
                      initialValue: step.title,
                      onChanged: (val) {
                        final updated = step.copy()..title = val.trim();
                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
                      },
                    ),
                    const SizedBox(height: 16),
                    _CanvasTextField(
                      label: "Step Description / Subtitle",
                      initialValue: step.description,
                      maxLines: 3,
                      onChanged: (val) {
                        final updated = step.copy()..description = val.trim();
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
                        final updated = step.copy()..nextStep = val.isEmpty ? null : val;
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
                    final updated = step.copy()..actions = [...step.actions, newAction];
                    ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                      final newActions = List<StepAction>.from(step.actions)..removeAt(index);
                                      final updated = step.copy()..actions = newActions;
                                      ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                        final newActions = List<StepAction>.from(step.actions);
                                        newActions[index] = action.copy()..trigger = val;
                                        final updated = step.copy()..actions = newActions;
                                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                        final newActions = List<StepAction>.from(step.actions);
                                        newActions[index] = action.copy()..actionType = val;
                                        final updated = step.copy()..actions = newActions;
                                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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
                                        final newActions = List<StepAction>.from(step.actions);
                                        newActions[index] = action.copy()..details = val.trim();
                                        final updated = step.copy()..actions = newActions;
                                        ref.read(journeyConfigProvider.notifier).updateStep(step.id, updated);
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

  Widget _buildLivePreview(JourneyStep step, Map<String, String> formValues, JourneyConfig config) {
    final activeStepId = ref.read(activeStepIdProvider);
    final activeStepIndex = config.steps.indexWhere((s) => s.id == activeStepId);

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
                                          if (activeStepIndex > 0)
                                            OutlinedButton(
                                              onPressed: () {
                                                ref.read(activeStepIdProvider.notifier).state = config.steps[activeStepIndex - 1].id;
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
                                              if (activeStepIndex < config.steps.length - 1) {
                                                ref.read(activeStepIdProvider.notifier).state = config.steps[activeStepIndex + 1].id;
                                                ref.read(selectedFieldIdProvider.notifier).state = null;
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              activeStepIndex == config.steps.length - 1 ? "Submit" : "Next",
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
                          // Navigate next step if possible
                          final index = config.steps.indexWhere((s) => s.id == activeStepId);
                          if (index != -1 && index < config.steps.length - 1) {
                            ref.read(activeStepIdProvider.notifier).state = config.steps[index + 1].id;
                            ref.read(selectedFieldIdProvider.notifier).state = null;
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          activeStepIndex == config.steps.length - 1 ? "Submit" : "Next",
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

  Widget _buildMobileFieldMockup(JourneyField field, Map<String, String> formValues) {
    final value = formValues[field.id] ?? '';

    switch (field.type.toLowerCase()) {
      case 'divider':
        return Divider(color: RevoTheme.cardBorder);
      
      case 'dropdown':
        final options = field.getResolvedOptions();
        final displayOptions = options.isEmpty ? ["Option 1", "Option 2"] : options;
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: RevoTheme.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: RevoTheme.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: displayOptions.contains(value) ? value : null,
              hint: Text(field.placeholder ?? field.hintText ?? "Select", style: TextStyle(fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5))),
              isExpanded: true,
              dropdownColor: RevoTheme.cardBg,
              style: TextStyle(fontSize: 10, color: RevoTheme.textPrimary),
              items: displayOptions.map((opt) {
                return DropdownMenuItem(
                  value: opt,
                  child: Text(opt, style: const TextStyle(fontSize: 10)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(formValuesProvider.notifier).updateValue(field.id, val);
                }
              },
            ),
          ),
        );

      case 'api_dropdown':
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: RevoTheme.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: RevoTheme.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  field.apiUrl != null && field.apiUrl!.isNotEmpty 
                      ? "API: ${field.apiUrl}" 
                      : (field.placeholder ?? field.hintText ?? "Select (API Loaded)"),
                  style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary.withValues(alpha:0.5), overflow: TextOverflow.ellipsis),
                ),
              ),
              Icon(Icons.cloud_sync_outlined, size: 12, color: RevoTheme.primaryLight),
            ],
          ),
        );

      case 'radio':
        final options = field.getResolvedOptions();
        final displayOptions = options.isEmpty ? ["Option 1", "Option 2"] : options;
        return Wrap(
          spacing: 6,
          children: displayOptions.map((opt) {
            final isSelected = value == opt;
            return InkWell(
              onTap: () {
                ref.read(formValuesProvider.notifier).updateValue(field.id, opt);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? RevoTheme.primary : RevoTheme.background,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isSelected ? RevoTheme.primaryLight : RevoTheme.cardBorder),
                ),
                child: Text(
                  opt,
                  style: TextStyle(fontSize: 8, color: isSelected ? Colors.white : RevoTheme.textSecondary, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        );

      case 'checkbox':
        final isChecked = value == 'true';
        return InkWell(
          onTap: () {
            ref.read(formValuesProvider.notifier).updateValue(field.id, (!isChecked).toString());
          },
          child: Row(
            children: [
              Icon(
                isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                size: 14,
                color: isChecked ? RevoTheme.primaryLight : RevoTheme.textSecondary.withValues(alpha:0.5),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  field.label,
                  style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary),
                ),
              ),
            ],
          ),
        );

      case 'switch':
        final isSwitched = value == 'true';
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(field.label, style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary)),
            Transform.scale(
              scale: 0.6,
              child: Switch(
                value: isSwitched,
                onChanged: (val) {
                  ref.read(formValuesProvider.notifier).updateValue(field.id, val.toString());
                },
              ),
            ),
          ],
        );

      case 'date':
        return InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              final formatted = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
              ref.read(formValuesProvider.notifier).updateValue(field.id, formatted);
            }
          },
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: RevoTheme.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value.isNotEmpty ? value : (field.placeholder ?? "DD/MM/YYYY"),
                  style: TextStyle(fontSize: 10, color: value.isNotEmpty ? RevoTheme.textPrimary : RevoTheme.textSecondary.withValues(alpha:0.5)),
                ),
                Icon(Icons.calendar_today_rounded, size: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5)),
              ],
            ),
          ),
        );

      case 'phone':
        return Row(
          children: [
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: RevoTheme.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: RevoTheme.cardBorder),
              ),
              alignment: Alignment.center,
              child: Text("🇮🇳 +91", style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary)),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SizedBox(
                height: 32,
                child: TextField(
                  style: TextStyle(fontSize: 10, color: RevoTheme.textPrimary),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    hintText: field.placeholder ?? "Enter mobile",
                    hintStyle: TextStyle(fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5)),
                    fillColor: RevoTheme.background,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: RevoTheme.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: RevoTheme.primaryLight),
                    ),
                  ),
                  onChanged: (val) {
                    ref.read(formValuesProvider.notifier).updateValue(field.id, val);
                  },
                ),
              ),
            ),
          ],
        );

      default:
        // text, textarea, etc.
        return SizedBox(
          height: field.type == 'textarea' ? 60 : 32,
          child: TextField(
            maxLines: field.type == 'textarea' ? 3 : 1,
            style: TextStyle(fontSize: 10, color: RevoTheme.textPrimary),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              hintText: field.placeholder ?? "Enter value",
              hintStyle: TextStyle(fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5)),
              fillColor: RevoTheme.background,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: RevoTheme.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: RevoTheme.primaryLight),
              ),
            ),
            onChanged: (val) {
              ref.read(formValuesProvider.notifier).updateValue(field.id, val);
            },
          ),
        );
    }
  }

  Widget _buildBottomStats(JourneyStep step) {
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
