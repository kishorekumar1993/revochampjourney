import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme.dart';
import '../../data/models.dart';
import '../providers/journey_provider.dart';

class BuildAuditResult {
  final List<String> errors;
  final List<String> warnings;

  const BuildAuditResult({
    required this.errors,
    required this.warnings,
  });
}

/// Memoized provider that recalculates the audit ONLY when journeyConfigProvider changes.
final buildAuditProvider = Provider.autoDispose<BuildAuditResult>((ref) {
  final config = ref.watch(journeyConfigProvider);
  final List<String> buildErrors = [];
  final List<String> buildWarnings = [];
  final allFieldIds = <String>{};
  final duplicatedFieldIds = <String>{};

  for (final s in config.steps) {
    if (s.fields.isEmpty) {
      buildWarnings.add("Step '${s.title}' has no fields on the canvas.");
    }
    for (final f in s.fields) {
      if (allFieldIds.contains(f.id)) {
        duplicatedFieldIds.add(f.id);
      } else {
        allFieldIds.add(f.id);
      }
      if (f.label.trim().isEmpty) {
        buildWarnings.add("Field '${f.id}' in Step '${s.title}' has an empty label.");
      }
      if ((f.type == 'dropdown' || f.type == 'radio' || f.type == 'multi_select') &&
          f.useStaticOptions &&
          (f.staticOptions == null || f.staticOptions!.isEmpty)) {
        buildWarnings.add("Dropdown/Radio field '${f.id}' has static options enabled but none configured.");
      }
      if (f.type == 'api_dropdown' && (f.dropdownApiUrl == null || f.dropdownApiUrl!.isEmpty)) {
        buildErrors.add("API Dropdown '${f.id}' is missing its Endpoint URL.");
      }
    }

    // Check Step Conditions
    for (final cond in s.conditions) {
      if (cond.field.isNotEmpty && !allFieldIds.contains(cond.field)) {
        buildErrors.add("Step '${s.title}' condition references non-existent field ID '${cond.field}'.");
      }
      if (cond.type == 'nextStepIf' && (cond.targetStep == null || !config.steps.any((step) => step.id == cond.targetStep))) {
        buildErrors.add("Step '${s.title}' branch target step '${cond.targetStep}' does not exist.");
      }
    }

    // Check Step Validations
    for (final val in s.validations) {
      if (val.field.isNotEmpty && !s.fields.any((f) => f.id == val.field)) {
        buildErrors.add("Step '${s.title}' validation references non-existent field ID '${val.field}'.");
      }
      if (val.type == 'dependency' && val.dependentField != null && !s.fields.any((f) => f.id == val.dependentField)) {
        buildErrors.add("Step '${s.title}' dependency validation references non-existent dependent field '${val.dependentField}'.");
      }
    }

    // Check Step APIs
    for (final api in s.apiCalls) {
      if (api.url.trim().isEmpty) {
        buildErrors.add("Step '${s.title}' has an API action with an empty Endpoint URL.");
      }
    }
  }
  for (final dup in duplicatedFieldIds) {
    buildErrors.add("Duplicate field ID '$dup' found across steps.");
  }

  for (int i = 0; i < config.steps.length; i++) {
    final step = config.steps[i];
    if (step.nextStep != null && step.nextStep!.isNotEmpty) {
      if (!config.steps.any((s) => s.id == step.nextStep)) {
        buildErrors.add("Step '${step.title}' next transition step '${step.nextStep}' does not exist.");
      }
    }
    if (i < config.steps.length - 1) {
      final next = step.nextStep;
      final hasBranch = step.conditions.any((c) => c.type == 'nextStepIf');
      if ((next == null || next.trim().isEmpty) && !hasBranch) {
        buildWarnings.add("Step '${step.title}' has no transition link to follow next.");
      }
    }
  }

  return BuildAuditResult(errors: buildErrors, warnings: buildWarnings);
});

class RevoStepsPanel extends ConsumerStatefulWidget {
  const RevoStepsPanel({super.key});

  @override
  ConsumerState<RevoStepsPanel> createState() => _RevoStepsPanelState();
}

class _RevoStepsPanelState extends ConsumerState<RevoStepsPanel> {
  String _activeSidebarTab = 'Journey Flow';
  
  // Local state for Build compilation mockup
  bool _compiling = false;
  bool _buildRan = false;
  
  // Global settings controllers
  late TextEditingController _nameController;
  late TextEditingController _versionController;
  late TextEditingController _descriptionController;
  String _selectedCategory = 'Onboarding';
  String _selectedLocale = 'English (US)';
  String _selectedPlatform = 'All Devices';
  
