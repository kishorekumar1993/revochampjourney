// lib/bloc/revochamp_bloc_generator.dart
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  RevochampBlocGenerator  v4 — Unified Orchestrator                       ║
// ║                                                                          ║
// ║  Generates THREE complete architecture patterns per step:                ║
// ║  1. BLoC   → lib/bloc/features/{journey}/{step}/                        ║
// ║  2. GetX   → lib/getx/features/{journey}/{step}/                        ║
// ║  3. Riverpod → lib/riverpod/features/{journey}/{step}/                  ║
// ║                                                                          ║
// ║  Shared core files (runtime, network, widgets) generated ONCE.          ║
// ╚══════════════════════════════════════════════════════════════════════════╝

// ignore_for_file: deprecated_member_use

import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import 'package:flutter/foundation.dart';
import 'package:revojourneytryone/codegenerator/generators/bloc/generators/di_generator.dart';
import 'package:revojourneytryone/codegenerator/generators/bloc/engine/field_schema.dart';
import 'package:revojourneytryone/codegenerator/filegegnerator/common_bloc_generator.dart';
import 'package:revojourneytryone/codegenerator/filegegnerator/getx_generator.dart';
import 'package:revojourneytryone/codegenerator/filegegnerator/riverpodgenerator.dart';
import 'package:revojourneytryone/codegenerator/getx/getx_core_generator.dart';
import 'package:revojourneytryone/codegenerator/generators/bloc/generators/widget_generator.dart';

import '../../features/journey_builder/domain/entities/journey_models.dart';

import '../getx/route_generator.dart';
import 'bloc_files_generator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Architecture enum — which patterns to generate
// ─────────────────────────────────────────────────────────────────────────────

enum Architecture { bloc, getx, riverpod }

// ─────────────────────────────────────────────────────────────────────────────
// Main entry point called from dashboard_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

