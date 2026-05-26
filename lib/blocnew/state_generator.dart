// class StateGenerator {
//   StateGenerator({
//     required this.featureName,
//     required this.flatFields,
//   });

//   final String featureName;
//   final List<Map<String, dynamic>> flatFields;

//   // --------------------------------------------------------------------------
//   // Core getters with correct deduplication
//   // --------------------------------------------------------------------------

//   List<Map<String, dynamic>> get _uniqueAsyncFields {
//     final seen = <String>{};
//     return flatFields
//         .where(_isApiDropdown)
//         .where((f) {
//           final key = _normalisedKey(f);
//           if (seen.contains(key)) return false;
//           seen.add(key);
//           return true;
//         })
//         .toList();
//   }

//   List<Map<String, dynamic>> get _uniqueFormFields {
//     final seen = <String>{};
//     return flatFields
//         .where(_isFormField)
//         .where((f) => !_isApiDropdown(f))
//         .where((f) {
//           final key = _normalisedKey(f);
//           if (seen.contains(key)) return false;
//           seen.add(key);
//           return true;
//         })
//         .toList();
//   }

//   // --------------------------------------------------------------------------
//   // Generation
//   // --------------------------------------------------------------------------

//   String generate() {
//     final stateName = '${featureName}State';
//     final buf = StringBuffer();

//     buf.writeln("import 'package:equatable/equatable.dart';");
//     buf.writeln("import '../bloc/async_value.dart';");

//     // Entity imports for async dropdowns
//     final importedEntities = <String>{};
//     for (final f in _uniqueAsyncFields) {
//       final entityClass = _resolveEntityClassName(f);
//       if (importedEntities.add(entityClass)) {
//         final fileName = _classNameToFileName(entityClass);
//         buf.writeln("import '../../domain/entity/$fileName';");
//       }
//     }
//     buf.writeln();

//     buf.writeln('class $stateName extends Equatable {');

//     // Async fields – conditional based on "returnsList"
//     for (final f in _uniqueAsyncFields) {
//       final fieldKey = _safeFieldName(f);
//       final entityClass = _resolveEntityClassName(f);
//       final returnsList = f['returnsList'] == true;
//       if (returnsList) {
//         buf.writeln('  final AsyncValue<List<$entityClass>> $fieldKey;');
//       } else {
//         buf.writeln('  final AsyncValue<$entityClass> $fieldKey;');
//       }
//     }
//     buf.writeln('  final Map<String, dynamic> formValues;');
//     buf.writeln();

//     // Constructor
//     buf.writeln('  const $stateName({');
//     for (final f in _uniqueAsyncFields) {
//       buf.writeln('    required this.${_safeFieldName(f)},');
//     }
//     buf.writeln('    required this.formValues,');
//     buf.writeln('  });');
//     buf.writeln();

//     // Factory initial
//     buf.writeln('  factory $stateName.initial() {');
//     buf.writeln('    return $stateName(');
//     for (final f in _uniqueAsyncFields) {
//       buf.writeln('      ${_safeFieldName(f)}: const AsyncValue.idle(),');
//     }
//     buf.writeln('      formValues: {');
//     final defaultValues = <String, String>{};
//     for (final f in _uniqueFormFields) {
//       final key = _safeFieldName(f);
//       if (defaultValues.containsKey(key)) continue;
//       final type = (f['type'] ?? '').toString().toLowerCase();
//       defaultValues[key] = _resolveDefault(f, type);
//     }
//     for (final entry in defaultValues.entries) {
//       buf.writeln("        '${entry.key}': ${entry.value},");
//     }
//     buf.writeln('      },');
//     buf.writeln('    );');
//     buf.writeln('  }');
//     buf.writeln();

