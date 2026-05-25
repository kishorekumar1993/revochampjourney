import 'dart:convert';

enum ComponentType {
  text, textarea, number, dropdown, api_dropdown, radio, checkbox, switchType, date, time, datetime, file, image, otp, phone, multi_select, table_grid, repeater, timeline, row, column, section, card, tabs, accordion, divider, formula, unknown
}

class JourneyConfig {
  String journeyName;
  String version;
  String description;
  String category;
  String locale;
  String platform;
  List<JourneyStep> steps;

  JourneyConfig({
    required this.journeyName,
    required this.version,
    this.description = '',
    this.category = 'Onboarding',
    this.locale = 'English (US)',
    this.platform = 'All Devices',
    required this.steps,
  });

  factory JourneyConfig.fromJson(Map<String, dynamic> json) {
    var stepsList = json['steps'] as List? ?? [];
    return JourneyConfig(
      journeyName: json['journeyName'] ?? 'Unnamed Journey',
      version: json['version'] ?? '1.0.0',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Onboarding',
      locale: json['locale'] ?? 'English (US)',
      platform: json['platform'] ?? 'All Devices',
      steps: stepsList.map((step) => JourneyStep.fromJson(step)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'journeyName': journeyName,
      'version': version,
      'description': description,
      'category': category,
      'locale': locale,
      'platform': platform,
      'steps': steps.map((step) => step.toJson()).toList(),
    };
  }

  JourneyConfig copyWith({
    String? journeyName,
    String? version,
    String? description,
    String? category,
    String? locale,
    String? platform,
    List<JourneyStep>? steps,
  }) {
    return JourneyConfig(
      journeyName: journeyName ?? this.journeyName,
      version: version ?? this.version,
      description: description ?? this.description,
      category: category ?? this.category,
      locale: locale ?? this.locale,
      platform: platform ?? this.platform,
      steps: steps ?? this.steps.map((s) => s.copy()).toList(),
    );
  }
}

class JourneyStep {
  String id;
  String title;
  String description;
  String? nextStep;
  List<JourneyField> fields;
  List<StepValidation> validations;
  List<StepCondition> conditions;
  List<StepAPI> apiCalls;
  List<StepAction> actions;

  JourneyStep({
    required this.id,
    required this.title,
    this.description = '',
    this.nextStep,
    required this.fields,
    this.validations = const [],
    this.conditions = const [],
    this.apiCalls = const [],
    this.actions = const [],
  });

  factory JourneyStep.fromJson(Map<String, dynamic> json) {
    var fieldsList = json['fields'] as List? ?? [];
    var validationsList = json['validations'] as List? ?? [];
    var conditionsList = json['conditions'] as List? ?? [];
    var apiCallsList = json['apiCalls'] as List? ?? [];
    var actionsList = json['actions'] as List? ?? [];

    return JourneyStep(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      nextStep: json['nextStep'],
      fields: fieldsList.map((field) => JourneyField.fromJson(field)).toList(),
      validations: validationsList.map((val) => StepValidation.fromJson(val)).toList(),
      conditions: conditionsList.map((cond) => StepCondition.fromJson(cond)).toList(),
      apiCalls: apiCallsList.map((api) => StepAPI.fromJson(api)).toList(),
      actions: actionsList.map((act) => StepAction.fromJson(act)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      if (nextStep != null) 'nextStep': nextStep,
      'fields': fields.map((field) => field.toJson()).toList(),
      'validations': validations.map((v) => v.toJson()).toList(),
      'conditions': conditions.map((c) => c.toJson()).toList(),
      'apiCalls': apiCalls.map((a) => a.toJson()).toList(),
      'actions': actions.map((a) => a.toJson()).toList(),
    };
  }

  JourneyStep copy() {
    return JourneyStep(
      id: id,
      title: title,
      description: description,
      nextStep: nextStep,
      fields: fields.map((f) => f.copy()).toList(),
      validations: validations.map((v) => v.copy()).toList(),
      conditions: conditions.map((c) => c.copy()).toList(),
      apiCalls: apiCalls.map((a) => a.copy()).toList(),
      actions: actions.map((a) => a.copy()).toList(),
    );
  }
}

// --------------------------------------------------------------------------
// BASE COMPONENT (Previously God-Class JourneyField)
// --------------------------------------------------------------------------
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

  // The below are legacy catch-alls to prevent immediate breaking changes in properties_panel
  // Subclasses that actually use these will override them.
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
    
    // Legacy mapping (will be overridden by subclasses)
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
      
      // Legacy exports
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

  JourneyField copy() {
    return JourneyField.fromJson(toJson());
  }

