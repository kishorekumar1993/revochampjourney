import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/blocnew/download.dart';
import 'package:revojourneytryone/blocnew/revochamp_bloc_generator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme.dart';
import '../../../journey_builder/data/models.dart';
import '../../../journey_builder/presentation/providers/journey_provider.dart';
import '../../../journey_builder/presentation/widgets/sidebar.dart';
import '../../../journey_builder/presentation/widgets/steps_panel.dart';
import '../../../journey_builder/presentation/widgets/canvas_panel.dart';
import '../../../journey_builder/presentation/widgets/properties_panel.dart';
import 'templates_screen.dart';
import 'journeys_screen.dart';
import 'runs_screen.dart';
import 'misc_screens.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _activeMenu = 'dashboard';
  String _environment = 'Production';
  bool _isEditingJourney = false;
  bool _isSidebarCollapsed = false;
  bool _showStepsPanel = true;
  bool _showPropertiesPanel = true;

  void _exportJson(BuildContext context, Map<String, dynamic> jsonMap) {
    // Mock export by printing and showing dialog
    final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonMap);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RevoTheme.cardBg,
        title: const Text("Exported JSON Configuration"),
        content: SizedBox(
          width: 500,
          height: 400,
          child: TextField(
            controller: TextEditingController(text: jsonStr),
            maxLines: null,
            readOnly: true,
            style: GoogleFonts.sourceCodePro(fontSize: 12, color: Colors.greenAccent),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  void _importJsonDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RevoTheme.cardBg,
        title: const Text("Import Journey Config JSON"),
        content: SizedBox(
          width: 500,
          height: 350,
          child: Column(
            children: [
              Text(
                "Paste your Journey JSON structure here to generate screens dynamically.",
                style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: textController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: '{\n  "journeyName": "Insurance",\n  "steps": []\n}',
                  ),
                  style: GoogleFonts.sourceCodePro(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final jsonStr = textController.text.trim();
              if (jsonStr.isNotEmpty) {
                final success = ref.read(journeyConfigProvider.notifier).updateFromJson(jsonStr);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text("Journey Config Imported successfully!"), backgroundColor: RevoTheme.success),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text("Invalid JSON structure!"), backgroundColor: RevoTheme.error),
                  );
                }
              }
            },
            child: const Text("Import"),
          ),
        ],
      ),
    );
  }


// void _generateBlocCode(BuildContext context, dynamic journeyConfig) {
//     final activeStepId = ref.read(activeStepIdProvider);
//     final activeStepIndex =
//         journeyConfig.steps.indexWhere((s) => s.id == activeStepId);

//     if (activeStepIndex == -1) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Please select a step to generate BLoC code!"),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//       return;
//     }

//     final step = journeyConfig.steps[activeStepIndex];
//     if (step.fields.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("The current step has no fields to generate code for!"),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//       return;
//     }

//     try {
//       // ✅ JSON round-trip: converts all JSArray/JSObject → plain Dart List/Map
//       // This is the ONLY safe way to sanitize Flutter Web interop types
//       final fieldsJson = jsonEncode(
//         step.fields.map((f) => f.toJson()).toList(),
//       );

//       final rawFields = (jsonDecode(fieldsJson) as List<dynamic>)
//           .map((e) => Map<String, dynamic>.from(e as Map))
//           .toList();

//       final cleanName = step.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
//       final screenName = cleanName.isNotEmpty
//           ? '${cleanName[0].toUpperCase()}${cleanName.substring(1)}'
//           : 'Step';

//       final fileDataArray = generateFileDataArray(
//         screenName: screenName,
//         modelName: 'Form',
//         fieldJsonRaw: rawFields,
//       );

//       // ✅ FIXED: No hasProperty check — function is always defined at page load
//       // ✅ jsonEncode converts fileDataArray to a plain JSON string for JS interop
//       final jsonString = jsonEncode(fileDataArray);
//       js.context.callMethod('saveMultipleFilesToFolders', [jsonString]);