List<Map<String, String>> generateAllFilesData({
  required dynamic journeyConfig,
  Set<Architecture> architectures = const {
    Architecture.bloc,
    Architecture.getx,
    Architecture.riverpod,
  },
  String layoutStyle = 'split',
}) {
  if (journeyConfig.steps.isEmpty) return [];

  // "Motor Insurance Journey" → "motorInsurance"
  final journeyNamespace = _toJourneyNamespace(
    journeyConfig.journeyName as String? ?? 'journey',
  );

  debugPrint('🚀 Journey: $journeyNamespace');
  debugPrint(
    '🏗️  Architectures: ${architectures.map((a) => a.name).join(', ')}',
  );

  final List<Map<String, String>> allFiles = [];
  bool coreFilesAdded = false;
  final blocFeaturesInfo = <FeatureInfo>[];
  final journeyJson =
      (journeyConfig as dynamic).toJson() as Map<String, dynamic>;

  for (final step in journeyConfig.steps) {
    if (step.fields.isEmpty) {
      debugPrint("⚠️  Skipping '${step.id}' — no fields");
      continue;
    }

    // Avoid jsonEncode/jsonDecode round-trips (CPU-heavy on web).
    // Explicit List<Map<...>> — on web, .map().toList() is List<dynamic> and
    // fails when passed to flattenFields / generateBlocFiles.
    final rawFields = fieldsToJsonMaps(step.fields);
    final fieldsForDi = rawFields
        .map((e) => FieldSchema.fromJson(e))
        .toList(growable: false);
    final flatFields = flattenFields(rawFields);

    final cleanName = step.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final screenName = cleanName.isNotEmpty
        ? '${cleanName[0].toUpperCase()}${cleanName.substring(1)}'
        : 'Step';

    debugPrint('  📋 Step: $screenName (${rawFields.length} fields)');

    final stepJson = step.toJson();

    // ── 1. BLoC ───────────────────────────────────────────────────────────
    if (architectures.contains(Architecture.bloc)) {
      final blocFiles = generateBlocFiles(
        screenName: screenName,
        journeyNamespace: journeyNamespace,
        rawFields: rawFields,
        stepJson: stepJson,
        addCoreFiles: !coreFilesAdded,
      );
      allFiles.addAll(blocFiles);

      blocFeaturesInfo.add(
        FeatureInfo(
          featureName: '${screenName}Form',
          baseName: screenName.toLowerCase(),
          fields: fieldsForDi,
          hasRemoteDataSource: true,
        ),
      );

      final commonFiles = generateCommonCleanArchiFiles(
        screenName: screenName,
        journeyNamespace: journeyNamespace,
        rawFields: rawFields,
        flatFields: flatFields,
        journeyJson: {
          'journeyName': journeyJson['journeyName'],
          'steps': [stepJson],
        },
        statemanagement: "bloc",
      );
      allFiles.addAll(commonFiles);
    }

    // ── 2. GetX ───────────────────────────────────────────────────────────
    if (architectures.contains(Architecture.getx)) {
      final allStepsJson = journeyConfig.steps.map((e) => e.toJson()).toList();
      final getxFiles = generateGetxFiles(
        screenName: screenName,
        journeyNamespace: journeyNamespace,
        rawFields: rawFields,
        flatFields: flatFields,
        stepJson: stepJson,
        allSteps: allStepsJson,
        layoutStyle: layoutStyle,
      );
      final coreFiles = generateGetxCoreFiles(
        projectName: screenName,
        baseUrl: 'https://dev-api.revochamp.com',
        environmentName: "Environment.dev",
        generateResultClass: true,
        generateBaseController: true,
      );
      
      if (!coreFilesAdded) {
        final widgetsBase = 'lib/getx/core/widgets';
        final getxWidgetsBarrel = ReusableWidgetSources.widgetsBarrel.replaceFirst(
          "export 'app_async_dropdown_field.dart';\n",
          "",
        );
        coreFiles.addAll([
          {'folderPath': widgetsBase, 'fileName': 'form_field_wrapper.dart', 'textContent': ReusableWidgetSources.formFieldWrapper},
          {'folderPath': widgetsBase, 'fileName': 'app_text_field.dart', 'textContent': ReusableWidgetSources.appTextField},
          {'folderPath': widgetsBase, 'fileName': 'app_dropdown_field.dart', 'textContent': ReusableWidgetSources.appDropdownField},
          {'folderPath': widgetsBase, 'fileName': 'app_checkbox_field.dart', 'textContent': ReusableWidgetSources.appCheckboxField},
          {'folderPath': widgetsBase, 'fileName': 'app_date_picker_field.dart', 'textContent': ReusableWidgetSources.appDatePickerField},
          {'folderPath': widgetsBase, 'fileName': 'app_radio_group_field.dart', 'textContent': ReusableWidgetSources.appRadioGroupField},
          {'folderPath': widgetsBase, 'fileName': 'app_file_upload_field.dart', 'textContent': ReusableWidgetSources.appFileUploadField},
          {'folderPath': widgetsBase, 'fileName': 'app_multi_select_field.dart', 'textContent': ReusableWidgetSources.appMultiSelectField},
          {'folderPath': widgetsBase, 'fileName': 'app_form_button.dart', 'textContent': ReusableWidgetSources.appFormButton},
          {'folderPath': widgetsBase, 'fileName': 'app_error_widget.dart', 'textContent': ReusableWidgetSources.appErrorWidget},
          {'folderPath': widgetsBase, 'fileName': 'app_loading_widget.dart', 'textContent': ReusableWidgetSources.appLoadingWidget},
          {'folderPath': widgetsBase, 'fileName': 'app_data_grid.dart', 'textContent': ReusableWidgetSources.appDataGrid},
          {'folderPath': widgetsBase, 'fileName': 'widgets.dart', 'textContent': getxWidgetsBarrel},
        ]);
      }

final routerFiles = generateGetXRouterFromSteps(allStepsJson, journeyNamespace);
allFiles.addAll(routerFiles);
      allFiles.addAll(getxFiles);
      allFiles.addAll(coreFiles);
    }
    // ── 3. Riverpod ───────────────────────────────────────────────────────
    if (architectures.contains(Architecture.riverpod)) {
      final riverpodFiles = generateRiverpodFiles(
        screenName: screenName,
        journeyNamespace: journeyNamespace,
        rawFields: rawFields,
        journeyJson: journeyJson,
        flatFields: flatFields,
        stepJson: stepJson,
      );
      allFiles.addAll(riverpodFiles);
    }

    coreFilesAdded = true;
  }

  // Journey route map for generated Next navigation (GetX / Riverpod / BLoC).
  allFiles.add({
    'folderPath': 'lib/core/routing',
    'fileName': 'journey_routes.dart',
    'textContent': _generateJourneyRoutes(journeyConfig),
  });

  if (architectures.contains(Architecture.bloc) &&
      blocFeaturesInfo.isNotEmpty) {
    final globalDi = GlobalDiGenerator(blocFeaturesInfo, journeyNamespace);
    allFiles.add({
      'folderPath': 'lib/bloc',
      'fileName': 'injection.dart',
      'textContent': globalDi.generateInjection(),
    });
    allFiles.add({
      'folderPath': 'lib/bloc',
      'fileName': 'main.dart',
      'textContent': globalDi.generateMain(),
    });
  }

  return allFiles;
}

