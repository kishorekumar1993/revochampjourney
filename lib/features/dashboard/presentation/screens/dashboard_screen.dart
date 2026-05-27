import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:revojourneytryone/filegegnerator/revochamp_bloc_generator.dart';
import '../../../../core/theme.dart';
import '../../../journey_builder/data/models.dart';
import '../../../journey_builder/presentation/providers/journey_provider.dart';
import '../../../journey_builder/presentation/widgets/sidebar.dart';
import '../../../journey_builder/presentation/widgets/steps_panel.dart' deferred as steps_panel;
import '../../../journey_builder/presentation/widgets/canvas_panel.dart' deferred as canvas_panel;
import '../../../journey_builder/presentation/widgets/properties_panel.dart' deferred as properties_panel;
import 'templates_screen.dart';
import 'journeys_screen.dart';
import 'runs_screen.dart';
import 'misc_screens.dart';

// Top-level providers to replace local setState and avoid full screen rebuilds
final dashboardMenuProvider = StateProvider<String>((ref) => 'dashboard');
final editingJourneyProvider = StateProvider<bool>((ref) => false);
final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);
final showStepsPanelProvider = StateProvider<bool>((ref) => true);
final showPropertiesPanelProvider = StateProvider<bool>((ref) => true);
final environmentProvider = StateProvider<String>((ref) => 'Production');

// Top-level isolate functions for JSON encoding
String _encodeJson(Map<String, dynamic> data) => json.encode(data);
String _encodeJsonPretty(Map<String, dynamic> data) => const JsonEncoder.withIndent('  ').convert(data);

// Deferred loader for Steps Panel with RepaintBoundary
class DeferredStepsPanel extends StatefulWidget {
  const DeferredStepsPanel({super.key});
  @override
  State<DeferredStepsPanel> createState() => _DeferredStepsPanelState();
}

class _DeferredStepsPanelState extends State<DeferredStepsPanel> {
  late Future<void> _libraryFuture;

