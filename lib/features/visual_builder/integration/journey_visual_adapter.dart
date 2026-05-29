import '../../../core/component_engine/models/component_node.dart';
import '../../../core/component_engine/registry/component_registry.dart';
import '../../journey_builder/domain/entities/journey_models.dart';

class JourneyVisualAdapter {
  static ComponentNode createTreeFromJourneyStep(JourneyStep step) {
    if (step.screenLayout != null && step.screenLayout!.isNotEmpty) {
      return ComponentNode.fromJson(step.screenLayout!);
    }

    // Auto-generate a default tree for an existing journey step
    final List<ComponentNode> children = [];
    for (final field in step.fields) {
      children.add(_fieldToComponentNode(field));
    }

    return ComponentNode(
      id: 'root_${step.id}',
      type: 'Column',
      properties: {
        'mainAxisAlignment': 'start',
        'crossAxisAlignment': 'stretch',
        'padding': 16.0,
      },
      children: children,
      actions: [],
    );
  }

  static List<JourneyField> extractFields(ComponentNode root) {
    final List<JourneyField> fields = [];
    _extractJourneyFieldsRecursive(root, fields);
    return fields;
  }

  static JourneyStep updateStepLayout(JourneyStep step, ComponentNode node) {
    final fields = extractFields(node);
    return step.copyWith(
      screenLayout: node.toJson(),
      fields: fields,
    );
  }

  // --- Helper Methods ---

  static ComponentNode _fieldToComponentNode(JourneyField field) {
    String type = 'TextField';
    Map<String, dynamic> props = {
      'fieldName': field.id,
      'label': field.label,
      'hint': field.placeholder ?? field.hintText ?? '',
      'required': field.required,
      'readOnly': field.readOnly,
      'enabled': !field.disable,
    };

    if (field.type == 'date') {
      type = 'DatePicker';
    } else if (field.type == 'number') {
      type = 'Slider';
      props['min'] = 0.0;
      props['max'] = 100.0;
    } else if (field is OptionsComponent) {
      if (field.type == 'dropdown' || field.type == 'api_dropdown') {
        type = 'Dropdown';
        props['options'] = field.options ?? [];
        props['apiUrl'] = field.dropdownApiUrl ?? '';
        props['apiMethod'] = field.dropdownApiMethod ?? 'GET';
      } else if (field.type == 'radio') {
        type = 'Radio';
        props['options'] = field.options ?? [];
      } else if (field.type == 'checkbox') {
        type = 'Checkbox';
      } else if (field.type == 'switch') {
        type = 'Switch';
      }
    } else if (field is LayoutComponent) {
      if (field.type == 'row') {
        type = 'Row';
      } else if (field.type == 'column') {
        type = 'Column';
      } else if (field.type == 'card') {
        type = 'Card';
      } else {
        type = 'Container';
      }
    } else if (field is GridComponent) {
      type = 'Table';
    } else if (field is RepeaterComponent) {
      type = 'ListView';
    }

    final children = <ComponentNode>[];
    if (field.nestedFields != null) {
      for (final subField in field.nestedFields!) {
        children.add(_fieldToComponentNode(subField));
      }
    }

    return ComponentNode(
      id: 'node_${field.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      properties: props,
      children: children,
      actions: [],
    );
  }

  static void _extractJourneyFieldsRecursive(ComponentNode node, List<JourneyField> fields) {
    final props = node.properties;
    final meta = ComponentRegistry.getByType(node.type);
    final isForm = meta?.category == ComponentCategory.form;

    if (isForm) {
      final fieldId = props['fieldName'] ?? node.id;
      final label = props['label'] ?? node.type;
      final hint = props['hint'] ?? '';
      final required = props['required'] == true;
      final readOnly = props['readOnly'] == true;
      final enabled = props['enabled'] != false;

      if (node.type == 'TextField') {
        fields.add(InputComponent(
          id: fieldId,
          label: label,
          type: 'text',
          required: required,
          readOnly: readOnly,
          placeholder: hint,
          disable: !enabled,
        ));
      } else if (node.type == 'Dropdown') {
        fields.add(OptionsComponent(
          id: fieldId,
          label: label,
          type: 'dropdown',
          required: required,
          readOnly: readOnly,
          placeholder: hint,
          options: List<String>.from(props['options'] ?? []),
          dropdownApiUrl: props['apiUrl'] ?? '',
          dropdownApiMethod: props['apiMethod'] ?? 'GET',
          disable: !enabled,
        ));
      } else if (node.type == 'Radio') {
        fields.add(OptionsComponent(
          id: fieldId,
          label: label,
          type: 'radio',
          required: required,
          options: List<String>.from(props['options'] ?? []),
          disable: !enabled,
        ));
      } else if (node.type == 'Checkbox') {
        fields.add(OptionsComponent(
          id: fieldId,
          label: label,
          type: 'checkbox',
          required: required,
          disable: !enabled,
        ));
      } else if (node.type == 'DatePicker') {
        fields.add(InputComponent(
          id: fieldId,
          label: label,
          type: 'date',
          required: required,
          placeholder: hint,
          disable: !enabled,
        ));
      } else if (node.type == 'Switch') {
        fields.add(OptionsComponent(
          id: fieldId,
          label: label,
          type: 'switch',
          required: required,
          disable: !enabled,
        ));
      } else if (node.type == 'Slider') {
        fields.add(InputComponent(
          id: fieldId,
          label: label,
          type: 'number',
          required: required,
          disable: !enabled,
        ));
      }
    } else if (node.type == 'Row' || node.type == 'Column' || node.type == 'Card' || node.type == 'Container') {
      final childrenFields = <JourneyField>[];
      for (final child in node.children) {
        _extractJourneyFieldsRecursive(child, childrenFields);
      }
      fields.add(LayoutComponent(
        id: node.id,
        label: node.type,
        type: node.type.toLowerCase(),
        nestedFields: childrenFields,
      ));
    } else {
      // For any other layout or display widgets, traverse children
      for (final child in node.children) {
        _extractJourneyFieldsRecursive(child, fields);
      }
    }
  }
}