//     // copyWith – conditional type
//     buf.writeln('  $stateName copyWith({');
//     for (final f in _uniqueAsyncFields) {
//       final fieldKey = _safeFieldName(f);
//       final entityClass = _resolveEntityClassName(f);
//       final returnsList = f['returnsList'] == true;
//       if (returnsList) {
//         buf.writeln('    AsyncValue<List<$entityClass>>? $fieldKey,');
//       } else {
//         buf.writeln('    AsyncValue<$entityClass>? $fieldKey,');
//       }
//     }
//     buf.writeln('    Map<String, dynamic>? formValues,');
//     buf.writeln('  }) {');
//     buf.writeln('    return $stateName(');
//     for (final f in _uniqueAsyncFields) {
//       final fieldKey = _safeFieldName(f);
//       buf.writeln('      $fieldKey: $fieldKey ?? this.$fieldKey,');
//     }
//     buf.writeln('      formValues: formValues ?? this.formValues,');
//     buf.writeln('    );');
//     buf.writeln('  }');
//     buf.writeln();

//     // copyWithValue (unchanged)
//     buf.writeln('  $stateName copyWithValue(String key, dynamic value) {');
//     buf.writeln(
//         '    final updated = Map<String, dynamic>.from(formValues)..[key] = value;');
//     buf.writeln('    return copyWith(formValues: updated);');
//     buf.writeln('  }');
//     buf.writeln();

//     // props
//     buf.writeln('  @override');
//     buf.writeln('  List<Object?> get props => [');
//     for (final f in _uniqueAsyncFields) {
//       buf.writeln('    ${_safeFieldName(f)},');
//     }
//     buf.writeln('    formValues,');
//     buf.writeln('  ];');
//     buf.writeln('}');

//     return buf.toString();
//   }

//   // --------------------------------------------------------------------------
//   // Helpers (unchanged from original)
//   // --------------------------------------------------------------------------

//   String _normalisedKey(Map<String, dynamic> field) {
//     final raw = (field['label'] ?? field['id'] ?? field['fieldId'] ?? '')
//         .toString()
//         .trim();
//     final cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
//     return cleaned.isEmpty ? 'field' : cleaned;
//   }

//   String _safeFieldName(Map<String, dynamic> field) {
//     final raw = (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'field')
//         .toString()
//         .trim();
//     final withoutSpaces = raw.replaceAll(RegExp(r'\s+'), '');
//     if (withoutSpaces.isEmpty) return 'field';
//     return withoutSpaces[0].toLowerCase() + withoutSpaces.substring(1);
//   }

//   bool _isFormField(Map<String, dynamic> field) {
//     final type = (field['type'] ?? '').toString().toLowerCase();
//     const skipTypes = {'card', 'group', 'section', 'step', 'tab', 'container'};
//     return !skipTypes.contains(type);
//   }

//   bool _isApiDropdown(Map<String, dynamic> field) {
//     final type = (field['type'] ?? '').toString().toLowerCase();
//     if (type != 'dropdown' && type != 'api_dropdown') return false;
//     final useStatic = field['useStaticOptions'] == true;
//     final hasApiUrl = field['dropdownApiUrl'] != null;
//     return !useStatic && hasApiUrl;
//   }

//   String _resolveEntityClassName(Map<String, dynamic> field) {
//     final explicit = field['entityName'] ?? field['referenceEntity'];
//     if (explicit != null && explicit.toString().isNotEmpty) {
//       final base = explicit.toString().trim();
//       return base.endsWith('Entity') ? base : '${base}Entity';
//     }

//     String rawName = (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'item')
//         .toString()
//         .trim();
//     if (rawName.isEmpty) rawName = 'item';

//     final pascal = rawName
//         .split(RegExp(r'[\s_-]+'))
//         .where((w) => w.isNotEmpty)
//         .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
//         .join();

//     return '${pascal}Entity';
//   }

//   String _classNameToFileName(String className) {
//     if (className.isEmpty) return 'entity.dart';
//     final buffer = StringBuffer();
//     buffer.write(className[0].toLowerCase());
//     for (int i = 1; i < className.length; i++) {
//       final char = className[i];
//       if (_isUpperCase(char)) {
//         buffer.write('_${char.toLowerCase()}');
//       } else {
//         buffer.write(char);
//       }
//     }
//     var result = buffer.toString();
//     if (result.endsWith('_entity')) {
//       result = result.substring(0, result.length - 7) + '_entity.dart';
//     } else {
//       result = '$result.dart';
//     }
//     return result;
//   }

