import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme.dart';
import '../../../journey_builder/data/models.dart';
import '../../../journey_builder/presentation/providers/journey_provider.dart';

class JourneyRunnerScreen extends ConsumerStatefulWidget {
  const JourneyRunnerScreen({super.key});

  @override
  ConsumerState<JourneyRunnerScreen> createState() => _JourneyRunnerScreenState();
}

class _JourneyRunnerScreenState extends ConsumerState<JourneyRunnerScreen> {
  String? _runnerStepId;
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _errors = {};
  final Map<String, List<Map<String, dynamic>>> _gridRows = {};
  final Map<String, Set<int>> _gridSelections = {};
  // repeater state: fieldId → list of per-row value maps
  final Map<String, List<Map<String, dynamic>>> _repeaterRows = {};
  final Map<String, String> _gridSearch = {};
  final Map<String, String> _gridSortField = {};
  final Map<String, bool> _gridSortAscending = {};
  final Set<String> _gridApiLoaded = {};
  final Set<String> _gridApiLoading = {};
  final Map<String, String> _gridApiErrors = {};

  @override
  void initState() {
    super.initState();
    // Start with the first step of the journey configuration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = ref.read(journeyConfigProvider);
      if (config.steps.isNotEmpty) {
        setState(() {
          _runnerStepId = config.steps.first.id;
        });
        ref.read(formValuesProvider.notifier).resetWithDefaults(config.steps.first.fields);
      }
    });
  }

  void _validateAndNext(JourneyStep step, List<JourneyStep> allSteps) {
    setState(() {
      _errors.clear();
    });

    final values = ref.read(formValuesProvider);
    bool isValid = true;

    // Run dynamic validation rules
    for (var val in step.validations) {
      final field = EngineHelper.flattenFields(step.fields).firstWhere((f) => f.id == val.field);
      // Only validate if field is visible
      if (EngineHelper.isFieldVisible(field, values)) {
        final fieldVal = values[val.field]?.toString() ?? '';
        if (val.type == 'required' && fieldVal.trim().isEmpty) {
          isValid = false;
          _errors[val.field] = val.message;
        }
      }
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please correct validation errors on this page."),
          backgroundColor: RevoTheme.error,
        ),
      );
      return;
    }

    // Resolve routing logic & condition checks
    String? nextId = step.nextStep;
    
    // Check if nextStepIf conditions are met
    for (var cond in step.conditions) {
      if (cond.type == 'nextStepIf' && EngineHelper.evaluateCondition(cond, values)) {
        nextId = cond.targetStep;
      }
    }

    if (nextId != null) {
      final nextStepIndex = allSteps.indexWhere((s) => s.id == nextId);
      if (nextStepIndex != -1) {
        setState(() {
          _runnerStepId = nextId;
        });
        ref.read(formValuesProvider.notifier).resetWithDefaults(allSteps[nextStepIndex].fields);
      }
    } else {
      // Record the run simulation log dynamically
      final config = ref.read(journeyConfigProvider);
      final currentRuns = ref.read(journeyRunsProvider);
      final nextRunNumber = 1050 + currentRuns.length;
      final userEmail = values['email']?.toString() ?? values['mobile']?.toString() ?? 'anonymous@revo.com';

      ref.read(journeyRunsProvider.notifier).addRun({
        'id': 'RUN-$nextRunNumber',
        'journeyName': config.journeyName,
        'user': userEmail,
        'status': 'Completed',
        'currentStep': step.title,
        'progress': 1.0,
        'stepsCount': '${config.steps.length}/${config.steps.length}',
        'started': 'Just now',
        'data': Map<String, dynamic>.from(values),
      });

      // Completed last step, show success banner
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: RevoTheme.cardBg,
          title: const Text("Journey Completed!"),
          content: const Text("All steps have been completed and validated successfully."),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              child: const Text("Back to Dashboard"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final config = ref.watch(journeyConfigProvider);
    if (config.steps.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No steps defined in configuration")),
      );
    }

    final activeId = _runnerStepId ?? config.steps.first.id;
    final activeStepIndex = config.steps.indexWhere((s) => s.id == activeId);
    final activeStep = activeStepIndex != -1 ? config.steps[activeStepIndex] : config.steps.first;
    final formValues = ref.watch(formValuesProvider);

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Nav Header
            _buildRunnerHeader(context, config, activeStep),

            // Timelines step indicator
            _buildTimeline(config, activeStepIndex),

            // Form container wrapper
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: RevoTheme.glassmorphicContainer(
                      key: ValueKey(activeStep.id),
                      width: 500,
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              activeStep.title,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: RevoTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              activeStep.description,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: RevoTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Fields List
                            ..._buildRunnerFields(activeStep.fields, formValues),

                            const SizedBox(height: 24),
                            // Button actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (activeStepIndex > 0)
                                  OutlinedButton(
                                    onPressed: () {
                                      final prevStep = config.steps[activeStepIndex - 1];
                                      setState(() {
                                        _runnerStepId = prevStep.id;
                                      });
                                      ref.read(formValuesProvider.notifier).resetWithDefaults(prevStep.fields);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    ),
                                    child: const Text("Back"),
                                  )
                                else
                                  const SizedBox.shrink(),
                                ElevatedButton(
                                  onPressed: () => _validateAndNext(activeStep, config.steps),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  ),
                                  child: Text(
                                    activeStepIndex == config.steps.length - 1 ? "Submit" : "Next",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunnerHeader(BuildContext context, JourneyConfig config, JourneyStep activeStep) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(
          bottom: BorderSide(color: RevoTheme.cardBorder, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: RevoTheme.textPrimary),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    config.journeyName,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: RevoTheme.textSecondary),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(JourneyConfig config, int activeIndex) {
    return Container(
      height: 70,
      color: RevoTheme.sidebarBackground,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: config.steps.asMap().entries.map((entry) {
            final idx = entry.key;
            final step = entry.value;
            final isCompleted = idx < activeIndex;
            final isActive = idx == activeIndex;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Step Dot circle
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive
                        ? RevoTheme.primary
                        : isCompleted
                            ? RevoTheme.secondary
                            : RevoTheme.cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? RevoTheme.primaryLight : RevoTheme.cardBorder,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : Text(
                          "${idx + 1}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isActive || isCompleted ? Colors.white : RevoTheme.textSecondary,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Text(
                  step.title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? RevoTheme.textPrimary
                        : isCompleted
                            ? RevoTheme.textSecondary
                            : const Color(0xFF555577),
                  ),
                ),
                if (idx < config.steps.length - 1) ...[
                  Container(
                    width: 40,
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: isCompleted ? RevoTheme.secondary : RevoTheme.cardBorder,
                  ),
                ],
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRunnerField(JourneyField field, Map<String, dynamic> values) {
    final hasError = _errors.containsKey(field.id);
    final errorMsg = _errors[field.id];

    switch (field.type.toLowerCase()) {
      case 'divider':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              field.label,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: RevoTheme.primaryLight),
            ),
            const SizedBox(height: 6),
            Divider(color: RevoTheme.cardBorder),
          ],
        );

      case 'dropdown':
        final options = field.getResolvedOptions();
        final displayOptions = options.isEmpty ? ["Select"] : options;
        final currentVal = values[field.id]?.toString();
        return DropdownButtonFormField<String>(
          initialValue: displayOptions.contains(currentVal) ? currentVal : null,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.placeholder ?? field.hintText,
            errorText: hasError ? errorMsg : null,
          ),
          dropdownColor: RevoTheme.cardBg,
          items: displayOptions.map((opt) {
            return DropdownMenuItem(value: opt, child: Text(opt));
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              ref.read(formValuesProvider.notifier).updateValue(field.id, val);
            }
          },
        );

      case 'api_dropdown':
        final currentVal = values[field.id]?.toString();
        return ApiDropdownWidget(
          field: field,
          initialValue: currentVal,
          onChanged: (val) {
            ref.read(formValuesProvider.notifier).updateValue(field.id, val);
          },
          errorText: hasError ? errorMsg : null,
        );

      case 'radio':
        final options = field.getResolvedOptions();
        final displayOptions = options.isEmpty ? [] : options;
        final currentVal = values[field.id]?.toString();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: displayOptions.map((opt) {
                final isSelected = currentVal == opt;
                return ChoiceChip(
                  label: Text(opt),
                  selected: isSelected,
                  selectedColor: RevoTheme.primary,
                  backgroundColor: RevoTheme.cardBg,
                  checkmarkColor: Colors.white,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(formValuesProvider.notifier).updateValue(field.id, opt);
                    }
                  },
                );
              }).toList(),
            ),
            if (hasError) ...[
              const SizedBox(height: 6),
              Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 10)),
            ]
          ],
        );

      case 'checkbox':
        final currentVal = values[field.id]?.toString() == 'true';
        return CheckboxListTile(
          title: Text(field.label, style: GoogleFonts.inter(fontSize: 12)),
          value: currentVal,
          activeColor: RevoTheme.primary,
          checkColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            ref.read(formValuesProvider.notifier).updateValue(field.id, (val ?? false).toString());
          },
          subtitle: hasError ? Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 10)) : null,
        );

      case 'switch':
        final currentVal = values[field.id]?.toString() == 'true';
        return SwitchListTile(
          title: Text(field.label, style: GoogleFonts.inter(fontSize: 12)),
          value: currentVal,
          activeColor: RevoTheme.primaryLight,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            ref.read(formValuesProvider.notifier).updateValue(field.id, val.toString());
          },
          subtitle: hasError ? Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 10)) : null,
        );

      case 'date':
      case 'time':
      case 'datetime':
        final currentVal = values[field.id]?.toString() ?? '';
        return TextField(
          controller: TextEditingController(text: currentVal),
          readOnly: true,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.placeholder ?? (field.type == 'time' ? 'Select Time' : 'Select Date'),
            suffixIcon: Icon(Icons.calendar_today_rounded, color: RevoTheme.textSecondary),
            errorText: hasError ? errorMsg : null,
          ),
          onTap: () async {
            if (field.type == 'time') {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                ref.read(formValuesProvider.notifier).updateValue(field.id, picked.format(context));
              }
              return;
            }
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
        );

      case 'number':
        return TextField(
          keyboardType: TextInputType.number,
          onChanged: (val) {
            ref.read(formValuesProvider.notifier).updateValue(field.id, val);
          },
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.placeholder,
            errorText: hasError ? errorMsg : null,
          ),
        );

      case 'image':
        return _buildUploadLikeField(field, values, hasError, errorMsg, isImage: true);

      case 'table_grid':
        return _buildTableGridRunner(field);

      case 'repeater':
        return _buildRepeaterRunner(field);

      case 'timeline':
        return _buildTimelineRunner(field);

      case 'section':
        return _buildNestedContainer(field, values, Icons.view_agenda_outlined);

      case 'card':
        return _buildNestedContainer(field, values, Icons.crop_square_rounded);

      case 'tabs':
        return _buildNestedTabs(field, values);

      case 'accordion':
        return _buildNestedContainer(field, values, Icons.unfold_more_rounded);

      case 'row':
        return _buildNestedRow(field, values);

      case 'formula':
        return TextField(
          readOnly: true,
          controller: TextEditingController(text: _evaluateSimpleFormula(field, values)),
          decoration: InputDecoration(
            labelText: field.label,
            helperText: field.formula,
            errorText: hasError ? errorMsg : null,
          ),
        );

      case 'phone':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0x12FFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x22A086FA)),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  const Text("🇮🇳", style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 4),
                  const Text("+91", style: TextStyle(fontSize: 13, color: Colors.white70)),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: RevoTheme.textSecondary),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.phone,
                onChanged: (val) {
                  ref.read(formValuesProvider.notifier).updateValue(field.id, val);
                },
                decoration: InputDecoration(
                  labelText: field.label,
                  hintText: field.placeholder ?? 'Enter Phone Number',
                  errorText: hasError ? errorMsg : null,
                ),
              ),
            ),
          ],
        );

      case 'file':
        return _buildUploadLikeField(field, values, hasError, errorMsg);

      case 'textarea':
        return TextField(
          maxLines: 4,
          onChanged: (val) {
            ref.read(formValuesProvider.notifier).updateValue(field.id, val);
          },
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.placeholder,
            alignLabelWithHint: true,
            errorText: hasError ? errorMsg : null,
          ),
        );

      case 'otp':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label, style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (idx) {
                return SizedBox(
                  width: 40,
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: RevoTheme.cardBorder),
                      ),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && idx < 5) {
                        FocusScope.of(context).nextFocus();
                      }
                      // Mock values update
                      ref.read(formValuesProvider.notifier).updateValue(field.id, "123456");
                    },
                  ),
                );
              }),
            ),
            if (hasError) ...[
              const SizedBox(height: 6),
              Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 10)),
            ]
          ],
        );

      default:
        return TextField(
          onChanged: (val) {
            ref.read(formValuesProvider.notifier).updateValue(field.id, val);
          },
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.placeholder,
            errorText: hasError ? errorMsg : null,
          ),
        );
    }
  }

  Widget _buildUploadLikeField(
    JourneyField field,
    Map<String, dynamic> values,
    bool hasError,
    String? errorMsg, {
    bool isImage = false,
  }) {
    final currentVal = values[field.id]?.toString() ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        children: [
          Icon(isImage ? Icons.image_outlined : Icons.cloud_upload_outlined, size: 28, color: RevoTheme.primaryLight),
          const SizedBox(height: 8),
          Text(
            currentVal.isNotEmpty ? currentVal : (isImage ? "Click to upload image" : "Drag & Drop or Click to Upload file"),
            style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              ref.read(formValuesProvider.notifier).updateValue(field.id, isImage ? "image_uploaded.png" : "document_uploaded.pdf");
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              side: BorderSide(color: RevoTheme.primary),
            ),
            child: Text(isImage ? "Select Image" : "Select File", style: const TextStyle(fontSize: 11)),
          ),
          if (hasError) ...[
            const SizedBox(height: 8),
            Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 10)),
          ]
        ],
      ),
    );
  }

  Map<String, dynamic> _componentConfig(JourneyField field) {
    final config = Map<String, dynamic>.from(field.componentConfig ?? {});
    if (field.type == 'table_grid') {
      return {
        'columns': [
          {'label': '#', 'fieldId': 'rowIndex', 'type': 'number', 'required': false},
          {'label': 'Name', 'fieldId': 'name', 'type': 'text', 'required': true},
          {'label': 'Age', 'fieldId': 'age', 'type': 'number', 'required': false},
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
        'minRows': 0,
        'maxRows': 10,
        ...config,
      };
    }
    return config;
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

  Widget _buildTableGridRunner(JourneyField field) {
    final config = _componentConfig(field);
    final columns = _configList(field, 'columns', [
      if (field.nestedFields != null && field.nestedFields!.isNotEmpty)
        ...field.nestedFields!.map((nested) => {
              'label': nested.label,
              'fieldId': nested.id,
              'type': nested.type,
              'required': nested.required,
            })
      else ...[
        {'label': '#'},
        {'label': 'Name', 'fieldId': 'name', 'required': true},
        {'label': 'Age', 'fieldId': 'age'},
      ],
    ]);
    final allowAdd = config['allowAddRow'] != false;
    final allowDelete = config['allowDeleteRow'] != false;
    final inlineEdit = config['inlineEdit'] != false;
    final bulkSelection = config['bulkSelection'] != false;
    final exportCsv = config['exportCsv'] != false;
    final searchEnabled = config['search'] != false;
    final sortingEnabled = config['sorting'] != false;
    final validationEnabled = config['dynamicRowValidation'] != false;
    final dataSource = config['dataSource']?.toString() ?? 'manual';
    final pagination = config['pagination'] != false;
    final apiPagination = config['apiPagination'] == true;
    final rowActions = config['rowActions'] is List ? List<String>.from((config['rowActions'] as List).map((item) => item.toString())) : <String>['edit', 'delete'];
    final rowsPerPage = int.tryParse(config['rowsPerPage']?.toString() ?? '') ?? 10;
    final maxRows = int.tryParse(config['maxRows']?.toString() ?? '') ?? 10;
    final rows = _ensureGridRows(field, columns, config);
    if (dataSource == 'api' && !_gridApiLoaded.contains(field.id) && !_gridApiLoading.contains(field.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadGridRowsFromApi(field, columns, config));
    }
    final search = _gridSearch[field.id] ?? '';
    final sortField = _gridSortField[field.id];
    final sortAscending = _gridSortAscending[field.id] ?? true;
    final selected = _gridSelections.putIfAbsent(field.id, () => <int>{});
    var visibleRows = rows.asMap().entries.where((entry) {
      if (search.trim().isEmpty) return true;
      final q = search.toLowerCase();
      return entry.value.values.any((value) => value.toString().toLowerCase().contains(q));
    }).toList();
    if (sortField != null && sortField.isNotEmpty) {
      visibleRows.sort((a, b) {
        final left = a.value[sortField]?.toString() ?? '';
        final right = b.value[sortField]?.toString() ?? '';
        final comparison = left.compareTo(right);
        return sortAscending ? comparison : -comparison;
      });
    }
    final pagedRows = pagination ? visibleRows.take(rowsPerPage).toList() : visibleRows;
    final sortColumnIndex = sortField == null ? -1 : columns.indexWhere((c) => _columnFieldId(c) == sortField);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(field.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: RevoTheme.textPrimary))),
              if (dataSource == 'api')
                IconButton(
                  tooltip: "Reload API data",
                  onPressed: _gridApiLoading.contains(field.id) ? null : () => _loadGridRowsFromApi(field, columns, config, force: true),
                  icon: _gridApiLoading.contains(field.id)
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: RevoTheme.primaryLight))
                      : Icon(Icons.refresh_rounded, size: 18, color: RevoTheme.textSecondary),
                ),
              if (exportCsv)
                IconButton(
                  tooltip: "Export CSV",
                  onPressed: () => _exportGridCsv(field, columns, rows),
                  icon: Icon(Icons.download_rounded, size: 18, color: RevoTheme.textSecondary),
                ),
              if (allowAdd)
                OutlinedButton.icon(
                  onPressed: rows.length >= maxRows ? null : () => _addGridRow(field, columns),
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: const Text("Add Row", style: TextStyle(fontSize: 11)),
                ),
          ],
        ),
          if (_gridApiErrors[field.id] != null) ...[
            const SizedBox(height: 8),
            Text(_gridApiErrors[field.id]!, style: GoogleFonts.inter(fontSize: 10, color: Colors.redAccent)),
          ],
          if (searchEnabled) ...[
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, size: 16, color: RevoTheme.textSecondary),
                hintText: "Search rows",
                hintStyle: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textPrimary),
              onChanged: (value) => setState(() => _gridSearch[field.id] = value),
            ),
          ],
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: bulkSelection,
              headingRowColor: WidgetStatePropertyAll(RevoTheme.background),
              dataRowMinHeight: 48,
              dataRowMaxHeight: 64,
              sortColumnIndex: sortColumnIndex < 0 ? null : sortColumnIndex,
              sortAscending: sortAscending,
              columns: [
                ...columns.map((column) {
                  final fieldId = _columnFieldId(column);
                  return DataColumn(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(column['label']?.toString() ?? 'Column'),
                        if (column['sticky'] == true || config['stickyColumns'] == true && columns.indexOf(column) == 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.push_pin_rounded, size: 12, color: RevoTheme.primaryLight),
                          ),
                      ],
                    ),
                    onSort: sortingEnabled
                        ? (_, ascending) {
                            setState(() {
                              _gridSortField[field.id] = fieldId;
                              _gridSortAscending[field.id] = ascending;
                            });
                          }
                        : null,
                  );
                }),
                DataColumn(label: Text("Action", style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
              ],
              rows: pagedRows.map((entry) {
                final rowIndex = entry.key;
                final row = entry.value;
                return DataRow(
                  selected: selected.contains(rowIndex),
                  onSelectChanged: bulkSelection
                      ? (checked) {
                          setState(() {
                            checked == true ? selected.add(rowIndex) : selected.remove(rowIndex);
                          });
                        }
                      : null,
                  cells: [
                    ...columns.map((column) => DataCell(_gridCell(field, column, row, rowIndex, inlineEdit, validationEnabled))),
                    DataCell(_gridActions(field, columns, rowIndex, row, rowActions, allowDelete)),
                  ],
                );
              }).toList(),
            ),
          ),
          if (bulkSelection && selected.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text("${selected.length} selected", style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary))),
                if (allowDelete)
                  TextButton.icon(
                    onPressed: () => _deleteSelectedGridRows(field),
                    icon: const Icon(Icons.delete_outline_rounded, size: 14),
                    label: const Text("Delete Selected"),
                  ),
              ],
            ),
          ],
          if (pagination || apiPagination) ...[
            const SizedBox(height: 8),
            Text(
              "${pagedRows.length} of ${visibleRows.length} row(s) shown${apiPagination ? " | API page params enabled" : ""}",
              style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _gridActions(
    JourneyField field,
    List<Map<String, dynamic>> columns,
    int rowIndex,
    Map<String, dynamic> row,
    List<String> actions,
    bool allowDelete,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions.map((action) {
        switch (action.toLowerCase()) {
          case 'delete':
            if (!allowDelete) return const SizedBox.shrink();
            return IconButton(
              tooltip: "Delete row",
              onPressed: () => _deleteGridRow(field, rowIndex),
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
            );
          case 'duplicate':
            return IconButton(
              tooltip: "Duplicate row",
              onPressed: () => _duplicateGridRow(field, columns, row),
              icon: Icon(Icons.copy_rounded, size: 16, color: RevoTheme.textSecondary),
            );
          case 'view':
            return Icon(Icons.visibility_outlined, size: 16, color: RevoTheme.textSecondary);
          case 'edit':
            return Icon(Icons.edit_outlined, size: 16, color: RevoTheme.primaryLight);
          default:
            return const SizedBox.shrink();
        }
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _ensureGridRows(JourneyField field, List<Map<String, dynamic>> columns, Map<String, dynamic> config) {
    return _gridRows.putIfAbsent(field.id, () {
      final minRows = int.tryParse(config['minRows']?.toString() ?? '') ?? 0;
      if ((config['dataSource']?.toString() ?? 'manual') == 'api') {
        return <Map<String, dynamic>>[];
      }
      final initialCount = minRows > 0 ? minRows : 1;
      return List.generate(initialCount, (_) => _emptyGridRow(columns));
    });
  }

  Future<void> _loadGridRowsFromApi(
    JourneyField field,
    List<Map<String, dynamic>> columns,
    Map<String, dynamic> config, {
    bool force = false,
  }) async {
    if (!force && _gridApiLoading.contains(field.id)) return;
    final urlText = config['gridApiUrl']?.toString().trim() ?? '';
    if (urlText.isEmpty) {
      setState(() {
        _gridApiLoaded.add(field.id);
        _gridApiErrors[field.id] = 'Grid API URL is required.';
      });
      return;
    }

    setState(() {
      _gridApiLoading.add(field.id);
      _gridApiErrors.remove(field.id);
    });

    try {
      final uri = _gridApiUri(urlText, config);
      final method = (config['gridApiMethod']?.toString() ?? 'GET').toUpperCase();
      final headers = _gridApiHeaders(config['gridApiHeaders']);
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
        throw Exception('Grid API failed with status ${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      final listKey = config['gridApiListKey']?.toString() ?? '';
      final rows = _normalizeGridApiRows(decoded, listKey, columns);

      setState(() {
        _gridRows[field.id] = rows;
        _gridSelections[field.id]?.clear();
        _gridApiLoaded.add(field.id);
        _gridApiLoading.remove(field.id);
      });
      _syncGridValue(field);
    } catch (e) {
      setState(() {
        _gridApiLoaded.add(field.id);
        _gridApiLoading.remove(field.id);
        _gridApiErrors[field.id] = e.toString();
      });
    }
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
    } else if (rawHeaders is String && rawHeaders.trim().isNotEmpty) {
      final decoded = json.decode(rawHeaders);
      if (decoded is Map) {
        decoded.forEach((key, value) => headers[key.toString()] = value.toString());
      }
    }
    return headers;
  }

  List<Map<String, dynamic>> _normalizeGridApiRows(dynamic decoded, String listKey, List<Map<String, dynamic>> columns) {
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
      final row = _emptyGridRow(columns);
      if (columns.isNotEmpty) row[_columnFieldId(columns.first)] = item.toString();
      return row;
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

  Map<String, dynamic> _emptyGridRow(List<Map<String, dynamic>> columns) {
    return {
      for (final column in columns) _columnFieldId(column): '',
    };
  }

  String _columnFieldId(Map<String, dynamic> column) {
    return (column['fieldId'] ?? column['key'] ?? column['label'] ?? 'column').toString();
  }

  Widget _gridCell(JourneyField field, Map<String, dynamic> column, Map<String, dynamic> row, int rowIndex, bool inlineEdit, bool validationEnabled) {
    final fieldId = _columnFieldId(column);
    final value = row[fieldId]?.toString() ?? '';
    final required = column['required'] == true;
    final hasError = validationEnabled && required && value.trim().isEmpty;
    if (!inlineEdit) {
      return Text(value.isEmpty ? '-' : value, style: GoogleFonts.inter(fontSize: 11, color: hasError ? Colors.redAccent : RevoTheme.textSecondary));
    }
    return SizedBox(
      width: 140,
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          isDense: true,
          hintText: column['label']?.toString(),
          errorText: hasError ? "Required" : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
        keyboardType: column['type'] == 'number' ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textPrimary),
        onChanged: (value) => _updateGridCell(field, rowIndex, fieldId, value),
      ),
    );
  }

  void _addGridRow(JourneyField field, List<Map<String, dynamic>> columns) {
    setState(() {
      final rows = _gridRows.putIfAbsent(field.id, () => []);
      rows.add(_emptyGridRow(columns));
      _syncGridValue(field);
    });
  }

  void _deleteGridRow(JourneyField field, int rowIndex) {
    setState(() {
      final rows = _gridRows[field.id];
      if (rows == null || rowIndex < 0 || rowIndex >= rows.length) return;
      rows.removeAt(rowIndex);
      _gridSelections[field.id]?.remove(rowIndex);
      _syncGridValue(field);
    });
  }

  void _duplicateGridRow(JourneyField field, List<Map<String, dynamic>> columns, Map<String, dynamic> row) {
    setState(() {
      final rows = _gridRows.putIfAbsent(field.id, () => []);
      rows.add({..._emptyGridRow(columns), ...row});
      _syncGridValue(field);
    });
  }

  void _deleteSelectedGridRows(JourneyField field) {
    setState(() {
      final rows = _gridRows[field.id];
      final selected = _gridSelections[field.id];
      if (rows == null || selected == null) return;
      final sorted = selected.toList()..sort((a, b) => b.compareTo(a));
      for (final index in sorted) {
        if (index >= 0 && index < rows.length) rows.removeAt(index);
      }
      selected.clear();
      _syncGridValue(field);
    });
  }

  void _updateGridCell(JourneyField field, int rowIndex, String fieldId, String value) {
    setState(() {
      final rows = _gridRows[field.id];
      if (rows == null || rowIndex < 0 || rowIndex >= rows.length) return;
      rows[rowIndex][fieldId] = value;
      _syncGridValue(field);
    });
  }

  void _syncGridValue(JourneyField field) {
    ref.read(formValuesProvider.notifier).updateValue(field.id, jsonEncode(_gridRows[field.id] ?? []));
  }

  void _exportGridCsv(JourneyField field, List<Map<String, dynamic>> columns, List<Map<String, dynamic>> rows) {
    final headers = columns.map((column) => column['label']?.toString() ?? _columnFieldId(column)).toList();
    final keys = columns.map(_columnFieldId).toList();
    final csv = [
      headers.map(_escapeCsv).join(','),
      ...rows.map((row) => keys.map((key) => _escapeCsv(row[key]?.toString() ?? '')).join(',')),
    ].join('\n');
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CSV copied to clipboard")));
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return value.contains(',') || value.contains('"') || value.contains('\n') ? '"$escaped"' : escaped;
  }

  Widget _tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
          color: isHeader ? RevoTheme.textPrimary : RevoTheme.textSecondary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildRepeaterRunner(JourneyField field) {
    final config = _componentConfig(field);
    final nestedFields = field.nestedFields ?? const <JourneyField>[];
    final allowAdd = config['allowAdd'] != false;
    final allowRemove = config['allowRemove'] != false;
    final itemLabel = config['itemLabel']?.toString() ?? 'Item';
    final addLabel = config['addButtonLabel']?.toString() ?? 'Add $itemLabel';
    final maxRows = int.tryParse(config['maxRows']?.toString() ?? '') ?? 20;

    // Initialise rows with one empty entry if none yet
    final rows = _repeaterRows.putIfAbsent(field.id, () => [_emptyRepeaterRow(nestedFields)]);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: RevoTheme.textPrimary)),
          const SizedBox(height: 10),
          ...rows.asMap().entries.map((entry) {
            final rowIndex = entry.key;
            final rowValues = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RevoTheme.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: RevoTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$itemLabel ${rowIndex + 1}',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: RevoTheme.textPrimary),
                        ),
                      ),
                      if (allowRemove && rows.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                          onPressed: () => setState(() {
                            _repeaterRows[field.id]!.removeAt(rowIndex);
                            _syncRepeaterValue(field);
                          }),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Render each nestedField with its own isolated row-scoped value map
                  if (nestedFields.isNotEmpty)
                    ...nestedFields.map((nestedField) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildRepeaterCell(field, rowIndex, nestedField, rowValues),
                        ))
                  else
                    Text(
                      'No fields configured inside this repeater.',
                      style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
                    ),
                ],
              ),
            );
          }),
          if (allowAdd && rows.length < maxRows)
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _repeaterRows[field.id]!.add(_emptyRepeaterRow(nestedFields));
                _syncRepeaterValue(field);
              }),
              icon: const Icon(Icons.add_rounded, size: 14),
              label: Text(addLabel, style: const TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Map<String, dynamic> _emptyRepeaterRow(List<JourneyField> fields) {
    final row = <String, dynamic>{};
    for (final f in fields) {
      row[f.id] = f.defaultValue ?? '';
    }
    return row;
  }

  void _syncRepeaterValue(JourneyField field) {
    ref.read(formValuesProvider.notifier).updateValue(field.id, List<Map<String, dynamic>>.from(_repeaterRows[field.id] ?? []));
  }

  Widget _buildRepeaterCell(JourneyField repeaterField, int rowIndex, JourneyField cellField, Map<String, dynamic> rowValues) {
    final currentVal = rowValues[cellField.id]?.toString() ?? '';
    void updateCell(dynamic val) {
      setState(() {
        _repeaterRows[repeaterField.id]![rowIndex][cellField.id] = val;
        _syncRepeaterValue(repeaterField);
      });
    }

    switch (cellField.type.toLowerCase()) {
      case 'dropdown':
        final opts = cellField.getResolvedOptions();
        return DropdownButtonFormField<String>(
          value: opts.contains(currentVal) ? currentVal : null,
          decoration: InputDecoration(labelText: cellField.label, isDense: true),
          dropdownColor: RevoTheme.cardBg,
          items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (v) { if (v != null) updateCell(v); },
        );
      case 'checkbox':
      case 'switch':
        final checked = currentVal == 'true';
        return CheckboxListTile(
          title: Text(cellField.label, style: GoogleFonts.inter(fontSize: 12)),
          value: checked,
          activeColor: RevoTheme.primary,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => updateCell((v ?? false).toString()),
        );
      default:
        return TextFormField(
          initialValue: currentVal,
          decoration: InputDecoration(labelText: cellField.label, isDense: true),
          keyboardType: cellField.type == 'number' ? TextInputType.number : TextInputType.text,
          onChanged: updateCell,
        );
    }
  }

  Widget _buildTimelineRunner(JourneyField field) {
    final items = _configList(field, 'items', [
      {'title': 'Started', 'description': 'Journey started', 'status': 'completed'},
      {'title': 'Current', 'description': 'Current step', 'status': 'active'},
      {'title': 'Completed', 'description': 'Final state', 'status': 'pending'},
    ]);

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
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: RevoTheme.textPrimary)),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final color = statusColor(item['status']?.toString());
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    if (index < items.length - 1) Container(width: 2, height: 38, color: RevoTheme.cardBorder),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title']?.toString() ?? 'Timeline item', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: RevoTheme.textPrimary)),
                        const SizedBox(height: 3),
                        Text(item['description']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStructuredComponent(JourneyField field, IconData icon, String fallbackLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: RevoTheme.primaryLight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label.isNotEmpty ? field.label : fallbackLabel,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: RevoTheme.textPrimary),
                ),
                if ((field.placeholder ?? field.hintText ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    field.placeholder ?? field.hintText!,
                    style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRunnerFields(List<JourneyField> fields, Map<String, dynamic> values) {
    return fields.map((field) {
      final isVisible = EngineHelper.isFieldVisible(field, values);
      if (!isVisible) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: _buildRunnerField(field, values),
      );
    }).toList();
  }

  Widget _buildNestedContainer(JourneyField field, Map<String, dynamic> values, IconData icon) {
    final children = field.nestedFields ?? const <JourneyField>[];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: RevoTheme.primaryLight),
              const SizedBox(width: 10),
              Expanded(child: Text(field.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: RevoTheme.textPrimary))),
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 14),
            ..._buildRunnerFields(children, values),
          ],
        ],
      ),
    );
  }

  Widget _buildNestedRow(JourneyField field, Map<String, dynamic> values) {
    final children = (field.nestedFields ?? const <JourneyField>[])
        .where((child) => EngineHelper.isFieldVisible(child, values))
        .toList();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: children.map((child) {
        final colSpan = int.tryParse(child.componentConfig?['colSpan']?.toString() ?? '') ?? 12;
        final width = MediaQuery.of(context).size.width;
        final itemWidth = width > 760 ? ((width - 220) * (colSpan.clamp(1, 12) / 12)) : double.infinity;
        return SizedBox(
          width: itemWidth,
          child: _buildRunnerField(child, values),
        );
      }).toList(),
    );
  }

  Widget _buildNestedTabs(JourneyField field, Map<String, dynamic> values) {
    final tabs = field.nestedFields ?? const <JourneyField>[];
    if (tabs.isEmpty) return _buildStructuredComponent(field, Icons.tab_rounded, 'Tabs');
    return DefaultTabController(
      length: tabs.length,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RevoTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RevoTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: RevoTheme.textPrimary)),
            const SizedBox(height: 10),
            TabBar(
              isScrollable: true,
              labelColor: RevoTheme.primaryLight,
              unselectedLabelColor: RevoTheme.textSecondary,
              tabs: tabs.map((tab) => Tab(text: tab.label)).toList(),
            ),
            SizedBox(
              height: 320,
              child: TabBarView(
                children: tabs.map((tab) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildRunnerFields(tab.nestedFields ?? const <JourneyField>[], values)),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _evaluateSimpleFormula(JourneyField field, Map<String, dynamic> values) {
    final formula = field.formula;
    if (formula == null || formula.trim().isEmpty) return field.defaultValue ?? '';
    final multiply = RegExp(r'^\s*([A-Za-z0-9_]+)\s*\*\s*([0-9.]+)\s*$').firstMatch(formula);
    if (multiply != null) {
      final left = double.tryParse(values[multiply.group(1)]?.toString() ?? '') ?? 0;
      final right = double.tryParse(multiply.group(2) ?? '') ?? 0;
      return (left * right).toStringAsFixed(2);
    }
    return formula;
  }
}

class ApiDropdownWidget extends ConsumerStatefulWidget {
  final JourneyField field;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final String? errorText;

  const ApiDropdownWidget({
    super.key,
    required this.field,
    required this.initialValue,
    required this.onChanged,
    this.errorText,
  });

  @override
  ConsumerState<ApiDropdownWidget> createState() => _ApiDropdownWidgetState();
}

class _ApiDropdownWidgetState extends ConsumerState<ApiDropdownWidget> {
  List<String> _options = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  @override
  void didUpdateWidget(ApiDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.dropdownApiUrl != widget.field.dropdownApiUrl) {
      _fetchOptions();
    }
  }

  Future<void> _fetchOptions() async {
    final urlStr = widget.field.dropdownApiUrl;
    if (urlStr == null || urlStr.trim().isEmpty) {
      setState(() {
        _options = widget.field.options ?? ["Select"];
        _isLoading = false;
        _error = "No API URL configured";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse(urlStr.trim());
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<String> parsedOptions = [];

        void extractList(dynamic data) {
          if (data is List) {
            final displayKey = widget.field.dropdownValue ?? 'title';
            for (var item in data) {
              if (item is String) {
                parsedOptions.add(item);
              } else if (item is num || item is bool) {
                parsedOptions.add(item.toString());
              } else if (item is Map) {
                if (item.containsKey(displayKey) && item[displayKey] != null) {
                  parsedOptions.add(item[displayKey].toString());
                } else {
                  final keysToTry = ['name', 'title', 'value', 'label', 'text', 'username', 'display_name'];
                  String? foundVal;
                  for (var key in keysToTry) {
                    if (item.containsKey(key) && item[key] != null) {
                      foundVal = item[key].toString();
                      break;
                    }
                  }
                  if (foundVal == null && item.isNotEmpty) {
                    foundVal = item.values.first.toString();
                  }
                  if (foundVal != null) {
                    parsedOptions.add(foundVal);
                  }
                }
              }
            }
          }
        }

        final responseKey = widget.field.dropdownApiResponseKey;
        if (decoded is List) {
          extractList(decoded);
        } else if (decoded is Map) {
          bool foundList = false;
          if (responseKey != null && responseKey.isNotEmpty) {
            if (decoded[responseKey] is List) {
              extractList(decoded[responseKey]);
              foundList = true;
            }
          }
          if (!foundList) {
            final keysToTry = ['data', 'results', 'items', 'users', 'options'];
            for (var key in keysToTry) {
              if (decoded[key] is List) {
                extractList(decoded[key]);
                foundList = true;
                break;
              }
            }
          }
          if (!foundList) {
            for (var val in decoded.values) {
              if (val is List) {
                extractList(val);
                foundList = true;
                break;
              }
            }
          }
          if (!foundList) {
            _error = "Could not find list in response";
          }
        } else {
          _error = "Invalid JSON response format";
        }

        if (parsedOptions.isEmpty && _error == null) {
          _error = "No options found in response";
        }

        setState(() {
          _options = parsedOptions.isNotEmpty ? parsedOptions : ["Select"];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "HTTP error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Connection failed";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _error != null || widget.errorText != null;
    final displayError = _error ?? widget.errorText;

    return DropdownButtonFormField<String>(
      initialValue: _options.contains(widget.initialValue) ? widget.initialValue : null,
      decoration: InputDecoration(
        labelText: widget.field.label,
        hintText: widget.field.placeholder ?? "Select option",
        errorText: hasError ? displayError : null,
        suffixIcon: _isLoading
            ? Padding(
                padding: const EdgeInsets.all(14.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(RevoTheme.primaryLight),
                  ),
                ),
              )
            : _error != null
                ? IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.amberAccent, size: 20),
                    tooltip: "Retry fetching options",
                    onPressed: _fetchOptions,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  )
                : null,
      ),
      dropdownColor: RevoTheme.cardBg,
      items: _options.map((opt) {
        return DropdownMenuItem(value: opt, child: Text(opt));
      }).toList(),
      onChanged: _isLoading ? null : (val) {
        if (val != null) {
          widget.onChanged(val);
        }
      },
    );
  }
}