  late FocusNode _nameFocus;
  late FocusNode _versionFocus;
  late FocusNode _descriptionFocus;
  
  ProviderSubscription<JourneyConfig>? _configSubscription;
  
  @override
  void initState() {
    super.initState();
    final config = ref.read(journeyConfigProvider);
    _nameController = TextEditingController(text: config.journeyName);
    _versionController = TextEditingController(text: config.version);
    _descriptionController = TextEditingController(text: config.description);
    _selectedCategory = config.category;
    _selectedLocale = config.locale;
    _selectedPlatform = config.platform;
    
    _nameFocus = FocusNode();
    _versionFocus = FocusNode();
    _descriptionFocus = FocusNode();

    // Safely sync input fields if config changes externally (e.g., JSON import or history rollback).
    // Checks focus to prevent erasing trailing spaces while the user is actively typing.
    _configSubscription = ref.listenManual<JourneyConfig>(journeyConfigProvider, (prev, next) {
      if (!_nameFocus.hasFocus && _nameController.text != next.journeyName) {
        _nameController.text = next.journeyName;
      }
      if (!_versionFocus.hasFocus && _versionController.text != next.version) {
        _versionController.text = next.version;
      }
      if (!_descriptionFocus.hasFocus && _descriptionController.text != next.description) {
        _descriptionController.text = next.description;
      }
      if (_selectedCategory != next.category) {
        setState(() => _selectedCategory = next.category);
      }
      if (_selectedLocale != next.locale) {
        setState(() => _selectedLocale = next.locale);
      }
      if (_selectedPlatform != next.platform) {
        setState(() => _selectedPlatform = next.platform);
      }
    });
  }

