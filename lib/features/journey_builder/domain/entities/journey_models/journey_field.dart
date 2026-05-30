import 'component_subclasses.dart';

abstract class JourneyField {
  String id;
  String label;
  String type; // kept as string for easy serialization and matching old code
  bool required;
  bool visible;
  bool readOnly;
  String? placeholder;
  String? hintText;
  String? errorMessage;
  bool disable;
  bool hidden;
  
  Map<String, dynamic>? visibleIf;
  List<Map<String, dynamic>>? conditionalValidations;
  Map<String, dynamic>? asyncValidation;
  String? validationPattern;
  String? dependsOn;
  List<String>? visibleForRoles;
  List<String>? editableForRoles;

  // Catch-all parameters for subclass support
  List<JourneyField>? nestedFields;
  String? defaultValue;
  List<String>? options;
  bool useStaticOptions = false;
  List<Map<String, String>>? staticOptions;
  String? dropdownApiUrl;
  String? dropdownApiMethod;
  Map<String, dynamic>? dropdownApiHeaders;
  String? dropdownApiBody;
  String? dropdownkey;
  String? dropdownValue;
  dynamic dropdowndata;
  String? dropdownApiResponseKey;
  String? dropdownListKey;
  String? apiParam;
  Map<String, dynamic>? componentConfig;
  String? fieldtype;
  int? maxLength;
  int? minLength;
  String? keyboardType;
  String? textInputAction;
  String? textCapitalization;
  bool obscureText = false;
  bool autocorrect = true;
  bool enableSuggestions = true;
  String? formula;
  bool repeatableGroup = false;
  Map<String, dynamic>? repeatConfig;
  String? groupId;
  String? sectionId;
  String? expression;
  String? defaultValueExpression;
  Map<String, dynamic>? cascadeConfig;
  Map<String, dynamic>? localization;

  JourneyField({
    required this.id,
    required this.label,
    required this.type,
    this.required = false,
    this.visible = true,
    this.readOnly = false,
    this.placeholder,
    this.hintText,
    this.errorMessage,
    this.disable = false,
    this.hidden = false,
    this.visibleIf,
    this.conditionalValidations,
    this.asyncValidation,
    this.validationPattern,
    this.dependsOn,
    this.visibleForRoles,
    this.editableForRoles,
    
    this.nestedFields,
    this.defaultValue,
    this.options,
    this.useStaticOptions = false,
    this.staticOptions,
    this.dropdownApiUrl,
    this.dropdownApiMethod,
    this.dropdownApiHeaders,
    this.dropdownApiBody,
    this.dropdownkey,
    this.dropdownValue,
    this.dropdowndata,
    this.dropdownApiResponseKey,
    this.dropdownListKey,
    this.apiParam,
    this.componentConfig,
    this.fieldtype,
    this.maxLength,
    this.minLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.formula,
    this.repeatableGroup = false,
    this.repeatConfig,
    this.groupId,
    this.sectionId,
    this.expression,
    this.defaultValueExpression,
    this.cascadeConfig,
    this.localization,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (groupId != null) 'groupId': groupId,
      if (sectionId != null) 'sectionId': sectionId,
      if (expression != null) 'expression': expression,
      if (defaultValueExpression != null) 'defaultValueExpression': defaultValueExpression,
      if (cascadeConfig != null) 'cascadeConfig': cascadeConfig,
      if (localization != null) 'localization': localization,
      'label': label,
      'type': type,
      'required': required,
      'visible': visible,
      'readOnly': readOnly,
      if (placeholder != null) 'placeholder': placeholder,
      if (hintText != null) 'hintText': hintText,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'disable': disable,
      'hidden': hidden,
      if (visibleIf != null) 'visibleIf': visibleIf,
      if (conditionalValidations != null) 'conditionalValidations': conditionalValidations,
      if (asyncValidation != null) 'asyncValidation': asyncValidation,
      if (validationPattern != null) 'validationPattern': validationPattern,
      if (dependsOn != null) 'dependsOn': dependsOn,
      if (visibleForRoles != null) 'visibleForRoles': visibleForRoles,
      if (editableForRoles != null) 'editableForRoles': editableForRoles,
      
      if (nestedFields != null) 'nestedFields': nestedFields!.map((f) => f.toJson()).toList(),
      if (defaultValue != null) 'defaultValue': defaultValue,
      if (options != null) 'options': options,
      'useStaticOptions': useStaticOptions,
      if (staticOptions != null) 'staticOptions': staticOptions,
      if (dropdownApiUrl != null) 'dropdownApiUrl': dropdownApiUrl,
      if (dropdownApiMethod != null) 'dropdownApiMethod': dropdownApiMethod,
      if (dropdownApiHeaders != null) 'dropdownApiHeaders': dropdownApiHeaders,
      if (dropdownApiBody != null) 'dropdownApiBody': dropdownApiBody,
      if (dropdownkey != null) 'dropdownkey': dropdownkey,
      if (dropdownValue != null) 'dropdownValue': dropdownValue,
      if (dropdowndata != null) 'dropdowndata': dropdowndata,
      if (dropdownApiResponseKey != null) 'dropdownApiResponseKey': dropdownApiResponseKey,
      if (dropdownListKey != null) 'dropdownListKey': dropdownListKey,
      if (apiParam != null) 'apiParam': apiParam,
      if (componentConfig != null) 'componentConfig': componentConfig,
      if (fieldtype != null) 'fieldtype': fieldtype,
      if (maxLength != null) 'maxLength': maxLength,
      if (minLength != null) 'minLength': minLength,
      if (keyboardType != null) 'keyboardType': keyboardType,
      if (textInputAction != null) 'textInputAction': textInputAction,
      if (textCapitalization != null) 'textCapitalization': textCapitalization,
      'obscureText': obscureText,
      'autocorrect': autocorrect,
      'enableSuggestions': enableSuggestions,
      if (formula != null) 'formula': formula,
      'repeatableGroup': repeatableGroup,
      if (repeatConfig != null) 'repeatConfig': repeatConfig,
    };
  }

