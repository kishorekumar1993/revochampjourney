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

class JourneyField {
  String id;
  String label;
  String type; // text, textarea, dropdown, api_dropdown, radio, checkbox, switch, date, time, datetime, file, image, otp, phone, slider, stepper, rating, signature, rich_text, multi_select, repeater, address, divider
  bool required;
  bool visible;
  bool readOnly;
  String? placeholder;
  List<String>? options;
  Map<String, dynamic>? visibleIf;
  String? defaultValue;
  String? apiUrl;

  // Additional design parameters
  bool useStaticOptions;
  List<Map<String, String>>? staticOptions;
  String? fieldtype;
  String? hintText;
  int? maxLength;
  int? minLength;
  bool disable;
  bool hidden;
  String? apiParam;
  bool api;
  String? dropdownApiUrl;
  String? dropdownApiMethod;
  Map<String, dynamic>? dropdownApiHeaders;
  String? dropdownApiBody;
  String? dropdownkey;
  String? dropdownValue;
  dynamic dropdowndata;
  String? dropdownApiResponseKey;
  String? validationPattern;
  String? errorMessage;
  bool obscureText;
  bool autocorrect;
  bool enableSuggestions;
  String? keyboardType;
  String? textInputAction;
  String? textCapitalization;

  JourneyField({
    required this.id,
    required this.label,
    required this.type,
    this.required = false,
    this.visible = true,
    this.readOnly = false,
    this.placeholder,
    this.options,
    this.visibleIf,
    this.defaultValue,
    this.apiUrl,
    this.useStaticOptions = false,
    this.staticOptions,
    this.fieldtype,
    this.hintText,
    this.maxLength,
    this.minLength,
    this.disable = false,
    this.hidden = false,
    this.apiParam,
    this.api = false,
    this.dropdownApiUrl,
    this.dropdownApiMethod,
    this.dropdownApiHeaders,
    this.dropdownApiBody,
    this.dropdownkey,
    this.dropdownValue,
    this.dropdowndata,
    this.dropdownApiResponseKey,
    this.validationPattern,
    this.errorMessage,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization,
  });

  factory JourneyField.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse staticOptions list of maps
    List<Map<String, String>>? parsedStaticOptions;
    if (json['staticOptions'] != null && json['staticOptions'] is List) {
      parsedStaticOptions = [];
      for (var item in json['staticOptions']) {
        if (item is Map) {
          parsedStaticOptions.add({
            'key': item['key']?.toString() ?? '',
            'value': item['value']?.toString() ?? '',
          });
        }
      }
    }

