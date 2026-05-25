import re

with open('lib/features/journey_builder/data/models.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add to constructor of InputComponent
content = content.replace('    super.defaultValue, super.fieldtype, super.maxLength, super.minLength,', '    super.groupId, super.sectionId, super.expression, super.defaultValueExpression, super.cascadeConfig, super.localization,\n    super.defaultValue, super.fieldtype, super.maxLength, super.minLength,')
# Add to InputComponent.fromJson
content = content.replace("      enableSuggestions: json['enableSuggestions'] ?? true, formula: json['formula'],", "      enableSuggestions: json['enableSuggestions'] ?? true, formula: json['formula'],\n      groupId: json['groupId'], sectionId: json['sectionId'], expression: json['expression'],\n      defaultValueExpression: json['defaultValueExpression'], cascadeConfig: json['cascadeConfig'],\n      localization: json['localization'],")

# Add to constructor of OptionsComponent
content = content.replace('    super.options, super.useStaticOptions, super.staticOptions,', '    super.groupId, super.sectionId, super.expression, super.defaultValueExpression, super.cascadeConfig, super.localization,\n    super.options, super.useStaticOptions, super.staticOptions,')
# Add to OptionsComponent.fromJson
content = content.replace("      defaultValue: json['defaultValue']?.toString() ?? json['initialValue']?.toString(),", "      defaultValue: json['defaultValue']?.toString() ?? json['initialValue']?.toString(),\n      groupId: json['groupId'], sectionId: json['sectionId'], expression: json['expression'],\n      defaultValueExpression: json['defaultValueExpression'], cascadeConfig: json['cascadeConfig'],\n      localization: json['localization'],")

# Add to constructor of LayoutComponent
content = content.replace('    super.nestedFields, super.repeatableGroup, super.repeatConfig,', '    super.groupId, super.sectionId, super.expression, super.defaultValueExpression, super.cascadeConfig, super.localization,\n    super.nestedFields, super.repeatableGroup, super.repeatConfig,')
# Add to LayoutComponent.fromJson
content = content.replace("      repeatConfig: json['repeatConfig'],", "      repeatConfig: json['repeatConfig'],\n      groupId: json['groupId'], sectionId: json['sectionId'], expression: json['expression'],\n      defaultValueExpression: json['defaultValueExpression'], cascadeConfig: json['cascadeConfig'],\n      localization: json['localization'],")

# Add to constructor of ComplexComponent
content = content.replace('    super.componentConfig, super.nestedFields,', '    super.groupId, super.sectionId, super.expression, super.defaultValueExpression, super.cascadeConfig, super.localization,\n    super.componentConfig, super.nestedFields,')
# Add to ComplexComponent.fromJson
content = content.replace("      nestedFields: nestedList.map((f) => BaseComponent.fromJson(f)).toList(),", "      nestedFields: nestedList.map((f) => BaseComponent.fromJson(f)).toList(),\n      groupId: json['groupId'], sectionId: json['sectionId'], expression: json['expression'],\n      defaultValueExpression: json['defaultValueExpression'], cascadeConfig: json['cascadeConfig'],\n      localization: json['localization'],")

# GridComponent & RepeaterComponent use ComplexComponent.fromJson and pass arguments to constructor.
content = content.replace('      componentConfig: json[\'componentConfig\'], nestedFields: nestedList.map((f) => BaseComponent.fromJson(f)).toList(),', '      groupId: json[\'groupId\'], sectionId: json[\'sectionId\'], expression: json[\'expression\'], defaultValueExpression: json[\'defaultValueExpression\'], cascadeConfig: json[\'cascadeConfig\'], localization: json[\'localization\'],\n      componentConfig: json[\'componentConfig\'], nestedFields: nestedList.map((f) => BaseComponent.fromJson(f)).toList(),')


# finally toJson
content = content.replace("      'id': id,", "      'id': id,\n      if (groupId != null) 'groupId': groupId,\n      if (sectionId != null) 'sectionId': sectionId,\n      if (expression != null) 'expression': expression,\n      if (defaultValueExpression != null) 'defaultValueExpression': defaultValueExpression,\n      if (cascadeConfig != null) 'cascadeConfig': cascadeConfig,\n      if (localization != null) 'localization': localization,")

# copy method inside InputComponent
content = content.replace('      defaultValue: defaultValue, fieldtype: fieldtype, maxLength: maxLength, minLength: minLength,', '      groupId: groupId, sectionId: sectionId, expression: expression, defaultValueExpression: defaultValueExpression, cascadeConfig: cascadeConfig, localization: localization,\n      defaultValue: defaultValue, fieldtype: fieldtype, maxLength: maxLength, minLength: minLength,')

# copy method inside OptionsComponent
content = content.replace('      options: options, useStaticOptions: useStaticOptions, staticOptions: staticOptions,', '      groupId: groupId, sectionId: sectionId, expression: expression, defaultValueExpression: defaultValueExpression, cascadeConfig: cascadeConfig, localization: localization,\n      options: options, useStaticOptions: useStaticOptions, staticOptions: staticOptions,')

# copy method inside LayoutComponent
content = content.replace('      nestedFields: nestedFields?.map((f) => f.copy()).toList(), repeatableGroup: repeatableGroup, repeatConfig: repeatConfig,', '      groupId: groupId, sectionId: sectionId, expression: expression, defaultValueExpression: defaultValueExpression, cascadeConfig: cascadeConfig, localization: localization,\n      nestedFields: nestedFields?.map((f) => f.copy()).toList(), repeatableGroup: repeatableGroup, repeatConfig: repeatConfig,')

# copy method inside ComplexComponent (RepeaterComponent / GridComponent)
# actually GridComponent has its own copy
content = content.replace('      componentConfig: componentConfig, nestedFields: nestedFields?.map((f) => f.copy()).toList(),', '      groupId: groupId, sectionId: sectionId, expression: expression, defaultValueExpression: defaultValueExpression, cascadeConfig: cascadeConfig, localization: localization,\n      componentConfig: componentConfig, nestedFields: nestedFields?.map((f) => f.copy()).toList(),')

with open('lib/features/journey_builder/data/models.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Updated models.dart subclasses successfully')
