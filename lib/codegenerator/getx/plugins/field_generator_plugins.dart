import 'field_generator_plugins_impl.dart';
export 'field_generator_plugins_impl.dart';

abstract class FieldGeneratorPlugin {
  bool matches(String type);
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  );

  void generateSummaryRow(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
  );
}

class FieldGeneratorRegistry {
  static final List<FieldGeneratorPlugin> plugins = [
    TextFieldPlugin(),
    DatePickerPlugin(),
    DateTimePickerPlugin(),
    TimePickerPlugin(),
    DropdownPlugin(),
    RadioButtonPlugin(),
    SwitchPlugin(),
    CheckboxPlugin(),
    FilePickerPlugin(),
    MultiSelectPlugin(),
    SliderPlugin(),
    LabelPlugin(),
    StarRatingPlugin(),
    SectionPlugin(),
    CardPlugin(),
    TabsPlugin(),
    AccordionPlugin(),
    RowColPlugin(),
    FormulaPlugin(),
  ];

  static FieldGeneratorPlugin? find(String type) {
    final t = type.toLowerCase().trim();
    for (final p in plugins) {
      if (p.matches(t)) return p;
    }
    return null;
  }
}
