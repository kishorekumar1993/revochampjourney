// Shared GetX dropdown model naming — used by generator, controller, and view.

String getxCapitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String getxSingularize(String text) {
  if (text.endsWith('ies')) {
    return '${text.substring(0, text.length - 3)}y';
  }
  if (text.endsWith('s') && text.length > 1) {
    return text.substring(0, text.length - 1);
  }
  return text;
}

/// PascalCase model class with `Model` suffix, e.g. `CountryModel`.
String resolveGetxModelClassName(Map<String, dynamic> field) {
  final dropdowndata = field['dropdowndata'];
  if (dropdowndata is Map) {
    for (final entry in dropdowndata.entries) {
      final v = entry.value;
      if (v is List && v.isNotEmpty && v.first is Map) {
        final singular = getxSingularize(entry.key.toString());
        return '${getxCapitalize(singular)}Model';
      }
    }
  }
  final raw = (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'model')
      .toString()
      .trim();
  final n = raw.replaceAll(RegExp(r'\s+'), '');
  return '${getxCapitalize(n.isEmpty ? 'model' : n)}Model';
}

/// snake_case file base (without `_model.dart`), e.g. `country`.
String resolveGetxModelFileBase(Map<String, dynamic> field) {
  final dropdowndata = field['dropdowndata'];
  if (dropdowndata is Map) {
    for (final entry in dropdowndata.entries) {
      final v = entry.value;
      if (v is List && v.isNotEmpty && v.first is Map) {
        return getxSingularize(entry.key.toString()).toLowerCase();
      }
    }
  }
  final raw = (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'model')
      .toString()
      .trim();
  return raw.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
}

String getxModelImportPath(String fileBase) => '../model/${fileBase}_model.dart';

/// File base from class name, e.g. `CountryModel` → `country`.
String getxModelFileBaseFromClassName(String modelClassName) {
  final base = modelClassName.endsWith('Model')
      ? modelClassName.substring(0, modelClassName.length - 5)
      : modelClassName;
  final snake = base.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (m) => '_${m.group(0)!.toLowerCase()}',
  );
  return snake.startsWith('_') ? snake.substring(1) : snake;
}

/// Sample JSON row for [generateClass] from dropdown field config.
Map<String, dynamic> getxModelSampleJson(Map<String, dynamic> field) {
  final dropdownData = field['dropdowndata'];
  if (dropdownData is List && dropdownData.isNotEmpty) {
    final first = dropdownData.first;
    if (first is Map) return Map<String, dynamic>.from(first);
  }
  if (dropdownData is Map) {
    for (final entry in dropdownData.entries) {
      final v = entry.value;
      if (v is List && v.isNotEmpty) {
        final first = v.first;
        if (first is Map) return Map<String, dynamic>.from(first);
      }
    }
  }
  return <String, dynamic>{};
}

bool fieldNeedsGetxModel(Map<String, dynamic> field) {
  final type = (field['type'] ?? '').toString().toLowerCase();
  if (type != 'dropdown' && type != 'api_dropdown') return false;
  final useStatic = field['useStaticOptions'] == true;
  final hasApiUrl = field['dropdownApiUrl'] != null;
  final staticOpts =
      (field['options'] as List<dynamic>?) ??
      (field['staticOptions'] as List<dynamic>?);
  return (!useStatic && hasApiUrl) ||
      (!useStatic && (staticOpts == null || staticOpts.isEmpty));
}