//     } catch (e, stack) {
//       debugPrint("BLoC generation error: $e\n$stack");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Generation error: $e"),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//     }
//   }
/*
void _generateBlocCode(BuildContext context, dynamic journeyConfig) {
    if (journeyConfig.steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No steps found in this journey!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      // ✅ Journey-level namespace from journeyName
      // "Motor Insurance Journey" → "motorInsurance"
      final rawJourneyName = (journeyConfig.journeyName as String? ?? 'journey');
      final journeyNamespace = _toJourneyNamespace(rawJourneyName);

      debugPrint("🚀 Generating BLoC for journey: $journeyNamespace");

      final List<Map<String, String>> allFiles = [];

      // ✅ Shared core files — generate from FIRST valid step only (avoid duplicates)
      bool coreFilesAdded = false;

      for (final step in journeyConfig.steps) {
        if (step.fields.isEmpty) {
          debugPrint("⚠️ Skipping step '${step.id}' — no fields");
          continue;
        }

        // JSON round-trip: JSArray → plain Dart List/Map
        final fieldsJson = jsonEncode(
          step.fields.map((f) => f.toJson()).toList(),
        );
        final rawFields = (jsonDecode(fieldsJson) as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        final cleanName = step.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        final screenName = cleanName.isNotEmpty
            ? '${cleanName[0].toUpperCase()}${cleanName.substring(1)}'
            : 'Step';

        debugPrint("  ✅ Step: $screenName (${rawFields.length} fields)");

        final fileDataArray = generateFileDataArray(
          screenName: screenName,
          modelName: 'Form',
          fieldJsonRaw: rawFields,
        );

        for (final file in fileDataArray) {
          final originalFolder = file['folderPath'] ?? '';
          final fileName       = file['fileName']   ?? '';
          final textContent    = file['textContent'] ?? '';

          // ── Core shared files (runtime, network, widgets, DI, main)
          // Keep their path as-is — shared across all journeys
          final isSharedFile = originalFolder.startsWith('lib/bloc/core') ||
              originalFolder == 'lib/bloc' ||
              originalFolder.startsWith('test/');

          if (isSharedFile) {
            // Only add core files once (from first step)
            if (!coreFilesAdded) {
              allFiles.add({
                'folderPath':  originalFolder,
                'fileName':    fileName,
                'textContent': textContent,
              });
            }
          } else {
            // ── Feature files: inject journey namespace
            // Original: lib/bloc/features/personal/domain/...
            // Fixed:    lib/bloc/features/motorInsurance/personal/domain/...
            final newFolder = originalFolder.replaceFirst(
              'lib/bloc/features/',
              'lib/bloc/features/$journeyNamespace/',
            );
            allFiles.add({
              'folderPath':  newFolder,
              'fileName':    fileName,
              'textContent': textContent,
            });
          }
        }

        coreFilesAdded = true; // after first step, skip core duplicates
      }

      if (allFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No fields found in any step!"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      debugPrint("📦 Total files: ${allFiles.length} → saving to lib/bloc/features/$journeyNamespace/");

      // Write files directly via File System Access API (no JS bridge needed)
      downloadGeneratedFiles(allFiles, context);

    } catch (e, stack) {
      debugPrint("BLoC generation error: $e\n$stack");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Generation error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
*/

