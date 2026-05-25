// // lib/blocnew/revochamp_bloc_generator.dart
// // ╔══════════════════════════════════════════════════════════════════════════╗
// // ║  RevochampBlocGenerator  v4 — Unified Orchestrator                       ║
// // ║                                                                          ║
// // ║  Generates THREE complete architecture patterns per step:                ║
// // ║  1. BLoC      → lib/bloc/features/{journey}/{step}/                     ║
// // ║  2. GetX      → lib/getx/features/{journey}/{step}/                     ║
// // ║  3. Riverpod  → lib/riverpod/features/{journey}/{step}/                 ║
// // ║                                                                          ║
// // ║  Core files (runtime, network, widgets) generated ONCE (first step).    ║
// // ║  api_service.dart shared once at lib/core/service/                      ║
// // ╚══════════════════════════════════════════════════════════════════════════╝

// import 'dart:convert';
// import 'dart:js' as js;

// import 'package:flutter/material.dart';

// // BLoC generators
// import 'package:revojourneytryone/blocnew/api_client_generator.dart';
// import 'package:revojourneytryone/blocnew/barrel_generator.dart';
// import 'package:revojourneytryone/blocnew/bloc_generator.dart';
// import 'package:revojourneytryone/blocnew/di_generator.dart';
// import 'package:revojourneytryone/blocnew/entity_generator.dart';
// import 'package:revojourneytryone/blocnew/event_generator.dart';
// import 'package:revojourneytryone/blocnew/feature_entity_generator.dart';
// import 'package:revojourneytryone/blocnew/field_schema.dart';
// import 'package:revojourneytryone/blocnew/mapper_generator.dart';
// import 'package:revojourneytryone/blocnew/model_generator.dart';
// import 'package:revojourneytryone/blocnew/observer_generator.dart';
// import 'package:revojourneytryone/blocnew/repository_generator.dart';
// import 'package:revojourneytryone/blocnew/runtime_sources.dart';
// import 'package:revojourneytryone/blocnew/screen_generator.dart';
// import 'package:revojourneytryone/blocnew/state_generator.dart';
// import 'package:revojourneytryone/blocnew/test_generator.dart';
// import 'package:revojourneytryone/blocnew/validation_generator.dart';
// import 'package:revojourneytryone/blocnew/widget_generator.dart';

// // GetX generators
// import 'package:revojourneytryone/getx/binding.dart';
// import 'package:revojourneytryone/getx/controller.dart';
// import 'package:revojourneytryone/getx/repository.dart';
// import 'package:revojourneytryone/getx/viewscreen.dart';
// import 'package:revojourneytryone/getx/getx_temp.dart';

// // Riverpod generators
// import 'package:revojourneytryone/riverpod/riverpod_data_datasource.dart';
// import 'package:revojourneytryone/riverpod/riverpod_data_notifier.dart';
// import 'package:revojourneytryone/riverpod/riverpod_data_repositoryimpl.dart';
// import 'package:revojourneytryone/riverpod/riverpod_domain_repository.dart';
// import 'package:revojourneytryone/riverpod/riverpod_enitity_class.dart';
// import 'package:revojourneytryone/riverpod/riverpod_locator.dart';
// import 'package:revojourneytryone/riverpod/riverpod_presentation.dart';
// import 'package:revojourneytryone/riverpod/riverpod_provider.dart';
// import 'package:revojourneytryone/riverpod/riverpod_temp_model.dart';
// import 'package:revojourneytryone/riverpod/riverpodapiservice.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// // Architecture enum
// // ─────────────────────────────────────────────────────────────────────────────

// enum Architecture { bloc, getx, riverpod }

// // ─────────────────────────────────────────────────────────────────────────────
// // PUBLIC ENTRY POINT — called from dashboard_screen.dart
// // ─────────────────────────────────────────────────────────────────────────────

// void generateAndSaveAllFiles({
//   required dynamic journeyConfig,
//   Set<Architecture> architectures = const {
//     Architecture.bloc,
//     Architecture.getx,
//     Architecture.riverpod,
//   },
// }) {
//   if (journeyConfig.steps == null || journeyConfig.steps.isEmpty) {
//     debugPrint('No steps in journeyConfig');
//     return;
//   }

//   final journeyNamespace = _toJourneyNamespace(
//     journeyConfig.journeyName as String? ?? 'journey',
//   );

