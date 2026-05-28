

// GetX generators
import 'package:revojourneytryone/codegenerator/filegegnerator/revochamp_bloc_generator.dart';
import 'package:revojourneytryone/codegenerator/getx/binding.dart';
import 'package:revojourneytryone/codegenerator/getx/controller.dart';
import 'package:revojourneytryone/codegenerator/getx/repository.dart';
import 'package:revojourneytryone/codegenerator/getx/viewscreen.dart';
import 'package:revojourneytryone/codegenerator/getx/getx_model.dart';
import 'package:revojourneytryone/codegenerator/getx/getx_model_naming.dart' hide resolveGetxModelClassName, resolveGetxModelFileBase;

// ─────────────────────────────────────────────────────────────────────────────
// 2. GetX Generator
// ─────────────────────────────────────────────────────────────────────────────

List<Map<String, String>> generateGetxFiles({
  required String screenName,
  required String journeyNamespace,
  required List<Map<String, dynamic>> rawFields,
  List<Map<String, dynamic>>? flatFields,
  Map<String, dynamic>? stepJson,
}) {
  final result    = <Map<String, String>>[];
  final baseName  = screenName.toLowerCase();
  final className = '${screenName}Form';
  final fileName  = '${baseName}_form';
  final base      = 'lib/getx/features/$journeyNamespace/$baseName';

  final effectiveFlatFields = flatFields ?? flattenFields(rawFields);

  // ── Generate GetX files ──────────────────────────────────────────────────
  final binding    = generateBindingClass(
    className, 
    rawFields.isNotEmpty ? rawFields.first : <String, dynamic>{}, 
    fileName,
  );
  final controller = generatecontrollerClass(
    className,
    rawFields,
    fileName,
    stepJson: stepJson,
  );
  final repository = generaterepositoryClass(className, rawFields, fileName);
  final view = generateviewClass(
    className,
    rawFields,
    fileName,
    stepJson: stepJson,
  );

  result.addAll([
    {'folderPath': '$base/bindings',     'fileName': '${fileName}_binding.dart',    'textContent': binding},
    {'folderPath': '$base/controllers',  'fileName': '${fileName}_controller.dart', 'textContent': controller},
    {'folderPath': '$base/repository',   'fileName': '${fileName}_repository.dart', 'textContent': repository},
    {'folderPath': '$base/presentation', 'fileName': '${fileName}_view.dart',       'textContent': view},
  ]);

  // ── GetX Model files (per dropdown field with data) ───────────────────────
  for (final field in effectiveFlatFields) {
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

    final modelName = resolveGetxModelClassName(field);
    final modelFile = resolveGetxModelFileBase(field);
    var sampleData = getxModelSampleJson(field);
    if (sampleData.isEmpty && dataList.first is Map) {
      sampleData = Map<String, dynamic>.from(dataList.first as Map);
    }

    final generated = generateClass(modelName, sampleData);

    result.add({
      'folderPath':  '$base/model',
      'fileName':    '${modelFile}_model.dart',
      'textContent': generated,
    });
  }

  return result;
}