  @override
  void dispose() {
    _configSubscription?.close();
    _nameController.dispose();
    _versionController.dispose();
    _descriptionController.dispose();
    _nameFocus.dispose();
    _versionFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  IconData _getStepIcon(String stepId) {
    switch (stepId) {
      case 'personal':
        return Icons.person_outline_rounded;
      case 'vehicle':
        return Icons.directions_car_filled_outlined;
      case 'nominee':
        return Icons.people_alt_outlined;
      case 'documents':
        return Icons.file_upload_outlined;
      case 'review':
        return Icons.rate_review_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'success':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  void _showAddStepDialog(BuildContext context) {
    final titleController = TextEditingController();
    final idController = TextEditingController();
    String? idError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
        backgroundColor: RevoTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: RevoTheme.cardBorder),
        ),
        title: Text(
          "Add New Journey Step",
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Step Title",
                hintText: "e.g. Address Details",
              ),
              onChanged: (val) {
                setState(() {
                  idController.text = val.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
                  idError = null;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: idController,
              decoration: InputDecoration(
                labelText: "Step ID (Unique Key)",
                hintText: "e.g. address_details",
                errorText: idError,
              ),
              onChanged: (_) {
                if (idError != null) setState(() => idError = null);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: RevoTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final id = idController.text.trim();
              if (title.isNotEmpty && id.isNotEmpty) {
                final config = ref.read(journeyConfigProvider);
                if (config.steps.any((s) => s.id == id)) {
                  setState(() => idError = "Step ID already exists.");
                  return;
                }
                final newStep = JourneyStep(
                  id: id,
                  title: title,
                  fields: [],
                );
                ref.read(journeyConfigProvider.notifier).addStep(newStep);
                ref.read(activeStepIdProvider.notifier).state = id;
                Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch themeModeProvider to trigger a rebuild when the global theme changes
    ref.watch(themeModeProvider);
    final config = ref.watch(journeyConfigProvider);
    final activeStepId = ref.watch(activeStepIdProvider);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(
          right: BorderSide(color: RevoTheme.cardBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Info
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        config.journeyName,
                        style: TextStyle(fontFamily: 'Outfit', 
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: RevoTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Tooltip(
                      message: "Rename Journey",
                      child: IconButton(
                      icon: Icon(Icons.edit, size: 16, color: RevoTheme.textSecondary),
                      onPressed: () {
                        // Rename journey dialog
                        final nameCtrl = TextEditingController(text: config.journeyName);
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: RevoTheme.cardBg,
                            title: const Text("Rename Journey"),
                            content: TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(labelText: "Journey Name"),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(journeyConfigProvider.notifier)
                                      .updateJourneyName(nameCtrl.text.trim());
                                  Navigator.pop(context);
                                },
                                child: const Text("Save"),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      "Version ${config.version}",
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTabItem("Journey Flow", _activeSidebarTab == 'Journey Flow', () {
                  setState(() => _activeSidebarTab = 'Journey Flow');
                }),
                _buildTabItem("Build", _activeSidebarTab == 'Build', () {
                  setState(() => _activeSidebarTab = 'Build');
                }),
                _buildTabItem("Settings", _activeSidebarTab == 'Settings', () {
                  setState(() => _activeSidebarTab = 'Settings');
                }),
                _buildTabItem("History", _activeSidebarTab == 'History', () {
                  setState(() => _activeSidebarTab = 'History');
                }),
              ],
            ),
          ),
          Divider(color: RevoTheme.cardBorder),

          // Active Tab Content
          Expanded(
            child: _buildTabContent(config, activeStepId),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: isSelected 
                ? Border(bottom: BorderSide(color: RevoTheme.primary, width: 2))
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? RevoTheme.textPrimary : RevoTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(JourneyConfig config, String activeStepId) {
    switch (_activeSidebarTab) {
      case 'Build':
        return _buildBuildTabContent(config);
      case 'Settings':
        return _buildSettingsTabContent(config);
      case 'History':
        return _buildHistoryTabContent(config);
      case 'Journey Flow':
      default:
        return _buildJourneyFlowTabContent(config, activeStepId);
    }
  }

  Widget _buildJourneyFlowTabContent(JourneyConfig config, String activeStepId) {
    final totalSteps = config.steps.length;
    final activeIndex = config.steps.indexWhere((s) => s.id == activeStepId);
    final completedSteps = activeIndex >= 0 ? activeIndex : 0;
    final percentage = totalSteps > 0 
        ? ((completedSteps / totalSteps) * 100).round() 
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Steps list title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Journey Steps",
                style: TextStyle(fontFamily: 'Outfit', 
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: RevoTheme.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddStepDialog(context),
                icon: Icon(Icons.add, size: 14, color: RevoTheme.primaryLight),
                label: Text(
                  "Add Step",
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: RevoTheme.primaryLight,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),

        // Reorderable Steps List
        Expanded(
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.transparent,
            ),
            child: ReorderableListView.builder(
              itemCount: config.steps.length,
              onReorder: (oldIndex, newIndex) {
                ref.read(journeyConfigProvider.notifier).reorderSteps(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final step = config.steps[index];
                final isSelected = step.id == activeStepId;
                final stepNum = index + 1;

                return Padding(
                  key: ValueKey(step.id),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    selected: isSelected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected 
                            ? RevoTheme.primary 
                            : RevoTheme.cardBorder,
                        width: 1.5,
                      ),
                    ),
                    tileColor: RevoTheme.cardBg,
                    selectedTileColor: RevoTheme.primary.withValues(alpha: 0.1),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Icon(
                            Icons.drag_indicator_rounded, 
                            color: RevoTheme.textSecondary, 
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? RevoTheme.primary 
                                : RevoTheme.cardBorder,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "$stepNum",
                            style: TextStyle(fontFamily: 'Inter', 
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : RevoTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      step.title,
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: RevoTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "${step.fields.length} fields • id: ${step.id}",
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: RevoTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStepIcon(step.id),
                          color: isSelected ? RevoTheme.primary : RevoTheme.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, size: 16, color: RevoTheme.textSecondary),
                          color: RevoTheme.cardBg,
                          onSelected: (val) {
                            if (val == 'delete') {
                              final currentActive = ref.read(activeStepIdProvider);
                              ref.read(journeyConfigProvider.notifier).removeStep(step.id);
                              if (currentActive == step.id) {
                                final steps = ref.read(journeyConfigProvider).steps;
                                final newActive = steps.isNotEmpty ? steps.first.id : '';
                                ref.read(activeStepIdProvider.notifier).state = newActive;
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
                                  SizedBox(width: 8),
                                  Text("Delete Step", style: TextStyle(color: Colors.red, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      ref.read(activeStepIdProvider.notifier).state = step.id;
                      ref.read(selectedFieldIdProvider.notifier).state = null;
                    },
                  ),
                );
              },
            ),
          ),
        ),

        // Journey Progress Radial Gauge & Preview Button
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: RevoTheme.sidebarBackground,
            border: Border(
              top: BorderSide(color: RevoTheme.cardBorder, width: 1),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: RevoTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: RevoTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Journey Progress",
                      style: TextStyle(fontFamily: 'Outfit', 
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: RevoTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 70,
                              height: 70,
                              child: CircularProgressIndicator(
                                value: totalSteps > 0 ? (completedSteps / totalSteps) : 0,
                                strokeWidth: 8,
                                backgroundColor: RevoTheme.cardBorder,
                                color: RevoTheme.primary,
                              ),
                            ),
                            Text(
                              "$percentage%",
                              style: TextStyle(fontFamily: 'Outfit', 
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: RevoTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProgressMetric("Completed Steps", "$completedSteps/$totalSteps"),
                              const SizedBox(height: 6),
                              _buildProgressMetric("In Progress", activeIndex >= 0 ? "1" : "0"),
                              const SizedBox(height: 6),
                              _buildProgressMetric("Remaining", "${totalSteps - completedSteps}"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push('/runner');
                  },
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                  label: const Text("Preview Journey"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: RevoTheme.primary),
                    foregroundColor: RevoTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBuildTabContent(JourneyConfig config) {
    // 1. Run validation audits on config
    final auditResult = ref.watch(buildAuditProvider);
    final buildErrors = auditResult.errors;
    final buildWarnings = auditResult.warnings;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Compile & Verify",
            style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            "Validate structural integrity, configurations, and API integrity checks.",
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: RevoTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _compiling
                ? null
                : () async {
                    setState(() {
                      _compiling = true;
                      _buildRan = false;
                    });
                    await Future.delayed(const Duration(milliseconds: 1000));
                    if (!mounted) return;
                    setState(() {
                      _compiling = false;
                      _buildRan = true;
                    });
                  },
            icon: _compiling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.flash_on_rounded, size: 16, color: Colors.white),
            label: Text(_compiling ? "Compiling..." : "Run Journey Audit", style: const TextStyle(color: Colors.white)),
          ),

          const SizedBox(height: 20),
          Expanded(
            child: _compiling
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Compiling rules and paths...", style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textSecondary)),
                        const SizedBox(height: 12),
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      ],
                    ),
                  )
                : !_buildRan
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.terminal_rounded, size: 36, color: RevoTheme.textSecondary.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text(
                              "Click button above to compile and run build checks.",
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary, height: 1.4),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Summary Report Card
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: buildErrors.isEmpty ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: buildErrors.isEmpty ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    buildErrors.isEmpty ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
                                    color: buildErrors.isEmpty ? Colors.greenAccent : Colors.redAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          buildErrors.isEmpty ? "Build Verified Successfully" : "Build Verification Failed",
                                          style: TextStyle(fontFamily: 'Inter', 
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: buildErrors.isEmpty ? Colors.greenAccent : Colors.redAccent,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${buildErrors.length} Errors, ${buildWarnings.length} Warnings found.",
                                          style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            if (buildErrors.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text("Errors (${buildErrors.length})", style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                              const SizedBox(height: 6),
                              ...buildErrors.map((err) => _buildIssueTile(err, Colors.redAccent)),
                            ],

                            if (buildWarnings.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text("Warnings (${buildWarnings.length})", style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                              const SizedBox(height: 6),
                              ...buildWarnings.map((warn) => _buildIssueTile(warn, Colors.orangeAccent)),
                            ],

                            if (buildErrors.isEmpty && buildWarnings.isEmpty) ...[
                              const SizedBox(height: 40),
                              Icon(Icons.done_all_rounded, size: 48, color: RevoTheme.success.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                "Excellent! All structural logic is verified and compiled cleanly.",
                                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.success, height: 1.4),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueTile(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 6, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textPrimary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTabContent(JourneyConfig config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Global Journey Settings",
            style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            "Configure journey properties and settings globally.",
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // Name field
          Text("Journey Title", style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            focusNode: _nameFocus,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: TextStyle(fontFamily: 'Inter', fontSize: 12),
            onChanged: (val) {
              ref.read(journeyConfigProvider.notifier).updateJourneyName(val.trim());
            },
          ),
          const SizedBox(height: 16),

          // Description field
          Text("Journey Description", style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            maxLines: 3,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: TextStyle(fontFamily: 'Inter', fontSize: 12),
            onChanged: (val) {
              ref.read(journeyConfigProvider.notifier).updateJourneyDescription(val.trim());
            },
          ),
          const SizedBox(height: 16),

          // Version field
          Text("Semantic Version", style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _versionController,
            focusNode: _versionFocus,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: TextStyle(fontFamily: 'Inter', fontSize: 12),
            onChanged: (val) {
              ref.read(journeyConfigProvider.notifier).updateJourneyVersion(val.trim());
            },
          ),
          const SizedBox(height: 16),

          // Category Selector
          Text("Journey Category", style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: RevoTheme.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: RevoTheme.cardBg,
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textPrimary),
                items: ['Onboarding', 'KYC Verification', 'Fintech Form', 'General Claim'].map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                    ref.read(journeyConfigProvider.notifier).updateJourneyCategory(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Locale Selector
          Text("Default System Language", style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: RevoTheme.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLocale,
                isExpanded: true,
                dropdownColor: RevoTheme.cardBg,
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textPrimary),
                items: ['English (US)', 'Spanish (ES)', 'Hindi (IN)', 'German (DE)'].map((loc) {
                  return DropdownMenuItem(value: loc, child: Text(loc));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedLocale = val);
                    ref.read(journeyConfigProvider.notifier).updateJourneyLocale(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Platform selector
          Text("Target Run Environment", style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: RevoTheme.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPlatform,
                isExpanded: true,
                dropdownColor: RevoTheme.cardBg,
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textPrimary),
                items: ['All Devices', 'Mobile Web Only', 'Desktop Only'].map((plat) {
                  return DropdownMenuItem(value: plat, child: Text(plat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedPlatform = val);
                    ref.read(journeyConfigProvider.notifier).updateJourneyPlatform(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RevoTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Journey Settings saved!"),
                  backgroundColor: RevoTheme.success,
                ),
              );
            },
            child: const Text("Save Global Settings", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTabContent(JourneyConfig config) {
    final historyState = ref.watch(historyProvider);
    final past = historyState.past;
    final future = historyState.future;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Change & State History",
            style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            "Undo, redo, and review past builder sessions state trails.",
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Undo/Redo Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: past.isEmpty
                      ? null
                      : () {
                          ref.read(historyProvider.notifier).undo();
                          // Reset active step to avoid dangling reference
                          final restoredConfig = ref.read(journeyConfigProvider);
                          final firstStepId = restoredConfig.steps.isNotEmpty ? restoredConfig.steps.first.id : '';
                          ref.read(activeStepIdProvider.notifier).state = firstStepId;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Undone last change!"), duration: Duration(milliseconds: 600)),
                          );
                        },
                  icon: const Icon(Icons.undo_rounded, size: 14),
                  label: Text("Undo (${past.length})", style: const TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: past.isEmpty ? RevoTheme.cardBorder : RevoTheme.primaryLight),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: future.isEmpty
                      ? null
                      : () {
                          ref.read(historyProvider.notifier).redo();
                          // Reset active step to avoid dangling reference
                          final restoredConfig = ref.read(journeyConfigProvider);
                          final firstStepId = restoredConfig.steps.isNotEmpty ? restoredConfig.steps.first.id : '';
                          ref.read(activeStepIdProvider.notifier).state = firstStepId;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Redone change!"), duration: Duration(milliseconds: 600)),
                          );
                        },
                  icon: const Icon(Icons.redo_rounded, size: 14),
                  label: Text("Redo (${future.length})", style: const TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: future.isEmpty ? RevoTheme.cardBorder : RevoTheme.primaryLight),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            "Version Audit Timeline",
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: past.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 36, color: RevoTheme.textSecondary.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          "No past edits recorded yet.\nMake changes to log history checkpoints.",
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: past.length + 1,
                    itemBuilder: (context, index) {
                      final isCurrent = index == past.length;
                      final snap = isCurrent ? historyState.present : past[index];
                      final stepsCount = snap.steps.length;
                      final fieldsCount = snap.steps.fold<int>(0, (sum, s) => sum + s.fields.length);
                      
                      return InkWell(
                        onTap: isCurrent
                            ? null
                            : () {
                                ref.read(historyProvider.notifier).rollbackTo(index);
                                // Reset active step to avoid dangling reference
                                final restoredConfig = ref.read(journeyConfigProvider);
                                final firstStepId = restoredConfig.steps.isNotEmpty ? restoredConfig.steps.first.id : '';
                                ref.read(activeStepIdProvider.notifier).state = firstStepId;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Restored state #${index + 1}!"), backgroundColor: RevoTheme.success),
                                );
                              },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCurrent ? RevoTheme.primary.withValues(alpha: 0.1) : RevoTheme.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrent ? RevoTheme.primary : RevoTheme.cardBorder,
                              width: isCurrent ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCurrent ? Icons.circle : Icons.history_rounded,
                                color: isCurrent ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isCurrent ? "Current Version (Active)" : "State Checkpoint #${index + 1}",
                                      style: TextStyle(fontFamily: 'Inter', 
                                        fontSize: 11,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                        color: isCurrent ? RevoTheme.textPrimary : RevoTheme.textPrimary.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "$stepsCount steps, $fieldsCount fields configured.",
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isCurrent) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.restore_rounded, size: 14, color: RevoTheme.primaryLight),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetric(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
        ),
      ],
    );
  }
}