//   debugPrint('Journey namespace : $journeyNamespace');
//   debugPrint('Architectures     : ${architectures.map((a) => a.name).join(', ')}');

//   final List<Map<String, String>> allFiles = [];
//   bool coreFilesAdded  = false;
//   bool apiServiceAdded = false;

//   for (final step in journeyConfig.steps) {
//     if (step.fields == null || (step.fields as List).isEmpty) {
//       debugPrint("Skipping '${step.id}' — no fields");
//       continue;
//     }

//     // JSON round-trip: eliminates all JSArray/JSObject types
//     final fieldsJson = jsonEncode(
//       (step.fields as List).map((f) => f.toJson()).toList(),
//     );
//     final rawFields = (jsonDecode(fieldsJson) as List<dynamic>)
//         .map((e) => Map<String, dynamic>.from(e as Map))
//         .toList();

//     final cleanName  = (step.id as String).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
//     final screenName = cleanName.isNotEmpty
//         ? '${cleanName[0].toUpperCase()}${cleanName.substring(1)}'
//         : 'Step';

//     debugPrint('  Step: $screenName — ${rawFields.length} fields');

//     if (architectures.contains(Architecture.bloc)) {
//       allFiles.addAll(_generateBlocFiles(
//         screenName:       screenName,
//         journeyNamespace: journeyNamespace,
//         rawFields:        rawFields,
//         addCoreFiles:     !coreFilesAdded,
//       ));
//     }

//     if (architectures.contains(Architecture.getx)) {
//       allFiles.addAll(_generateGetxFiles(
//         screenName:       screenName,
//         journeyNamespace: journeyNamespace,
//         rawFields:        rawFields,
//       ));
//     }

//     if (architectures.contains(Architecture.riverpod)) {
//       allFiles.addAll(_generateRiverpodFiles(
//         screenName:       screenName,
//         journeyNamespace: journeyNamespace,
//         rawFields:        rawFields,
//         addApiService:    !apiServiceAdded,
//       ));
//       apiServiceAdded = true;
//     }

//     coreFilesAdded = true;
//   }

//   if (allFiles.isEmpty) {
//     debugPrint('No files generated');
//     return;
//   }

//   debugPrint('Total files: ${allFiles.length}');
//   js.context.callMethod('saveMultipleFilesToFolders', [jsonEncode(allFiles)]);
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // 1. BLoC — one step
// // ─────────────────────────────────────────────────────────────────────────────

// List<Map<String, String>> _generateBlocFiles({
//   required String screenName,
//   required String journeyNamespace,
//   required List<Map<String, dynamic>> rawFields,
//   required bool addCoreFiles,
// }) {
//   final result  = <Map<String, String>>[];
//   final files   = RevochampBlocGenerator(
//     screenName:      screenName,
//     modelName:       'Form',
//     fieldJsonRaw:    _deepClone(rawFields),
//     generateTests:   true,
//     generateBarrels: true,
//   ).generate();

//   for (final entry in files.entries) {
//     final parts      = entry.key.split('/');
//     final fileName   = parts.last;
//     final origFolder = parts.take(parts.length - 1).join('/');

//     final isCore = origFolder.startsWith('lib/bloc/core') ||
//         origFolder == 'lib/bloc' ||
//         origFolder.startsWith('test/');

//     if (isCore && !addCoreFiles) continue;

//     final folder = isCore
//         ? origFolder
//         : origFolder.replaceFirst(
//             'lib/bloc/features/',
//             'lib/bloc/features/$journeyNamespace/',
//           );

//     result.add({
//       'folderPath':  folder,
//       'fileName':    fileName,
//       'textContent': entry.value,
//     });
//   }
//   return result;
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // 2. GetX — one step
// // Output:
// //   lib/getx/features/{journey}/{step}/bindings/
// //   lib/getx/features/{journey}/{step}/controllers/
// //   lib/getx/features/{journey}/{step}/repository/
// //   lib/getx/features/{journey}/{step}/presentation/
// //   lib/getx/features/{journey}/{step}/model/   (per dropdown field)
// // ─────────────────────────────────────────────────────────────────────────────

// List<Map<String, String>> _generateGetxFiles({
//   required String screenName,
//   required String journeyNamespace,
//   required List<Map<String, dynamic>> rawFields,
// }) {
//   final result    = <Map<String, String>>[];
//   final baseName  = screenName.toLowerCase();
//   final className = '${screenName}Form';
//   final fileName  = '${baseName}_form';
//   final base      = 'lib/getx/features/$journeyNamespace/$baseName';