//   bool _isUpperCase(String char) => RegExp(r'[A-Z]').hasMatch(char);
//   String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
//   String _singularize(String text) {
//     if (text.endsWith('ies')) return '${text.substring(0, text.length - 3)}y';
//     if (text.endsWith('s') && text.length > 1) return text.substring(0, text.length - 1);
//     return text;
//   }

//   String _resolveDefault(Map<String, dynamic> field, String type) {
//     final defaultVal = field['defaultValue'];
//     if (defaultVal != null) {
//       if (defaultVal is String) return "'${_escape(defaultVal)}'";
//       return defaultVal.toString();
//     }
//     switch (type) {
//       case 'text':
//       case 'textfield':
//       case 'textarea':
//       case 'email':
//       case 'password':
//       case 'phone':
//       case 'otp':
//       case 'formula':
//         return "''";
//       case 'number':
//       case 'integer':
//       case 'int':
//         return '0';
//       case 'decimal':
//       case 'double':
//       case 'float':
//         return '0.0';
//       case 'checkbox':
//       case 'switch':
//         return 'false';
//       case 'multiselect':
//       case 'multi_select':
//         return '<String>[]';
//       default:
//         return 'null';
//     }
//   }

//   String _escape(String s) => s.replaceAll("'", "\\'");
// }

// // class StateGenerator {
// //   StateGenerator({
// //     required this.featureName,
// //     required this.flatFields,
// //   });

// //   final String featureName;
// //   final List<Map<String, dynamic>> flatFields;

// //   // --------------------------------------------------------------------------
// //   // Core getters with correct deduplication
// //   // --------------------------------------------------------------------------

// //   /// Async dropdown fields (excluded from formValues)
// //   List<Map<String, dynamic>> get _uniqueAsyncFields {
// //     final seen = <String>{};
// //     return flatFields
// //         .where(_isApiDropdown)
// //         .where((f) {
// //           final key = _normalisedKey(f);
// //           if (seen.contains(key)) return false;
// //           seen.add(key);
// //           return true;
// //         })
// //         .toList();
// //   }

// //   /// Form fields (non‑async, non‑container) – these go into formValues
// //   List<Map<String, dynamic>> get _uniqueFormFields {
// //     final seen = <String>{};
// //     return flatFields
// //         .where(_isFormField)
// //         .where((f) => !_isApiDropdown(f)) // async dropdowns are NOT form fields
// //         .where((f) {
// //           final key = _normalisedKey(f);
// //           if (seen.contains(key)) return false;
// //           seen.add(key);
// //           return true;
// //         })
// //         .toList();
// //   }

// //   // --------------------------------------------------------------------------
// //   // Generation
// //   // --------------------------------------------------------------------------

// //   String generate() {
// //     final stateName = '${featureName}State';
// //     final buf = StringBuffer();

// //     buf.writeln("import 'package:equatable/equatable.dart';");
// //     buf.writeln("import '../bloc/async_value.dart';");

// //     // Entity imports for async dropdowns
// //     final importedEntities = <String>{};
// //     for (final f in _uniqueAsyncFields) {
// //       final entityClass = _resolveEntityClassName(f);
// //       if (importedEntities.add(entityClass)) {
// //         final fileName = _classNameToFileName(entityClass);
// //         buf.writeln("import '../../domain/entity/$fileName';");
// //       }
// //     }
// //     buf.writeln();

// //     buf.writeln('class $stateName extends Equatable {');

// //     // Async fields
// //     for (final f in _uniqueAsyncFields) {
// //       final fieldKey = _safeFieldName(f);
// //       final entityClass = _resolveEntityClassName(f);
// //       buf.writeln('  final AsyncValue<List<$entityClass>> $fieldKey;');
// //     }
// //     buf.writeln('  final Map<String, dynamic> formValues;');
// //     buf.writeln();

