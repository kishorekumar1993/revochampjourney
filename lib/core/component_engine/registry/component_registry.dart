import 'package:flutter/material.dart';

enum ComponentCategory { layout, form, button, display, advanced }

class ComponentMetadata {
  final String type;
  final String label;
  final IconData icon;
  final ComponentCategory category;
  final bool canHaveChildren;
  final Map<String, dynamic> defaultProperties;

  const ComponentMetadata({
    required this.type,
    required this.label,
    required this.icon,
    required this.category,
    required this.canHaveChildren,
    required this.defaultProperties,
  });
}

class ComponentRegistry {
  static final List<ComponentMetadata> components = [
    // --- LAYOUT ---
    const ComponentMetadata(
      type: 'Container',
      label: 'Container',
      icon: Icons.crop_square_rounded,
      category: ComponentCategory.layout,
      canHaveChildren: true,
      defaultProperties: {
        'width': null,
        'height': null,
        'backgroundColor': '#FFFFFF',
        'padding': 16.0,
        'margin': 0.0,
        'borderRadius': 8.0,
      },
    ),
    const ComponentMetadata(
      type: 'Row',
      label: 'Row',
      icon: Icons.reorder_rounded,
      category: ComponentCategory.layout,
      canHaveChildren: true,
      defaultProperties: {
        'mainAxisAlignment': 'start',
        'crossAxisAlignment': 'center',
      },
    ),
    const ComponentMetadata(
      type: 'Column',
      label: 'Column',
      icon: Icons.view_week_rounded,
      category: ComponentCategory.layout,
      canHaveChildren: true,
      defaultProperties: {
        'mainAxisAlignment': 'start',
        'crossAxisAlignment': 'stretch',
      },
    ),
    const ComponentMetadata(
      type: 'Stack',
      label: 'Stack',
      icon: Icons.layers_rounded,
      category: ComponentCategory.layout,
      canHaveChildren: true,
      defaultProperties: {},
    ),
    const ComponentMetadata(
      type: 'Wrap',
      label: 'Wrap',
      icon: Icons.wrap_text_rounded,
      category: ComponentCategory.layout,
      canHaveChildren: true,
      defaultProperties: {
        'spacing': 8.0,
        'runSpacing': 8.0,
      },
    ),
    const ComponentMetadata(
      type: 'GridView',
      label: 'GridView',
      icon: Icons.grid_on_rounded,
      category: ComponentCategory.layout,
      canHaveChildren: true,
      defaultProperties: {
        'spacing': 8.0,
        'runSpacing': 8.0,
      },
    ),
    const ComponentMetadata(
      type: 'ListView',
      label: 'ListView',
      icon: Icons.list_alt_rounded,
      category: ComponentCategory.layout,
      canHaveChildren: true,
      defaultProperties: {
        'spacing': 8.0,
      },
    ),
    const ComponentMetadata(
      type: 'Card',
      label: 'Card',
      icon: Icons.picture_in_picture_rounded,
      category: ComponentCategory.layout,
      canHaveChildren: true,
      defaultProperties: {
        'elevation': 2.0,
        'backgroundColor': '#FFFFFF',
        'margin': 8.0,
        'padding': 16.0,
        'borderRadius': 12.0,
      },
    ),
    const ComponentMetadata(
      type: 'Spacer',
      label: 'Spacer',
      icon: Icons.space_bar_rounded,
      category: ComponentCategory.layout,
      canHaveChildren: false,
      defaultProperties: {},
    ),
    const ComponentMetadata(
      type: 'Divider',
      label: 'Divider',
      icon: Icons.remove_rounded,
      category: ComponentCategory.layout,
      canHaveChildren: false,
      defaultProperties: {
        'height': 1.0,
        'color': '#E4E6F0',
      },
    ),

    // --- FORM ---
    const ComponentMetadata(
      type: 'TextField',
      label: 'TextField',
      icon: Icons.text_fields_rounded,
      category: ComponentCategory.form,
      canHaveChildren: false,
      defaultProperties: {
        'fieldName': 'input',
        'label': 'Label',
        'hint': 'Enter value',
        'required': false,
        'obscureText': false,
        'keyboardType': 'text',
        'maxLength': null,
      },
    ),
    const ComponentMetadata(
      type: 'Dropdown',
      label: 'Dropdown',
      icon: Icons.arrow_drop_down_circle_rounded,
      category: ComponentCategory.form,
      canHaveChildren: false,
      defaultProperties: {
        'fieldName': 'dropdown',
        'label': 'Dropdown Option',
        'hint': 'Select option',
        'required': false,
        'options': ['Option 1', 'Option 2', 'Option 3'],
        'apiUrl': '',
        'apiMethod': 'GET',
        'responseListKey': 'data',
        'labelKey': 'name',
        'valueKey': 'id',
      },
    ),
    const ComponentMetadata(
      type: 'Radio',
      label: 'Radio',
      icon: Icons.radio_button_checked_rounded,
      category: ComponentCategory.form,
      canHaveChildren: false,
      defaultProperties: {
        'fieldName': 'radio',
        'label': 'Select Value',
        'options': ['Option A', 'Option B'],
        'required': false,
      },
    ),
    const ComponentMetadata(
      type: 'Checkbox',
      label: 'Checkbox',
      icon: Icons.check_box_rounded,
      category: ComponentCategory.form,
      canHaveChildren: false,
      defaultProperties: {
        'fieldName': 'checkbox',
        'label': 'Check details',
        'required': false,
      },
    ),
    const ComponentMetadata(
      type: 'DatePicker',
      label: 'DatePicker',
      icon: Icons.calendar_today_rounded,
      category: ComponentCategory.form,
      canHaveChildren: false,
      defaultProperties: {
        'fieldName': 'datepicker',
        'label': 'Select Date',
        'hint': 'DD/MM/YYYY',
        'required': false,
      },
    ),
    const ComponentMetadata(
      type: 'Switch',
      label: 'Switch',
      icon: Icons.toggle_on_rounded,
      category: ComponentCategory.form,
      canHaveChildren: false,
      defaultProperties: {
        'fieldName': 'switch',
        'label': 'Enable Option',
        'required': false,
      },
    ),
    const ComponentMetadata(
      type: 'Slider',
      label: 'Slider',
      icon: Icons.linear_scale_rounded,
      category: ComponentCategory.form,
      canHaveChildren: false,
      defaultProperties: {
        'fieldName': 'slider',
        'label': 'Value Slider',
        'required': false,
        'min': 0.0,
        'max': 100.0,
      },
    ),

    // --- BUTTON ---
    const ComponentMetadata(
      type: 'Button',
      label: 'Button',
      icon: Icons.smart_button_rounded,
      category: ComponentCategory.button,
      canHaveChildren: false,
      defaultProperties: {
        'label': 'Click Me',
        'backgroundColor': '#5B4FCF',
        'textColor': '#FFFFFF',
        'borderRadius': 8.0,
      },
    ),
    const ComponentMetadata(
      type: 'IconButton',
      label: 'IconButton',
      icon: Icons.blur_on_rounded,
      category: ComponentCategory.button,
      canHaveChildren: false,
      defaultProperties: {
        'icon': 'star',
        'color': '#5B4FCF',
      },
    ),
    const ComponentMetadata(
      type: 'FloatingButton',
      label: 'Floating Button',
      icon: Icons.add_circle_rounded,
      category: ComponentCategory.button,
      canHaveChildren: false,
      defaultProperties: {
        'icon': 'add',
        'backgroundColor': '#5B4FCF',
        'textColor': '#FFFFFF',
      },
    ),

    // --- DISPLAY ---
    const ComponentMetadata(
      type: 'Text',
      label: 'Text',
      icon: Icons.text_format_rounded,
      category: ComponentCategory.display,
      canHaveChildren: false,
      defaultProperties: {
        'label': 'Sample Text',
        'fontSize': 14.0,
        'fontWeight': 'normal',
        'color': '#1A1A2E',
      },
    ),
    const ComponentMetadata(
      type: 'Image',
      label: 'Image',
      icon: Icons.image_rounded,
      category: ComponentCategory.display,
      canHaveChildren: false,
      defaultProperties: {
        'src': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500',
        'width': null,
        'height': 200.0,
        'fit': 'cover',
        'borderRadius': 8.0,
      },
    ),
    const ComponentMetadata(
      type: 'Icon',
      label: 'Icon',
      icon: Icons.category_rounded,
      category: ComponentCategory.display,
      canHaveChildren: false,
      defaultProperties: {
        'icon': 'info',
        'fontSize': 24.0,
        'color': '#1A1A2E',
      },
    ),

    // --- ADVANCED ---
    const ComponentMetadata(
      type: 'Chart',
      label: 'Chart',
      icon: Icons.bar_chart_rounded,
      category: ComponentCategory.advanced,
      canHaveChildren: false,
      defaultProperties: {
        'title': 'Usage Statistics',
        'chartType': 'bar', // bar, line, pie
      },
    ),
    const ComponentMetadata(
      type: 'Table',
      label: 'Table',
      icon: Icons.table_chart_rounded,
      category: ComponentCategory.advanced,
      canHaveChildren: false,
      defaultProperties: {
        'columns': ['ID', 'Name', 'Status'],
      },
    ),
    const ComponentMetadata(
      type: 'Stepper',
      label: 'Stepper',
      icon: Icons.more_horiz_rounded,
      category: ComponentCategory.advanced,
      canHaveChildren: false,
      defaultProperties: {
        'steps': ['Start', 'Processing', 'Done'],
      },
    ),
    const ComponentMetadata(
      type: 'Timeline',
      label: 'Timeline',
      icon: Icons.timeline_rounded,
      category: ComponentCategory.advanced,
      canHaveChildren: false,
      defaultProperties: {
        'items': ['Registered', 'Verified', 'Active'],
      },
    ),
    const ComponentMetadata(
      type: 'Expanded',
      label: 'Expanded',
      icon: Icons.expand_rounded,
      category: ComponentCategory.layout,
      canHaveChildren: true,
      defaultProperties: {},
    ),
    const ComponentMetadata(
      type: 'Flexible',
      label: 'Flexible',
      icon: Icons.fit_screen_rounded,
      category: ComponentCategory.layout,
      canHaveChildren: true,
      defaultProperties: {},
    ),
    const ComponentMetadata(
      type: 'SafeArea',
      label: 'SafeArea',
      icon: Icons.security_rounded,
      category: ComponentCategory.layout,
      canHaveChildren: true,
      defaultProperties: {},
    ),
    const ComponentMetadata(
      type: 'FilePicker',
      label: 'FilePicker',
      icon: Icons.attach_file_rounded,
      category: ComponentCategory.form,
      canHaveChildren: false,
      defaultProperties: {
        'fieldName': 'file',
        'label': 'Select File',
        'required': false,
      },
    ),
    const ComponentMetadata(
      type: 'OTP',
      label: 'OTP Verification',
      icon: Icons.pin_rounded,
      category: ComponentCategory.form,
      canHaveChildren: false,
      defaultProperties: {
        'fieldName': 'otp',
        'label': 'Enter OTP',
        'required': false,
        'length': 6,
      },
    ),
    const ComponentMetadata(
      type: 'Search',
      label: 'Search Field',
      icon: Icons.search_rounded,
      category: ComponentCategory.form,
      canHaveChildren: false,
      defaultProperties: {
        'fieldName': 'search',
        'label': 'Search',
        'hint': 'Type keywords...',
      },
    ),
    const ComponentMetadata(
      type: 'Avatar',
      label: 'Avatar Image',
      icon: Icons.account_circle_rounded,
      category: ComponentCategory.display,
      canHaveChildren: false,
      defaultProperties: {
        'src': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        'radius': 24.0,
      },
    ),
    const ComponentMetadata(
      type: 'Chip',
      label: 'Chip Badge',
      icon: Icons.tag_rounded,
      category: ComponentCategory.display,
      canHaveChildren: false,
      defaultProperties: {
        'label': 'Tag',
        'backgroundColor': '#E8E7FD',
        'textColor': '#5B4FCF',
      },
    ),
    const ComponentMetadata(
      type: 'Badge',
      label: 'Badge Indicator',
      icon: Icons.notification_important_rounded,
      category: ComponentCategory.display,
      canHaveChildren: false,
      defaultProperties: {
        'label': 'New',
        'backgroundColor': '#FF3B30',
        'textColor': '#FFFFFF',
      },
    ),
    const ComponentMetadata(
      type: 'Progress',
      label: 'Progress Bar',
      icon: Icons.sync_rounded,
      category: ComponentCategory.display,
      canHaveChildren: false,
      defaultProperties: {
        'color': '#5B4FCF',
        'isCircular': true,
      },
    ),
    const ComponentMetadata(
      type: 'Tabs',
      label: 'Tabs View',
      icon: Icons.tab_rounded,
      category: ComponentCategory.advanced,
      canHaveChildren: true,
      defaultProperties: {
        'tabs': ['Tab One', 'Tab Two'],
      },
    ),
    const ComponentMetadata(
      type: 'Drawer',
      label: 'Side Drawer',
      icon: Icons.menu_open_rounded,
      category: ComponentCategory.advanced,
      canHaveChildren: true,
      defaultProperties: {
        'title': 'App Drawer',
      },
    ),
    const ComponentMetadata(
      type: 'NavigationBar',
      label: 'Navigation Bar',
      icon: Icons.menu_rounded,
      category: ComponentCategory.advanced,
      canHaveChildren: false,
      defaultProperties: {
        'items': ['Home', 'Search', 'Profile'],
      },
    ),
  ];

  static ComponentMetadata? getByType(String type) {
    for (final component in components) {
      if (component.type == type) return component;
    }
    return null;
  }
}