  JourneyField copyWith({
    String? id,
    String? label,
    String? type,
    bool? required,
    bool? visible,
    bool? readOnly,
    String? placeholder,
    String? hintText,
    String? errorMessage,
    bool? disable,
    bool? hidden,
    List<JourneyField>? nestedFields,
  }) {
    final map = toJson();
    if (id != null) map['id'] = id;
    if (label != null) map['label'] = label;
    if (type != null) map['type'] = type;
    if (required != null) map['required'] = required;
    if (visible != null) map['visible'] = visible;
    if (readOnly != null) map['readOnly'] = readOnly;
    if (placeholder != null) map['placeholder'] = placeholder;
    if (hintText != null) map['hintText'] = hintText;
    if (errorMessage != null) map['errorMessage'] = errorMessage;
    if (disable != null) map['disable'] = disable;
    if (hidden != null) map['hidden'] = hidden;
    if (nestedFields != null) map['nestedFields'] = nestedFields.map((f) => f.toJson()).toList();
    return JourneyField.fromJson(map);
  }

  factory JourneyField.fromJson(Map<String, dynamic> json) {
    String t = json['type'] ?? 'text';
    switch (t) {
      case 'section':
      case 'card':
      case 'tabs':
      case 'accordion':
      case 'row':
      case 'column':
        return LayoutComponent.fromJson(json);
      case 'dropdown':
      case 'api_dropdown':
      case 'radio':
      case 'checkbox':
      case 'switch':
      case 'multi_select':
        return OptionsComponent.fromJson(json);
      case 'table_grid':
        return GridComponent.fromJson(json);
      case 'repeater':
        return RepeaterComponent.fromJson(json);
      default:
        return InputComponent.fromJson(json);
    }
  }

  List<String> getResolvedOptions() {
    if (useStaticOptions && staticOptions != null) {
      return staticOptions!.map((opt) => opt['value'] ?? '').where((val) => val.isNotEmpty).toList();
    }
    if (!useStaticOptions && dropdowndata != null) {
      final key = dropdownValue ?? 'title';
      List<dynamic> listToParse = [];
      if (dropdowndata is List) {
        listToParse = dropdowndata;
      } else if (dropdowndata is Map) {
        final responseKey = dropdownListKey ?? dropdownApiResponseKey;
        if (responseKey != null && responseKey.isNotEmpty && dropdowndata[responseKey] is List) {
          listToParse = dropdowndata[responseKey];
        } else {
          final keysToTry = ['data', 'results', 'items', 'users', 'options'];
          for (var k in keysToTry) {
            if (dropdowndata[k] is List) {
              listToParse = dropdowndata[k];
              break;
            }
          }
        }
      }
      
      final List<String> resolved = [];
      for (var item in listToParse) {
        if (item is String) {
          resolved.add(item);
        } else if (item is num || item is bool) {
          resolved.add(item.toString());
        } else if (item is Map) {
          if (item.containsKey(key) && item[key] != null) {
            resolved.add(item[key].toString());
          } else {
            final keysToTry = ['title', 'name', 'value', 'label', 'text'];
            for (var k in keysToTry) {
              if (item.containsKey(k) && item[k] != null) {
                resolved.add(item[k].toString());
                break;
              }
            }
          }
        }
      }
      return resolved.where((val) => val.isNotEmpty).toList();
    }
    return options ?? [];
  }
}