  factory JourneyField.fromJson(Map<String, dynamic> json) {
    String t = json['type'] ?? 'text';
    // Instead of instantiating the abstract base, we now instantiate the God-class temporarily
    // until we fully migrate to subclasses. Wait, the user wants a true tree based structure.
    // I will return a Concrete Component depending on type.
    
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
        if (item is String) resolved.add(item);
        else if (item is num || item is bool) resolved.add(item.toString());
        else if (item is Map) {
          if (item.containsKey(key) && item[key] != null) resolved.add(item[key].toString());
          else {
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

// --------------------------------------------------------------------------
// COMPONENT SUBCLASSES
// --------------------------------------------------------------------------

class InputComponent extends JourneyField {
  InputComponent({
    required super.id, required super.label, required super.type,
    super.required, super.visible, super.readOnly, super.placeholder,
    super.hintText, super.errorMessage, super.disable, super.hidden,
    super.visibleIf, super.conditionalValidations, super.asyncValidation,
    super.validationPattern, super.dependsOn, super.visibleForRoles, super.editableForRoles,
    
    super.groupId, super.sectionId, super.expression, super.defaultValueExpression, super.cascadeConfig, super.localization,
    super.defaultValue, super.fieldtype, super.maxLength, super.minLength,
    super.keyboardType, super.textInputAction, super.textCapitalization,
    super.obscureText, super.autocorrect, super.enableSuggestions, super.formula,
  });

  factory InputComponent.fromJson(Map<String, dynamic> json) {
    return InputComponent(
      id: json['id'] ?? '', label: json['label'] ?? '', type: json['type'] ?? 'text',
      required: json['required'] ?? false, visible: json['visible'] ?? true,
      readOnly: json['readOnly'] ?? false, placeholder: json['placeholder'],
      hintText: json['hintText'], errorMessage: json['errorMessage'],
      disable: json['disable'] ?? false, hidden: json['hidden'] ?? false,
      visibleIf: json['visibleIf'], conditionalValidations: _parseMapList(json['conditionalValidations']),
      asyncValidation: json['asyncValidation'], validationPattern: json['validationPattern'],
      dependsOn: json['dependsOn'], visibleForRoles: _parseStringList(json['visibleForRoles']),
      editableForRoles: _parseStringList(json['editableForRoles']),
      
      defaultValue: json['defaultValue']?.toString() ?? json['initialValue']?.toString(),
      groupId: json['groupId'], sectionId: json['sectionId'], expression: json['expression'],
      defaultValueExpression: json['defaultValueExpression'], cascadeConfig: json['cascadeConfig'],
      localization: json['localization'],
      fieldtype: json['fieldtype'], maxLength: _parseInt(json['maxLength']),
      minLength: _parseInt(json['minLength']), keyboardType: json['keyboardType'],
      textInputAction: json['textInputAction'], textCapitalization: json['textCapitalization'],
      obscureText: json['obscureText'] ?? false, autocorrect: json['autocorrect'] ?? true,
      enableSuggestions: json['enableSuggestions'] ?? true, formula: json['formula'],
    );
  }
}

class OptionsComponent extends JourneyField {
  OptionsComponent({
    required super.id, required super.label, required super.type,
    super.required, super.visible, super.readOnly, super.placeholder,
    super.hintText, super.errorMessage, super.disable, super.hidden,
    super.visibleIf, super.conditionalValidations, super.asyncValidation,
    super.validationPattern, super.dependsOn, super.visibleForRoles, super.editableForRoles,
    
    super.groupId, super.sectionId, super.expression, super.defaultValueExpression, super.cascadeConfig, super.localization,
    super.options, super.useStaticOptions, super.staticOptions,
    super.dropdownApiUrl, super.dropdownApiMethod, super.dropdownApiHeaders,
    super.dropdownApiBody, super.dropdownkey, super.dropdownValue, super.dropdowndata,
    super.dropdownApiResponseKey, super.dropdownListKey, super.apiParam, super.defaultValue,
  });

  factory OptionsComponent.fromJson(Map<String, dynamic> json) {
    return OptionsComponent(
      id: json['id'] ?? '', label: json['label'] ?? '', type: json['type'] ?? 'dropdown',
      required: json['required'] ?? false, visible: json['visible'] ?? true,
      readOnly: json['readOnly'] ?? false, placeholder: json['placeholder'],
      hintText: json['hintText'], errorMessage: json['errorMessage'],
      disable: json['disable'] ?? false, hidden: json['hidden'] ?? false,
      visibleIf: json['visibleIf'], conditionalValidations: _parseMapList(json['conditionalValidations']),
      asyncValidation: json['asyncValidation'], validationPattern: json['validationPattern'],
      dependsOn: json['dependsOn'], visibleForRoles: _parseStringList(json['visibleForRoles']),
      editableForRoles: _parseStringList(json['editableForRoles']),
      
      options: _parseStringList(json['options']),
      useStaticOptions: json['useStaticOptions'] ?? false,
      staticOptions: _parseStringMapList(json['staticOptions']),
      dropdownApiUrl: json['dropdownApiUrl'] ?? json['apiUrl'],
      dropdownApiMethod: json['dropdownApiMethod'],
      dropdownApiHeaders: json['dropdownApiHeaders'],
      dropdownApiBody: json['dropdownApiBody'],
      dropdownkey: json['dropdownkey'] ?? json['dropdownKey'] ?? json['dropdownValueKey'],
      dropdownValue: json['dropdownValue'] ?? json['dropdownLabelKey'],
      dropdowndata: json['dropdowndata'] is List ? List.from(json['dropdowndata']) : json['dropdowndata'],
      dropdownApiResponseKey: json['dropdownApiResponseKey'] ?? json['responseListKey'],
      dropdownListKey: json['dropdownListKey'],
      apiParam: json['apiParam'],
      defaultValue: json['defaultValue']?.toString(),
    );
  }
}

class LayoutComponent extends JourneyField {
  LayoutComponent({
    required super.id, required super.label, required super.type,
    super.required, super.visible, super.readOnly, super.placeholder,
    super.hintText, super.errorMessage, super.disable, super.hidden,
    super.visibleIf, super.conditionalValidations, super.asyncValidation,
    super.validationPattern, super.dependsOn, super.visibleForRoles, super.editableForRoles,
    
    super.nestedFields, super.componentConfig,
  });

  factory LayoutComponent.fromJson(Map<String, dynamic> json) {
    return LayoutComponent(
      id: json['id'] ?? '', label: json['label'] ?? '', type: json['type'] ?? 'section',
      required: json['required'] ?? false, visible: json['visible'] ?? true,
      readOnly: json['readOnly'] ?? false, placeholder: json['placeholder'],
      hintText: json['hintText'], errorMessage: json['errorMessage'],
      disable: json['disable'] ?? false, hidden: json['hidden'] ?? false,
      visibleIf: json['visibleIf'], conditionalValidations: _parseMapList(json['conditionalValidations']),
      asyncValidation: json['asyncValidation'], validationPattern: json['validationPattern'],
      dependsOn: json['dependsOn'], visibleForRoles: _parseStringList(json['visibleForRoles']),
      editableForRoles: _parseStringList(json['editableForRoles']),
      
      nestedFields: _parseNestedFields(json['nestedFields'] ?? json['children'] ?? json['fields']),
      componentConfig: json['componentConfig'],
    );
  }
}

class GridComponent extends JourneyField {
  GridComponent({
    required super.id, required super.label, required super.type,
    super.required, super.visible, super.readOnly, super.placeholder,
    super.hintText, super.errorMessage, super.disable, super.hidden,
    super.visibleIf, super.conditionalValidations, super.asyncValidation,
    super.validationPattern, super.dependsOn, super.visibleForRoles, super.editableForRoles,
    
    super.nestedFields, super.componentConfig,
  });

  factory GridComponent.fromJson(Map<String, dynamic> json) {
    return GridComponent(
      id: json['id'] ?? '', label: json['label'] ?? '', type: json['type'] ?? 'table_grid',
      required: json['required'] ?? false, visible: json['visible'] ?? true,
      readOnly: json['readOnly'] ?? false, placeholder: json['placeholder'],
      hintText: json['hintText'], errorMessage: json['errorMessage'],
      disable: json['disable'] ?? false, hidden: json['hidden'] ?? false,
      visibleIf: json['visibleIf'], conditionalValidations: _parseMapList(json['conditionalValidations']),
      asyncValidation: json['asyncValidation'], validationPattern: json['validationPattern'],
      dependsOn: json['dependsOn'], visibleForRoles: _parseStringList(json['visibleForRoles']),
      editableForRoles: _parseStringList(json['editableForRoles']),
      
      nestedFields: _parseNestedFields(json['nestedFields'] ?? json['children'] ?? json['fields']),
      componentConfig: json['componentConfig'],
    );
  }
}

class RepeaterComponent extends JourneyField {
  RepeaterComponent({
    required super.id, required super.label, required super.type,
    super.required, super.visible, super.readOnly, super.placeholder,
    super.hintText, super.errorMessage, super.disable, super.hidden,
    super.visibleIf, super.conditionalValidations, super.asyncValidation,
    super.validationPattern, super.dependsOn, super.visibleForRoles, super.editableForRoles,
    
    super.groupId, super.sectionId, super.expression, super.defaultValueExpression, super.cascadeConfig, super.localization,
    super.nestedFields, super.repeatableGroup, super.repeatConfig,
  });

  factory RepeaterComponent.fromJson(Map<String, dynamic> json) {
    return RepeaterComponent(
      id: json['id'] ?? '', label: json['label'] ?? '', type: json['type'] ?? 'repeater',
      required: json['required'] ?? false, visible: json['visible'] ?? true,
      readOnly: json['readOnly'] ?? false, placeholder: json['placeholder'],
      hintText: json['hintText'], errorMessage: json['errorMessage'],
      disable: json['disable'] ?? false, hidden: json['hidden'] ?? false,
      visibleIf: json['visibleIf'], conditionalValidations: _parseMapList(json['conditionalValidations']),
      asyncValidation: json['asyncValidation'], validationPattern: json['validationPattern'],
      dependsOn: json['dependsOn'], visibleForRoles: _parseStringList(json['visibleForRoles']),
      editableForRoles: _parseStringList(json['editableForRoles']),
      
      nestedFields: _parseNestedFields(json['nestedFields'] ?? json['children'] ?? json['fields']),
      repeatableGroup: json['repeatableGroup'] ?? true,
      repeatConfig: json['repeatConfig'],
      groupId: json['groupId'], sectionId: json['sectionId'], expression: json['expression'],
      defaultValueExpression: json['defaultValueExpression'], cascadeConfig: json['cascadeConfig'],
      localization: json['localization'],
    );
  }
}

// Validation & Condition helpers

class StepValidation {
  String type;
  String field;
  String message;
  String? regexPattern;
  String? validationUrl;
  String? dependentField;
  String? dependentValue;
  Map<String, dynamic>? condition;
  Map<String, dynamic>? request;
  String? expression;

  StepValidation({
    required this.type, required this.field, required this.message,
    this.regexPattern, this.validationUrl, this.dependentField,
    this.dependentValue, this.condition, this.request, this.expression,
  });

  factory StepValidation.fromJson(Map<String, dynamic> json) => StepValidation(
    type: json['type'] ?? 'required', field: json['field'] ?? '', message: json['message'] ?? '',
    regexPattern: json['regexPattern'], validationUrl: json['validationUrl'],
    dependentField: json['dependentField'], dependentValue: json['dependentValue'],
    condition: json['condition'], request: json['request'], expression: json['expression'],
  );

  Map<String, dynamic> toJson() => {
    'type': type, 'field': field, 'message': message, 'regexPattern': regexPattern,
    'validationUrl': validationUrl, 'dependentField': dependentField,
    'dependentValue': dependentValue, 'condition': condition, 'request': request, 'expression': expression,
  };

  StepValidation copy() => StepValidation.fromJson(toJson());
}

class StepCondition {
  String type;
  String field;
  String operator;
  String value;
  String? targetStep;

  StepCondition({
    required this.type, required this.field, required this.operator, required this.value, this.targetStep,
  });

  factory StepCondition.fromJson(Map<String, dynamic> json) => StepCondition(
    type: json['type'] ?? 'visibleIf', field: json['field'] ?? '',
    operator: json['operator'] ?? 'equals', value: json['value']?.toString() ?? '',
    targetStep: json['targetStep'],
  );

  Map<String, dynamic> toJson() => {
    'type': type, 'field': field, 'operator': operator, 'value': value, 'targetStep': targetStep,
  };

  StepCondition copy() => StepCondition.fromJson(toJson());
}

class StepAPI {
  String method, url, description;
  Map<String, dynamic>? headers;
  String? body;

  StepAPI({required this.method, required this.url, required this.description, this.headers, this.body});

  factory StepAPI.fromJson(Map<String, dynamic> json) => StepAPI(
    method: json['method'] ?? 'GET', url: json['url'] ?? '', description: json['description'] ?? '',
    headers: json['headers'], body: json['body']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'method': method, 'url': url, 'description': description, 'headers': headers, 'body': body,
  };

  StepAPI copy() => StepAPI.fromJson(toJson());
}

class StepAction {
  String trigger, actionType, details;

  StepAction({required this.trigger, required this.actionType, required this.details});

  factory StepAction.fromJson(Map<String, dynamic> json) => StepAction(
    trigger: json['trigger'] ?? 'onSubmit', actionType: json['actionType'] ?? '', details: json['details'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'trigger': trigger, 'actionType': actionType, 'details': details,
  };

  StepAction copy() => StepAction.fromJson(toJson());
}

// Parsers
List<String>? _parseStringList(dynamic value) {
  if (value is! List) return null;
  return value.map((e) => e.toString()).toList();
}
List<Map<String, dynamic>>? _parseMapList(dynamic value) {
  if (value is! List) return null;
  return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}
List<Map<String, String>>? _parseStringMapList(dynamic value) {
  if (value is! List) return null;
  return value.whereType<Map>().map((e) => {'key': e['key']?.toString() ?? '', 'value': e['value']?.toString() ?? ''}).toList();
}
List<JourneyField>? _parseNestedFields(dynamic value) {
  if (value is! List) return null;
  return value.whereType<Map>().map((e) => JourneyField.fromJson(Map<String, dynamic>.from(e))).toList();
}
int? _parseInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}