// //     // Constructor
// //     buf.writeln('  const $stateName({');
// //     for (final f in _uniqueAsyncFields) {
// //       buf.writeln('    required this.${_safeFieldName(f)},');
// //     }
// //     buf.writeln('    required this.formValues,');
// //     buf.writeln('  });');
// //     buf.writeln();

// //     // Factory initial
// //     buf.writeln('  factory $stateName.initial() {');
// //     buf.writeln('    return $stateName(');
// //     for (final f in _uniqueAsyncFields) {
// //       buf.writeln('      ${_safeFieldName(f)}: const AsyncValue.idle(),');
// //     }
// //     buf.writeln('      formValues: {');
// //     final defaultValues = <String, String>{};
// //     for (final f in _uniqueFormFields) {
// //       final key = _safeFieldName(f);
// //       if (defaultValues.containsKey(key)) continue;
// //       final type = (f['type'] ?? '').toString().toLowerCase();
// //       defaultValues[key] = _resolveDefault(f, type);
// //     }
// //     for (final entry in defaultValues.entries) {
// //       buf.writeln("        '${entry.key}': ${entry.value},");
// //     }
// //     buf.writeln('      },');
// //     buf.writeln('    );');
// //     buf.writeln('  }');
// //     buf.writeln();

// //     // copyWith
// //     buf.writeln('  $stateName copyWith({');
// //     for (final f in _uniqueAsyncFields) {
// //       final fieldKey = _safeFieldName(f);
// //       final entityClass = _resolveEntityClassName(f);
// //       buf.writeln('    AsyncValue<List<$entityClass>>? $fieldKey,');
// //     }
// //     buf.writeln('    Map<String, dynamic>? formValues,');
// //     buf.writeln('  }) {');
// //     buf.writeln('    return $stateName(');
// //     for (final f in _uniqueAsyncFields) {
// //       final fieldKey = _safeFieldName(f);
// //       buf.writeln('      $fieldKey: $fieldKey ?? this.$fieldKey,');
// //     }
// //     buf.writeln('      formValues: formValues ?? this.formValues,');
// //     buf.writeln('    );');
// //     buf.writeln('  }');
// //     buf.writeln();

// //     // copyWithValue
// //     buf.writeln('  $stateName copyWithValue(String key, dynamic value) {');
// //     buf.writeln(
// //         '    final updated = Map<String, dynamic>.from(formValues)..[key] = value;');
// //     buf.writeln('    return copyWith(formValues: updated);');
// //     buf.writeln('  }');
// //     buf.writeln();

// //     // props
// //     buf.writeln('  @override');
// //     buf.writeln('  List<Object?> get props => [');
// //     for (final f in _uniqueAsyncFields) {
// //       buf.writeln('    ${_safeFieldName(f)},');
// //     }
// //     buf.writeln('    formValues,');
// //     buf.writeln('  ];');
// //     buf.writeln('}');

// //     return buf.toString();
// //   }

// //   // --------------------------------------------------------------------------
// //   // Helpers (improved)
// //   // --------------------------------------------------------------------------

// //   /// Normalised key for deduplication (lowercase, no spaces or special chars)
// //   String _normalisedKey(Map<String, dynamic> field) {
// //     final raw = (field['label'] ?? field['id'] ?? field['fieldId'] ?? '')
// //         .toString()
// //         .trim();
// //     final cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
// //     return cleaned.isEmpty ? 'field' : cleaned;
// //   }

// //   /// Safe field name for Dart code (camelCase, no spaces)
// //   String _safeFieldName(Map<String, dynamic> field) {
// //     final raw = (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'field')
// //         .toString()
// //         .trim();
// //     final withoutSpaces = raw.replaceAll(RegExp(r'\s+'), '');
// //     if (withoutSpaces.isEmpty) return 'field';
// //     return withoutSpaces[0].toLowerCase() + withoutSpaces.substring(1);
// //   }

