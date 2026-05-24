// lib/bloc/revochamp_bloc_generator.dart  (v3 — full fixed orchestrator)
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  RevochampBlocGenerator  v3                                              ║
// ║                                                                          ║
// ║  FIXES vs v2:                                                            ║
// ║  1. NewWorkHomeResult circular-import — moved to dedicated *_result.dart ║
// ║  2. toJson() was missing on FeatureEntity — now generated               ║
// ║  3. http.Client replaced with Dio-based DioClient                       ║
// ║  4. failureMapper.dart replaces inline try/catch patterns               ║
// ║  5. LocalStorageService wired for cacheable dropdowns                   ║
// ║  6. Reusable core widgets (AppTextField, AppDropdownField, etc.)        ║
// ║  7. AppException hierarchy (ServerException, NetworkException, etc.)    ║
// ╚══════════════════════════════════════════════════════════════════════════╝

import 'dart:convert';

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

class RevochampBlocGenerator {
  RevochampBlocGenerator({
    required this.screenName,
    required this.modelName,
    required this.fieldJsonRaw,
    this.generateTests   = true,
    this.generateBarrels = true,
  });

  final String                     screenName;
  final String                     modelName;
  final List<Map<String, dynamic>> fieldJsonRaw;
  final bool                       generateTests;
  final bool                       generateBarrels;