//   result.addAll([
//     {
//       'folderPath':  '$base/bindings',
//       'fileName':    '${fileName}_binding.dart',
//       'textContent': generatebindingClass(className, rawFields.first, fileName),
//     },
//     {
//       'folderPath':  '$base/controllers',
//       'fileName':    '${fileName}_controller.dart',
//       'textContent': generatecontrollerClass(className, rawFields, fileName),
//     },
//     {
//       'folderPath':  '$base/repository',
//       'fileName':    '${fileName}_repository.dart',
//       'textContent': generaterepositoryClass(className, rawFields, fileName),
//     },
//     {
//       'folderPath':  '$base/presentation',
//       'fileName':    '${fileName}_view.dart',
//       'textContent': generateviewClass(className, rawFields, fileName),
//     },
//   ]);

//   // Model per dropdown field
//   for (final field in rawFields) {
//     final sample = _extractDropdownSample(field);
//     if (sample == null) continue;
//     final label     = (field['label'] as String? ?? 'Unnamed').trim();
//     final safeLabel = label.isEmpty ? 'Unnamed' : label;
//     result.add({
//       'folderPath':  '$base/model',
//       'fileName':    '${safeLabel.toLowerCase().replaceAll(' ', '_')}_model.dart',
//       'textContent': generateClass(safeLabel.replaceAll(' ', ''), sample),
//     });
//   }

//   return result;
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // 3. Riverpod — one step
// // Output:
// //   lib/riverpod/features/{journey}/{step}/domain/entity/
// //   lib/riverpod/features/{journey}/{step}/domain/repository/
// //   lib/riverpod/features/{journey}/{step}/domain/locator/
// //   lib/riverpod/features/{journey}/{step}/data/model/
// //   lib/riverpod/features/{journey}/{step}/data/dataSource/
// //   lib/riverpod/features/{journey}/{step}/data/repositoryimpl/
// //   lib/riverpod/features/{journey}/{step}/presentation/controller/
// //   lib/riverpod/features/{journey}/{step}/presentation/provider/
// //   lib/riverpod/features/{journey}/{step}/presentation/view/
// //   lib/core/service/api_service.dart  (once)
// // ─────────────────────────────────────────────────────────────────────────────

// List<Map<String, String>> _generateRiverpodFiles({
//   required String screenName,
//   required String journeyNamespace,
//   required List<Map<String, dynamic>> rawFields,
//   required bool addApiService,
// }) {
//   final result    = <Map<String, String>>[];
//   final baseName  = screenName.toLowerCase();
//   final className = '${screenName}Form';
//   final fileName  = '${baseName}_form';
//   final base      = 'lib/riverpod/features/$journeyNamespace/$baseName';

//   // Model + Entity per dropdown field
//   for (final field in rawFields) {
//     final sample = _extractDropdownSample(field);
//     if (sample == null) continue;
//     final label     = (field['label'] as String? ?? 'Unnamed').trim();
//     final safeLabel = label.isEmpty ? 'Unnamed' : label;
//     final modelName = safeLabel.replaceAll(' ', '');
//     final modelFile = safeLabel.toLowerCase().replaceAll(' ', '_');
//     result.addAll([
//       {
//         'folderPath':  '$base/data/model',
//         'fileName':    '${modelFile}_model.dart',
//         'textContent': riverpodModelGenerateClass(modelName, sample, modelFile),
//       },
//       {
//         'folderPath':  '$base/domain/entity',
//         'fileName':    '${modelFile}_entity.dart',
//         'textContent': generateEntityClass('${modelName}Entity', sample, modelFile),
//       },
//     ]);
//   }

