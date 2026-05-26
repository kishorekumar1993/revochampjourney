

// GetX generators
import 'package:revojourneytryone/filegegnerator/revochamp_bloc_generator.dart';
import 'package:revojourneytryone/getx/binding.dart';
import 'package:revojourneytryone/getx/controller.dart';
import 'package:revojourneytryone/getx/repository.dart';
import 'package:revojourneytryone/getx/viewscreen.dart';
import 'package:revojourneytryone/getx/getx_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 2. GetX Generator
// ─────────────────────────────────────────────────────────────────────────────

List<Map<String, String>> generateGetxFiles({
  required String screenName,
  required String journeyNamespace,
  required List<Map<String, dynamic>> rawFields,
}) {
  final result    = <Map<String, String>>[];
  final baseName  = screenName.toLowerCase();
  final className = '${screenName}Form';
  final fileName  = '${baseName}_form';
  final base      = 'lib/getx/features/$journeyNamespace/$baseName';

  final flatFields = flattenFields(rawFields);

  // ── Generate GetX files ──────────────────────────────────────────────────
  final binding    = generateBindingClass(
    className, 
    rawFields.isNotEmpty ? rawFields.first : <String, dynamic>{}, 
    fileName,
  );
  final controller = generatecontrollerClass(className, rawFields, fileName);
  final repository = generaterepositoryClass(className, rawFields, fileName);
  final view       = generateviewClass(className, rawFields, fileName);

  result.addAll([
    {'folderPath': '$base/bindings',     'fileName': '${fileName}_binding.dart',    'textContent': binding},
    {'folderPath': '$base/controllers',  'fileName': '${fileName}_controller.dart', 'textContent': controller},
    {'folderPath': '$base/repository',   'fileName': '${fileName}_repository.dart', 'textContent': repository},
    {'folderPath': '$base/presentation', 'fileName': '${fileName}_view.dart',       'textContent': view},
  ]);

  // ── GetX Model files (per dropdown field with data) ───────────────────────
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

    final rawLabel    = field['label'] as String? ?? 'Unnamed';
    final safeLabel   = rawLabel.trim().isEmpty ? 'Unnamed' : rawLabel;
    final modelName   = '${safeLabel.replaceAll(' ', '')}Model';
    final modelFile   = safeLabel.toLowerCase().replaceAll(' ', '_');
    final sampleData  = dataList.first is Map
        ? Map<String, dynamic>.from(dataList.first as Map)
        : <String, dynamic>{};

    final generated = generateClass(modelName, sampleData);

    result.add({
      'folderPath':  '$base/model',
      'fileName':    '${modelFile}_model.dart',
      'textContent': generated,
    });
  }

  return result;
}