  Map<String, String> generate() {
    final featureName = '$screenName$modelName';
    final baseName    = screenName.toLowerCase();
    final snakeName   = toSnakeCase(featureName);
    final resultData  = '${featureName}ResultData';
    final featBase    = 'lib/bloc/features/$baseName';

    final fields = fieldJsonRaw.map(FieldSchema.fromJson).toList();
    final files  = <String, String>{};

    // ── 1. Core runtime ──────────────────────────────────────────────────────
    _addRuntime(files);

    // ── 2. Core network layer (Dio) ──────────────────────────────────────────
    _addNetworkLayer(files);

    // ── 3. Core storage ──────────────────────────────────────────────────────
    files['lib/bloc/core/storage/local_storage_service.dart'] =
        ApiClientSources.localStorageService;

    // ── 4. Reusable widgets (once per project) ────────────────────────────────
    _addCoreWidgets(files);

    // ── 5. BLoC observer ─────────────────────────────────────────────────────
    files['lib/bloc/core/observer/bloc_observer.dart'] =
        const ObserverGenerator().generate();

    // ── 6. Per-dropdown: Entity + Model ──────────────────────────────────────
    for (final f in fields.where((f) => f.hasDropdownData)) {
      final entitySnake =
          toSnakeCase(f.entityClassName.replaceAll('Entity', ''));

      files['$featBase/domain/entities/${entitySnake}_entity.dart'] =
          EntityGenerator(
            className:  f.entityClassName,
            sampleJson: f.dropdownData.first,
          ).generate();

      files['$featBase/data/model/${entitySnake}_model.dart'] =
          ModelGenerator(
            modelClassName:  f.modelClassName,
            entityClassName: f.entityClassName,
            sampleJson:      f.dropdownData.first,
            entityImportPath:
                '../../domain/entities/${entitySnake}_entity.dart',
          ).generate();
    }

    // ── 7. Feature domain entity  (FIX: includes toJson) ─────────────────────
    files['$featBase/domain/entities/${snakeName}_entity.dart'] =
        FeatureEntityGenerator(
          featureName: featureName,
          fields:      fields,
        ).generate();

    // ── 8. Result model  (FIX: own file, breaks circular import) ─────────────
    files['$featBase/domain/result/${snakeName}_result.dart'] =
        ResultModelGenerator(featureName: featureName).generate();

    // ── 9. Domain repository interface ────────────────────────────────────────
    files['$featBase/domain/repositories/${snakeName}_repository.dart'] =
        DomainRepositoryGenerator(
          featureName: featureName,
          fields:      fields,
        ).generate();

    // ── 10. Use cases ──────────────────────────────────────────────────────────
    files['$featBase/domain/usecases/${snakeName}_usecases.dart'] =
        UseCaseGenerator(
          featureName: featureName,
          fields:      fields,
        ).generate();

    // ── 11. DataSource  (FIX: Dio + LocalStorage) ─────────────────────────────
    files['$featBase/data/datasources/${snakeName}_datasource.dart'] =
        DataSourceGenerator(
          featureName: featureName,
          fields:      fields,
        ).generate();

    // ── 12. Repository implementation  (FIX: failureMapper) ───────────────────
    files['$featBase/data/repositories/${snakeName}_repository_impl.dart'] =
        RepositoryImplGenerator(
          featureName: featureName,
          fields:      fields,
        ).generate();

    // ── 13. Validators ─────────────────────────────────────────────────────────
    files['$featBase/presentation/validation/${snakeName}_validators.dart'] =
        ValidationGenerator(
          featureName: featureName,
          fields:      fields,
        ).generate();

    // ── 14. Event ─────────────────────────────────────────────────────────────
    files['$featBase/presentation/events/${snakeName}_event.dart'] =
        EventGenerator(
          featureName:      featureName,
          fields:           fields,
          hasAsyncDropdown: fields.any((f) => f.isAsyncDropdown),
        ).generate();

    // ── 15. State ─────────────────────────────────────────────────────────────
    files['$featBase/presentation/state/${snakeName}_feature_state.dart'] =
        StateGenerator(
          featureName:          featureName,
          fields:               fields,
          resultDataClass:      resultData,
          runtimeImportPrefix:  '../../../../core/runtime',
        ).generate();

    // ── 16. Mapper ────────────────────────────────────────────────────────────
    files['$featBase/presentation/mapper/${snakeName}_mapper.dart'] =
        MapperGenerator(
          featureName:     featureName,
          fields:          fields,
          entityClassName: '${featureName}Entity',
          stateName:       '${featureName}FeatureState',
        ).generate();

    // ── 17. BLoC ─────────────────────────────────────────────────────────────
    files['$featBase/presentation/bloc/${snakeName}_bloc.dart'] =
        BlocGenerator(
          featureName:          featureName,
          fields:               fields,
          stateName:            '${featureName}FeatureState',
          mapperName:           '${featureName}Mapper',
          validatorsName:       '${featureName}Validators',
          resultDataClass:      resultData,
          runtimeImportPrefix:  '../../../../core/runtime',
        ).generate();

    // ── 18. Screen (uses reusable widgets) ─────────────────────────────────────
    files['$featBase/presentation/screens/${snakeName}_screen.dart'] =
        ScreenGenerator(
          featureName: featureName,
          fields:      fields,
        ).generate();

    // ── 19. DI + main.dart ────────────────────────────────────────────────────
    final diGen = DiGenerator(
      featureName: featureName,
      fields:      fields,
      baseName:    baseName,
    );
    files['lib/bloc/injection.dart'] = diGen.generateInjection();
    files['lib/bloc/main.dart']      = diGen.generateMain();

    // ── 20. Barrel exports ────────────────────────────────────────────────────
    if (generateBarrels) {
      final barrelGen = BarrelGenerator(
        featureName: featureName,
        fields:      fields,
        baseName:    baseName,
      );
      for (final entry in barrelGen.generateAll().entries) {
        files['$featBase/${entry.key}'] = entry.value;
      }
    }

    // ── 21. Test stubs ────────────────────────────────────────────────────────
    if (generateTests) {
      files['test/features/$baseName/${snakeName}_bloc_test.dart'] =
          TestGenerator(
            featureName: featureName,
            fields:      fields,
            baseName:    baseName,
          ).generate();
    }

    return files;
  }

  // ── Runtime core ──────────────────────────────────────────────────────────

