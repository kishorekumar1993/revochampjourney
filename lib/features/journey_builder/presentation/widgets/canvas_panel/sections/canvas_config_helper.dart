import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';

final List<Map<String, dynamic>> componentGroups = [
  {
    'title': 'FORM COMPONENTS',
    'items': [
      {'type': 'text', 'label': 'Text Field', 'icon': Icons.text_fields_rounded},
      {'type': 'dropdown', 'label': 'Dropdown', 'icon': Icons.arrow_drop_down_circle_outlined},
      {'type': 'radio', 'label': 'Radio', 'icon': Icons.radio_button_checked_rounded},
      {'type': 'checkbox', 'label': 'Checkbox', 'icon': Icons.check_box_outlined},
      {'type': 'date', 'label': 'Date Picker', 'icon': Icons.calendar_today_rounded},
      {'type': 'file', 'label': 'File Upload', 'icon': Icons.cloud_upload_outlined},
      {'type': 'textarea', 'label': 'Text Area', 'icon': Icons.notes_rounded},
      {'type': 'number', 'label': 'Number', 'icon': Icons.pin_outlined},
      {'type': 'switch', 'label': 'Switch', 'icon': Icons.toggle_on_outlined},
    ],
  },
  {
    'title': 'DATA COMPONENTS',
    'items': [
      {'type': 'table_grid', 'label': 'Table / Grid', 'icon': Icons.table_chart_outlined},
      {'type': 'repeater', 'label': 'Repeater', 'icon': Icons.view_week_outlined},
      {'type': 'timeline', 'label': 'Timeline', 'icon': Icons.format_list_bulleted_rounded},
    ],
  },
  {
    'title': 'LAYOUT COMPONENTS',
    'items': [
      {'type': 'section', 'label': 'Section', 'icon': Icons.view_agenda_outlined},
      {'type': 'card', 'label': 'Card', 'icon': Icons.crop_square_rounded},
      {'type': 'tabs', 'label': 'Tabs', 'icon': Icons.tab_rounded},
      {'type': 'accordion', 'label': 'Accordion', 'icon': Icons.unfold_more_rounded},
    ],
  },
];

Map<String, dynamic> componentDefaults(String fieldType) {
  switch (fieldType) {
    case 'dropdown':
      return {'label': 'Dropdown', 'placeholder': 'Select an option', 'options': ['Option 1', 'Option 2']};
    case 'radio':
      return {'label': 'Radio Group', 'options': ['Option 1', 'Option 2']};
    case 'checkbox':
      return {'label': 'Checkbox', 'defaultValue': 'false'};
    case 'date':
      return {'label': 'Date Picker', 'placeholder': 'DD/MM/YYYY'};
    case 'file':
      return {'label': 'File Upload', 'placeholder': 'Upload file'};
    case 'textarea':
      return {'label': 'Text Area', 'placeholder': 'Enter details'};
    case 'number':
      return {'label': 'Number', 'placeholder': 'Enter number', 'keyboardType': 'number'};
    case 'switch':
      return {'label': 'Switch', 'defaultValue': 'false'};
    case 'table_grid':
      return {
        'label': 'Table / Grid',
        'placeholder': 'Manage tabular data',
        'componentConfig': {
          'columns': [
            {'label': 'Name', 'fieldId': 'name', 'type': 'text', 'required': true, 'sortable': true, 'filterable': true, 'sticky': true},
            {'label': 'Age', 'fieldId': 'age', 'type': 'number', 'required': false, 'sortable': true, 'filterable': true, 'sticky': false},
          ],
          'rowActions': ['edit', 'delete'],
          'allowAddRow': true,
          'allowDeleteRow': true,
          'inlineEdit': true,
          'bulkSelection': true,
          'exportCsv': true,
          'search': true,
          'sorting': true,
          'filtering': true,
          'stickyColumns': true,
          'dataSource': 'manual',
          'gridApiUrl': '',
          'gridApiMethod': 'GET',
          'gridApiHeaders': {},
          'gridApiBody': '',
          'gridApiListKey': 'data',
          'apiPagination': false,
          'dynamicRowValidation': true,
          'pagination': true,
          'rowsPerPage': 10,
        },
      };
    case 'repeater':
      return {'label': 'Repeater', 'placeholder': 'Repeat a field group'};
    case 'timeline':
      return {'label': 'Timeline', 'placeholder': 'Show journey milestones'};
    case 'section':
      return {'label': 'Section', 'placeholder': 'Group related components'};
    case 'card':
      return {'label': 'Card', 'placeholder': 'Card content container'};
    case 'tabs':
      return {'label': 'Tabs', 'placeholder': 'Organize content into tabs'};
    case 'accordion':
      return {'label': 'Accordion', 'placeholder': 'Expandable content'};
    default:
      return {'label': 'Text Field', 'placeholder': 'Enter details'};
  }
}

void addField(WidgetRef ref, String fieldType) {
  final activeStepId = ref.read(activeStepIdProvider);
  final fieldId = "field_${DateTime.now().millisecondsSinceEpoch}";
  final defaults = componentDefaults(fieldType);
  final newField = JourneyField.fromJson({
    'id': fieldId,
    'label': defaults['label'],
    'type': fieldType,
    'required': false,
    'placeholder': defaults['placeholder'],
    'options': defaults['options'],
    'defaultValue': defaults['defaultValue'],
    'keyboardType': defaults['keyboardType'],
    'componentConfig': defaults['componentConfig'],
  });
  ref.read(journeyConfigProvider.notifier).addFieldToStep(activeStepId, newField);
  ref.read(selectedFieldIdProvider.notifier).state = fieldId;
}

void duplicateField(WidgetRef ref, JourneyField field) {
  final activeStepId = ref.read(activeStepIdProvider);
  final newFieldId = "field_${DateTime.now().millisecondsSinceEpoch}";
  final duplicated = field.copyWith(
    id: newFieldId,
    label: "${field.label} (Copy)",
  );
  ref.read(journeyConfigProvider.notifier).addFieldToStep(activeStepId, duplicated);
  ref.read(selectedFieldIdProvider.notifier).state = newFieldId;
}