void _generateBlocCode(BuildContext context, dynamic journeyConfig) {
    // ── Validate ───────────────────────────────────────────────────────────
    if (journeyConfig.steps == null || journeyConfig.steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No steps found in this journey!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      // ✅ Single call — generates BLoC + GetX + Riverpod for ALL steps
      // All JSArray → Dart conversion, journey namespace, core dedup,
      // and JS file save happen inside generateAndSaveAllFiles()
      generateAndSaveAllFiles(
        journeyConfig: journeyConfig,
        architectures: const {
          Architecture.bloc,
          Architecture.getx,
          Architecture.riverpod,
        },
      );

      // ✅ Show success snackbar after JS call is dispatched
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Code generation started — select your project folder!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e, stack) {
      debugPrint("Generation error: $e\n$stack");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Generation error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
  /// "Motor Insurance Journey" → "motorInsurance"
  /// "Health Insurance"       → "healthInsurance"
  /// "my_journey"             → "myJourney"
  String _toJourneyNamespace(String name) {
    // Remove common suffixes
    final cleaned = name
        .replaceAll(RegExp(r'\bjourney\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s_\-]'), '')
        .trim();

    if (cleaned.isEmpty) return 'journey';

    // Split on spaces, underscores, hyphens
    final parts = cleaned
        .split(RegExp(r'[\s_\-]+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'journey';

    // camelCase: first word lowercase, rest capitalized
    return parts.first.toLowerCase() +
        parts
            .skip(1)
            .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
            .join();
  }

  @override
  Widget build(BuildContext context) {
    final journeyConfig = ref.watch(journeyConfigProvider);

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Row(
        children: [
          // 1. Sidebar Menu (Leftmost)
          RevoSidebar(
            activeMenu: _activeMenu,
            isCollapsed: _isSidebarCollapsed,
            onMenuChanged: (menu) {
              setState(() {
                _activeMenu = menu;
                _isEditingJourney = false;
              });
            },
          ),

          // Main content container
          Expanded(
            child: Column(
              children: [
                // 2. Top Header Navigation Bar
                _buildTopHeader(context, journeyConfig),
                
                // 3. Lower Content Panels (3 columns layout or Templates Screen)
                Expanded(
                  child: _activeMenu == 'templates'
                      ? RevoTemplatesScreen(
                          onTemplateLoaded: () {
                            setState(() {
                              _activeMenu = 'journeys';
                              _isEditingJourney = true;
                            });
                          },
                        )
                      : _activeMenu == 'runs'
                          ? RevoRunsScreen()
                          : _activeMenu == 'dashboard'
                              ? RevoDashboardOverviewScreen()
                              : _activeMenu == 'analytics'
                                  ? RevoAnalyticsScreen()
                                  : _activeMenu == 'approvals'
                                      ? RevoApprovalsScreen()
                                      : _activeMenu == 'users'
                                          ? RevoUsersScreen()
                                          : _activeMenu == 'settings'
                                              ? RevoSettingsScreen()
                                              : _activeMenu == 'api_hub'
                                                  ? RevoApiHubScreen()
                                                  : _activeMenu == 'audit_logs'
                                                      ? RevoAuditLogsScreen()
                                                      : _activeMenu == 'journeys' && !_isEditingJourney
                                                          ? RevoJourneysScreen(
                                                              onEditJourney: (journey) {
                                                                ref.read(journeyConfigProvider.notifier).updateFromJson(json.encode(journey.toJson()));
                                                                setState(() {
                                                                  _isEditingJourney = true;
                                                                });
                                                              },
                                                              onCreateNew: () {
                                                                final blank = JourneyConfig(journeyName: "New Journey", version: "1.0.0", steps: []);
                                                                ref.read(journeyConfigProvider.notifier).updateFromJson(json.encode(blank.toJson()));
                                                                setState(() {
                                                                  _isEditingJourney = true;
                                                                });
                                                              },
                                                            )
                                                          : Row(
                                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                                              children: [
                                                                // Steps Sidebar (Column 2)
                                                                if (_showStepsPanel) RevoStepsPanel(),

                                                                // Canvas Builder Area (Column 3)
                                                                RevoCanvasPanel(),

                                                                // Right properties editor panel (Column 4)
                                                                if (_showPropertiesPanel) RevoPropertiesPanel(),
                                                              ],
                                                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, dynamic journeyConfig) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 1350;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(
          bottom: BorderSide(color: RevoTheme.cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left breadcrumb / Environment indicator
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _isSidebarCollapsed ? Icons.menu_rounded : Icons.menu_open_rounded,
                    color: RevoTheme.textPrimary,
                    size: 20,
                  ),
                  tooltip: _isSidebarCollapsed ? "Expand Sidebar" : "Collapse Sidebar",
                  onPressed: () {
                    setState(() {
                      _isSidebarCollapsed = !_isSidebarCollapsed;
                    });
                  },
                ),
                const SizedBox(width: 8),
                if (_activeMenu == 'journeys' && _isEditingJourney) ...[
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: RevoTheme.textPrimary, size: 20),
                    tooltip: "Back to Catalog",
                    onPressed: () {
                      setState(() {
                        _isEditingJourney = false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  Icon(Icons.settings_outlined, color: RevoTheme.textSecondary, size: 20),
                ],
                const SizedBox(width: 24),
                // Environment Switcher dropdown mockup
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: RevoTheme.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: RevoTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: RevoTheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCompact ? "Prod" : "Environment: $_environment",
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: RevoTheme.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Action buttons & Icons
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isEditingJourney) ...[
                    if (isCompact) ...[
                      IconButton(
                        icon: Icon(
                          _showStepsPanel ? Icons.format_list_bulleted_rounded : Icons.list_rounded,
                          color: _showStepsPanel ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                          size: 20,
                        ),
                        tooltip: _showStepsPanel ? "Hide Steps Panel" : "Show Steps Panel",
                        onPressed: () {
                          setState(() {
                            _showStepsPanel = !_showStepsPanel;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          _showPropertiesPanel ? Icons.tune_rounded : Icons.tune_outlined,
                          color: _showPropertiesPanel ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                          size: 20,
                        ),
                        tooltip: _showPropertiesPanel ? "Hide Properties Panel" : "Show Properties Panel",
                        onPressed: () {
                          setState(() {
                            _showPropertiesPanel = !_showPropertiesPanel;
                          });
                        },
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showStepsPanel = !_showStepsPanel;
                          });
                        },
                        icon: Icon(
                          _showStepsPanel ? Icons.format_list_bulleted_rounded : Icons.list_rounded,
                          size: 16,
                          color: _showStepsPanel ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                        ),
                        label: Text(
                          _showStepsPanel ? "Hide Steps" : "Show Steps",
                          style: TextStyle(
                            fontSize: 11,
                            color: _showStepsPanel ? RevoTheme.textPrimary : RevoTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: BorderSide(
                            color: _showStepsPanel ? RevoTheme.primary.withValues(alpha:0.5) : RevoTheme.cardBorder,
                          ),
                          backgroundColor: _showStepsPanel ? RevoTheme.primary.withValues(alpha:0.08) : Colors.transparent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showPropertiesPanel = !_showPropertiesPanel;
                          });
                        },
                        icon: Icon(
                          _showPropertiesPanel ? Icons.tune_rounded : Icons.tune_outlined,
                          size: 16,
                          color: _showPropertiesPanel ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                        ),
                        label: Text(
                          _showPropertiesPanel ? "Hide Props" : "Show Props",
                          style: TextStyle(
                            fontSize: 11,
                            color: _showPropertiesPanel ? RevoTheme.textPrimary : RevoTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: BorderSide(
                            color: _showPropertiesPanel ? RevoTheme.primary.withValues(alpha:0.5) : RevoTheme.cardBorder,
                          ),
                          backgroundColor: _showPropertiesPanel ? RevoTheme.primary.withValues(alpha:0.08) : Colors.transparent,
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 24,
                      child: VerticalDivider(color: RevoTheme.cardBorder, width: 1),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (isCompact) ...[
                    Tooltip(
                      message: "Export JSON",
                      child: OutlinedButton(
                        onPressed: () => _exportJson(context, journeyConfig.toJson()),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          minimumSize: Size.zero,
                        ),
                        child: const Icon(Icons.download_rounded, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: "Import JSON",
                      child: OutlinedButton(
                        onPressed: () => _importJsonDialog(context, ref),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          minimumSize: Size.zero,
                        ),
                        child: const Icon(Icons.upload_file_rounded, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: "Generate BLoC Code",
                      child: OutlinedButton(
                        onPressed: () => _generateBlocCode(context, journeyConfig),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          minimumSize: Size.zero,
                        ),
                        child: const Icon(Icons.code_rounded, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: "Run Journey",
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/runner');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          minimumSize: Size.zero,
                          backgroundColor: RevoTheme.primary,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, size: 16),
                      ),
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: () => _exportJson(context, journeyConfig.toJson()),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text("Export JSON"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _importJsonDialog(context, ref),
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text("Import JSON"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _generateBlocCode(context, journeyConfig),
                      icon: const Icon(Icons.code_rounded, size: 16),
                      label: const Text("Generate BLoC"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push('/runner');
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text("Run Journey"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        backgroundColor: RevoTheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(width: 24),
                  // Profile icons
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications_none_rounded, color: RevoTheme.textSecondary),
                        onPressed: () {},
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            "3",
                            style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      ref.watch(themeModeProvider) == ThemeMode.dark
                          ? Icons.wb_sunny_outlined
                          : Icons.dark_mode_outlined,
                      color: RevoTheme.textSecondary,
                    ),
                    onPressed: () {
                      final notifier = ref.read(themeModeProvider.notifier);
                      notifier.state = notifier.state == ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