Future<void> generateAndSaveAllFiles({
  required dynamic journeyConfig,
  Set<Architecture> architectures = const {
    Architecture.bloc,
    Architecture.getx,
    Architecture.riverpod,
  },
  String layoutStyle = 'split',
}) async {
  final allFiles = await generateAllFilesDataIsolate(
    journeyConfig: journeyConfig,
    architectures: architectures,
    layoutStyle: layoutStyle,
  );

  if (allFiles.isEmpty) {
    debugPrint('❌ No files generated');
    return;
  }

  debugPrint('📦 Total files: ${allFiles.length}');
  js.context.callMethod('saveMultipleFilesToFolders', [jsonEncode(allFiles)]);
}

/// Isolate wrapper: runs the *pure* generation work off the UI thread.
Future<List<Map<String, String>>> generateAllFilesDataIsolate({
  required dynamic journeyConfig,
  Set<Architecture> architectures = const {
    Architecture.bloc,
    Architecture.getx,
    Architecture.riverpod,
  },
  String layoutStyle = 'split',
}) async {
  // Flutter Web does not support real isolates; run generation on main thread.
  if (kIsWeb) {
    return generateAllFilesData(
      journeyConfig: journeyConfig,
      architectures: architectures,
      layoutStyle: layoutStyle,
    );
  }

  final journeyJson =
      (journeyConfig as dynamic).toJson() as Map<String, dynamic>;
  final archNames = architectures.map((a) => a.name).toList(growable: false);

  return compute(_generateAllFilesDataEntry, <String, dynamic>{
    'journeyJson': journeyJson,
    'architectures': archNames,
    'layoutStyle': layoutStyle,
  });
}