  void _addRuntime(Map<String, String> files) {
    const base = 'lib/bloc/core/runtime';
    files['$base/failure.dart']          = RuntimeSources.failure;
    files['$base/validation_error.dart'] = RuntimeSources.validationError;
    files['$base/validator.dart']        = RuntimeSources.validator;
    files['$base/reactive_value.dart']   = RuntimeSources.reactiveValue;
    files['$base/async_state.dart']      = RuntimeSources.asyncState;
    files['$base/base_reactive_bloc.dart'] = RuntimeSources.baseReactiveBloc;
  }

  // ── Dio network layer ─────────────────────────────────────────────────────

  void _addNetworkLayer(Map<String, String> files) {
    const base = 'lib/bloc/core/network';
    files['$base/app_exception.dart']                    = ApiClientSources.appException;
    files['$base/api_response.dart']                     = ApiClientSources.apiResponse;
    files['$base/dio_client.dart']                       = ApiClientSources.dioClient;
    files['$base/failure_mapper.dart']                   = ApiClientSources.failureMapper;
    files['$base/interceptors/auth_interceptor.dart']    = ApiClientSources.authInterceptor;
    files['$base/interceptors/logging_interceptor.dart'] = ApiClientSources.loggingInterceptor;
    files['$base/interceptors/error_interceptor.dart']   = ApiClientSources.errorInterceptor;
  }

  // ── Reusable widgets ──────────────────────────────────────────────────────

  void _addCoreWidgets(Map<String, String> files) {
    const base = 'lib/bloc/core/widgets';
    files['$base/form_field_wrapper.dart']       = ReusableWidgetSources.formFieldWrapper;
    files['$base/app_text_field.dart']           = ReusableWidgetSources.appTextField;
    files['$base/app_dropdown_field.dart']       = ReusableWidgetSources.appDropdownField;
    files['$base/app_async_dropdown_field.dart'] = ReusableWidgetSources.appAsyncDropdownField;
    files['$base/app_checkbox_field.dart']       = ReusableWidgetSources.appCheckboxField;
    files['$base/app_form_button.dart']          = ReusableWidgetSources.appFormButton;
    files['$base/app_error_widget.dart']         = ReusableWidgetSources.appErrorWidget;
    files['$base/app_loading_widget.dart']       = ReusableWidgetSources.appLoadingWidget;
    files['$base/widgets.dart']                  = ReusableWidgetSources.widgetsBarrel;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience — fileDataArray for JS interop
// ─────────────────────────────────────────────────────────────────────────────

// List<Map<String, String>> generateFileDataArray({
//   required String screenName,
//   required String modelName,
//   required List<Map<String, dynamic>> fieldJsonRaw,
//   bool generateTests   = true,
//   bool generateBarrels = true,
// }) {
//   final files = RevochampBlocGenerator(
//     screenName:      screenName,
//     modelName:       modelName,
//     fieldJsonRaw:    fieldJsonRaw,
//     generateTests:   generateTests,
//     generateBarrels: generateBarrels,
//   ).generate();
List<Map<String, String>> generateFileDataArray({
  required String screenName,
  required String modelName,
  required List<Map<String, dynamic>> fieldJsonRaw,
  bool generateTests   = true,
  bool generateBarrels = true,
}) {
  // Deep-clone via JSON round-trip so any JSArray/JSObject remnants from
  // Flutter Web interop are converted to plain Dart List/Map before the
  // generators run.
  final roundTripped = jsonDecode(jsonEncode(fieldJsonRaw)) as List<dynamic>;
  final safeFields = roundTripped
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  final files = RevochampBlocGenerator(
    screenName:      screenName,
    modelName:       modelName,
    fieldJsonRaw:    safeFields,
    generateTests:   generateTests,
    generateBarrels: generateBarrels,
  ).generate();
  
  return files.entries.map((e) {
    final parts      = e.key.split('/');
    final fileName   = parts.last;
    final folderPath = parts.take(parts.length - 1).join('/');
    return {
      'folderPath':  folderPath,
      'fileName':    fileName,
      'textContent': e.value,
    };
  }).toList();
}