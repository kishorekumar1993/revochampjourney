import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';

Map<String, dynamic> getComponentConfig(JourneyField field) {
  final config = Map<String, dynamic>.from(field.componentConfig ?? {});
  switch (field.type) {
    case 'table_grid':
      return {
        'columns': [
          {'label': '#', 'fieldId': 'rowIndex', 'type': 'number', 'required': false},
          {'label': 'Registration No.', 'fieldId': 'registrationNo', 'type': 'text', 'required': true},
          {'label': 'Manufacturer', 'fieldId': 'manufacturer', 'type': 'dropdown', 'required': true},
        ],
        'allowAddRow': true,
        'allowEditRow': true,
        'allowDeleteRow': true,
        'allowViewRow': true,
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
        'rowActions': ['view', 'edit', 'delete'],
        'minRows': 0,
        'maxRows': 10,
        'pagination': true,
        'rowsPerPage': 10,
        'apiPageParam': 'page',
        'apiPageSizeParam': 'limit',
        ...config,
      };
    case 'repeater':
      return {
        'itemLabel': 'Item',
        'addButtonLabel': 'Add Item',
        'fields': [
          {'label': 'Name', 'fieldId': 'name', 'type': 'text', 'required': true},
          {'label': 'Value', 'fieldId': 'value', 'type': 'text', 'required': false},
        ],
        'minItems': 0,
        'maxItems': 5,
        'allowAdd': true,
        'allowRemove': true,
        'allowReorder': true,
        'showItemIndex': true,
        'collapsibleItems': true,
        'layout': 'singleColumn',
        ...config,
      };
    case 'timeline':
      return {
        'orientation': 'vertical',
        'markerStyle': 'numbered',
        'showTimestamp': true,
        'showConnector': true,
        'allowFutureSteps': true,
        'defaultStatus': 'pending',
        'itemsSource': 'static',
        'titleField': 'title',
        'dateField': 'date',
        'statusField': 'status',
        'items': [
          {'title': 'Started', 'description': 'Journey started', 'status': 'completed'},
          {'title': 'In Progress', 'description': 'Current step', 'status': 'active'},
          {'title': 'Completed', 'description': 'Final state', 'status': 'pending'},
        ],
        ...config,
      };
    case 'section':
      return {
        'headingLevel': 'H2',
        'collapsible': false,
        'defaultExpanded': true,
        'showDivider': true,
        'padding': 'medium',
        ...config,
      };
    case 'card':
      return {
        'variant': 'outlined',
        'showHeader': true,
        'showFooter': false,
        'padding': 'medium',
        ...config,
      };
    case 'tabs':
      return {
        'variant': 'underline',
        'alignment': 'start',
        'persistActiveTab': true,
        'tabs': ['Tab 1', 'Tab 2'],
        ...config,
      };
    case 'accordion':
      return {
        'allowMultipleOpen': false,
        'defaultExpanded': false,
        'iconPosition': 'right',
        'variant': 'bordered',
        ...config,
      };
    default:
      return config;
  }
}

void updateComponentConfig(WidgetRef ref, JourneyField field, String activeStepId, String key, dynamic value) {
  final isInitial = field.componentConfig == null || field.componentConfig!.isEmpty;
  final updatedConfig = Map<String, dynamic>.from(field.componentConfig ?? {});
  if (isInitial) {
    updatedConfig.addAll(getComponentConfig(field));
  }
  updatedConfig[key] = value;
  final updated = field.copyWith()..componentConfig = updatedConfig;
  ref.read(journeyConfigProvider.notifier).updateFieldInStep(activeStepId, field.id, updated);
}

int intConfig(Map<String, dynamic> config, String key, int fallback) {
  final value = config[key];
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool boolConfig(Map<String, dynamic> config, String key, bool fallback) {
  final value = config[key];
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}