//   result.addAll([
//     {
//       'folderPath':  '$base/domain/repository',
//       'fileName':    '${fileName}_repository.dart',
//       'textContent': generateRepositoryInterface(className, rawFields, fileName),
//     },
//     {
//       'folderPath':  '$base/data/repositoryimpl',
//       'fileName':    '${fileName}_repositoryimpl.dart',
//       'textContent': generateRepositoryImplInterface(className, rawFields, fileName),
//     },
//     {
//       'folderPath':  '$base/presentation/controller',
//       'fileName':    '${fileName}_notifier.dart',
//       'textContent': generateNotifierImplInterface(className, rawFields, fileName),
//     },
//     {
//       'folderPath':  '$base/data/dataSource',
//       'fileName':    '${fileName}_data_source.dart',
//       'textContent': generateDataSourceInterface(className, rawFields, fileName),
//     },
//     {
//       'folderPath':  '$base/domain/locator',
//       'fileName':    '${fileName}_locator.dart',
//       'textContent': generateLocaltorInterface(className, rawFields, fileName),
//     },
//     {
//       'folderPath':  '$base/presentation/provider',
//       'fileName':    '${fileName}_provider.dart',
//       'textContent': generateProviderInterface(className, rawFields, fileName),
//     },
//     {
//       'folderPath':  '$base/presentation/view',
//       'fileName':    '${fileName}_view.dart',
//       'textContent': generateriverpodviewClass(className, rawFields, fileName),
//     },
//   ]);

//   if (addApiService) {
//     result.add({
//       'folderPath':  'lib/core/service',
//       'fileName':    'api_service.dart',
//       'textContent': generateapiserviceInterface(),
//     });
//   }

//   return result;
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // BLoC inner class
// // ─────────────────────────────────────────────────────────────────────────────

// class RevochampBlocGenerator {
//   RevochampBlocGenerator({
//     required this.screenName,
//     required this.modelName,
//     required this.fieldJsonRaw,
//     this.generateTests   = true,
//     this.generateBarrels = true,
//   });

//   final String                     screenName;
//   final String                     modelName;
//   final List<Map<String, dynamic>> fieldJsonRaw;
//   final bool                       generateTests;
//   final bool                       generateBarrels;

//   Map<String, String> generate() {
//     final featureName = '$screenName$modelName';
//     final baseName    = screenName.toLowerCase();
//     final snakeName   = toSnakeCase(featureName);
//     final resultData  = '${featureName}ResultData';
//     final featBase    = 'lib/bloc/features/$baseName';
//     final fields      = fieldJsonRaw.map(FieldSchema.fromJson).toList();
//     final files       = <String, String>{};

//     _addRuntime(files);
//     _addNetworkLayer(files);
//     files['lib/bloc/core/storage/local_storage_service.dart'] =
//         ApiClientSources.localStorageService;
//     _addCoreWidgets(files);
//     files['lib/bloc/core/observer/bloc_observer.dart'] =
//         const ObserverGenerator().generate();

//     for (final f in fields.where((f) => f.hasDropdownData)) {
//       final entitySnake = toSnakeCase(f.entityClassName.replaceAll('Entity', ''));
//       files['$featBase/domain/entities/${entitySnake}_entity.dart'] =
//           EntityGenerator(className: f.entityClassName, sampleJson: f.dropdownData.first).generate();
//       files['$featBase/data/model/${entitySnake}_model.dart'] =
//           ModelGenerator(
//             modelClassName:   f.modelClassName,
//             entityClassName:  f.entityClassName,
//             sampleJson:       f.dropdownData.first,
//             entityImportPath: '../../domain/entities/${entitySnake}_entity.dart',
//           ).generate();
//     }

//     files['$featBase/domain/entities/${snakeName}_entity.dart'] =
//         FeatureEntityGenerator(featureName: featureName, fields: fields).generate();
//     files['$featBase/domain/result/${snakeName}_result.dart'] =
//         ResultModelGenerator(featureName: featureName).generate();
//     files['$featBase/domain/repositories/${snakeName}_repository.dart'] =
//         DomainRepositoryGenerator(featureName: featureName, fields: fields).generate();
//     files['$featBase/domain/usecases/${snakeName}_usecases.dart'] =
//         UseCaseGenerator(featureName: featureName, fields: fields).generate();
//     files['$featBase/data/datasources/${snakeName}_datasource.dart'] =
//         DataSourceGenerator(featureName: featureName, fields: fields).generate();
//     files['$featBase/data/repositories/${snakeName}_repository_impl.dart'] =
//         RepositoryImplGenerator(featureName: featureName, fields: fields).generate();
//     files['$featBase/presentation/validation/${snakeName}_validators.dart'] =
//         ValidationGenerator(featureName: featureName, fields: fields).generate();
//     files['$featBase/presentation/events/${snakeName}_event.dart'] =
//         EventGenerator(featureName: featureName, fields: fields,
//             hasAsyncDropdown: fields.any((f) => f.isAsyncDropdown)).generate();
//     files['$featBase/presentation/state/${snakeName}_feature_state.dart'] =
//         StateGenerator(featureName: featureName, fields: fields,
//             resultDataClass: resultData, runtimeImportPrefix: '../../../../core/runtime').generate();
//     files['$featBase/presentation/mapper/${snakeName}_mapper.dart'] =
//         MapperGenerator(featureName: featureName, fields: fields,
//             entityClassName: '${featureName}Entity', stateName: '${featureName}FeatureState').generate();
//     files['$featBase/presentation/bloc/${snakeName}_bloc.dart'] =
//         BlocGenerator(featureName: featureName, fields: fields, 
//             generateAsyncValueSeparately: fields.any((f) => f.isAsyncDropdown
//             )).generate();
//     files['$featBase/presentation/screens/${snakeName}_screen.dart'] =
//         ScreenGenerator(featureName: featureName, fields: fields).generate();

