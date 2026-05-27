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

import 'package:flutter/material.dart';
import 'package:revojourneytryone/blocnew/di_generator.dart';
import 'package:revojourneytryone/blocnew/field_schema.dart';
import 'package:revojourneytryone/filegegnerator/common_bloc_generator.dart';
import 'package:revojourneytryone/filegegnerator/getx_generator.dart';
import 'package:revojourneytryone/filegegnerator/riverpodgenerator.dart';

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
  blocFeaturesInfo.clear();

  for (final step in journeyConfig.steps) {
    if (step.fields.isEmpty) {
      debugPrint("⚠️  Skipping '${step.id}' — no fields");
      continue;
    }

    final fieldsJson = jsonEncode(step.fields.map((f) => f.toJson()).toList());
    final rawFields = (jsonDecode(fieldsJson) as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final fieldsForDi = rawFields.map(FieldSchema.fromJson).toList();

    final cleanName = step.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final screenName = cleanName.isNotEmpty
        ? '${cleanName[0].toUpperCase()}${cleanName.substring(1)}'
        : 'Step';

    debugPrint('  📋 Step: $screenName (${rawFields.length} fields)');
    final journeyJson =
        jsonDecode(jsonEncode(journeyConfig)) as Map<String, dynamic>;
  
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

void generateAndSaveAllFiles({
  required dynamic journeyConfig,
  Set<Architecture> architectures = const {
    Architecture.bloc,
    Architecture.getx,
    Architecture.riverpod,
  },
}) {
  final allFiles = generateAllFilesData(
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

final List<FeatureInfo> blocFeaturesInfo = [];

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
  final safeFields = deepClone(fieldJsonRaw);
  final files = RevochampBlocGenerator(
    screenName: screenName,
    modelName: modelName,
    fieldJsonRaw: safeFields,
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

/// Deep-clone via JSON round-trip: eliminates all JSArray/JSObject remnants
List<Map<String, dynamic>> deepClone(List<Map<String, dynamic>> input) {
  return (jsonDecode(jsonEncode(input)) as List<dynamic>)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
}

/// Flattens nested fields so models for inner dropdowns are generated
List<Map<String, dynamic>> flattenFields(List<Map<String, dynamic>> source) {
  final result = <Map<String, dynamic>>[];
  void flatten(dynamic item) {
    if (item == null) return;
    if (item is List) {
      for (final i in item) flatten(i);
      return;
    }
    if (item is! Map<String, dynamic>) return;

    if (item.containsKey('type')) {
      result.add(item);
      flatten(item['nestedFields']);
      final config = item['componentConfig'];
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
