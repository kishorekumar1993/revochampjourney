// Riverpod generators
import 'package:revojourneytryone/filegegnerator/revochamp_bloc_generator.dart';
import 'package:revojourneytryone/common/common_datasource.dart';
import 'package:revojourneytryone/common/common_data_repositoryimpl.dart';
import 'package:revojourneytryone/common/common_domain_repository.dart';
import 'package:revojourneytryone/common/common_enitity_class.dart';
import 'package:revojourneytryone/common/common_locator.dart';
import 'package:revojourneytryone/common/common_temp_model.dart';
import 'package:revojourneytryone/common/common_usecase_generator.dart';
import 'package:revojourneytryone/common/commonapiservice.dart';

import 'package:revojourneytryone/riverpod/riverpod_presentation.dart';
import 'package:revojourneytryone/riverpod/riverpod_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 3. Riverpod Generator
// ─────────────────────────────────────────────────────────────────────────────

List<Map<String, String>> generateRiverpodFiles({
  required String screenName,
  required String journeyNamespace,
  required List<Map<String, dynamic>> rawFields,
    required Map<String, dynamic> journeyJson,   // new parameter

}) {
  final result   = <Map<String, String>>[];
  final baseName = screenName.toLowerCase();
  final className = '${screenName}Form';
  final fileName  = '${baseName}_form';
  final base      = 'lib/riverpod/features/$journeyNamespace/$baseName';

  final flatFields = flattenFields(rawFields);

  // ── Riverpod model + entity files (per dropdown field) ───────────────────
  for (final field in flatFields) {
    final dropdownData = field['dropdowndata'];
    if (dropdownData == null) continue;

    List<dynamic> dataList = [];
    if (dropdownData is List && dropdownData.isNotEmpty) {
      dataList = dropdownData;
    } else if (dropdownData is Map && dropdownData.isNotEmpty) {
      dataList = [dropdownData];
    } else {
      continue;
    }

    final rawLabel   = field['label'] as String? ?? 'Unnamed';
    final safeLabel  = rawLabel.trim().isEmpty ? 'Unnamed' : rawLabel;
    final modelName  = safeLabel.replaceAll(' ', '');
    final modelFile  = safeLabel.toLowerCase().replaceAll(' ', '_');
    final sampleData = dataList.first is Map
        ? Map<String, dynamic>.from(dataList.first as Map)
        : <String, dynamic>{};

    final modelContent  = riverpodModelGenerateClass(modelName, sampleData, modelFile);
    final entityContent = generateEquatableEntityClass('${modelName}Entity', sampleData, modelFile);

    result.addAll([
      {'folderPath': '$base/data/model',       'fileName': '${modelFile}_model.dart',  'textContent': modelContent},
      {'folderPath': '$base/domain/entity',    'fileName': '${modelFile}_entity.dart', 'textContent': entityContent},
    ]);
  }

  // ── Riverpod architecture files ───────────────────────────────────────────
  final domainRepo    = generateRepositoryInterface(className, rawFields, fileName);
  final repoImpl      = generateRepositoryImplInterface(className, rawFields, fileName);
  // final notifier      = generateNotifierImplInterface(className, rawFields, fileName);
  final apiService    = generateApiServiceInterface();
  final locator       = generateLocatorInterface(className, rawFields, fileName);
  final dataSource    = generateDataSourceInterface(className, rawFields, fileName);
  final provider      = generateProviderInterface(className, rawFields, fileName);
  final view          = generateriverpodviewClass(className, rawFields, fileName);
// ── Use‑case generator ─────────────────────────────────────────────
// ── Use‑case generator ─────────────────────────────────────────────
final repositoryClassName = '${className}Repository';
final useCaseGen = JourneyUseCaseGenerator(journeyJson, repositoryClassName: repositoryClassName);
final useCasesCode = useCaseGen.generate();

result.add({
  'folderPath':  '$base/domain/usecases',
  'fileName':    '${fileName}_usecases.dart',
  'textContent': useCasesCode,
});


  result.addAll([
    {'folderPath': '$base/domain/repository',        'fileName': '${fileName}_repository.dart',     'textContent': domainRepo},
    {'folderPath': '$base/data/repositoryimpl',      'fileName': '${fileName}_repositoryimpl.dart', 'textContent': repoImpl},
    // {'folderPath': '$base/presentation/controller',  'fileName': '${fileName}_notifier.dart',       'textContent': notifier},
    {'folderPath': '$base/data/dataSource',          'fileName': '${fileName}_data_source.dart',    'textContent': dataSource},
    {'folderPath': '$base/domain/locator',           'fileName': '${fileName}_locator.dart',        'textContent': locator},
    {'folderPath': '$base/presentation/provider',    'fileName': '${fileName}_provider.dart',       'textContent': provider},
    {'folderPath': '$base/presentation/view',        'fileName': '${fileName}_view.dart',           'textContent': view},
    // ── api_service.dart shared once at core level
    {'folderPath': 'lib/core/service',               'fileName': 'api_service.dart',                'textContent': apiService},
  ]);

  return result;
}