//     final diGen = DiGenerator(featureName: featureName, fields: fields, baseName: baseName);
//     files['lib/bloc/injection.dart'] = diGen.generateInjection();
//     files['lib/bloc/main.dart']      = diGen.generateMain();

//     if (generateBarrels) {
//       final barrelGen = BarrelGenerator(featureName: featureName, fields: fields, baseName: baseName);
//       for (final entry in barrelGen.generateAll().entries) {
//         files['$featBase/${entry.key}'] = entry.value;
//       }
//     }

//     if (generateTests) {
//       files['test/features/$baseName/${snakeName}_bloc_test.dart'] =
//           TestGenerator(featureName: featureName, fields: fields, baseName: baseName).generate();
//     }

//     return files;
//   }

//   void _addRuntime(Map<String, String> files) {
//     const base = 'lib/bloc/core/runtime';
//     files['$base/failure.dart']            = RuntimeSources.failure;
//     files['$base/validation_error.dart']   = RuntimeSources.validationError;
//     files['$base/validator.dart']          = RuntimeSources.validator;
//     files['$base/reactive_value.dart']     = RuntimeSources.reactiveValue;
//     files['$base/async_state.dart']        = RuntimeSources.asyncState;
//     files['$base/base_reactive_bloc.dart'] = RuntimeSources.baseReactiveBloc;
//   }

//   void _addNetworkLayer(Map<String, String> files) {
//     const base = 'lib/bloc/core/network';
//     files['$base/app_exception.dart']                    = ApiClientSources.appException;
//     files['$base/api_response.dart']                     = ApiClientSources.apiResponse;
//     files['$base/dio_client.dart']                       = ApiClientSources.dioClient;
//     files['$base/failure_mapper.dart']                   = ApiClientSources.failureMapper;
//     files['$base/interceptors/auth_interceptor.dart']    = ApiClientSources.authInterceptor;
//     files['$base/interceptors/logging_interceptor.dart'] = ApiClientSources.loggingInterceptor;
//     files['$base/interceptors/error_interceptor.dart']   = ApiClientSources.errorInterceptor;
//   }

//   void _addCoreWidgets(Map<String, String> files) {
//     const base = 'lib/bloc/core/widgets';
//     files['$base/form_field_wrapper.dart']       = ReusableWidgetSources.formFieldWrapper;
//     files['$base/app_text_field.dart']           = ReusableWidgetSources.appTextField;
//     files['$base/app_dropdown_field.dart']       = ReusableWidgetSources.appDropdownField;
//     files['$base/app_async_dropdown_field.dart'] = ReusableWidgetSources.appAsyncDropdownField;
//     files['$base/app_checkbox_field.dart']       = ReusableWidgetSources.appCheckboxField;
//     files['$base/app_form_button.dart']          = ReusableWidgetSources.appFormButton;
//     files['$base/app_error_widget.dart']         = ReusableWidgetSources.appErrorWidget;
//     files['$base/app_loading_widget.dart']       = ReusableWidgetSources.appLoadingWidget;
//     files['$base/widgets.dart']                  = ReusableWidgetSources.widgetsBarrel;
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Legacy wrapper — backward compatible
// // ─────────────────────────────────────────────────────────────────────────────

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
//     fieldJsonRaw:    _deepClone(fieldJsonRaw),
//     generateTests:   generateTests,
//     generateBarrels: generateBarrels,
//   ).generate();