// Top-level entrypoint for `compute()`.
List<Map<String, String>> _generateAllFilesDataEntry(
  Map<String, dynamic> payload,
) {
  final journeyJson = payload['journeyJson'] as Map<String, dynamic>;
  final archNames = (payload['architectures'] as List<dynamic>).cast<String>();
  final layoutStyle = payload['layoutStyle']?.toString() ?? 'split';

  final archSet = <Architecture>{};
  for (final name in archNames) {
    switch (name) {
      case 'bloc':
        archSet.add(Architecture.bloc);
        break;
      case 'getx':
        archSet.add(Architecture.getx);
        break;
      case 'riverpod':
        archSet.add(Architecture.riverpod);
        break;
    }
  }

  final journeyConfig = JourneyConfig.fromJson(journeyJson);
  return generateAllFilesData(
    journeyConfig: journeyConfig,
    architectures: archSet,
    layoutStyle: layoutStyle,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience wrapper — still usable from old call sites
// ─────────────────────────────────────────────────────────────────────────────

List<Map<String, String>> generateFileDataArray({
  required String screenName,
  required String modelName,
  required List<Map<String, dynamic>> fieldJsonRaw,
  bool generateTests = true,
  bool generateBarrels = true,
}) {
  final files = RevochampBlocGenerator(
    screenName: screenName,
    modelName: modelName,
    fieldJsonRaw: fieldJsonRaw,
    generateTests: generateTests,
    generateBarrels: generateBarrels,
  ).generate();

  return files.entries.map((e) {
    final parts = e.key.split('/');
    final fileName = parts.last;
    final folderPath = parts.take(parts.length - 1).join('/');
    return {
      'folderPath': folderPath,
      'fileName': fileName,
      'textContent': e.value,
    };
  }).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Converts journey fields to JSON maps with a web-safe list type.
List<Map<String, dynamic>> fieldsToJsonMaps(List<JourneyField> fields) {
  return List<Map<String, dynamic>>.from(
    fields.map((f) => Map<String, dynamic>.from(f.toJson())),
  );
}

/// Flattens nested fields so models for inner dropdowns are generated
List<Map<String, dynamic>> flattenFields(List<dynamic> source) {
  final result = <Map<String, dynamic>>[];
  void flatten(dynamic item) {
    if (item == null) return;
    if (item is List) {
      for (final i in item) {
        flatten(i);
      }
      return;
    }
    if (item is! Map) return;

    final map = Map<String, dynamic>.from(item);
    if (map.containsKey('type')) {
      result.add(map);
      flatten(map['nestedFields']);
      final config = map['componentConfig'];
      if (config is Map) {
        flatten(config['fields']);
        flatten(config['columns']);
      }
    }
  }

  flatten(source);
  return result;
}

// ── Helper functions ─────────────────────────────────────────────────────
String toSnakeCase(String text) {
  if (text.isEmpty) return text;
  final buffer = StringBuffer();
  buffer.write(text[0].toLowerCase());
  for (int i = 1; i < text.length; i++) {
    final char = text[i];
    if (char.toUpperCase() == char && char != char.toLowerCase()) {
      // It's an uppercase letter
      buffer.write('_${char.toLowerCase()}');
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

/// "Motor Insurance Journey" → "motorInsurance"
String _toJourneyNamespace(String name) {
  final cleaned = name
      .replaceAll(RegExp(r'\bjourney\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'[^a-zA-Z0-9\s_\-]'), '')
      .trim();

  if (cleaned.isEmpty) return 'journey';

  final parts = cleaned
      .split(RegExp(r'[\s_\-]+'))
      .where((p) => p.isNotEmpty)
      .toList();

  if (parts.isEmpty) return 'journey';

  return parts.first.toLowerCase() +
      parts
          .skip(1)
          .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
          .join();
}

/// Route constants from journey JSON steps (used by generated Next navigation).
String _generateJourneyRoutes(dynamic journeyConfig) {
  final buf = StringBuffer();
  final steps = journeyConfig.steps;
  buf.writeln('// AUTO-GENERATED — enterprise journey routing registry');
  buf.writeln("import 'package:flutter/material.dart';");
  buf.writeln();
  buf.writeln('class JourneyRouteMeta {');
  buf.writeln('  const JourneyRouteMeta({');
  buf.writeln('    required this.stepId,');
  buf.writeln('    required this.path,');
  buf.writeln('    required this.title,');
  buf.writeln('    required this.index,');
  buf.writeln('    this.description,');
  buf.writeln('    this.requiresValidation = false,');
  buf.writeln('    this.guardKey,');
  buf.writeln('  });');
  buf.writeln('  final String stepId;');
  buf.writeln('  final String path;');
  buf.writeln('  final String title;');
  buf.writeln('  final int index;');
  buf.writeln('  final String? description;');
  buf.writeln('  final bool requiresValidation;');
  buf.writeln('  final String? guardKey;');
  buf.writeln('}');
  buf.writeln();
  buf.writeln(
    'typedef StepGuard = bool Function(String stepId, Map<String, String> query);',
  );
  buf.writeln(
    'typedef StepValidator = bool Function(String stepId, Map<String, dynamic> payload);',
  );
  buf.writeln();
  buf.writeln('class JourneyRoutes {');
  buf.writeln('  JourneyRoutes._();');
  buf.writeln("  static const String journeyPrefix = '/journey';");
  buf.writeln();
  for (final step in steps) {
    final id = step.id.replaceAll("'", "\\'");
    final title = (step.title ?? step.id).toString().replaceAll("'", "\\'");
    final desc = (step.description ?? '').toString().replaceAll("'", "\\'");
    buf.writeln("  static const String $id = '/journey/$id';");
    buf.writeln(
      "  static const JourneyRouteMeta ${id}Meta = JourneyRouteMeta(",
    );
    buf.writeln("    stepId: '$id',");
    buf.writeln("    path: $id,");
    buf.writeln("    title: '$title',");
    buf.writeln("    index: ${steps.indexOf(step)},");
    buf.writeln(
      desc.isNotEmpty ? "    description: '$desc'," : "    description: null,",
    );
    buf.writeln("  );");
    buf.writeln();
  }
  buf.writeln(
    '  static const List<JourneyRouteMeta> orderedSteps = <JourneyRouteMeta>[',
  );
  for (final step in steps) {
    final id = step.id.replaceAll("'", "\\'");
    buf.writeln('    ${id}Meta,');
  }
  buf.writeln('  ];');
  buf.writeln();
  buf.writeln('  static final Map<String, JourneyRouteMeta> byStepId = {');
  for (final step in steps) {
    final id = step.id.replaceAll("'", "\\'");
    buf.writeln("    '$id': ${id}Meta,");
  }
  buf.writeln('  };');
  buf.writeln();
  buf.writeln('  static final Map<String, JourneyRouteMeta> byPath = {');
  buf.writeln('    for (final meta in orderedSteps) meta.path: meta,');
  buf.writeln('  };');
  buf.writeln();
  buf.writeln(
    '  static String pathForStep(String stepId, {Map<String, String>? query}) {',
  );
  buf.writeln(
    "    final base = byStepId[stepId]?.path ?? '\$journeyPrefix/\$stepId';",
  );
  buf.writeln('    if (query == null || query.isEmpty) return base;');
  buf.writeln('    final uri = Uri(path: base, queryParameters: query);');
  buf.writeln('    return uri.toString();');
  buf.writeln('  }');
  buf.writeln();
  buf.writeln('  static String? stepIdFromLocation(String location) {');
  buf.writeln("    final uri = Uri.tryParse(location) ?? Uri(path: location);");
  buf.writeln("    if (!uri.path.startsWith('\$journeyPrefix/')) return null;");
  buf.writeln(
    "    final segments = uri.path.split('/').where((e) => e.isNotEmpty).toList();",
  );
  buf.writeln('    if (segments.length < 2) return null;');
  buf.writeln('    return segments[1];');
  buf.writeln('  }');
  buf.writeln();
  buf.writeln('  static Map<String, String> parseQuery(String location) {');
  buf.writeln("    final uri = Uri.tryParse(location) ?? Uri(path: location);");
  buf.writeln('    return uri.queryParameters;');
  buf.writeln('  }');
  buf.writeln();
  buf.writeln(
    '  static bool existsStep(String stepId) => byStepId.containsKey(stepId);',
  );
  buf.writeln(
    '  static bool existsPath(String path) => byPath.containsKey(path);',
  );
  buf.writeln(
    '  static int indexOfStep(String stepId) => byStepId[stepId]?.index ?? -1;',
  );
  buf.writeln(
    '  static JourneyRouteMeta? metaForStep(String stepId) => byStepId[stepId];',
  );
  buf.writeln(
    '  static String titleForStep(String stepId) => byStepId[stepId]?.title ?? stepId;',
  );
  buf.writeln();
  buf.writeln('  static String? nextStepId(String currentStepId) {');
  buf.writeln('    final i = indexOfStep(currentStepId);');
  buf.writeln('    if (i < 0 || i + 1 >= orderedSteps.length) return null;');
  buf.writeln('    return orderedSteps[i + 1].stepId;');
  buf.writeln('  }');
  buf.writeln();
  buf.writeln('  static String? previousStepId(String currentStepId) {');
  buf.writeln('    final i = indexOfStep(currentStepId);');
  buf.writeln('    if (i <= 0) return null;');
  buf.writeln('    return orderedSteps[i - 1].stepId;');
  buf.writeln('  }');
  buf.writeln();
  buf.writeln(
    '  static String? nextPath(String currentStepId, {Map<String, String>? query}) {',
  );
  buf.writeln('    final next = nextStepId(currentStepId);');
  buf.writeln('    if (next == null) return null;');
  buf.writeln('    return pathForStep(next, query: query);');
  buf.writeln('  }');
  buf.writeln();
  buf.writeln(
    '  static String? previousPath(String currentStepId, {Map<String, String>? query}) {',
  );
  buf.writeln('    final prev = previousStepId(currentStepId);');
  buf.writeln('    if (prev == null) return null;');
  buf.writeln('    return pathForStep(prev, query: query);');
  buf.writeln('  }');
  buf.writeln();
  buf.writeln('  static bool canNavigate({');
  buf.writeln('    required String toStepId,');
  buf.writeln('    Map<String, String>? query,');
  buf.writeln('    StepGuard? guard,');
  buf.writeln('  }) {');
  buf.writeln('    if (!existsStep(toStepId)) return false;');
  buf.writeln('    if (guard == null) return true;');
  buf.writeln('    return guard(toStepId, query ?? const <String, String>{});');
  buf.writeln('  }');
  buf.writeln();
  buf.writeln('  static bool validateBeforeNavigation({');
  buf.writeln('    required String fromStepId,');
  buf.writeln('    required Map<String, dynamic> payload,');
  buf.writeln('    StepValidator? validator,');
  buf.writeln('  }) {');
  buf.writeln('    if (validator == null) return true;');
  buf.writeln('    return validator(fromStepId, payload);');
  buf.writeln('  }');
  buf.writeln();
  buf.writeln('  static String? normalizeDeepLinkLocation(String location) {');
  buf.writeln("    final uri = Uri.tryParse(location) ?? Uri(path: location);");
  buf.writeln("    if (uri.path == '/' || uri.path.isEmpty) {");
  buf.writeln('      if (orderedSteps.isEmpty) return null;');
  buf.writeln('      return orderedSteps.first.path;');
  buf.writeln('    }');
  buf.writeln('    final stepId = stepIdFromLocation(uri.toString());');
  buf.writeln('    if (stepId == null || !existsStep(stepId)) return null;');
  buf.writeln('    return pathForStep(stepId, query: uri.queryParameters);');
  buf.writeln('  }');
  buf.writeln('}');

  return buf.toString();
}
