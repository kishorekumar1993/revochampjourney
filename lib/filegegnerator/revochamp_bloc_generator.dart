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

import 'dart:convert';
import 'dart:js' as js;

import 'package:flutter/foundation.dart';
import 'package:revojourneytryone/generators/bloc/generators/di_generator.dart';
import 'package:revojourneytryone/generators/bloc/engine/field_schema.dart';
import 'package:revojourneytryone/filegegnerator/common_bloc_generator.dart';
import 'package:revojourneytryone/filegegnerator/getx_generator.dart';
import 'package:revojourneytryone/filegegnerator/riverpodgenerator.dart';

import '../features/journey_builder/domain/entities/journey_models.dart';

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
  final journeyJson = (journeyConfig as dynamic).toJson() as Map<String, dynamic>;

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
  
    // ── 1. BLoC ───────────────────────────────────────────────────────────
    if (architectures.contains(Architecture.bloc)) {
      final blocFiles = generateBlocFiles(
        screenName: screenName,
        journeyNamespace: journeyNamespace,
        rawFields: rawFields,
        addCoreFiles: !coreFilesAdded,
      );
      allFiles.addAll(blocFiles);

      blocFeaturesInfo.add(
        FeatureInfo(
          featureName: '${screenName}Form',
          baseName: screenName.toLowerCase(),
          fields: fieldsForDi,
        ),
      );

      final commonFiles = generateCommonCleanArchiFiles(
        screenName: screenName,
        journeyNamespace: journeyNamespace,
        rawFields: rawFields,
        flatFields: flatFields,
        journeyJson: journeyJson,
        statemanagement: "Bloc" // <-- pass the full JSON
      );
      allFiles.addAll(commonFiles);
    }

    // ── 2. GetX ───────────────────────────────────────────────────────────
    if (architectures.contains(Architecture.getx)) {
      final getxFiles = generateGetxFiles(
        screenName: screenName,
        journeyNamespace: journeyNamespace,
        rawFields: rawFields,
        flatFields: flatFields,
      );
      allFiles.addAll(getxFiles);
    }
    // ── 3. Riverpod ───────────────────────────────────────────────────────
    if (architectures.contains(Architecture.riverpod)) {
      final riverpodFiles = generateRiverpodFiles(
        screenName: screenName,
        journeyNamespace: journeyNamespace,
        rawFields: rawFields,
        journeyJson: journeyJson, // <-- pass the full JSON
        flatFields: flatFields,
      );
      allFiles.addAll(riverpodFiles);
    }

    coreFilesAdded = true;
  }

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
}) async {
  final allFiles = await generateAllFilesDataIsolate(
    journeyConfig: journeyConfig,
    architectures: architectures,
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
}) async {
  // Flutter Web does not support real isolates; run generation on main thread.
  if (kIsWeb) {
    return generateAllFilesData(
      journeyConfig: journeyConfig,
      architectures: architectures,
    );
  }

  final journeyJson = (journeyConfig as dynamic).toJson() as Map<String, dynamic>;
  final archNames = architectures.map((a) => a.name).toList(growable: false);

  return compute(
    _generateAllFilesDataEntry,
    <String, dynamic>{
      'journeyJson': journeyJson,
      'architectures': archNames,
    },
  );
}

// Top-level entrypoint for `compute()`.
List<Map<String, String>> _generateAllFilesDataEntry(
  Map<String, dynamic> payload,
) {
  final journeyJson = payload['journeyJson'] as Map<String, dynamic>;
  final archNames = (payload['architectures'] as List<dynamic>).cast<String>();

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
      for (final i in item) flatten(i);
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