    return JourneyField(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      type: json['type'] ?? 'text',
      required: json['required'] ?? false,
      visible: json['visible'] ?? true,
      readOnly: json['readOnly'] ?? false,
      placeholder: json['placeholder'] ?? json['hintText'],
      options: json['options'] != null ? List<String>.from(json['options']) : null,
      visibleIf: json['visibleIf'] != null ? Map<String, dynamic>.from(json['visibleIf']) : null,
      defaultValue: json['defaultValue']?.toString() ?? json['initialValue']?.toString(),
      apiUrl: json['apiUrl']?.toString() ?? json['dropdownApiUrl']?.toString(),
      
      useStaticOptions: json['useStaticOptions'] ?? false,
      staticOptions: parsedStaticOptions,
      fieldtype: json['fieldtype']?.toString(),
      hintText: json['hintText']?.toString(),
      maxLength: json['maxLength'] is int ? json['maxLength'] : int.tryParse(json['maxLength']?.toString() ?? ''),
      minLength: json['minLength'] is int ? json['minLength'] : int.tryParse(json['minLength']?.toString() ?? ''),
      disable: json['disable'] ?? false,
      hidden: json['hidden'] ?? false,
      apiParam: json['apiParam']?.toString(),
      api: json['api'] ?? false,
      dropdownApiUrl: json['dropdownApiUrl']?.toString(),
      dropdownApiMethod: json['dropdownApiMethod']?.toString(),
      dropdownApiHeaders: json['dropdownApiHeaders'] != null ? Map<String, dynamic>.from(json['dropdownApiHeaders']) : null,
      dropdownApiBody: json['dropdownApiBody']?.toString(),
      dropdownkey: json['dropdownkey']?.toString(),
      dropdownValue: json['dropdownValue']?.toString(),
      // dropdowndata: json['dropdowndata'],
      // Safe — normalize immediately at parse time
dropdowndata: json['dropdowndata'] is List
    ? (json['dropdowndata'] as List)
        .map((e) => e is Map ? Map<String, dynamic>.from(e) : e)
        .toList()
    : json['dropdowndata'],

      dropdownApiResponseKey: json['dropdownApiResponseKey']?.toString() ?? json['responseListKey']?.toString(),
      validationPattern: json['validationPattern']?.toString(),
      errorMessage: json['errorMessage']?.toString(),
      obscureText: json['obscureText'] ?? false,
      autocorrect: json['autocorrect'] ?? true,
      enableSuggestions: json['enableSuggestions'] ?? true,
      keyboardType: json['keyboardType']?.toString(),
      textInputAction: json['textInputAction']?.toString(),
      textCapitalization: json['textCapitalization']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type,
      'required': required,
      'visible': visible,
      'readOnly': readOnly,
      if (placeholder != null) 'placeholder': placeholder,
      if (options != null) 'options': options,
      if (visibleIf != null) 'visibleIf': visibleIf,
      if (defaultValue != null) 'defaultValue': defaultValue,
      if (apiUrl != null) 'apiUrl': apiUrl,
      
      'useStaticOptions': useStaticOptions,
      if (staticOptions != null) 'staticOptions': staticOptions,
      if (fieldtype != null) 'fieldtype': fieldtype,
      if (hintText != null) 'hintText': hintText,
      if (maxLength != null) 'maxLength': maxLength,
      if (minLength != null) 'minLength': minLength,
      'disable': disable,
      'hidden': hidden,
      if (apiParam != null) 'apiParam': apiParam,
      'api': api,
      if (dropdownApiUrl != null) 'dropdownApiUrl': dropdownApiUrl,
      if (dropdownApiMethod != null) 'dropdownApiMethod': dropdownApiMethod,
      if (dropdownApiHeaders != null) 'dropdownApiHeaders': dropdownApiHeaders,
      if (dropdownApiBody != null) 'dropdownApiBody': dropdownApiBody,
      if (dropdownkey != null) 'dropdownkey': dropdownkey,
      if (dropdownValue != null) 'dropdownValue': dropdownValue,
      if (dropdowndata != null) 'dropdowndata': dropdowndata,
      if (dropdownApiResponseKey != null) 'dropdownApiResponseKey': dropdownApiResponseKey,
      if (validationPattern != null) 'validationPattern': validationPattern,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'obscureText': obscureText,
      'autocorrect': autocorrect,
      'enableSuggestions': enableSuggestions,
      if (keyboardType != null) 'keyboardType': keyboardType,
      if (textInputAction != null) 'textInputAction': textInputAction,
      if (textCapitalization != null) 'textCapitalization': textCapitalization,
    };
  }

  JourneyField copy() {
    return JourneyField(
      id: id,
      label: label,
      type: type,
      required: required,
      visible: visible,
      readOnly: readOnly,
      placeholder: placeholder,
      options: options != null ? List<String>.from(options!) : null,
      visibleIf: visibleIf != null ? Map<String, dynamic>.from(visibleIf!) : null,
      defaultValue: defaultValue,
      apiUrl: apiUrl,
      
      useStaticOptions: useStaticOptions,
      staticOptions: staticOptions?.map((item) => Map<String, String>.from(item)).toList(),
      fieldtype: fieldtype,
      hintText: hintText,
      maxLength: maxLength,
      minLength: minLength,
      disable: disable,
      hidden: hidden,
      apiParam: apiParam,
      api: api,
      dropdownApiUrl: dropdownApiUrl,
      dropdownApiMethod: dropdownApiMethod,
      dropdownApiHeaders: dropdownApiHeaders != null ? Map<String, dynamic>.from(dropdownApiHeaders!) : null,
      dropdownApiBody: dropdownApiBody,
      dropdownkey: dropdownkey,
      dropdownValue: dropdownValue,
      dropdowndata: dropdowndata,
      dropdownApiResponseKey: dropdownApiResponseKey,
      validationPattern: validationPattern,
      errorMessage: errorMessage,
      obscureText: obscureText,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
    );
  }

  List<String> getResolvedOptions() {
    if (useStaticOptions && staticOptions != null) {
      return staticOptions!.map((opt) => opt['value'] ?? '').where((val) => val.isNotEmpty).toList();
    }
    if (!useStaticOptions && dropdowndata != null) {
      final key = dropdownValue ?? 'title';
      
      // Extract option list from dropdowndata (which could be List or Map)
      List<dynamic> listToParse = [];
      if (dropdowndata is List) {
        listToParse = dropdowndata;
      } else if (dropdowndata is Map) {
        final responseKey = dropdownApiResponseKey;
        if (responseKey != null && responseKey.isNotEmpty && dropdowndata[responseKey] is List) {
          listToParse = dropdowndata[responseKey];
        } else {
          // Fallback to standard nested keys
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
            // Try standard display keys as fallback if key is not found
            final keysToTry = ['title', 'name', 'value', 'label', 'text'];
            String? found;
            for (var k in keysToTry) {
              if (item.containsKey(k) && item[k] != null) {
                found = item[k].toString();
                break;
              }
            }
            if (found == null && item.isNotEmpty) {
              found = item.values.first.toString();
            }
            if (found != null) {
              resolved.add(found);
            }
          }
        }
      }
      return resolved.where((val) => val.isNotEmpty).toList();
    }
    return options ?? [];
  }
}