// //   bool _isFormField(Map<String, dynamic> field) {
// //     final type = (field['type'] ?? '').toString().toLowerCase();
// //     const skipTypes = {'card', 'group', 'section', 'step', 'tab', 'container'};
// //     return !skipTypes.contains(type);
// //   }

// //   bool _isApiDropdown(Map<String, dynamic> field) {
// //     final type = (field['type'] ?? '').toString().toLowerCase();
// //     if (type != 'dropdown' && type != 'api_dropdown') return false;
// //     final useStatic = field['useStaticOptions'] == true;
// //     final hasApiUrl = field['dropdownApiUrl'] != null;
// //     return !useStatic && hasApiUrl;
// //   }

// //   /// Generate entity class name from field label.
// //   /// Example: "Post Title" → "PostTitleEntity"
// //   String _resolveEntityClassName(Map<String, dynamic> field) {
// //     // First try explicit entityName / referenceEntity
// //     final explicit = field['entityName'] ?? field['referenceEntity'];
// //     if (explicit != null && explicit.toString().isNotEmpty) {
// //       final base = explicit.toString().trim();
// //       return base.endsWith('Entity') ? base : '${base}Entity';
// //     }

// //     // Derive from label or id
// //     String rawName = (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'item')
// //         .toString()
// //         .trim();
// //     if (rawName.isEmpty) rawName = 'item';

// //     // Convert to PascalCase (e.g., "post title" → "PostTitle")
// //     final pascal = rawName
// //         .split(RegExp(r'[\s_-]+'))
// //         .where((w) => w.isNotEmpty)
// //         .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
// //         .join();

// //     return '${pascal}Entity';
// //   }

// //   /// Convert PascalCase class name to snake_case file name.
// //   /// Example: "PostTitleEntity" → "post_title_entity.dart"
// //   String _classNameToFileName(String className) {
// //     if (className.isEmpty) return 'entity.dart';
// //     final buffer = StringBuffer();
// //     buffer.write(className[0].toLowerCase());
// //     for (int i = 1; i < className.length; i++) {
// //       final char = className[i];
// //       if (_isUpperCase(char)) {
// //         buffer.write('_${char.toLowerCase()}');
// //       } else {
// //         buffer.write(char);
// //       }
// //     }
// //     // Remove trailing "_entity" duplication if any (safety)
// //     var result = buffer.toString();
// //     if (result.endsWith('_entity')) {
// //       result = result.substring(0, result.length - 7) + '_entity.dart';
// //     } else {
// //       result = '$result.dart';
// //     }
// //     return result;
// //   }

// //   bool _isUpperCase(String char) => RegExp(r'[A-Z]').hasMatch(char);
// //   String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
// //   String _singularize(String text) {
// //     if (text.endsWith('ies')) return '${text.substring(0, text.length - 3)}y';
// //     if (text.endsWith('s') && text.length > 1) return text.substring(0, text.length - 1);
// //     return text;
// //   }

// //   String _resolveDefault(Map<String, dynamic> field, String type) {
// //     final defaultVal = field['defaultValue'];
// //     if (defaultVal != null) {
// //       if (defaultVal is String) return "'${_escape(defaultVal)}'";
// //       return defaultVal.toString();
// //     }
// //     switch (type) {
// //       case 'text':
// //       case 'textfield':
// //       case 'textarea':
// //       case 'email':
// //       case 'password':
// //       case 'phone':
// //       case 'otp':
// //       case 'formula':
// //         return "''";
// //       case 'number':
// //       case 'integer':
// //       case 'int':
// //         return '0';
// //       case 'decimal':
// //       case 'double':
// //       case 'float':
// //         return '0.0';
// //       case 'checkbox':
// //       case 'switch':
// //         return 'false';
// //       case 'multiselect':
// //       case 'multi_select':
// //         return '<String>[]';
// //       default:
// //         return 'null';
// //     }
// //   }

// //   String _escape(String s) => s.replaceAll("'", "\\'");
// // }