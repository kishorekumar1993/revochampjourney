// lib/bloc/revochamp_bloc_generator.dart
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  RevochampBlocGenerator  v5 — Unified Architecture                       ║
// ║                                                                          ║
// ║  ONE shared feature folder per step:                                     ║
// ║    lib/features/{journey}/{step}/                                        ║
// ║      ┣ data/        ← shared (datasource, repository_impl)              ║
// ║      ┣ domain/      ← shared (entity, repository, usecase)              ║
// ║      ┗ presentation/                                                     ║
// ║          ┣ bloc/    ← BLoC-specific (bloc, event, state, screen)        ║
// ║          ┗ riverpod/← Riverpod-specific (provider, notifier, view)      ║
// ║                                                                          ║
// ║  No duplication of entities / repositories / datasources.               ║
// ║  GetX removed.                                                           ║
// ╚══════════════════════════════════════════════════════════════════════════╝

import 'dart:convert';
import 'dart:js' as js;

import 'package:flutter/material.dart';

// Shared / common generators
import 'package:revojourneytryone/blocnew/api_client_generator.dart';
import 'package:revojourneytryone/blocnew/barrel_generator.dart';
import 'package:revojourneytryone/blocnew/bloc_generator.dart';
import 'package:revojourneytryone/blocnew/di_generator.dart';
import 'package:revojourneytryone/blocnew/entity_generator.dart';
import 'package:revojourneytryone/blocnew/event_generator.dart';
import 'package:revojourneytryone/blocnew/feature_entity_generator.dart';
import 'package:revojourneytryone/blocnew/field_schema.dart';
import 'package:revojourneytryone/blocnew/mapper_generator.dart';
import 'package:revojourneytryone/blocnew/model_generator.dart';
import 'package:revojourneytryone/blocnew/observer_generator.dart';
import 'package:revojourneytryone/blocnew/repository_generator.dart';
import 'package:revojourneytryone/blocnew/runtime_sources.dart';
import 'package:revojourneytryone/blocnew/screen_generator.dart';
import 'package:revojourneytryone/blocnew/state_generator.dart';
import 'package:revojourneytryone/blocnew/test_generator.dart';
import 'package:revojourneytryone/blocnew/validation_generator.dart';
import 'package:revojourneytryone/blocnew/widget_generator.dart';

// Riverpod presentation-only generators
import 'package:revojourneytryone/common/riverpod/riverpodapiservice.dart';
import 'package:revojourneytryone/common/riverpod/riverpod_presentation.dart';
import 'package:revojourneytryone/common/riverpod/riverpod_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Architecture enum — BLoC and Riverpod only; GetX removed
// ─────────────────────────────────────────────────────────────────────────────

enum Architecture { bloc, riverpod,getx }

// ─────────────────────────────────────────────────────────────────────────────
// Main entry point called from dashboard_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