  @override
  void initState() {
    super.initState();
    _libraryFuture = steps_panel.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _libraryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return RepaintBoundary(child: steps_panel.RevoStepsPanel());
        }
        return const SizedBox(width: 320, child: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

// Deferred loader for Canvas Panel with RepaintBoundary
class DeferredCanvasPanel extends StatefulWidget {
  const DeferredCanvasPanel({super.key});
  @override
  State<DeferredCanvasPanel> createState() => _DeferredCanvasPanelState();
}

class _DeferredCanvasPanelState extends State<DeferredCanvasPanel> {
  late Future<void> _libraryFuture;

  @override
  void initState() {
    super.initState();
    _libraryFuture = canvas_panel.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _libraryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return RepaintBoundary(child: canvas_panel.RevoCanvasPanel());
        }
        return const Expanded(child: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

// Deferred loader for Properties Panel with RepaintBoundary
class DeferredPropertiesPanel extends StatefulWidget {
  const DeferredPropertiesPanel({super.key});
  @override
  State<DeferredPropertiesPanel> createState() => _DeferredPropertiesPanelState();
}

class _DeferredPropertiesPanelState extends State<DeferredPropertiesPanel> {
  late Future<void> _libraryFuture;

  @override
  void initState() {
    super.initState();
    _libraryFuture = properties_panel.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _libraryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return RepaintBoundary(child: properties_panel.RevoPropertiesPanel());
        }
        return const SizedBox(width: 320, child: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMenu = ref.watch(dashboardMenuProvider);
    final isSidebarCollapsed = ref.watch(sidebarCollapsedProvider);

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Row(
        children: [
          // 1. Sidebar Menu (Leftmost)
          RevoSidebar(
            activeMenu: activeMenu,
            isCollapsed: isSidebarCollapsed,
            onMenuChanged: (menu) {
              ref.read(dashboardMenuProvider.notifier).state = menu;
              ref.read(editingJourneyProvider.notifier).state = false;
            },
          ),

          // Main content container
          const Expanded(
            child: Column(
              children: [
                // 2. Top Header Navigation Bar
                DashboardTopHeader(),
                
                // 3. Lower Content Panels (3 columns layout or Templates Screen)
                Expanded(
                  child: DashboardMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardMainContent extends ConsumerWidget {
  const DashboardMainContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMenu = ref.watch(dashboardMenuProvider);
    final isEditingJourney = ref.watch(editingJourneyProvider);
    final showStepsPanel = ref.watch(showStepsPanelProvider);
    final showPropertiesPanel = ref.watch(showPropertiesPanelProvider);

    switch (activeMenu) {
      case 'templates':
        return RevoTemplatesScreen(
          onTemplateLoaded: () {
            ref.read(dashboardMenuProvider.notifier).state = 'journeys';
            ref.read(editingJourneyProvider.notifier).state = true;
            ref.read(sidebarCollapsedProvider.notifier).state = true;
          },
        );
      case 'runs':
        return const RevoRunsScreen();
      case 'analytics':
        return const RevoAnalyticsScreen();
      case 'approvals':
        return const RevoApprovalsScreen();
      case 'users':
        return const RevoUsersScreen();
      case 'settings':
        return const RevoSettingsScreen();
      case 'api_hub':
        return const RevoApiHubScreen();
      case 'audit_logs':
        return const RevoAuditLogsScreen();
      case 'journeys':
        if (!isEditingJourney) {
          return RevoJourneysScreen(
            onEditJourney: (journey) async {
              final jsonStr = await compute(_encodeJson, journey.toJson());
              ref.read(journeyConfigProvider.notifier).updateFromJson(jsonStr);
              ref.read(editingJourneyProvider.notifier).state = true;
              ref.read(sidebarCollapsedProvider.notifier).state = true;
            },
            onCreateNew: () async {
              final blank = JourneyConfig(journeyName: "New Journey", version: "1.0.0", steps: []);
              final jsonStr = await compute(_encodeJson, blank.toJson());
              ref.read(journeyConfigProvider.notifier).updateFromJson(jsonStr);
              ref.read(editingJourneyProvider.notifier).state = true;
              ref.read(sidebarCollapsedProvider.notifier).state = true;
            },
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Steps Sidebar (Column 2)
            if (showStepsPanel) const DeferredStepsPanel(),

            // Canvas Builder Area (Column 3)
            const DeferredCanvasPanel(),

            // Right properties editor panel (Column 4)
            if (showPropertiesPanel) const DeferredPropertiesPanel(),
          ],
        );
      case 'dashboard':
      default:
        return RevoDashboardOverviewScreen(
          onCreateNew: () async {
            final blank = JourneyConfig(journeyName: "New Journey", version: "1.0.0", steps: []);
            final jsonStr = await compute(_encodeJson, blank.toJson());
            ref.read(journeyConfigProvider.notifier).updateFromJson(jsonStr);
            ref.read(dashboardMenuProvider.notifier).state = 'journeys';
            ref.read(editingJourneyProvider.notifier).state = true;
            ref.read(sidebarCollapsedProvider.notifier).state = true;
          },
          onEditJourney: (journey) async {
            final jsonStr = await compute(_encodeJson, journey.toJson());
            ref.read(journeyConfigProvider.notifier).updateFromJson(jsonStr);
            ref.read(dashboardMenuProvider.notifier).state = 'journeys';
            ref.read(editingJourneyProvider.notifier).state = true;
            ref.read(sidebarCollapsedProvider.notifier).state = true;
          },
          onViewCatalog: () {
            ref.read(dashboardMenuProvider.notifier).state = 'journeys';
            ref.read(editingJourneyProvider.notifier).state = false;
          },
          onViewTemplates: () {
            ref.read(dashboardMenuProvider.notifier).state = 'templates';
          },
          onViewRuns: () {
            ref.read(dashboardMenuProvider.notifier).state = 'runs';
          },
        );
    }
  }
}

class DashboardTopHeader extends StatelessWidget {
  const DashboardTopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(
          bottom: BorderSide(color: RevoTheme.cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          HeaderEnvironment(),
          SizedBox(width: 16),
          HeaderControls(),
        ],
      ),
    );
  }
}

class HeaderControls extends ConsumerWidget {
  const HeaderControls({super.key});

  Future<void> _exportJson(BuildContext context, Map<String, dynamic> jsonMap) async {
    // Moved to compute to avoid UI thread block on large JSON structures
    final jsonStr = await compute(_encodeJsonPretty, jsonMap);
    if (!context.mounted) return;

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
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
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
                  Navigator.pop(dialogContext);
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
    if (journeyConfig.steps == null || journeyConfig.steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No steps found in this journey!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        bool blocSelected = true;
        bool getxSelected = true;
        bool riverpodSelected = true;

        return StatefulBuilder(
          builder: (sbContext, setStateDialog) {
            final textStyle = GoogleFonts.inter(color: RevoTheme.textPrimary);
            final hasSelection = blocSelected || getxSelected || riverpodSelected;

            return AlertDialog(
              backgroundColor: RevoTheme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: RevoTheme.cardBorder),
              ),
              title: Text(
                "Generate Flutter Code",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select target architectures to generate for your multi-step journey:",
                      style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Theme(
                      data: ThemeData(
                        unselectedWidgetColor: RevoTheme.textSecondary,
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: Text("BLoC Architecture", style: textStyle.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text("Clean Code, Repositories, Use Cases, Events, States & Screens", style: textStyle.copyWith(fontSize: 11, color: RevoTheme.textSecondary)),
                            value: blocSelected,
                            activeColor: RevoTheme.primaryLight,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              setStateDialog(() {
                                blocSelected = val ?? false;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: Text("GetX Architecture", style: textStyle.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text("Bindings, Controllers, Repositories & View Screens", style: textStyle.copyWith(fontSize: 11, color: RevoTheme.textSecondary)),
                            value: getxSelected,
                            activeColor: RevoTheme.primaryLight,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              setStateDialog(() {
                                getxSelected = val ?? false;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: Text("Riverpod Architecture", style: textStyle.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text("Notifier, Providers, Entities, Data Sources & Screens", style: textStyle.copyWith(fontSize: 11, color: RevoTheme.textSecondary)),
                            value: riverpodSelected,
                            activeColor: RevoTheme.primaryLight,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              setStateDialog(() {
                                riverpodSelected = val ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text("Cancel", style: TextStyle(color: RevoTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: !hasSelection
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                          final architectures = <Architecture>{
                            if (blocSelected) Architecture.bloc,
                            if (getxSelected) Architecture.getx,
                            if (riverpodSelected) Architecture.riverpod,
                          };

                          try {
                            generateAndSaveAllFiles(
                              journeyConfig: journeyConfig,
                              architectures: architectures,
                            );

                  if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("✅ Code generation started — select your project folder!"),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          } catch (e, stack) {
                            debugPrint("Generation error: $e\n$stack");
                  if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Generation error: $e"),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RevoTheme.primary,
                  ),
                  child: const Text("Generate"),
                ),
          
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Localize watches so the header only rebuilds when needed
    final isEditingJourney = ref.watch(editingJourneyProvider);
    final showStepsPanel = ref.watch(showStepsPanelProvider);
    final showPropertiesPanel = ref.watch(showPropertiesPanelProvider);
    final themeMode = ref.watch(themeModeProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 1350;

    return Flexible(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
                  if (isEditingJourney) ...[
                    if (isCompact) ...[
                      IconButton(
                        icon: Icon(
                          showStepsPanel ? Icons.format_list_bulleted_rounded : Icons.list_rounded,
                          color: showStepsPanel ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                          size: 20,
                        ),
                        tooltip: showStepsPanel ? "Hide Steps Panel" : "Show Steps Panel",
                        onPressed: () {
                          ref.read(showStepsPanelProvider.notifier).state = !showStepsPanel;
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          showPropertiesPanel ? Icons.tune_rounded : Icons.tune_outlined,
                          color: showPropertiesPanel ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                          size: 20,
                        ),
                        tooltip: showPropertiesPanel ? "Hide Properties Panel" : "Show Properties Panel",
                        onPressed: () {
                          ref.read(showPropertiesPanelProvider.notifier).state = !showPropertiesPanel;
                        },
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.read(showStepsPanelProvider.notifier).state = !showStepsPanel;
                        },
                        icon: Icon(
                          showStepsPanel ? Icons.format_list_bulleted_rounded : Icons.list_rounded,
                          size: 16,
                          color: showStepsPanel ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                        ),
                        label: Text(
                          showStepsPanel ? "Hide Steps" : "Show Steps",
                          style: TextStyle(
                            fontSize: 11,
                            color: showStepsPanel ? RevoTheme.textPrimary : RevoTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: BorderSide(
                            color: showStepsPanel ? RevoTheme.primary.withValues(alpha:0.5) : RevoTheme.cardBorder,
                          ),
                          backgroundColor: showStepsPanel ? RevoTheme.primary.withValues(alpha:0.08) : Colors.transparent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.read(showPropertiesPanelProvider.notifier).state = !showPropertiesPanel;
                        },
                        icon: Icon(
                          showPropertiesPanel ? Icons.tune_rounded : Icons.tune_outlined,
                          size: 16,
                          color: showPropertiesPanel ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                        ),
                        label: Text(
                          showPropertiesPanel ? "Hide Props" : "Show Props",
                          style: TextStyle(
                            fontSize: 11,
                            color: showPropertiesPanel ? RevoTheme.textPrimary : RevoTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: BorderSide(
                            color: showPropertiesPanel ? RevoTheme.primary.withValues(alpha:0.5) : RevoTheme.cardBorder,
                          ),
                          backgroundColor: showPropertiesPanel ? RevoTheme.primary.withValues(alpha:0.08) : Colors.transparent,
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
                        onPressed: () => _exportJson(context, ref.read(journeyConfigProvider).toJson()),
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
                      message: "Generate Code",
                      child: OutlinedButton(
                        onPressed: () => _generateBlocCode(context, ref.read(journeyConfigProvider)),
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
                      onPressed: () => _exportJson(context, ref.read(journeyConfigProvider).toJson()),
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
                      onPressed: () => _generateBlocCode(context, ref.read(journeyConfigProvider)),
                      icon: const Icon(Icons.code_rounded, size: 16),
                      label: const Text("Generate Code"),
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
                      themeMode == ThemeMode.dark
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
    );
  }
}

class HeaderEnvironment extends ConsumerWidget {
  const HeaderEnvironment({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSidebarCollapsed = ref.watch(sidebarCollapsedProvider);
    final activeMenu = ref.watch(dashboardMenuProvider);
    final isEditingJourney = ref.watch(editingJourneyProvider);
    final environment = ref.watch(environmentProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 1350;

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isSidebarCollapsed ? Icons.menu_rounded : Icons.menu_open_rounded,
              color: RevoTheme.textPrimary,
              size: 20,
            ),
            tooltip: isSidebarCollapsed ? "Expand Sidebar" : "Collapse Sidebar",
            onPressed: () {
              ref.read(sidebarCollapsedProvider.notifier).state = !isSidebarCollapsed;
            },
          ),
          const SizedBox(width: 8),
          if (activeMenu == 'journeys' && isEditingJourney) ...[
            IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: RevoTheme.textPrimary, size: 20),
              tooltip: "Back to Catalog",
              onPressed: () {
                ref.read(editingJourneyProvider.notifier).state = false;
                ref.read(sidebarCollapsedProvider.notifier).state = false;
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
                  isCompact ? "Prod" : "Environment: $environment",
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: RevoTheme.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