class StepValidation {
  String type; // required, regex, async, dependency
  String field;
  String message;
  String? regexPattern;
  String? validationUrl;
  String? dependentField;
  String? dependentValue;

  StepValidation({
    required this.type,
    required this.field,
    required this.message,
    this.regexPattern,
    this.validationUrl,
    this.dependentField,
    this.dependentValue,
  });

  factory StepValidation.fromJson(Map<String, dynamic> json) {
    return StepValidation(
      type: json['type'] ?? 'required',
      field: json['field'] ?? '',
      message: json['message'] ?? 'Validation failed',
      regexPattern: json['regexPattern'],
      validationUrl: json['validationUrl'],
      dependentField: json['dependentField'],
      dependentValue: json['dependentValue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'field': field,
      'message': message,
      if (regexPattern != null) 'regexPattern': regexPattern,
      if (validationUrl != null) 'validationUrl': validationUrl,
      if (dependentField != null) 'dependentField': dependentField,
      if (dependentValue != null) 'dependentValue': dependentValue,
    };
  }

  StepValidation copy() {
    return StepValidation(
      type: type,
      field: field,
      message: message,
      regexPattern: regexPattern,
      validationUrl: validationUrl,
      dependentField: dependentField,
      dependentValue: dependentValue,
    );
  }
}

class StepCondition {
  String type; // showIf, enableIf, visibleIf, nextStepIf
  String field;
  String operator; // equals, notEquals, contains
  String value;
  String? targetStep; // for nextStepIf

  StepCondition({
    required this.type,
    required this.field,
    required this.operator,
    required this.value,
    this.targetStep,
  });

  factory StepCondition.fromJson(Map<String, dynamic> json) {
    return StepCondition(
      type: json['type'] ?? 'visibleIf',
      field: json['field'] ?? '',
      operator: json['operator'] ?? 'equals',
      value: json['value']?.toString() ?? '',
      targetStep: json['targetStep'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'field': field,
      'operator': operator,
      'value': value,
      if (targetStep != null) 'targetStep': targetStep,
    };
  }

  StepCondition copy() {
    return StepCondition(
      type: type,
      field: field,
      operator: operator,
      value: value,
      targetStep: targetStep,
    );
  }
}

class StepAPI {
  String method; // GET, POST, PUT, DELETE
  String url;
  String description;
  Map<String, dynamic>? headers;
  String? body;

  StepAPI({
    required this.method,
    required this.url,
    required this.description,
    this.headers,
    this.body,
  });

  factory StepAPI.fromJson(Map<String, dynamic> json) {
    return StepAPI(
      method: json['method'] ?? 'GET',
      url: json['url'] ?? '',
      description: json['description'] ?? '',
      headers: json['headers'] != null ? Map<String, dynamic>.from(json['headers']) : null,
      body: json['body']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'url': url,
      'description': description,
      if (headers != null) 'headers': headers,
      if (body != null) 'body': body,
    };
  }

  StepAPI copy() {
    return StepAPI(
      method: method,
      url: url,
      description: description,
      headers: headers != null ? Map<String, dynamic>.from(headers!) : null,
      body: body,
    );
  }
}

class StepAction {
  String trigger; // onSubmit, onFieldChange
  String actionType; // apiCall, navigate, showBanner
  String details;

  StepAction({
    required this.trigger,
    required this.actionType,
    required this.details,
  });

  factory StepAction.fromJson(Map<String, dynamic> json) {
    return StepAction(
      trigger: json['trigger'] ?? 'onSubmit',
      actionType: json['actionType'] ?? 'showBanner',
      details: json['details'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trigger': trigger,
      'actionType': actionType,
      'details': details,
    };
  }

  StepAction copy() {
    return StepAction(
      trigger: trigger,
      actionType: actionType,
      details: details,
    );
  }
}