void generateAndSaveAllFiles({
  required dynamic journeyConfig,
  Set<Architecture> architectures = const {
    Architecture.bloc,
    Architecture.riverpod,
  },
}) {
  if (journeyConfig.steps.isEmpty) return;

  final journeyNamespace = _toJourneyNamespace(
    journeyConfig.journeyName as String? ?? 'journey',
  );

  debugPrint('🚀 Journey: $journeyNamespace');
  debugPrint('🏗️  Architectures: ${architectures.map((a) => a.name).join(', ')}');

  final List<Map<String, String>> allFiles = [];
  bool coreFilesAdded = false;
  blocFeaturesInfo.clear();

  for (final step in journeyConfig.steps) {
    if (step.fields.isEmpty) {
      debugPrint("⚠️  Skipping '${step.id}' — no fields");
      continue;
    }

    final fieldsJson  = jsonEncode(step.fields.map((f) => f.toJson()).toList());
    final rawFields   = (jsonDecode(fieldsJson) as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final fieldsForDi = rawFields.map(FieldSchema.fromJson).toList();

    final cleanName  = step.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final screenName = cleanName.isNotEmpty
        ? '${cleanName[0].toUpperCase()}${cleanName.substring(1)}'
        : 'Step';

    debugPrint('  📋 Step: $screenName (${rawFields.length} fields)');

    // ── STEP 1: Shared common files (entity, repository, datasource, usecase) ──
    // Generated ONCE per step — neither BLoC nor Riverpod duplicates these.
    final commonFiles = _generateCommonFiles(
      screenName:       screenName,
      journeyNamespace: journeyNamespace,
      rawFields:        rawFields,
      addCoreFiles:     !coreFilesAdded,
    );
    allFiles.addAll(commonFiles);

    // ── STEP 2: BLoC presentation layer only ──────────────────────────────
    if (architectures.contains(Architecture.bloc)) {
      final blocFiles = _generateBlocPresentationFiles(
        screenName:       screenName,
        journeyNamespace: journeyNamespace,
        rawFields:        rawFields,
      );
      allFiles.addAll(blocFiles);

      blocFeaturesInfo.add(FeatureInfo(
        featureName: '${screenName}Form',
        baseName:    screenName.toLowerCase(),
        fields:      fieldsForDi,
      ));
    }

    // ── STEP 3: Riverpod presentation layer only ──────────────────────────
    if (architectures.contains(Architecture.riverpod)) {
      final riverpodFiles = _generateRiverpodPresentationFiles(
        screenName:       screenName,
        journeyNamespace: journeyNamespace,
        rawFields:        rawFields,
      );
      allFiles.addAll(riverpodFiles);
    }

    coreFilesAdded = true;
  }

  // ── Global BLoC DI (injection.dart + main.dart) ───────────────────────────
  if (architectures.contains(Architecture.bloc) && blocFeaturesInfo.isNotEmpty) {
    final globalDi = GlobalDiGenerator(blocFeaturesInfo, journeyNamespace);
    allFiles.addAll([
      {
        'folderPath':  'lib/bloc',
        'fileName':    'injection.dart',
        'textContent': globalDi.generateInjection(),
      },
      {
        'folderPath':  'lib/bloc',
        'fileName':    'main.dart',
        'textContent': globalDi.generateMain(),
      },
    ]);
  }

  if (allFiles.isEmpty) {
    debugPrint('❌ No files generated');
    return;
  }

  debugPrint('📦 Total files: ${allFiles.length}');
  js.context.callMethod('saveMultipleFilesToFolders', [jsonEncode(allFiles)]);
}

final List<FeatureInfo> blocFeaturesInfo = [];

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — Common / shared feature files
// Placed at:  lib/features/{journey}/{step}/
//   data/    — datasource, model, repository_impl
//   domain/  — entity, repository, usecase
//
// Neither BLoC nor Riverpod should re-generate any of these.
// ─────────────────────────────────────────────────────────────────────────────

List<Map<String, String>> _generateCommonFiles({
  required String screenName,
  required String journeyNamespace,
  required List<Map<String, dynamic>> rawFields,
  required bool addCoreFiles,
}) {
  final result      = <Map<String, String>>[];
  final baseName    = screenName.toLowerCase();
  final featureName = '${screenName}Form';
  final snakeName   = toSnakeCase(featureName);
  final base        = 'lib/features/$journeyNamespace/$baseName';

  final fields     = rawFields.map(FieldSchema.fromJson).toList();
  final flatFields = _flattenFields(rawFields).map(FieldSchema.fromJson).toList();

  // ── Core runtime / network / widgets (first step only) ───────────────────
  if (addCoreFiles) {
    result.addAll(_buildCoreFiles());
  }

  // ── Per-dropdown entity + model files ────────────────────────────────────
  for (final f in flatFields.where((f) => f.hasDropdownData)) {
    final entitySnake = toSnakeCase(f.entityClassName.replaceAll('Entity', ''));

    result.add({
      'folderPath':  '$base/domain/entity',
      'fileName':    '${entitySnake}_entity.dart',
      'textContent': EntityGenerator(
        className:  f.entityClassName,
        sampleJson: f.dropdownData.first,
      ).generate(),
    });

    result.add({
      'folderPath':  '$base/data/model',
      'fileName':    '${entitySnake}_model.dart',
      'textContent': ModelGenerator(
        modelClassName:  f.modelClassName,
        entityClassName: f.entityClassName,
        sampleJson:      f.dropdownData.first,
        entityImportPath:
            '../../domain/entity/${entitySnake}_entity.dart',
      ).generate(),
    });
  }

  // ── Feature entity ────────────────────────────────────────────────────────
  result.add({
    'folderPath':  '$base/domain/entity',
    'fileName':    '${snakeName}_entity.dart',
    'textContent': FeatureEntityGenerator(
      featureName: featureName,
      fields:      flatFields,
    ).generate(),
  });

  // ── Domain repository interface ───────────────────────────────────────────
  result.add({
    'folderPath':  '$base/domain/repository',
    'fileName':    '${snakeName}_repository.dart',
    'textContent': DomainRepositoryGenerator(
      featureName: featureName,
      fields:      flatFields,
    ).generate(),
  });

  // ── Use-case ──────────────────────────────────────────────────────────────
  result.add({
    'folderPath':  '$base/domain/usecase',
    'fileName':    '${snakeName}_usecase.dart',
    'textContent': UseCaseGenerator(
      featureName: featureName,
      fields:      flatFields,
    ).generate(),
  });

  // ── Data source ───────────────────────────────────────────────────────────
  result.add({
    'folderPath':  '$base/data/datasource',
    'fileName':    '${snakeName}_datasource.dart',
    'textContent': DataSourceGenerator(
      featureName: featureName,
      fields:      flatFields,
    ).generate(),
  });

  // ── Repository impl ───────────────────────────────────────────────────────
  result.add({
    'folderPath':  '$base/data/repository_impl',
    'fileName':    '${snakeName}_repository_impl.dart',
    'textContent': RepositoryImplGenerator(
      featureName: featureName,
      fields:      flatFields,
    ).generate(),
  });

  // ── Result model ─────────────────────────────────────────────────────────
  result.add({
    'folderPath':  '$base/domain/result',
    'fileName':    '${snakeName}_result.dart',
    'textContent': ResultModelGenerator(featureName: featureName).generate(),
  });

  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 — BLoC presentation layer ONLY
// Placed at:  lib/features/{journey}/{step}/presentation/bloc/
//
// Generates:  bloc, event, state, screen, validation, mapper, barrel, test
// Does NOT generate: entity, repository, datasource, model (those are common)
// ─────────────────────────────────────────────────────────────────────────────

List<Map<String, String>> _generateBlocPresentationFiles({
  required String screenName,
  required String journeyNamespace,
  required List<Map<String, dynamic>> rawFields,
}) {
  final result      = <Map<String, String>>[];
  final baseName    = screenName.toLowerCase();
  final featureName = '${screenName}Form';
  final snakeName   = toSnakeCase(featureName);
  final resultData  = '${featureName}ResultData';

  // Presentation lives inside the unified feature folder
  final presBase = 'lib/features/$journeyNamespace/$baseName/presentation/bloc';

  final fields     = rawFields.map(FieldSchema.fromJson).toList();
  final flatFields = _flattenFields(rawFields).map(FieldSchema.fromJson).toList();

  // ── Validation ────────────────────────────────────────────────────────────
  result.add({
    'folderPath':  '$presBase/validation',
    'fileName':    '${snakeName}_validators.dart',
    'textContent': ValidationGenerator(
      featureName: featureName,
      fields:      flatFields,
    ).generate(),
  });

  // ── Event ─────────────────────────────────────────────────────────────────
  result.add({
    'folderPath':  '$presBase/event',
    'fileName':    '${snakeName}_event.dart',
    'textContent': EventGenerator(
      featureName:       featureName,
      fields:            flatFields,
      hasAsyncDropdown:  flatFields.any((f) => f.isAsyncDropdown),
    ).generate(),
  });

  // ── State ─────────────────────────────────────────────────────────────────
  result.add({
    'folderPath':  '$presBase/state',
    'fileName':    '${snakeName}_feature_state.dart',
    'textContent': StateGenerator(
      featureName:         featureName,
      fields:              flatFields,
      resultDataClass:     resultData,
      // Import path from bloc/state/ up to core/runtime
      runtimeImportPrefix: '../../../../../../core/runtime',
    ).generate(),
  });

  // ── Mapper ────────────────────────────────────────────────────────────────
  result.add({
    'folderPath':  '$presBase/mapper',
    'fileName':    '${snakeName}_mapper.dart',
    'textContent': MapperGenerator(
      featureName:    featureName,
      fields:         flatFields,
      entityClassName:'${featureName}Entity',
      stateName:      '${featureName}FeatureState',
    ).generate(),
  });

  // ── BLoC (split files via generateAll) ───────────────────────────────────
  final blocFiles = BlocGenerator(
    featureName:                 featureName,
    configList:                  fields,
    generateAsyncValueSeparately:false,
    hasSubmit:                   false,
  ).generateAll();

  blocFiles.forEach((key, value) {
    result.add({
      'folderPath':  '$presBase/bloc',
      'fileName':    key,
      'textContent': value,
    });
  });

  // ── Screen ────────────────────────────────────────────────────────────────
  result.add({
    'folderPath':  '$presBase/screen',
    'fileName':    '${snakeName}_screen.dart',
    'textContent': ScreenGenerator(
      featureName: featureName,
      fields:      fields,
    ).generate(),
  });

  // ── Barrel files ──────────────────────────────────────────────────────────
  final barrelGen = BarrelGenerator(
    featureName: featureName,
    fields:      flatFields,
    baseName:    baseName,
  );
  barrelGen.generateAll().forEach((key, value) {
    result.add({
      'folderPath':  '$presBase/$key'.replaceAll('/$key', ''),
      'fileName':    key.split('/').last,
      'textContent': value,
    });
  });

  // ── Test ──────────────────────────────────────────────────────────────────
  result.add({
    'folderPath':  'test/features/$journeyNamespace/$baseName',
    'fileName':    '${snakeName}_bloc_test.dart',
    'textContent': TestGenerator(
      featureName: featureName,
      fields:      flatFields,
      baseName:    baseName,
    ).generate(),
  });

  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 3 — Riverpod presentation layer ONLY
// Placed at:  lib/features/{journey}/{step}/presentation/riverpod/
//
// Generates:  provider, notifier, view
// Does NOT generate: entity, repository, datasource, model (those are common)
// ─────────────────────────────────────────────────────────────────────────────

List<Map<String, String>> _generateRiverpodPresentationFiles({
  required String screenName,
  required String journeyNamespace,
  required List<Map<String, dynamic>> rawFields,
}) {
  final result      = <Map<String, String>>[];
  final baseName    = screenName.toLowerCase();
  final featureName = '${screenName}Form';
  final fileName    = '${baseName}_form';

  final presBase =
      'lib/features/$journeyNamespace/$baseName/presentation/riverpod';

  // ── Notifier (controller) ─────────────────────────────────────────────────
  // result.add({
  //   'folderPath':  '$presBase/controller',
  //   'fileName':    '${fileName}_notifier.dart',
  //   'textContent': generateNotifierImplInterface(
  //     featureName, rawFields, fileName,
  //   ),
  // });

  // ── Provider ──────────────────────────────────────────────────────────────
  result.add({
    'folderPath':  '$presBase/provider',
    'fileName':    '${fileName}_provider.dart',
    'textContent': generateProviderInterface(
      featureName, rawFields, fileName,
    ),
  });

  // ── View (screen) ─────────────────────────────────────────────────────────
  result.add({
    'folderPath':  '$presBase/view',
    'fileName':    '${fileName}_view.dart',
    'textContent': generateriverpodviewClass(
      featureName, rawFields, fileName,
    ),
  });

  // ── Shared api_service.dart — written once at core level ─────────────────
  result.add({
    'folderPath':  'lib/core/service',
    'fileName':    'api_service.dart',
    'textContent': generateApiServiceInterface(),
  });

  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// Core runtime / network / widgets helper
// Returns a flat list; called only for the first step.
// ─────────────────────────────────────────────────────────────────────────────

List<Map<String, String>> _buildCoreFiles() {
  const runtime  = 'lib/core/runtime';
  const network  = 'lib/core/network';
  const widgets  = 'lib/core/widgets';
  const storage  = 'lib/core/storage';
  const observer = 'lib/core/observer';

  return [
    // Runtime
    {'folderPath': runtime, 'fileName': 'failure.dart',            'textContent': RuntimeSources.failure},
    {'folderPath': runtime, 'fileName': 'validation_error.dart',   'textContent': RuntimeSources.validationError},
    {'folderPath': runtime, 'fileName': 'validator.dart',          'textContent': RuntimeSources.validator},
    {'folderPath': runtime, 'fileName': 'reactive_value.dart',     'textContent': RuntimeSources.reactiveValue},
    {'folderPath': runtime, 'fileName': 'async_state.dart',        'textContent': RuntimeSources.asyncState},
    {'folderPath': runtime, 'fileName': 'base_reactive_bloc.dart', 'textContent': RuntimeSources.baseReactiveBloc},

    // Network
    {'folderPath': network,              'fileName': 'app_exception.dart',    'textContent': ApiClientSources.appException},
    {'folderPath': network,              'fileName': 'api_response.dart',     'textContent': ApiClientSources.apiResponse},
    {'folderPath': network,              'fileName': 'dio_client.dart',       'textContent': ApiClientSources.dioClient},
    {'folderPath': network,              'fileName': 'failure_mapper.dart',   'textContent': ApiClientSources.failureMapper},
    {'folderPath': '$network/interceptors', 'fileName': 'auth_interceptor.dart',    'textContent': ApiClientSources.authInterceptor},
    {'folderPath': '$network/interceptors', 'fileName': 'logging_interceptor.dart', 'textContent': ApiClientSources.loggingInterceptor},
    {'folderPath': '$network/interceptors', 'fileName': 'error_interceptor.dart',   'textContent': ApiClientSources.errorInterceptor},

    // Storage
    {'folderPath': storage,  'fileName': 'local_storage_service.dart', 'textContent': ApiClientSources.localStorageService},

    // Observer
    {'folderPath': observer, 'fileName': 'bloc_observer.dart', 'textContent': const ObserverGenerator().generate()},

    // Widgets
    {'folderPath': widgets, 'fileName': 'form_field_wrapper.dart',       'textContent': ReusableWidgetSources.formFieldWrapper},
    {'folderPath': widgets, 'fileName': 'app_text_field.dart',           'textContent': ReusableWidgetSources.appTextField},
    {'folderPath': widgets, 'fileName': 'app_dropdown_field.dart',       'textContent': ReusableWidgetSources.appDropdownField},
    {'folderPath': widgets, 'fileName': 'app_async_dropdown_field.dart', 'textContent': ReusableWidgetSources.appAsyncDropdownField},
    {'folderPath': widgets, 'fileName': 'app_checkbox_field.dart',       'textContent': ReusableWidgetSources.appCheckboxField},
    {'folderPath': widgets, 'fileName': 'app_date_picker_field.dart',    'textContent': ReusableWidgetSources.appDatePickerField},
    {'folderPath': widgets, 'fileName': 'app_radio_group_field.dart',    'textContent': ReusableWidgetSources.appRadioGroupField},
    {'folderPath': widgets, 'fileName': 'app_file_upload_field.dart',    'textContent': ReusableWidgetSources.appFileUploadField},
    {'folderPath': widgets, 'fileName': 'app_multi_select_field.dart',   'textContent': ReusableWidgetSources.appMultiSelectField},
    {'folderPath': widgets, 'fileName': 'app_form_button.dart',          'textContent': ReusableWidgetSources.appFormButton},
    {'folderPath': widgets, 'fileName': 'app_error_widget.dart',         'textContent': ReusableWidgetSources.appErrorWidget},
    {'folderPath': widgets, 'fileName': 'app_loading_widget.dart',       'textContent': ReusableWidgetSources.appLoadingWidget},
    {'folderPath': widgets, 'fileName': 'widgets.dart',                  'textContent': ReusableWidgetSources.widgetsBarrel},
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience wrapper — still usable from old call-sites
// ─────────────────────────────────────────────────────────────────────────────

List<Map<String, String>> generateFileDataArray({
  required String screenName,
  required String modelName,
  required List<Map<String, dynamic>> fieldJsonRaw,
  bool generateTests   = true,
  bool generateBarrels = true,
  String journeyNamespace = 'journey',
}) {
  final safeFields = _deepClone(fieldJsonRaw);

  final all = <Map<String, String>>[];
  all.addAll(_generateCommonFiles(
    screenName:       screenName,
    journeyNamespace: journeyNamespace,
    rawFields:        safeFields,
    addCoreFiles:     true,
  ));
  all.addAll(_generateBlocPresentationFiles(
    screenName:       screenName,
    journeyNamespace: journeyNamespace,
    rawFields:        safeFields,
  ));
  return all;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Deep-clone via JSON round-trip — eliminates all JSArray/JSObject remnants.
List<Map<String, dynamic>> _deepClone(List<Map<String, dynamic>> input) =>
    (jsonDecode(jsonEncode(input)) as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

/// Recursively flattens nested / component fields.
List<Map<String, dynamic>> _flattenFields(List<Map<String, dynamic>> source) {
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

/// camelCase / PascalCase → snake_case
String toSnakeCase(String text) {
  if (text.isEmpty) return text;
  final buffer = StringBuffer()..write(text[0].toLowerCase());
  for (int i = 1; i < text.length; i++) {
    final char = text[i];
    if (char.toUpperCase() == char && char != char.toLowerCase()) {
      buffer.write('_${char.toLowerCase()}');
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
}