//   return files.entries.map((e) {
//     final parts = e.key.split('/');
//     return {
//       'folderPath':  parts.take(parts.length - 1).join('/'),
//       'fileName':    parts.last,
//       'textContent': e.value,
//     };
//   }).toList();
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Private helpers
// // ─────────────────────────────────────────────────────────────────────────────

// List<Map<String, dynamic>> _deepClone(List<Map<String, dynamic>> input) {
//   return (jsonDecode(jsonEncode(input)) as List<dynamic>)
//       .map((e) => Map<String, dynamic>.from(e as Map))
//       .toList();
// }

// Map<String, dynamic>? _extractDropdownSample(Map<String, dynamic> field) {
//   final raw = field['dropdowndata'] ?? field['dropdownData'];
//   if (raw == null) return null;
//   if (raw is List && raw.isNotEmpty && raw.first is Map)
//     return Map<String, dynamic>.from(raw.first as Map);
//   if (raw is Map && raw.isNotEmpty) {
//     final listKey = (field['dropdownListKey'] ??
//             field['dropdownApiResponseKey'] ??
//             field['responseListKey'] ??
//             '')
//         .toString();
//     final candidates = [
//       _readPath(raw, listKey),
//       raw[listKey],
//       raw['data'],
//       raw['results'],
//       raw['items'],
//       raw['users'],
//       raw['options'],
//     ];
//     for (final candidate in candidates) {
//       if (candidate is List && candidate.isNotEmpty && candidate.first is Map) {
//         return Map<String, dynamic>.from(candidate.first as Map);
//       }
//     }
//     return Map<String, dynamic>.from(raw);
//   }
//   return null;
// }

// dynamic _readPath(Map<dynamic, dynamic> source, String path) {
//   if (path.trim().isEmpty) return null;
//   dynamic cursor = source;
//   for (final part in path.split('.')) {
//     if (cursor is Map) {
//       cursor = cursor[part];
//     } else {
//       return null;
//     }
//   }
//   return cursor;
// }
//  // ── Helper functions ─────────────────────────────────────────────────────
//   String toSnakeCase(String text) {
//     if (text.isEmpty) return text;
//     final buffer = StringBuffer();
//     buffer.write(text[0].toLowerCase());
//     for (int i = 1; i < text.length; i++) {
//       final char = text[i];
//       if (char.toUpperCase() == char && char != char.toLowerCase()) {
//         // It's an uppercase letter
//         buffer.write('_${char.toLowerCase()}');
//       } else {
//         buffer.write(char);
//       }
//     }
//     return buffer.toString();
//   }


// String _toJourneyNamespace(String name) {
//   final cleaned = name
//       .replaceAll(RegExp(r'\bjourney\b', caseSensitive: false), '')
//       .replaceAll(RegExp(r'[^a-zA-Z0-9\s_\-]'), '')
//       .trim();
//   if (cleaned.isEmpty) return 'journey';
//   final parts = cleaned.split(RegExp(r'[\s_\-]+')).where((p) => p.isNotEmpty).toList();
//   if (parts.isEmpty) return 'journey';
//   return parts.first.toLowerCase() +
//       parts.skip(1).map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}').join();
// }


      // ElevatedButton(
      //             onPressed: !hasSelection
      //                 ? null
      //                 : () {
      //                     Navigator.pop(dialogContext);
      //                     final architectures = <Architecture>{
      //                       if (blocSelected) Architecture.bloc,
      //                       if (getxSelected) Architecture.getx,
      //                       if (riverpodSelected) Architecture.riverpod,
      //                     };

      //                     try {
      //                       generateAndSaveAllFiles(
      //                         journeyConfig: journeyConfig,
      //                         architectures: architectures,
      //                       );

      //                       ScaffoldMessenger.of(context).showSnackBar(
      //                         const SnackBar(
      //                           content: Text("✅ Code generation started — select your project folder!"),
      //                           backgroundColor: Colors.green,
      //                           duration: Duration(seconds: 4),
      //                         ),
      //                       );
      //                     } catch (e, stack) {
      //                       debugPrint("Generation error: $e\n$stack");
      //                       ScaffoldMessenger.of(context).showSnackBar(
      //                         SnackBar(
      //                           content: Text("Generation error: $e"),
      //                           backgroundColor: Colors.redAccent,
      //                         ),
      //                       );
      //                     }
      //                   },
      //             style: ElevatedButton.styleFrom(
      //               backgroundColor: RevoTheme.primary,
      //             ),
      //             child: const Text("Generate"),
      //           ),
          
