import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final field = step.fields.firstWhere((f) => f.id == val.field);
      // Only validate if field is visible
      if (EngineHelper.isFieldVisible(field, values)) {
        final fieldVal = values[val.field] ?? '';
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
      final userEmail = values['email'] ?? values['mobile'] ?? 'anonymous@revo.com';

      ref.read(journeyRunsProvider.notifier).addRun({
        'id': 'RUN-$nextRunNumber',
        'journeyName': config.journeyName,
        'user': userEmail,
        'status': 'Completed',
        'currentStep': step.title,
        'progress': 1.0,
        'stepsCount': '${config.steps.length}/${config.steps.length}',
        'started': 'Just now',
        'data': Map<String, String>.from(values),
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
                            ...activeStep.fields.map((field) {
                              // Evaluate visibility condition
                              final isVisible = EngineHelper.isFieldVisible(field, formValues);
                              if (!isVisible) return const SizedBox.shrink();

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: _buildRunnerField(field, formValues),
                              );
                            }),

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

  Widget _buildRunnerField(JourneyField field, Map<String, String> values) {
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
        final currentVal = values[field.id];
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
        final currentVal = values[field.id];
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
        final currentVal = values[field.id];
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
        final currentVal = values[field.id] == 'true';
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
        final currentVal = values[field.id] == 'true';
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
        final currentVal = values[field.id] ?? '';
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
        return _buildStructuredComponent(field, Icons.view_agenda_outlined, 'Section');

      case 'card':
        return _buildStructuredComponent(field, Icons.crop_square_rounded, 'Card');

      case 'tabs':
        return _buildStructuredComponent(field, Icons.tab_rounded, 'Tabs');

      case 'accordion':
        return _buildStructuredComponent(field, Icons.unfold_more_rounded, 'Accordion');

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
    Map<String, String> values,
    bool hasError,
    String? errorMsg, {
    bool isImage = false,
  }) {
    final currentVal = values[field.id] ?? '';
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

  Widget _buildTableGridRunner(JourneyField field) {
    final config = _componentConfig(field);
    final columns = _configList(field, 'columns', [
      {'label': '#'},
      {'label': 'Column A'},
      {'label': 'Action'},
    ]).take(5).toList();
    final allowAdd = config['allowAddRow'] != false;

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
              if (allowAdd)
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: const Text("Add Row", style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Table(
              border: TableBorder.all(color: RevoTheme.cardBorder),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: BoxDecoration(color: RevoTheme.background),
                  children: columns.map((column) => _tableCell(column['label']?.toString() ?? 'Column', isHeader: true)).toList(),
                ),
                ...List.generate(2, (index) {
                  return TableRow(
                    children: columns.map((column) {
                      final label = column['label']?.toString().toLowerCase() ?? '';
                      final text = label == '#' || label.contains('index') ? '${index + 1}' : (label.contains('action') ? 'Edit' : 'Value');
                      return _tableCell(text);
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
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
    final fields = _configList(field, 'fields', [
      {'label': 'Name'},
      {'label': 'Value'},
    ]).take(4).toList();
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
          ...List.generate(2, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
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
                      Expanded(child: Text("${config['itemLabel'] ?? 'Item'} ${index + 1}", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700))),
                      if (config['allowRemove'] != false) Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: fields.map((item) {
                      return SizedBox(
                        width: 150,
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: item['label']?.toString() ?? 'Field',
                            isDense: true,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
          if (config['allowAdd'] != false)
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 14),
              label: Text(config['addButtonLabel']?.toString() ?? 'Add Item', style: const TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
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
    if (oldWidget.field.apiUrl != widget.field.apiUrl) {
      _fetchOptions();
    }
  }

  Future<void> _fetchOptions() async {
    final urlStr = widget.field.dropdownApiUrl ?? widget.field.apiUrl;
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
