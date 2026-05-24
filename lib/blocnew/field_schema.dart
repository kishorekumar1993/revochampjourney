// lib/bloc/generators/field_schema.dart
// ---------------------------------------------------------------------------
// String Helpers
// ---------------------------------------------------------------------------

String toCap(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

String toCamelCase(String text) {
  if (text.trim().isEmpty) return 'field';
  final parts = text.trim().split(RegExp(r'[\s_\-]+'));
  return parts.first.toLowerCase() +
      parts.skip(1).map((e) => e.isEmpty ? '' : toCap(e)).join();
}

String toPascalCase(String text) {
  if (text.trim().isEmpty) return 'Field';
  return text
      .trim()
      .split(RegExp(r'[\s_\-]+'))
      .map((e) => e.isEmpty ? '' : toCap(e))
      .join();
}

String toSnakeCase(String text) {
  if (text.isEmpty) return '';
  final snake = text
      .replaceAllMapped(
        RegExp(r'[A-Z]'),
        (m) => '_${m.group(0)!.toLowerCase()}',
      )
      .toLowerCase();
  return snake.startsWith('_') ? snake.substring(1) : snake;
}

// ---------------------------------------------------------------------------
// FieldType
// ---------------------------------------------------------------------------

enum FieldType {
  text,
  email,
  phone,
  number,
  decimal,
  password,
  textarea,
  dropdown,
  asyncDropdown,
  multiSelect,
  checkbox,
  radio,
  date,
  time,
  dateTime,
  file,
  image,
  fileUpload,
  hidden,
  textField,
}

FieldType parseFieldType(String raw) {
  switch (raw.toLowerCase().replaceAll('_', '').replaceAll('-', '').trim()) {
    case 'text':
    case 'textfield':
      return FieldType.text;
    case 'email':
      return FieldType.email;
    case 'phone':
    case 'tel':
      return FieldType.phone;
    case 'number':
    case 'integer':
    case 'int':
      return FieldType.number;
    case 'decimal':
    case 'double':
    case 'float':
      return FieldType.decimal;
    case 'password':
      return FieldType.password;
    case 'textarea':
    case 'multiline':
      return FieldType.textarea;
    case 'dropdown':
    case 'select':
      return FieldType.dropdown;
    case 'asyncdropdown':
    case 'asyncselect':
    case 'remoteselect':
      return FieldType.asyncDropdown;
    case 'multiselect':
      return FieldType.multiSelect;
    case 'checkbox':
    case 'switch': // treat switch as checkbox
      return FieldType.checkbox;
    case 'radio':
    case 'radiobuttons':
      return FieldType.radio;
    case 'date':
      return FieldType.date;
    case 'time':
      return FieldType.time;
    case 'datetime':
      return FieldType.dateTime;
    case 'file':
    case 'fileupload':
      return FieldType.file;
    case 'image':
      return FieldType.image;
    case 'hidden':
      return FieldType.hidden;
    default:
      return FieldType.text;
  }
}

// ---------------------------------------------------------------------------
// DropdownSource
// ---------------------------------------------------------------------------

enum DropdownSource { none, staticList, api }

// ---------------------------------------------------------------------------
// StaticOption
// ---------------------------------------------------------------------------

class StaticOption {
  const StaticOption({required this.key, required this.value});
  final String key;
  final String value;

  factory StaticOption.fromJson(Map<String, dynamic> j) {
    return StaticOption(
      key: j['key']?.toString() ?? '',
      value: j['value']?.toString() ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// FieldSchema
// ---------------------------------------------------------------------------

class FieldSchema {
  const FieldSchema({
    required this.fieldName,
    required this.fieldType,
    required this.label,
    required this.validationPattern,
    required this.errorMessage,
    required this.dropdownValue,
    this.hint,
    this.isRequired = false,
    this.isReadOnly = false,
    this.isDisabled = false,
    this.isHidden = false,
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.regex,
    this.regexError,
    this.defaultValue,
    this.staticOptions = const [],
    this.staticStringValues = const [],
    this.dropdownData = const [],
    this.dropdownApiUrl = '',
    this.dropdownApiMethod = 'GET',
    this.dropdownApiBody = '',
    this.dropdownApiHeaders,
    this.dropdownKey = '',
    this.dropdownLabelKey = 'name',
    this.dropdownValueKey = 'id',
    this.cacheKey,
    this.cacheDuration,
    this.dependsOn,
    this.keyboardType = 'text',
    this.obscureText = false,
    this.textCapitalization = 'none',
    this.textInputAction = 'done',
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.isLocalStorageEnabled = false,
    this.localStorageKey,
    this.apiEnabled = false,
  });

  final String fieldName;
  final FieldType fieldType;
  final String label;
  final String? hint;
  final String validationPattern;
  final String errorMessage;

  final bool isRequired;
  final bool isReadOnly;
  final bool isDisabled;
  final bool isHidden;

  final int? minLength;
  final int? maxLength;
  final num? minValue;
  final num? maxValue;
  final String? regex;
  final String? regexError;

  final dynamic defaultValue;

  final List<Map<String, dynamic>> staticOptions;
  final List<String> staticStringValues;

  final List<Map<String, dynamic>> dropdownData;
  final String dropdownApiUrl;
  final String dropdownApiMethod;
  final String dropdownApiBody;
  final Map<String, String>? dropdownApiHeaders;
  final String dropdownKey;
  final String dropdownLabelKey;
  final String dropdownValueKey;
  final dynamic dropdownValue;

  final String? cacheKey;
  final int? cacheDuration;
  final String? dependsOn;

  final String keyboardType;
  final bool obscureText;
  final String textCapitalization;
  final String textInputAction;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool apiEnabled;

  final bool isLocalStorageEnabled;
  final String? localStorageKey;

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  bool get isAsyncDropdown => apiEnabled || dropdownApiUrl.isNotEmpty;
  bool get isStaticDropdown => fieldType == FieldType.dropdown;
  bool get hasDropdownData => dropdownData.isNotEmpty;
  bool get isFileUpload => fieldType == FieldType.file;
  bool get isStaticStringOnly =>
      staticStringValues.isNotEmpty && dropdownData.isEmpty;

  String get entityClassName => '${toPascalCase(fieldName)}Entity';
  String get modelClassName => '${toPascalCase(fieldName)}Model';
  String get snakeFieldName => toSnakeCase(fieldName);

  String get dartType {
    switch (fieldType) {
      case FieldType.number:
        return 'int?';
      case FieldType.decimal:
        return 'double?';
      case FieldType.checkbox:
        return 'bool';
      case FieldType.date:
      case FieldType.time:
      case FieldType.dateTime:
        return 'DateTime?';
      case FieldType.multiSelect:
        return 'List<String>';
      case FieldType.file:
      case FieldType.image:
        return 'dynamic';
      case FieldType.dropdown:
      case FieldType.asyncDropdown:
      case FieldType.radio:
        if (isStaticStringOnly) return 'String';
        return hasDropdownData ? '$entityClassName?' : 'String';
      default:
        return 'String';
    }
  }

  String get reactiveValueType => dartType;

  String get pureDefault {
    if (dartType == 'bool') return 'false';
    if (dartType == 'List<String>') return 'const []';
    if (dartType.endsWith('?')) return 'null';
    return "''";
  }

  // -----------------------------------------------------------------------
  // Factory — THE FIXED fromJson
  // -----------------------------------------------------------------------

  factory FieldSchema.fromJson(Map<String, dynamic> j) {
    final rawType =
        (j['fieldType'] as String?) ?? (j['type'] as String?) ?? 'text';
    final fieldType = parseFieldType(rawType);

    // ─────────────────────────────────────────────────────────────────────
    // CORE FIX: parseAnyList
    // Handles ALL three cases from your JSON on Flutter Web:
    //   1. null                        → []
    //   2. ["Male","Female"]           → [{key:Male, value:Male}, ...]
    //   3. [{"key":"m","value":"Male"}]→ [{key:m, value:Male}, ...]
    // ─────────────────────────────────────────────────────────────────────
    List<Map<String, dynamic>> parseAnyList(dynamic value) {
      if (value == null) return const [];
      if (value is! List) return const [];
      return value.map<Map<String, dynamic>>((e) {
        // Already a Map (staticOptions format: {key, value})
        if (e is Map) return Map<String, dynamic>.from(e);
        // Plain string (options format: "Male")
        final s = e.toString();
        return <String, dynamic>{'key': s, 'value': s};
      }).toList();
    }

    // ─────────────────────────────────────────────────────────────────────
    // parseDropdownData — API response data (list of objects)
    // ─────────────────────────────────────────────────────────────────────
    List<Map<String, dynamic>> parseDropdownData(dynamic value) {
      if (value == null) return const [];
      if (value is! List) return const [];
      return value.map<Map<String, dynamic>>((e) {
        if (e is Map) return Map<String, dynamic>.from(e);
        return <String, dynamic>{'value': e.toString()};
      }).toList();
    }

    // ─────────────────────────────────────────────────────────────────────
    // Resolve staticOptions: prefer explicit staticOptions, fall back to options
    // ─────────────────────────────────────────────────────────────────────
    final rawStaticOptions = parseAnyList(
      j['useStaticOptions'] == true
          ? (j['staticOptions'] ?? j['options'])
          : j['staticOptions'],
    );

    // ─────────────────────────────────────────────────────────────────────
    // staticStringValues: always built from plain options[] list
    // This covers: gender, maritalStatus, vehicleMake, regYear, etc.
    // ─────────────────────────────────────────────────────────────────────
    final List<String> staticStringValues;
    if (j['options'] is List && (j['options'] as List).isNotEmpty) {
      staticStringValues = (j['options'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (rawStaticOptions.isNotEmpty) {
      staticStringValues = rawStaticOptions
          .map((e) => e['value']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      staticStringValues = const [];
    }

    final dropdownData =
        parseDropdownData(j['dropdownData'] ?? j['dropdowndata']);

    // ─────────────────────────────────────────────────────────────────────
    // Safe headers cast — .cast() crashes on Flutter Web JSObject
    // ─────────────────────────────────────────────────────────────────────
    Map<String, String>? safeHeaders;
    if (j['dropdownApiHeaders'] is Map) {
      safeHeaders = Map<String, String>.from(
        (j['dropdownApiHeaders'] as Map).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ),
      );
    }

    // fieldName: prefer explicit fieldName, then id, then camelCase of label
    final fieldName = j['fieldName'] as String? ??
        (j['id'] as String? ?? toCamelCase(j['label'] as String? ?? 'field'));

    return FieldSchema(
      fieldName: fieldName,
      fieldType: fieldType,
      validationPattern: j['validationPattern'] as String? ?? '',
      errorMessage: j['errorMessage'] as String? ?? '',
      apiEnabled: j['api'] as bool? ?? false,
      label: j['label'] as String? ?? '',
      hint: j['hint'] as String? ??
          j['hintText'] as String? ??
          j['placeholder'] as String?,
      isRequired:
          j['required'] as bool? ?? j['isRequired'] as bool? ?? false,
      isReadOnly:
          j['readOnly'] as bool? ?? j['isReadOnly'] as bool? ?? false,
      isDisabled:
          j['disable'] as bool? ?? j['disabled'] as bool? ?? false,
      isHidden: j['hidden'] as bool? ?? false,
      minLength: (j['minLength'] as num?)?.toInt(),
      maxLength: (j['maxLength'] as num?)?.toInt(),
      minValue: j['minValue'] as num?,
      maxValue: j['maxValue'] as num?,
      regex: j['regex'] as String? ?? j['validationPattern'] as String?,
      regexError:
          j['regexError'] as String? ?? j['errorMessage'] as String?,
      defaultValue: j['defaultValue'],
      staticOptions: rawStaticOptions,
      staticStringValues: staticStringValues,
      dropdownData: dropdownData,
      dropdownApiUrl: j['dropdownApiUrl'] as String? ?? '',
      dropdownApiMethod: j['dropdownApiMethod'] as String? ?? 'GET',
      dropdownApiBody: j['dropdownApiBody'] as String? ?? '',
      dropdownApiHeaders: safeHeaders,
      dropdownKey: j['dropdownKey'] as String? ?? '',
      dropdownLabelKey: j['dropdownLabelKey'] as String? ?? 'name',
      dropdownValueKey: j['dropdownValueKey'] as String? ?? 'id',
      cacheKey: j['cacheKey'] as String?,
      cacheDuration: (j['cacheDuration'] as num?)?.toInt(),
      dependsOn: j['dependsOn'] as String?,
      keyboardType: j['keyboardType'] as String? ?? 'text',
      obscureText: j['obscureText'] == true,
      textCapitalization: j['textCapitalization'] as String? ?? 'none',
      textInputAction: j['textInputAction'] as String? ?? 'done',
      autocorrect: j['autocorrect'] != false,
      enableSuggestions: j['enableSuggestions'] != false,
      isLocalStorageEnabled: j['isLocalStorageEnabled'] as bool? ?? false,
      localStorageKey: j['localStorageKey'] as String?,
      dropdownValue: j['dropdownValue'] as String? ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// GeneratorField
// ---------------------------------------------------------------------------

class GeneratorField {
  const GeneratorField({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.isDateTime,
  });

  final String name;
  final String type;
  final bool isRequired;
  final bool isDateTime;

  bool get isNullable => !isRequired || type.endsWith('?');

  static List<GeneratorField> parseFields(Map<String, dynamic> json) {
    return json.entries.map((e) {
      final name = toCamelCase(e.key);
      final isRequired = e.value != null;
      final isDateTime =
          e.value is String && isIso8601(e.value as String);
      final type = dartTypeForValue(e.value, isRequired: isRequired);
      return GeneratorField(
        name: name,
        type: type,
        isRequired: isRequired,
        isDateTime: isDateTime,
      );
    }).toList();
  }

  static String dartTypeForValue(dynamic value, {required bool isRequired}) {
    if (value == null) return 'Object?';
    if (value is int) return isRequired ? 'int' : 'int?';
    if (value is double) return isRequired ? 'double' : 'double?';
    if (value is bool) return isRequired ? 'bool' : 'bool?';
    if (value is String) {
      if (isIso8601(value)) return isRequired ? 'DateTime' : 'DateTime?';
      return isRequired ? 'String' : 'String?';
    }
    if (value is List) return isRequired ? 'List<dynamic>' : 'List<dynamic>?';
    if (value is Map) {
      return isRequired ? 'Map<String, dynamic>' : 'Map<String, dynamic>?';
    }
    return 'Object?';
  }
}

bool isIso8601(String s) {
  return RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s);
}


// // lib/bloc/generators/field_schema.dart
// //
// // Unified + enhanced FieldSchema parser for Revochamp.
// // Combines features from both implementations.
// //
// // Features:
// // ✅ Async dropdown
// // ✅ Static dropdown
// // ✅ Radio buttons
// // ✅ File upload
// // ✅ Multi select
// // ✅ Validation rules
// // ✅ API headers/body
// // ✅ Local storage support
// // ✅ Cache support
// // ✅ Dynamic entity/model naming
// // ✅ GeneratorField helper
// // ✅ Reactive state helpers
// // ✅ Keyboard + text behavior config
// // ✅ Date/time support
// // ✅ Hidden/readOnly/disabled support
// //
// // ---------------------------------------------------------------------------
// // String Helpers
// // ---------------------------------------------------------------------------

// String toCap(String text) {
//   if (text.isEmpty) return text;
//   return text[0].toUpperCase() + text.substring(1);
// }

// String toCamelCase(String text) {
//   if (text.trim().isEmpty) return 'field';

//   final parts = text
//       .trim()
//       .split(RegExp(r'[\s_\-]+'));

//   return parts.first.toLowerCase() +
//       parts
//           .skip(1)
//           .map((e) => e.isEmpty ? '' : toCap(e))
//           .join();
// }

// String toPascalCase(String text) {
//   if (text.trim().isEmpty) return 'Field';

//   return text
//       .trim()
//       .split(RegExp(r'[\s_\-]+'))
//       .map((e) => e.isEmpty ? '' : toCap(e))
//       .join();
// }

// String toSnakeCase(String text) {
//   if (text.isEmpty) return '';

//   final snake = text
//       .replaceAllMapped(
//         RegExp(r'[A-Z]'),
//         (m) => '_${m.group(0)!.toLowerCase()}',
//       )
//       .toLowerCase();

//   return snake.startsWith('_')
//       ? snake.substring(1)
//       : snake;
// }

// // ---------------------------------------------------------------------------
// // FieldType
// // ---------------------------------------------------------------------------

// enum FieldType {
//   text,
//   email,
//   phone,
//   number,
//   decimal,
//   password,
//   textarea,
//   dropdown,
//   asyncDropdown,
//   multiSelect,
//   checkbox,
//   radio,
//   date,
//   time,
//   dateTime,
//   file,
//   image,
//   fileUpload,
//   hidden,
//   textField
// }

// FieldType parseFieldType(String raw) {
//   switch (raw
//       .toLowerCase()
//       .replaceAll('_', '')
//       .replaceAll('-', '')
//       .trim()) {
//     case 'text':
//     case 'textfield':
//       return FieldType.text;

//     case 'email':
//       return FieldType.email;

//     case 'phone':
//     case 'tel':
//       return FieldType.phone;

//     case 'number':
//     case 'integer':
//     case 'int':
//       return FieldType.number;

//     case 'decimal':
//     case 'double':
//     case 'float':
//       return FieldType.decimal;

//     case 'password':
//       return FieldType.password;

//     case 'textarea':
//     case 'multiline':
//       return FieldType.textarea;

//     case 'dropdown':
//     case 'select':
//       return FieldType.dropdown;

//     case 'asyncdropdown':
//     case 'asyncselect':
//     case 'remoteselect':
//       return FieldType.asyncDropdown;

//     case 'multiselect':
//       return FieldType.multiSelect;

//     case 'checkbox':
//       return FieldType.checkbox;

//     case 'radio':
//     case 'radiobuttons':
//       return FieldType.radio;

//     case 'date':
//       return FieldType.date;

//     case 'time':
//       return FieldType.time;

//     case 'datetime':
//       return FieldType.dateTime;

//     case 'file':
//     case 'fileupload':
//       return FieldType.file;

//     case 'image':
//       return FieldType.image;

//     case 'hidden':
//       return FieldType.hidden;

//     default:
//       return FieldType.text;
//   }
// }

// // ---------------------------------------------------------------------------
// // DropdownSource
// // ---------------------------------------------------------------------------

// enum DropdownSource {
//   none,
//   staticList,
//   api,
// }

// // ---------------------------------------------------------------------------
// // StaticOption
// // ---------------------------------------------------------------------------

// class StaticOption {
//   const StaticOption({
//     required this.key,
//     required this.value,
//   });

//   final String key;
//   final String value;

//   factory StaticOption.fromJson(Map<String, dynamic> j) {
//     return StaticOption(
//       key: j['key']?.toString() ?? '',
//       value: j['value']?.toString() ?? '',
//     );
//   }
// }

// // ---------------------------------------------------------------------------
// // FieldSchema
// // ---------------------------------------------------------------------------

// class FieldSchema {
//   const FieldSchema({
//     required this.fieldName,
//     required this.fieldType,
//     required this.label,
//         required this.validationPattern,
//     required this.errorMessage,

//     this.hint,
//     this.isRequired = false,
//     this.isReadOnly = false,
//     this.isDisabled = false,
//     this.isHidden = false,
//     this.minLength,
//     this.maxLength,
//     this.minValue,
//     this.maxValue,
//     this.regex,
//     this.regexError,
//     this.defaultValue,
//     this.staticOptions = const [],
//     this.staticStringValues = const [],
//     this.dropdownData = const [],
//     this.dropdownApiUrl = '',
//     this.dropdownApiMethod = 'GET',
//     this.dropdownApiBody = '',
//     this.dropdownApiHeaders,
//     this.dropdownKey = '',
//     this.dropdownLabelKey = 'name',
//     this.dropdownValueKey = 'id',

//     this.cacheKey,
//     this.cacheDuration,
//     this.dependsOn,
//     this.keyboardType = 'text',
//     this.obscureText = false,
//     this.textCapitalization = 'none',
//     this.textInputAction = 'done',
//     this.autocorrect = true,
//     this.enableSuggestions = true,
//     this.isLocalStorageEnabled = false,
//     this.localStorageKey,
//             required this.dropdownValue,
//             this.apiEnabled = false,

//   });

//   // -----------------------------------------------------------------------
//   // Basic
//   // -----------------------------------------------------------------------

//   final String fieldName;
//   final FieldType fieldType;
//   final String label;
//   final String? hint;
//         final String validationPattern;
//   final String errorMessage;

//   // -----------------------------------------------------------------------
//   // State
//   // -----------------------------------------------------------------------

//   final bool isRequired;
//   final bool isReadOnly;
//   final bool isDisabled;
//   final bool isHidden;

//   // -----------------------------------------------------------------------
//   // Validation
//   // -----------------------------------------------------------------------

//   final int? minLength;
//   final int? maxLength;
//   final num? minValue;
//   final num? maxValue;
//   final String? regex;
//   final String? regexError;

//   // -----------------------------------------------------------------------
//   // Defaults
//   // -----------------------------------------------------------------------

//   final dynamic defaultValue;

//   // -----------------------------------------------------------------------
//   // Static dropdown
//   // -----------------------------------------------------------------------

//   final List<Map<String, dynamic>> staticOptions;
//   final List<String> staticStringValues;

//   // -----------------------------------------------------------------------
//   // API dropdown
//   // -----------------------------------------------------------------------

//   final List<Map<String, dynamic>> dropdownData;

//   final String dropdownApiUrl;
//   final String dropdownApiMethod;
//   final String dropdownApiBody;

//   final Map<String, String>? dropdownApiHeaders;

//   final String dropdownKey;
//   final String dropdownLabelKey;
//   final String dropdownValueKey;

//   final String? cacheKey;
//   final int? cacheDuration;
//   final String? dependsOn;

//   // -----------------------------------------------------------------------
//   // Input behavior
//   // -----------------------------------------------------------------------

//   final String keyboardType;
//   final bool obscureText;
//   final String textCapitalization;
//   final String textInputAction;
//   final bool autocorrect;
//   final bool enableSuggestions;
// final bool apiEnabled;
//   // -----------------------------------------------------------------------
//   // Local storage
//   // -----------------------------------------------------------------------

//   final bool isLocalStorageEnabled;
//   final String? localStorageKey;
  
//   final dynamic dropdownValue;

//   // -----------------------------------------------------------------------
//   // Helpers
//   // -----------------------------------------------------------------------

//   // bool get isAsyncDropdown => fieldType == FieldType.asyncDropdown;
//   bool get isAsyncDropdown =>
//     apiEnabled || dropdownApiUrl.isNotEmpty;

//   bool get isStaticDropdown => fieldType == FieldType.dropdown;

//   bool get hasDropdownData => dropdownData.isNotEmpty;

//   bool get isFileUpload => fieldType == FieldType.file;

//   bool get isStaticStringOnly =>
//       staticStringValues.isNotEmpty && dropdownData.isEmpty;

//   String get entityClassName =>
//       '${toPascalCase(fieldName)}Entity';

//   String get modelClassName =>
//       '${toPascalCase(fieldName)}Model';

//   String get snakeFieldName => toSnakeCase(fieldName);

//   // -----------------------------------------------------------------------
//   // Dart Type
//   // -----------------------------------------------------------------------

//   String get dartType {
//     switch (fieldType) {
//       case FieldType.number:
//         return 'int?';

//       case FieldType.decimal:
//         return 'double?';

//       case FieldType.checkbox:
//         return 'bool';

//       case FieldType.date:
//       case FieldType.time:
//       case FieldType.dateTime:
//         return 'DateTime?';

//       case FieldType.multiSelect:
//         return 'List<String>';

//       case FieldType.file:
//       case FieldType.image:
//         return 'dynamic';

//       case FieldType.dropdown:
//       case FieldType.asyncDropdown:
//       case FieldType.radio:
//         if (isStaticStringOnly) {
//           return 'String';
//         }

//         return hasDropdownData
//             ? '$entityClassName?'
//             : 'String';

//       default:
//         return 'String';
//     }
//   }

//   String get reactiveValueType {
//     return dartType;
//   }

//   String get pureDefault {
//     if (dartType == 'bool') {
//       return 'false';
//     }

//     if (dartType == 'List<String>') {
//       return 'const []';
//     }

//     if (dartType.endsWith('?')) {
//       return 'null';
//     }

//     return "''";
//   }


//   // -----------------------------------------------------------------------
//   // Factory
//   // -----------------------------------------------------------------------

//   factory FieldSchema.fromJson(Map<String, dynamic> j) {
//     final rawType =
//         (j['fieldType'] as String?) ??
//         (j['type'] as String?) ??
//         'text';

//     final fieldType = parseFieldType(rawType);

//     List<Map<String, dynamic>> parseMapList(dynamic value) {
//       if (value is List) {
//         return value
//             .map((e) => Map<String, dynamic>.from(e as Map))
//             .toList();
//       }

//       return const [];
//     }
    
//     // final rawStaticOptions =
//     //     parseMapList(j['staticOptions'] ?? j['options']);

//     // final staticStringValues = rawStaticOptions
//     //     .map((e) => e['value']?.toString() ?? '')
//     //     .where((e) => e.isNotEmpty)
//     //     .toList();

//     // final dropdownData =
//     //     parseMapList(j['dropdownData'] ?? j['dropdowndata']);

//  // ✅ Safe parser for dropdowndata (can be null, List, JSArray)
//   List<Map<String, dynamic>> parseDropdownData(dynamic value) {
//     if (value == null) return const [];
//     if (value is List) {
//       return value.map((e) {
//         if (e is Map) return Map<String, dynamic>.from(e);
//         return <String, dynamic>{'value': e.toString()};
//       }).toList();
//     }
//     return const [];
//   }

//   final rawStaticOptions =
//       parseMapList(j['staticOptions'] ?? j['options']);

//   final staticStringValues = rawStaticOptions
//       .map((e) => e['value']?.toString() ?? '')
//       .where((e) => e.isNotEmpty)
//       .toList();

//   final dropdownData =
//       parseDropdownData(j['dropdownData'] ?? j['dropdowndata']);

//   // ✅ Safe headers cast
//   Map<String, String>? safeHeaders;
//   if (j['dropdownApiHeaders'] is Map) {
//     safeHeaders = Map<String, String>.from(
//       (j['dropdownApiHeaders'] as Map).map(
//         (k, v) => MapEntry(k.toString(), v.toString()),
//       ),
//     );
//   }


//     return FieldSchema(
//       fieldName: j['fieldName'] as String? ??
//           toCamelCase(j['label'] as String? ?? 'field'),

//       fieldType: fieldType,

//       validationPattern:     j['validationPattern'] as String? ?? '',
//       errorMessage:          j['errorMessage'] as String? ?? '',
// apiEnabled: j['api'] as bool? ?? false,
//       label: j['label'] as String? ?? '',

//       hint: j['hint'] as String? ??
//           j['hintText'] as String?,

//       isRequired: j['required'] as bool? ??
//           j['isRequired'] as bool? ??
//           false,

//       isReadOnly: j['readOnly'] as bool? ??
//           j['isReadOnly'] as bool? ??
//           false,

//       isDisabled: j['disable'] as bool? ??
//           j['disabled'] as bool? ??
//           false,

//       isHidden: j['hidden'] as bool? ?? false,

//       minLength: (j['minLength'] as num?)?.toInt(),
//       maxLength: (j['maxLength'] as num?)?.toInt(),

//       minValue: j['minValue'] as num?,
//       maxValue: j['maxValue'] as num?,

//       regex: j['regex'] as String? ??
//           j['validationPattern'] as String?,

//       regexError: j['regexError'] as String? ??
//           j['errorMessage'] as String?,

//       defaultValue: j['defaultValue'],

//       staticOptions: rawStaticOptions,

//       staticStringValues: staticStringValues,

//       dropdownData: dropdownData,

//       dropdownApiUrl:
//           j['dropdownApiUrl'] as String? ?? '',

//       dropdownApiMethod:
//           j['dropdownApiMethod'] as String? ?? 'GET',

//       dropdownApiBody:
//           j['dropdownApiBody'] as String? ?? '',

//       // dropdownApiHeaders:
//       //     (j['dropdownApiHeaders'] as Map?)
//       //         ?.cast<String, String>(),
// dropdownApiHeaders: safeHeaders,          
//       dropdownKey:
//           j['dropdownKey'] as String? ?? '',

//       dropdownLabelKey:
//           j['dropdownLabelKey'] as String? ?? 'name',

//       dropdownValueKey:
//           j['dropdownValueKey'] as String? ?? 'id',

//       cacheKey:
//           j['cacheKey'] as String?,

//       cacheDuration:
//           (j['cacheDuration'] as num?)?.toInt(),

//       dependsOn:
//           j['dependsOn'] as String?,

//       keyboardType:
//           j['keyboardType'] as String? ?? 'text',

//       obscureText:
//           j['obscureText'] == true,

//       textCapitalization:
//           j['textCapitalization'] as String? ?? 'none',

//       textInputAction:
//           j['textInputAction'] as String? ?? 'done',

//       autocorrect:
//           j['autocorrect'] != false,

//       enableSuggestions:
//           j['enableSuggestions'] != false,

//       isLocalStorageEnabled:
//           j['isLocalStorageEnabled'] as bool? ?? false,

//       localStorageKey:
//           j['localStorageKey'] as String?, dropdownValue:         j['dropdownValue'] as String? ?? '',
//     );
//   }

// }

// // ---------------------------------------------------------------------------
// // GeneratorField
// // ---------------------------------------------------------------------------

// class GeneratorField {
//   const GeneratorField({
//     required this.name,
//     required this.type,
//     required this.isRequired,
//     required this.isDateTime,
//   });

//   final String name;
//   final String type;
//   final bool isRequired;
//   final bool isDateTime;

//   bool get isNullable =>
//       !isRequired || type.endsWith('?');

//   static List<GeneratorField> parseFields(
//     Map<String, dynamic> json,
//   ) {
//     return json.entries.map((e) {
//       final name = toCamelCase(e.key);

//       final isRequired = e.value != null;

//       final isDateTime =
//           e.value is String &&
//           isIso8601(e.value as String);

//       final type = dartTypeForValue(
//         e.value,
//         isRequired: isRequired,
//       );

//       return GeneratorField(
//         name: name,
//         type: type,
//         isRequired: isRequired,
//         isDateTime: isDateTime,
//       );
//     }).toList();
//   }

//   static String dartTypeForValue(
//     dynamic value, {
//     required bool isRequired,
//   }) {
//     if (value == null) {
//       return 'Object?';
//     }

//     if (value is int) {
//       return isRequired ? 'int' : 'int?';
//     }

//     if (value is double) {
//       return isRequired ? 'double' : 'double?';
//     }

//     if (value is bool) {
//       return isRequired ? 'bool' : 'bool?';
//     }

//     if (value is String) {
//       if (isIso8601(value)) {
//         return isRequired
//             ? 'DateTime'
//             : 'DateTime?';
//       }

//       return isRequired
//           ? 'String'
//           : 'String?';
//     }

//     if (value is List) {
//       return isRequired
//           ? 'List<dynamic>'
//           : 'List<dynamic>?';
//     }

//     if (value is Map) {
//       return isRequired
//           ? 'Map<String, dynamic>'
//           : 'Map<String, dynamic>?';
//     }

//     return 'Object?';
//   }
// }

// bool isIso8601(String s) {
//   return RegExp(r'^\d{4}-\d{2}-\d{2}')
//       .hasMatch(s);
// }
// // // lib/bloc/generators/field_schema.dart
// // //
// // // Parses the raw field JSON array (from Revochamp UI) into strongly-typed
// // // FieldSchema objects consumed by every generator.
// // // v2: Added staticString type, fileUpload dartType, apiHeaders support,
// // //     multi-API support, staticStringValues for radio/dropdown without data.

// // // ---------------------------------------------------------------------------
// // // FieldType enum
// // // ---------------------------------------------------------------------------

// // enum FieldType {
// //   textField,
// //   dropdown,
// //   radioButtons,
// //   date,
// //   checkbox,
// //   fileUpload,
// //   multiSelect,
// //   unknown,
// // }

// // // ---------------------------------------------------------------------------
// // // DropdownSource
// // // ---------------------------------------------------------------------------

// // enum DropdownSource { none, staticList, api }

// // // ---------------------------------------------------------------------------
// // // StaticOption  (key / value pair inside staticOptions)
// // // ---------------------------------------------------------------------------

// // class StaticOption {
// //   const StaticOption({required this.key, required this.value});
// //   final String key;
// //   final String value;
// //   factory StaticOption.fromJson(Map<String, dynamic> j) =>
// //       StaticOption(key: j['key']?.toString() ?? '', value: j['value']?.toString() ?? '');
// // }

// // // ---------------------------------------------------------------------------
// // // FieldSchema  — one field on the form
// // // ---------------------------------------------------------------------------

// // class FieldSchema {
// //   const FieldSchema({
// //     required this.id,
// //     required this.type,
// //     required this.label,
// //     required this.fieldName,
// //     required this.dartType,
// //     required this.defaultValue,
// //     required this.required,
// //     required this.hidden,
// //     required this.readOnly,
// //     required this.disabled,
// //     required this.hintText,
// //     required this.maxLength,
// //     required this.minLength,
// //     required this.validationPattern,
// //     required this.errorMessage,
// //     required this.dropdownSource,
// //     required this.staticOptions,
// //     required this.dropdownApiUrl,
// //     required this.dropdownApiMethod,
// //     required this.dropdownApiHeaders,
// //     required this.dropdownApiBody,
// //     required this.dropdownKey,
// //     required this.dropdownValue,
// //     required this.dropdownData,
// //     required this.keyboardType,
// //     required this.obscureText,
// //     required this.entityClassName,
// //     required this.modelClassName,
// //     required this.isStaticStringOnly,
// //     required this.staticStringValues,
// //     required this.textCapitalization,
// //     required this.textInputAction,
// //     required this.autocorrect,
// //     required this.enableSuggestions,
// //   });

// //   final String id;
// //   final FieldType type;
// //   final String label;

// //   /// camelCase field name  e.g. "firstName"
// //   final String fieldName;

// //   /// Dart type string  e.g. "String", "DateTime?", "File?"
// //   final String dartType;

// //   /// Default pure value  e.g. "''"  or  "null"
// //   final String defaultValue;

// //   final bool required;
// //   final bool hidden;
// //   final bool readOnly;
// //   final bool disabled;
// //   final String hintText;
// //   final int? maxLength;
// //   final int? minLength;
// //   final String validationPattern;
// //   final String errorMessage;

// //   final DropdownSource dropdownSource;
// //   final List<StaticOption> staticOptions;
// //   final String dropdownApiUrl;
// //   final String dropdownApiMethod;
// //   final Map<String, String>? dropdownApiHeaders;

// //   /// Raw JSON body string for POST/PUT/PATCH requests (may be empty)
// //   final String dropdownApiBody;

// //   final String dropdownKey;
// //   final String dropdownValue;

// //   /// Raw API data (first item used to generate entity/model)
// //   final List<Map<String, dynamic>> dropdownData;

// //   final String keyboardType;
// //   final bool obscureText;

// //   /// e.g. "PostEntity"   (only for dropdown/radio with API data)
// //   final String entityClassName;

// //   /// e.g. "PostModel"
// //   final String modelClassName;

// //   /// True when field has only staticOptions with string values (no entity needed)
// //   final bool isStaticStringOnly;

// //   /// Plain string list from staticOptions when no dropdowndata present
// //   final List<String> staticStringValues;

// //   final String textCapitalization;
// //   final String textInputAction;
// //   final bool autocorrect;
// //   final bool enableSuggestions;

// //   // -------------------------------------------------------------------------
// //   // Factory
// //   // -------------------------------------------------------------------------

// //   factory FieldSchema.fromJson(Map<String, dynamic> j) {
// //     final rawType = (j['type'] as String? ?? '').toLowerCase().trim();
// //     final type = _parseType(rawType);

// //     final label     = j['label'] as String? ?? '';
// //     final fieldName = _toCamelCase(label);

// //     final rawStaticOptions = j['staticOptions'] as List<dynamic>? ?? [];
// //     final staticOptions    = rawStaticOptions
// //         .map((e) => StaticOption.fromJson(e as Map<String, dynamic>))
// //         .toList();

// //     final useStaticOptions = j['useStaticOptions'] == true;
// //     final apiUrl = (j['dropdownApiUrl'] as String? ?? '').trim();

// //     DropdownSource dropdownSource;
// //     if (useStaticOptions && staticOptions.isNotEmpty) {
// //       dropdownSource = DropdownSource.staticList;
// //     } else if (apiUrl.isNotEmpty) {
// //       dropdownSource = DropdownSource.api;
// //     } else {
// //       dropdownSource = DropdownSource.none;
// //     }

// //     final rawDropdownData = j['dropdowndata'] as List<dynamic>? ?? [];
// //     final dropdownData = rawDropdownData
// //         .map((e) => Map<String, dynamic>.from(e as Map))
// //         .toList();

// //     // Headers (may be Map or null)
// //     final rawHeaders = j['dropdownApiHeaders'];
// //     Map<String, String>? headers;
// //     if (rawHeaders is Map) {
// //       headers = rawHeaders.map((k, v) => MapEntry(k.toString(), v.toString()));
// //     }

// //     // Static string only: radio/dropdown with staticOptions but NO dropdowndata
// //     final isStaticStringOnly = (type == FieldType.radioButtons || type == FieldType.dropdown)
// //         && dropdownSource == DropdownSource.staticList
// //         && dropdownData.isEmpty;

// //     final staticStringValues = isStaticStringOnly
// //         ? staticOptions.map((o) => o.value).toList()
// //         : <String>[];

// //     // Entity/model class names — only when API data available
// //     final entityClassName = dropdownData.isNotEmpty
// //         ? '${_toPascalCase(label)}Entity'
// //         : '';
// //     final modelClassName = dropdownData.isNotEmpty
// //         ? '${_toPascalCase(label)}Model'
// //         : '';

// //     final dartType    = _resolveDartType(type, entityClassName, isStaticStringOnly);
// //     final defaultValue = _resolveDefault(dartType);

// //     return FieldSchema(
// //       id:                    j['id'] as String? ?? '',
// //       type:                  type,
// //       label:                 label,
// //       fieldName:             fieldName,
// //       dartType:              dartType,
// //       defaultValue:          defaultValue,
// //       required:              j['required'] == true,
// //       hidden:                j['hidden'] == true,
// //       readOnly:              j['readOnly'] == true,
// //       disabled:              j['disable'] == true,
// //       hintText:              j['hintText'] as String? ?? '',
// //       maxLength:             j['maxLength'] as int?,
// //       minLength:             j['minLength'] as int?,
// //       validationPattern:     j['validationPattern'] as String? ?? '',
// //       errorMessage:          j['errorMessage'] as String? ?? '',
// //       dropdownSource:        dropdownSource,
// //       staticOptions:         staticOptions,
// //       dropdownApiUrl:        apiUrl,
// //       dropdownApiMethod:     (j['dropdownApiMethod'] as String? ?? 'GET').trim().toUpperCase(),
// //       dropdownApiHeaders:    headers,
// //       dropdownApiBody:       j['dropdownApiBody'] as String? ?? '',
// //       dropdownKey:           j['dropdownkey'] as String? ?? '',
// //       dropdownValue:         j['dropdownValue'] as String? ?? '',
// //       dropdownData:          dropdownData,
// //       keyboardType:          j['keyboardType'] as String? ?? 'text',
// //       obscureText:           j['obscureText'] == true,
// //       entityClassName:       entityClassName,
// //       modelClassName:        modelClassName,
// //       isStaticStringOnly:    isStaticStringOnly,
// //       staticStringValues:    staticStringValues,
// //       textCapitalization:    j['textCapitalization'] as String? ?? 'none',
// //       textInputAction:       j['textInputAction'] as String? ?? 'done',
// //       autocorrect:           j['autocorrect'] != false,
// //       enableSuggestions:     j['enableSuggestions'] != false,
// //     );
// //   }

// //   // -------------------------------------------------------------------------
// //   // Derived helpers
// //   // -------------------------------------------------------------------------

// //   bool get hasDropdownData  => dropdownData.isNotEmpty && entityClassName.isNotEmpty;
// //   bool get isAsyncDropdown  => dropdownSource == DropdownSource.api && dropdownData.isNotEmpty;
// //   bool get isStaticDropdown => dropdownSource == DropdownSource.staticList;
// //   bool get isFileUpload     => type == FieldType.fileUpload;
// //   String get componentKey   => fieldName;
// //   String get snakeFieldName => _toSnakeCase(fieldName);

// //   // Reactive value type string for state/bloc generation
// //   String get reactiveValueType {
// //     if (isStaticStringOnly) return 'String';
// //     if (type == FieldType.dropdown || type == FieldType.radioButtons) {
// //       return entityClassName.isNotEmpty ? '$entityClassName?' : 'String';
// //     }
// //     return switch (type) {
// //       FieldType.date       => 'DateTime?',
// //       FieldType.checkbox   => 'bool',
// //       FieldType.fileUpload => 'dynamic',
// //       _                    => 'String',
// //     };
// //   }

// //   // Pure default for ReactiveValue constructor
// //   String get pureDefault {
// //     if (type == FieldType.checkbox) return 'false';
// //     if (reactiveValueType.endsWith('?')) return 'null';
// //     if (reactiveValueType == 'String') return "''";
// //     return 'null';
// //   }

// //   static FieldType _parseType(String raw) => switch (raw) {
// //         'textfield'     => FieldType.textField,
// //         'text field'    => FieldType.textField,
// //         'text'          => FieldType.textField,
// //         'dropdown'      => FieldType.dropdown,
// //         'radio buttons' => FieldType.radioButtons,
// //         'radio'         => FieldType.radioButtons,
// //         'date'          => FieldType.date,
// //         'checkbox'      => FieldType.checkbox,
// //         'file'          => FieldType.fileUpload,
// //         'fileupload'    => FieldType.fileUpload,
// //         'file upload'   => FieldType.fileUpload,
// //         'multiselect'   => FieldType.multiSelect,
// //         'multi select'  => FieldType.multiSelect,
// //         _               => FieldType.textField,
// //       };

// //   static String _resolveDartType(FieldType type, String entityClass, bool isStaticStringOnly) {
// //     if (isStaticStringOnly) return 'String';
// //     return switch (type) {
// //       FieldType.date         => 'DateTime?',
// //       FieldType.checkbox     => 'bool',
// //       FieldType.fileUpload   => 'dynamic',
// //       FieldType.multiSelect  => 'List<String>',
// //       FieldType.dropdown ||
// //       FieldType.radioButtons =>
// //           entityClass.isNotEmpty ? '$entityClass?' : 'String',
// //       _                      => 'String',
// //     };
// //   }

// //   static String _resolveDefault(String dartType) {
// //     if (dartType == 'bool')         return 'false';
// //     if (dartType == 'List<String>') return 'const []';
// //     if (dartType.endsWith('?'))     return 'null';
// //     if (dartType == 'String')       return "''";
// //     return 'null';
// //   }
// // }

// // // ---------------------------------------------------------------------------
// // // Shared string helpers  (used by all generators)
// // // ---------------------------------------------------------------------------

// // String toCamelCase(String text)  => _toCamelCase(text);
// // String toPascalCase(String text) => _toPascalCase(text);
// // String toSnakeCase(String text)  => _toSnakeCase(text);
// // String toCap(String text)        => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

// // String _toCamelCase(String text) {
// //   if (text.trim().isEmpty) return 'field';
// //   final parts = text.trim().split(RegExp(r'[\s_\-]+'));
// //   return parts.first.toLowerCase() +
// //       parts.skip(1).map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join();
// // }

// // String _toPascalCase(String text) {
// //   if (text.trim().isEmpty) return 'Field';
// //   return text.trim().split(RegExp(r'[\s_\-]+')).map((w) {
// //     if (w.isEmpty) return '';
// //     return w[0].toUpperCase() + w.substring(1);
// //   }).join();
// // }

// // String _toSnakeCase(String text) {
// //   if (text.isEmpty) return '';
// //   final snake = text.replaceAllMapped(
// //     RegExp(r'[A-Z]'),
// //     (m) => '_${m.group(0)!.toLowerCase()}',
// //   ).toLowerCase();
// //   return snake.startsWith('_') ? snake.substring(1) : snake;
// // }

// // // ---------------------------------------------------------------------------
// // // Helper for parsing arbitrary JSON keys into Dart fields (used by Entity & Model generators)
// // // ---------------------------------------------------------------------------

// // class GeneratorField {
// //   const GeneratorField({
// //     required this.name,
// //     required this.type,
// //     required this.isRequired,
// //     required this.isDateTime,
// //   });

// //   final String name;
// //   final String type;
// //   final bool isRequired;
// //   final bool isDateTime;

// //   bool get isNullable => !isRequired || type.endsWith('?');

// //   static List<GeneratorField> parseFields(Map<String, dynamic> json) {
// //     return json.entries.map((e) {
// //       final name = _toCamelCase(e.key);
// //       final isRequired = e.value != null;
// //       final isDateTime = e.value is String && _isIso8601(e.value as String);
// //       final type = dartTypeForValue(e.value, isRequired: isRequired);
// //       return GeneratorField(
// //         name: name,
// //         type: type,
// //         isRequired: isRequired,
// //         isDateTime: isDateTime,
// //       );
// //     }).toList();
// //   }

// //   static String dartTypeForValue(dynamic value, {required bool isRequired}) {
// //     if (value == null) return 'Object?';
// //     if (value is int)    return isRequired ? 'int'    : 'int?';
// //     if (value is double) return isRequired ? 'double' : 'double?';
// //     if (value is bool)   return isRequired ? 'bool'   : 'bool?';
// //     if (value is String) {
// //       if (_isIso8601(value)) return isRequired ? 'DateTime' : 'DateTime?';
// //       return isRequired ? 'String' : 'String?';
// //     }
// //     if (value is List)   return isRequired ? 'List<dynamic>' : 'List<dynamic>?';
// //     if (value is Map)    return isRequired ? 'Map<String, dynamic>' : 'Map<String, dynamic>?';
// //     return 'Object?';
// //   }

// //   static bool _isIso8601(String s) {
// //     return RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s);
// //   }
// // }


