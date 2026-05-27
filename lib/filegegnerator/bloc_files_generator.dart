// ─────────────────────────────────────────────────────────────────────────────
// 1. BLoC Generator
// ─────────────────────────────────────────────────────────────────────────────

import 'package:revojourneytryone/generators/bloc/generators/widget_generator.dart';
import 'package:revojourneytryone/generators/bloc/generators/api_client_generator.dart';
import 'package:revojourneytryone/generators/bloc/generators/bloc_generator.dart';
// import 'package:revojourneytryone/generators/bloc/generators/entity_generator.dart';
import 'package:revojourneytryone/generators/bloc/generators/event_generator.dart';
import 'package:revojourneytryone/generators/bloc/engine/field_schema.dart' hide toSnakeCase;
import 'package:revojourneytryone/generators/bloc/generators/mapper_generator.dart';
import 'package:revojourneytryone/generators/bloc/runtime/observer_generator.dart';
import 'package:revojourneytryone/generators/bloc/runtime/runtime_sources.dart';
import 'package:revojourneytryone/generators/bloc/generators/screen_generator.dart';
import 'package:revojourneytryone/generators/bloc/validators/validation_generator.dart';

List<Map<String, String>> generateBlocFiles({
  required String screenName,
  required String journeyNamespace,
  required List<Map<String, dynamic>> rawFields,
  required bool addCoreFiles,
}) {
  final result = <Map<String, String>>[];

  final files = RevochampBlocGenerator(
    screenName: screenName,
    modelName: 'Form',
    fieldJsonRaw: rawFields,
    generateTests: true,
    generateBarrels: true,
  ).generate();

  for (final entry in files.entries) {
    final parts = entry.key.split('/');
    final fileName = parts.last;
    final origFolder = parts.take(parts.length - 1).join('/');

    // Shared core files — only from first step
    final isCore =
        origFolder.startsWith('lib/bloc/core') ||
        origFolder == 'lib/bloc' ||
        origFolder.startsWith('test/');

    if (isCore && !addCoreFiles) continue;

    // Inject journey namespace into feature paths
    final folder = isCore
        ? origFolder
        : origFolder.replaceFirst(
            'lib/bloc/features/',
            'lib/bloc/features/$journeyNamespace/',
          );

    result.add({
      'folderPath': folder,
      'fileName': fileName,
      'textContent': entry.value,
    });
  }

  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// BLoC inner class (unchanged from v3)
// ─────────────────────────────────────────────────────────────────────────────
String _fieldNameFromMap(Map<String, dynamic> f) {
  final raw = (f['label'] ?? f['id'] ?? f['fieldId'] ?? 'field').toString().trim();
  final n = raw.replaceAll(RegExp(r'\s+'), '');
  return n.isEmpty ? 'field' : n[0].toLowerCase() + n.substring(1);
}
class RevochampBlocGenerator {
  RevochampBlocGenerator({
    required this.screenName,
    required this.modelName,
    required this.fieldJsonRaw,
    this.generateTests = true,
    this.generateBarrels = true,
  });

  final String screenName;
  final String modelName;
  final List<Map<String, dynamic>> fieldJsonRaw;
  final bool generateTests;
  final bool generateBarrels;

Map<String, String> generate() {
  final featureName = '$screenName$modelName';
  final baseName = screenName.toLowerCase();
  final snakeName = toSnakeCase(featureName);
  final resultData = '${featureName}ResultData';
  final featBase = 'lib/bloc/features/$baseName';

  // ----- Use raw JSON fields for the new generators -----
  final flatFields = flattenBlocFields(fieldJsonRaw); // List<Map<String,dynamic>>
  final fieldNames = flatFields
      .map((f) => _fieldNameFromMap(f)) // extract human-readable key
      .toList();

  // Legacy FieldSchema list (keep for older generators like EventGenerator)
  final fields = fieldJsonRaw
      .map((e) => FieldSchema.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  final files = <String, String>{};

  _addRuntime(files);
  _addNetworkLayer(files);
  files['lib/bloc/core/storage/local_storage_service.dart'] =
      ApiClientSources.localStorageService;
  _addCoreWidgets(files);
  files['lib/bloc/core/observer/bloc_observer.dart'] =
      const ObserverGenerator().generate();

  // ----- Updated generators (using flatFields / fieldNames) -----
  files['$featBase/presentation/validation/${snakeName}_validators.dart'] =
      ValidationGenerator(
        featureName: featureName,
        fields: flatFields, // now expects List<Map<String,dynamic>>
      ).generate();

  // EventGenerator may still use FieldSchema list (adapt if needed)
//   files['$featBase/presentation/events/${snakeName}_event.dart'] =
//       EventGenerator(
//         featureName: featureName,
// fieldNames: fieldNames, // corrected: List<String>
//         hasAsyncDropdown: fields.any((f) => f.isAsyncDropdown),
//       ).generate();

  // files['$featBase/presentation/state/${snakeName}_feature_state.dart'] =
  //     StateGenerator(
  //       featureName: featureName,
  //       flatFields: flatFields, // new parameter
  //       // hasSubmit: true,
  //       // resultEntityClass: '${featureName}Entity',
  //     ).generate();

  files['$featBase/presentation/mapper/${snakeName}_mapper.dart'] =
      MapperGenerator(
        featureName: featureName,
        fieldNames: fieldNames, // required List<String>
        entityClassName: '${featureName}Entity',
        stateClassName: '${featureName}FeatureState',
      ).generate();

  // BLoC generator (already fixed) uses configList = flatFields
  final blocFiles = BlocGenerator(
    featureName: featureName,
    configList: flatFields, // raw JSON list
    generateAsyncValueSeparately: false,
    // hasSubmit: true, // or false, depending on your form
  ).generateAll();

  blocFiles.forEach((key, value) {
    files['$featBase/presentation/bloc/$key'] = value;
  });

  files['$featBase/presentation/screens/${snakeName}_screen.dart'] =
      ScreenGenerator(
        featureName: featureName,
        flatFields: flatFields,
        hasSubmit: true,
      ).generate();
  //   if (generateBarrels) {
  //     final barrelGen = BarrelGenerator(
  //       featureName: featureName,
  //       fields: fields,
  //       baseName: baseName,
  //     );
  //     for (final entry in barrelGen.generateAll().entries) {
  //       files['$featBase/${entry.key}'] = entry.value;
  //     }
  //   }

  //   if (generateTests) {
  //     files['test/features/$baseName/${snakeName}_bloc_test.dart'] =
  //         TestGenerator(
  //           featureName: featureName,
  //           fields: fields,
  //           baseName: baseName,
  //         ).generate();
  //   }

    return files;

}

  // Map<String, String> generate() {
  //   final featureName = '$screenName$modelName';
  //   final baseName = screenName.toLowerCase();
  //   final snakeName = toSnakeCase(featureName);
  //   final resultData = '${featureName}ResultData';
  //   final featBase = 'lib/bloc/features/$baseName';

  //   final fields = fieldJsonRaw.map(FieldSchema.fromJson).toList();
  //   final files = <String, String>{};

  //   _addRuntime(files);
  //   _addNetworkLayer(files);
  //   files['lib/bloc/core/storage/local_storage_service.dart'] =
  //       ApiClientSources.localStorageService;
  //   _addCoreWidgets(files);
  //   files['lib/bloc/core/observer/bloc_observer.dart'] =
  //       const ObserverGenerator().generate();

  //   // for (final f in fields.where((f) => f.hasDropdownData)) {
  //   //   final entitySnake = toSnakeCase(f.entityClassName.replaceAll('Entity', ''));
  //   //   files['$featBase/domain/entities/${entitySnake}_entity.dart'] =
  //   //       EntityGenerator(className: f.entityClassName, sampleJson: f.dropdownData.first).generate();
  //   //   files['$featBase/data/model/${entitySnake}_model.dart'] =
  //   //       ModelGenerator(
  //   //         modelClassName: f.modelClassName,
  //   //         entityClassName: f.entityClassName,
  //   //         sampleJson: f.dropdownData.first,
  //   //         entityImportPath: '../../domain/entities/${entitySnake}_entity.dart',
  //   //       ).generate();
  //   // }

  //   // files['$featBase/domain/entities/${snakeName}_entity.dart'] =
  //   //     FeatureEntityGenerator(featureName: featureName, fields: fields).generate();
  //   // files['$featBase/domain/result/${snakeName}_result.dart'] =
  //   //     ResultModelGenerator(featureName: featureName).generate();
  //   // files['$featBase/domain/repositories/${snakeName}_repository.dart'] =
  //   //     DomainRepositoryGenerator(featureName: featureName, fields: fields).generate();
  //   // files['$featBase/domain/usecases/${snakeName}_usecases.dart'] =
  //   //     UseCaseGenerator(featureName: featureName, fields: fields).generate();
  //   // files['$featBase/data/datasources/${snakeName}_datasource.dart'] =
  //   //     DataSourceGenerator(featureName: featureName, fields: fields).generate();
  //   // files['$featBase/data/repositories/${snakeName}_repository_impl.dart'] =
  //   //     RepositoryImplGenerator(featureName: featureName, fields: fields).generate();
  //   final flatFields = flattenBlocFields(fields);

  //   files['$featBase/presentation/validation/${snakeName}_validators.dart'] =
  //       ValidationGenerator(
  //         featureName: featureName,
  //         fields: flatFields,
  //       ).generate();
  //   files['$featBase/presentation/events/${snakeName}_event.dart'] =
  //       EventGenerator(
  //         featureName: featureName,
  //         fields: fields,
  //         hasAsyncDropdown: fields.any((f) => f.isAsyncDropdown),
  //       ).generate();

  //   files['$featBase/presentation/state/${snakeName}_feature_state.dart'] =
  //       StateGenerator(
  //         featureName: featureName,
  //         fields: fields,
  //         resultDataClass: resultData,
  //         runtimeImportPrefix: '../../../../../core/runtime',
  //       ).generate();
  //   files['$featBase/presentation/mapper/${snakeName}_mapper.dart'] =
  //       MapperGenerator(
  //         featureName: featureName,
  //         fields: fields,
  //         entityClassName: '${featureName}Entity',
  //         stateName: '${featureName}FeatureState',
  //       ).generate();
  //   //     files['$featBase/presentation/bloc/${snakeName}_bloc.dart'] =
  //   //         BlocGenerator(
  //   //   featureName: featureName,
  //   //   configList: fields,
  //   //   generateAsyncValueSeparately: false,
  //   //   hasSubmit: false,
  //   // ).generate();
  //   final blocFiles = BlocGenerator(
  //     featureName: featureName,
  //     configList: fields,
  //     generateAsyncValueSeparately: false,
  //     hasSubmit: false,
  //   ).generateAll(); // Changed from .generate() to .generateAll()

  //   blocFiles.forEach((key, value) {
  //     files['$featBase/presentation/bloc/$key'] = value;
  //   });

  //   files['$featBase/presentation/screens/${snakeName}_screen.dart'] =
  //       ScreenGenerator(
  //         featureName: featureName,
  //         flatFields: flatFields,
  //         hasSubmit: true,
  //       ).generate();

  //   // Removed single injection.dart and main.dart to use GlobalDiGenerator

  //   if (generateBarrels) {
  //     final barrelGen = BarrelGenerator(
  //       featureName: featureName,
  //       fields: fields,
  //       baseName: baseName,
  //     );
  //     for (final entry in barrelGen.generateAll().entries) {
  //       files['$featBase/${entry.key}'] = entry.value;
  //     }
  //   }

  //   if (generateTests) {
  //     files['test/features/$baseName/${snakeName}_bloc_test.dart'] =
  //         TestGenerator(
  //           featureName: featureName,
  //           fields: fields,
  //           baseName: baseName,
  //         ).generate();
  //   }

  //   return files;
  // }



  void _addRuntime(Map<String, String> files) {
    const base = 'lib/bloc/core/runtime';
    files['$base/failure.dart'] = RuntimeSources.failure;
    files['$base/validation_error.dart'] = RuntimeSources.validationError;
    files['$base/validator.dart'] = RuntimeSources.validator;
    files['$base/reactive_value.dart'] = RuntimeSources.reactiveValue;
    files['$base/async_state.dart'] = RuntimeSources.asyncState;
    files['$base/base_reactive_bloc.dart'] = RuntimeSources.baseReactiveBloc;
  }

  void _addNetworkLayer(Map<String, String> files) {
    const base = 'lib/bloc/core/network';
    files['$base/app_exception.dart'] = ApiClientSources.appException;
    files['$base/api_response.dart'] = ApiClientSources.apiResponse;
    files['$base/dio_client.dart'] = ApiClientSources.dioClient;
    files['$base/failure_mapper.dart'] = ApiClientSources.failureMapper;
    files['$base/interceptors/auth_interceptor.dart'] =
        ApiClientSources.authInterceptor;
    files['$base/interceptors/logging_interceptor.dart'] =
        ApiClientSources.loggingInterceptor;
    files['$base/interceptors/error_interceptor.dart'] =
        ApiClientSources.errorInterceptor;
  }

  void _addCoreWidgets(Map<String, String> files) {
    const base = 'lib/bloc/core/widgets';
    files['$base/form_field_wrapper.dart'] =
        ReusableWidgetSources.formFieldWrapper;
    files['$base/app_text_field.dart'] = ReusableWidgetSources.appTextField;
    files['$base/app_dropdown_field.dart'] =
        ReusableWidgetSources.appDropdownField;
    files['$base/app_async_dropdown_field.dart'] =
        ReusableWidgetSources.appAsyncDropdownField;
    files['$base/app_checkbox_field.dart'] =
        ReusableWidgetSources.appCheckboxField;
    files['$base/app_date_picker_field.dart'] =
        ReusableWidgetSources.appDatePickerField;
    files['$base/app_radio_group_field.dart'] =
        ReusableWidgetSources.appRadioGroupField;
    files['$base/app_file_upload_field.dart'] =
        ReusableWidgetSources.appFileUploadField;
    files['$base/app_multi_select_field.dart'] =
        ReusableWidgetSources.appMultiSelectField;
    files['$base/app_form_button.dart'] = ReusableWidgetSources.appFormButton;
    files['$base/app_error_widget.dart'] = ReusableWidgetSources.appErrorWidget;
    files['$base/app_loading_widget.dart'] =
        ReusableWidgetSources.appLoadingWidget;
    files['$base/widgets.dart'] = ReusableWidgetSources.widgetsBarrel;
  }
}

// Local helper (previously came from `revochamp_bloc_generator.dart`).
String toSnakeCase(String text) {
  if (text.isEmpty) return text;
  final buffer = StringBuffer();
  buffer.write(text[0].toLowerCase());
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

