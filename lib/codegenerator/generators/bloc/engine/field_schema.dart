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
  slider,
  repeater,
  timeline,
  section,
  label,
  starRating,
  autoComplete,
  signature,
  grid,
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
    case 'slider':
    case 'rangeslider':
      return FieldType.slider;
    case 'repeater':
      return FieldType.repeater;
    case 'timeline':
      return FieldType.timeline;
    case 'section':
      return FieldType.section;
    case 'label':
      return FieldType.label;
    case 'starrating':
    case 'rating':
      return FieldType.starRating;
    case 'autocomplete':
      return FieldType.autoComplete;
    case 'signature':
      return FieldType.signature;
    case 'grid':
    case 'table':
      return FieldType.grid;
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
    this.dropdownListKey = '',
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
    this.nestedFields = const [],
    this.groupId,
    this.groupLabel,
    this.sectionId,
    this.repeatableGroup = false,
    this.repeatConfig,
    this.conditionalValidations = const [],
    this.formula,
    this.expression,
    this.asyncValidation,
    this.cascadeConfig,
    this.localization,
    this.defaultValueExpression,
    this.visibleForRoles = const [],
    this.editableForRoles = const [],
    this.roleVisibility,
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
  final String dropdownListKey;
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
  final List<Map<String, dynamic>> nestedFields;
  final String? groupId;
  final String? groupLabel;
  final String? sectionId;
  final bool repeatableGroup;
  final Map<String, dynamic>? repeatConfig;
  final List<Map<String, dynamic>> conditionalValidations;
  final String? formula;
  final String? expression;
  final Map<String, dynamic>? asyncValidation;
  final Map<String, dynamic>? cascadeConfig;
  final Map<String, dynamic>? localization;
  final String? defaultValueExpression;
  final List<String> visibleForRoles;
  final List<String> editableForRoles;
  final Map<String, dynamic>? roleVisibility;

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
    dynamic readPath(dynamic source, String path) {
      if (source == null || path.trim().isEmpty) return null;
      dynamic cursor = source;
      for (final part in path.split('.')) {
        if (cursor is Map) {
          cursor = cursor[part];
        } else {
          return null;
        }
      }
      return cursor;
    }

    List<Map<String, dynamic>> parseDropdownData(dynamic value, String listKey) {
      if (value == null) return const [];
      if (value is Map) {
        final fromConfiguredPath = readPath(value, listKey);
        final candidates = [
          fromConfiguredPath,
          value[listKey],
          value['data'],
          value['results'],
          value['items'],
          value['users'],
          value['options'],
        ];
        for (final candidate in candidates) {
          if (candidate is List) {
            return parseDropdownData(candidate, '');
          }
        }
        return const [];
      }
      if (value is! List) return const [];
      return value.map<Map<String, dynamic>>((e) {
        if (e is Map) return Map<String, dynamic>.from(e);
        return <String, dynamic>{'value': e.toString()};
      }).toList();
    }

    List<Map<String, dynamic>> parseMapListValue(dynamic value) {
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    List<String> parseStringListValue(dynamic value) {
      if (value is! List) return const [];
      return value.map((item) => item.toString()).toList();
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

    final dropdownListKey = (j['dropdownListKey'] ??
            j['dropdownApiResponseKey'] ??
            j['responseListKey'] ??
            '')
        .toString();

    final dropdownData =
        parseDropdownData(j['dropdownData'] ?? j['dropdowndata'], dropdownListKey);

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
      dropdownKey: (j['dropdownKey'] ?? j['dropdownkey'] ?? '').toString(),
      dropdownLabelKey: (j['dropdownLabelKey'] ?? j['dropdownValue'] ?? 'name').toString(),
      dropdownValueKey: (j['dropdownValueKey'] ?? j['dropdownkey'] ?? j['dropdownKey'] ?? 'id').toString(),
      dropdownListKey: dropdownListKey,
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
      nestedFields: parseMapListValue(j['nestedFields'] ?? j['children'] ?? j['fields']),
      groupId: j['groupId']?.toString(),
      groupLabel: j['groupLabel']?.toString(),
      sectionId: j['sectionId']?.toString(),
      repeatableGroup: j['repeatableGroup'] == true,
      repeatConfig: j['repeatConfig'] is Map ? Map<String, dynamic>.from(j['repeatConfig'] as Map) : null,
      conditionalValidations: parseMapListValue(j['conditionalValidations']),
      formula: j['formula']?.toString(),
      expression: j['expression']?.toString(),
      asyncValidation: j['asyncValidation'] is Map ? Map<String, dynamic>.from(j['asyncValidation'] as Map) : null,
      cascadeConfig: j['cascadeConfig'] is Map ? Map<String, dynamic>.from(j['cascadeConfig'] as Map) : null,
      localization: j['localization'] is Map ? Map<String, dynamic>.from(j['localization'] as Map) : null,
      defaultValueExpression: j['defaultValueExpression']?.toString() ?? j['dynamicDefaultValue']?.toString(),
      visibleForRoles: parseStringListValue(j['visibleForRoles']),
      editableForRoles: parseStringListValue(j['editableForRoles']),
      roleVisibility: j['roleVisibility'] is Map ? Map<String, dynamic>.from(j['roleVisibility'] as Map) : null,
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
