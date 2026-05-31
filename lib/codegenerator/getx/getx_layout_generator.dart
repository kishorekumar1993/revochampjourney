import 'package:flutter/material.dart';
import '../../../../core/component_engine/models/component_node.dart';
import '../../../../core/component_engine/models/component_property.dart';

class GetxLayoutGenerator {
  /// Entry point to generate the GetX View Page.
  static String generateView(ComponentNode rootNode, String className, String fileName) {
    final buffer = StringBuffer();
    final controllerClass = '${className}Controller';

    // 1. Imports
    buffer.writeln("// AUTO-GENERATED - Layout-based GetX View");
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'package:get/get.dart';");
    buffer.writeln("import 'package:google_fonts/google_fonts.dart';");
    buffer.writeln("import '../controllers/${fileName}_controller.dart';");
    buffer.writeln();

    // 2. Class Declaration
    buffer.writeln("class ${className}View extends GetView<$controllerClass> {");
    buffer.writeln("  const ${className}View({super.key});");
    buffer.writeln();

    // 3. Build Method
    buffer.writeln("  @override");
    buffer.writeln("  Widget build(BuildContext context) {");
    
    // Compile root node
    final rootCompiled = _compileNode(rootNode, "    ", controllerClass);
    buffer.writeln("    return $rootCompiled;");
    buffer.writeln("  }");
    buffer.writeln("}");

    return buffer.toString();
  }

  /// Entry point to generate the GetX Controller.
  static String generateController(ComponentNode rootNode, String className) {
    final buffer = StringBuffer();
    final inputNodes = <ComponentNode>[];
    _findInputFields(rootNode, inputNodes);

    // 1. Imports
    buffer.writeln("// AUTO-GENERATED - Layout-based GetX Controller");
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'package:get/get.dart';");
    buffer.writeln();

    // 2. Class Declaration
    buffer.writeln("class ${className}Controller extends GetxController {");
    buffer.writeln("  final formKey = GlobalKey<FormState>();");
    buffer.writeln("  final isExecuting = false.obs;");
    buffer.writeln();

    // 3. Declare specific fields
    final Map<String, String> textControllers = {}; // fieldName -> camelName
    final Map<String, dynamic> rxFields = {};       // fieldName -> initVal

    for (final node in inputNodes) {
      final fieldName = node.properties['fieldName'] ?? node.properties['label'] ?? node.id;
      final camelName = _toCamelCase(fieldName.toString());
      if (camelName.isEmpty) continue;

      final type = node.type;
      if (type == 'TextField' || type == 'DatePicker' || type == 'OTP' || type == 'Search') {
        textControllers[fieldName.toString()] = camelName;
      } else if (type == 'Checkbox' || type == 'Switch') {
        rxFields[camelName] = false;
      } else if (type == 'Slider') {
        rxFields[camelName] = 0.0;
      } else {
        // Dropdown, Radio, etc.
        rxFields[camelName] = "''";
      }
    }

    // Output TextEditingControllers
    if (textControllers.isNotEmpty) {
      buffer.writeln("  // Form Fields - Text Controllers");
      textControllers.forEach((field, camel) {
        buffer.writeln("  final ${camel}Controller = TextEditingController();");
      });
      buffer.writeln();
    }

    // Output Rx observables
    if (rxFields.isNotEmpty) {
      buffer.writeln("  // Form Fields - Observables");
      rxFields.forEach((camel, initVal) {
        buffer.writeln("  final $camel = $initVal.obs;");
      });
      buffer.writeln();
    }

    // 4. Submit Method
    buffer.writeln("  // Submit handling");
    buffer.writeln("  void submitForm() async {");
    buffer.writeln("    if (formKey.currentState?.validate() ?? false) {");
    buffer.writeln("      isExecuting.value = true;");
    buffer.writeln("      try {");
    buffer.writeln("        // Assemble form payload");
    buffer.writeln("        final payload = <String, dynamic>{");
    textControllers.forEach((field, camel) {
      buffer.writeln("          '$field': ${camel}Controller.text,");
    });
    rxFields.forEach((camel, _) {
      buffer.writeln("          '$camel': $camel.value,");
    });
    buffer.writeln("        };");
    buffer.writeln();
    buffer.writeln("        debugPrint('Submitting Form: \$payload');");
    buffer.writeln("        // Simulate network API call");
    buffer.writeln("        await Future.delayed(const Duration(seconds: 2));");
    buffer.writeln();
    buffer.writeln("        Get.snackbar(");
    buffer.writeln("          'Success',");
    buffer.writeln("          'Form submitted successfully!',");
    buffer.writeln("          snackPosition: SnackPosition.BOTTOM,");
    buffer.writeln("          backgroundColor: Colors.green,");
    buffer.writeln("          colorText: Colors.white,");
    buffer.writeln("        );");
    buffer.writeln("      } catch (e) {");
    buffer.writeln("        Get.snackbar(");
    buffer.writeln("          'Error',");
    buffer.writeln("          'Failed to submit form: \$e',");
    buffer.writeln("          snackPosition: SnackPosition.BOTTOM,");
    buffer.writeln("          backgroundColor: Colors.red,");
    buffer.writeln("          colorText: Colors.white,");
    buffer.writeln("        );");
    buffer.writeln("      } finally {");
    buffer.writeln("        isExecuting.value = false;");
    buffer.writeln("      }");
    buffer.writeln("    }");
    buffer.writeln("  }");
    buffer.writeln();

    // 5. Close Method (Dispose controllers)
    buffer.writeln("  @override");
    buffer.writeln("  void onClose() {");
    textControllers.forEach((field, camel) {
      buffer.writeln("    ${camel}Controller.dispose();");
    });
    buffer.writeln("    super.onClose();");
    buffer.writeln("  }");

    buffer.writeln("}");

    return buffer.toString();
  }

  // --- Recursive Node Compilation ---
  static String _compileNode(ComponentNode node, String indent, String controllerClass) {
    final type = node.type;
    final buffer = StringBuffer();

    // Helper functions
    dynamic getProp(String key, [dynamic fallback]) {
      if (node.properties.containsKey(key)) return node.properties[key];
      if (node.styles.containsKey(key)) return node.styles[key];
      return fallback;
    }

    String compileChild(String slotName) {
      final child = node.slots[slotName];
      if (child != null) {
        return _compileNode(child, "$indent  ", controllerClass);
      }
      return 'null';
    }

    List<String> compileChildren() {
      return node.children.map((c) => _compileNode(c, "$indent    ", controllerClass)).toList();
    }

    switch (type) {
      case 'Scaffold':
        final bgStr = _formatColor(getProp('backgroundColor'));
        final appBar = compileChild('appBar');
        final body = compileChild('body');
        final bottomNav = compileChild('bottomNavigationBar');
        final drawer = compileChild('drawer');
        final fab = compileChild('floatingActionButton');
        final bottomSheet = compileChild('bottomSheet');

        buffer.writeln("Scaffold(");
        if (bgStr != 'null') buffer.writeln("$indent  backgroundColor: $bgStr,");
        if (appBar != 'null') buffer.writeln("$indent  appBar: PreferredSize(preferredSize: const Size.fromHeight(56), child: $appBar),");
        if (bottomNav != 'null') buffer.writeln("$indent  bottomNavigationBar: $bottomNav,");
        if (drawer != 'null') buffer.writeln("$indent  drawer: $drawer,");
        if (fab != 'null') buffer.writeln("$indent  floatingActionButton: $fab,");
        if (bottomSheet != 'null') buffer.writeln("$indent  bottomSheet: $bottomSheet,");
        
        // Wrap body in Form
        buffer.writeln("$indent  body: Form(");
        buffer.writeln("$indent    key: controller.formKey,");
        buffer.writeln("$indent    child: SingleChildScrollView(");
        buffer.writeln("$indent      child: $body,");
        buffer.writeln("$indent    ),");
        buffer.writeln("$indent  ),");
        buffer.write("$indent)");
        break;

      case 'AppBar':
        final bgStr = _formatColor(getProp('backgroundColor'));
        final titleText = getProp('title')?.toString() ?? 'App Title';
        final title = compileChild('title');
        final leading = compileChild('leading');
        final actions = compileChild('actions');

        buffer.writeln("AppBar(");
        if (bgStr != 'null') buffer.writeln("$indent  backgroundColor: $bgStr,");
        buffer.writeln("$indent  title: ${title != 'null' ? title : "Text('$titleText')" },");
        if (leading != 'null') buffer.writeln("$indent  leading: $leading,");
        if (actions != 'null') buffer.writeln("$indent  actions: [$actions],");
        buffer.write("$indent)");
        break;

      case 'Container':
        final width = PropertyParser.tryParseDouble(getProp('width'));
        final height = PropertyParser.tryParseDouble(getProp('height'));
        final bgStr = _formatColor(getProp('backgroundColor'));
        final gradientStr = _formatGradient(node);
        final pad = _formatPadding(getProp('padding'));
        final marg = _formatPadding(getProp('margin'));
        final radius = PropertyParser.tryParseDouble(getProp('borderRadius')) ?? 0.0;
        final borderColor = _formatColor(getProp('borderColor'));
        final borderWidth = PropertyParser.tryParseDouble(getProp('borderWidth')) ?? 1.0;
        final elevation = PropertyParser.tryParseDouble(getProp('elevation')) ?? 0.0;
        final alignment = _formatAlignment(getProp('alignment'));
        final child = compileChild('child');

        buffer.writeln("Container(");
        if (width != null) buffer.writeln("$indent  width: ${width == double.infinity ? 'double.infinity' : width},");
        if (height != null) buffer.writeln("$indent  height: ${height == double.infinity ? 'double.infinity' : height},");
        if (pad != 'EdgeInsets.zero') buffer.writeln("$indent  padding: $pad,");
        if (marg != 'EdgeInsets.zero') buffer.writeln("$indent  margin: $marg,");
        buffer.writeln("$indent  alignment: $alignment,");

        // Decoration
        if (bgStr != 'null' || gradientStr != 'null' || radius > 0.0 || borderColor != 'null' || elevation > 0.0) {
          buffer.writeln("$indent  decoration: BoxDecoration(");
          if (gradientStr != 'null') {
            buffer.writeln("$indent    gradient: $gradientStr,");
          } else if (bgStr != 'null') {
            buffer.writeln("$indent    color: $bgStr,");
          }
          if (radius > 0.0) buffer.writeln("$indent    borderRadius: BorderRadius.circular($radius),");
          if (borderColor != 'null') buffer.writeln("$indent    border: Border.all(color: $borderColor, width: $borderWidth),");
          if (elevation > 0.0) {
            buffer.writeln("$indent    boxShadow: [");
            buffer.writeln("$indent      BoxShadow(");
            buffer.writeln("$indent        color: Colors.black.withValues(alpha: 0.15),");
            buffer.writeln("$indent        blurRadius: ${elevation * 2},");
            buffer.writeln("$indent        offset: const Offset(0, $elevation),");
            buffer.writeln("$indent      ),");
            buffer.writeln("$indent    ],");
          }
          buffer.writeln("$indent  ),");
        }

        buffer.writeln("$indent  child: ${child != 'null' ? child : 'const SizedBox.shrink()'},");
        buffer.write("$indent)");
        break;

      case 'Card':
        final bgStr = _formatColor(getProp('backgroundColor'));
        final elevation = PropertyParser.tryParseDouble(getProp('elevation')) ?? 2.0;
        final pad = _formatPadding(getProp('padding'));
        final marg = _formatPadding(getProp('margin'));
        final radius = PropertyParser.tryParseDouble(getProp('borderRadius')) ?? 12.0;
        final child = compileChild('child');

        buffer.writeln("Card(");
        buffer.writeln("$indent  elevation: $elevation,");
        if (bgStr != 'null') buffer.writeln("$indent  color: $bgStr,");
        buffer.writeln("$indent  margin: $marg,");
        buffer.writeln("$indent  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular($radius)),");
        buffer.writeln("$indent  child: Padding(");
        buffer.writeln("$indent    padding: $pad,");
        buffer.writeln("$indent    child: ${child != 'null' ? child : 'const SizedBox.shrink()'},");
        buffer.writeln("$indent  ),");
        buffer.write("$indent)");
        break;

      case 'Column':
        final mainAlign = _formatMainAlign(getProp('mainAxisAlignment'));
        final crossAlign = _formatCrossAlign(getProp('crossAxisAlignment'));
        final spacing = PropertyParser.tryParseDouble(getProp('spacing'));
        final children = compileChildren();

        buffer.writeln("Column(");
        buffer.writeln("$indent  mainAxisAlignment: $mainAlign,");
        buffer.writeln("$indent  crossAxisAlignment: $crossAlign,");
        buffer.writeln("$indent  children: [");
        for (int i = 0; i < children.length; i++) {
          buffer.writeln("$indent    ${children[i]},");
          if (spacing != null && i < children.length - 1) {
            buffer.writeln("$indent    const SizedBox(height: $spacing),");
          }
        }
        buffer.writeln("$indent  ],");
        buffer.write("$indent)");
        break;

      case 'Row':
        final mainAlign = _formatMainAlign(getProp('mainAxisAlignment'));
        final crossAlign = _formatCrossAlign(getProp('crossAxisAlignment'));
        final spacing = PropertyParser.tryParseDouble(getProp('spacing'));
        final children = compileChildren();

        buffer.writeln("Row(");
        buffer.writeln("$indent  mainAxisAlignment: $mainAlign,");
        buffer.writeln("$indent  crossAxisAlignment: $crossAlign,");
        buffer.writeln("$indent  children: [");
        for (int i = 0; i < children.length; i++) {
          buffer.writeln("$indent    ${children[i]},");
          if (spacing != null && i < children.length - 1) {
            buffer.writeln("$indent    const SizedBox(width: $spacing),");
          }
        }
        buffer.writeln("$indent  ],");
        buffer.write("$indent)");
        break;

      case 'Stack':
        final children = compileChildren();
        buffer.writeln("Stack(");
        buffer.writeln("$indent  children: [");
        for (final child in children) {
          buffer.writeln("$indent    $child,");
        }
        buffer.writeln("$indent  ],");
        buffer.write("$indent)");
        break;

      case 'Wrap':
        final spacing = PropertyParser.tryParseDouble(getProp('spacing')) ?? 8.0;
        final runSpacing = PropertyParser.tryParseDouble(getProp('runSpacing')) ?? 8.0;
        final children = compileChildren();

        buffer.writeln("Wrap(");
        buffer.writeln("$indent  spacing: $spacing,");
        buffer.writeln("$indent  runSpacing: $runSpacing,");
        buffer.writeln("$indent  children: [");
        for (final child in children) {
          buffer.writeln("$indent    $child,");
        }
        buffer.writeln("$indent  ],");
        buffer.write("$indent)");
        break;

      case 'Text':
        final textVal = getProp('text') ?? getProp('label') ?? 'Text';
        final fontSize = PropertyParser.tryParseDouble(getProp('fontSize')) ?? 14.0;
        final fontWeightStr = _formatFontWeight(getProp('fontWeight'));
        final fontStyleStr = getProp('fontStyle')?.toString().toLowerCase() == 'italic' ? 'FontStyle.italic' : 'FontStyle.normal';
        final colorStr = _formatColor(getProp('color') ?? getProp('textColor'));
        final alignStr = _formatTextAlign(getProp('textAlign'));
        final maxLines = getProp('maxLines');

        buffer.writeln("Text(");
        buffer.writeln("$indent  '$textVal',");
        buffer.writeln("$indent  style: GoogleFonts.inter(");
        buffer.writeln("$indent    fontSize: $fontSize,");
        buffer.writeln("$indent    fontWeight: $fontWeightStr,");
        buffer.writeln("$indent    fontStyle: $fontStyleStr,");
        if (colorStr != 'null') buffer.writeln("$indent    color: $colorStr,");
        buffer.writeln("$indent  ),");
        buffer.writeln("$indent  textAlign: $alignStr,");
        if (maxLines != null) buffer.writeln("$indent  maxLines: $maxLines,");
        buffer.write("$indent)");
        break;

      case 'Button':
        final labelVal = getProp('label') ?? getProp('text') ?? 'Button';
        final bgStr = _formatColor(getProp('backgroundColor'));
        final textColorStr = _formatColor(getProp('textColor') ?? getProp('color'));
        final radius = PropertyParser.tryParseDouble(getProp('borderRadius')) ?? 8.0;

        buffer.writeln("ElevatedButton(");
        buffer.writeln("$indent  onPressed: () => controller.submitForm(),");
        buffer.writeln("$indent  style: ElevatedButton.styleFrom(");
        if (bgStr != 'null') buffer.writeln("$indent    backgroundColor: $bgStr,");
        if (textColorStr != 'null') buffer.writeln("$indent    foregroundColor: $textColorStr,");
        buffer.writeln("$indent    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular($radius)),");
        buffer.writeln("$indent  ),");
        buffer.writeln("$indent  child: Text('$labelVal', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),");
        buffer.write("$indent)");
        break;

      case 'IconButton':
        final iconVal = getProp('icon') ?? 'help';
        final colorStr = _formatColor(getProp('color'));
        final size = PropertyParser.tryParseDouble(getProp('size')) ?? 24.0;

        buffer.writeln("IconButton(");
        buffer.writeln("$indent  icon: Icon(Icons.$iconVal, size: $size${colorStr != 'null' ? ", color: $colorStr" : ""}),");
        buffer.writeln("$indent  onPressed: () {},");
        buffer.write("$indent)");
        break;

      case 'Image':
        final srcVal = getProp('src') ?? 'https://placehold.co/600x400/5B4FCF/ffffff/png';
        final width = PropertyParser.tryParseDouble(getProp('width'));
        final height = PropertyParser.tryParseDouble(getProp('height'));
        final fit = _formatBoxFit(getProp('fit'));
        final radius = PropertyParser.tryParseDouble(getProp('borderRadius')) ?? 0.0;

        if (radius > 0.0) {
          buffer.writeln("ClipRRect(");
          buffer.writeln("$indent  borderRadius: BorderRadius.circular($radius),");
          buffer.writeln("$indent  child: Image.network(");
          buffer.writeln("$indent    '$srcVal',");
          if (width != null) buffer.writeln("$indent    width: $width,");
          if (height != null) buffer.writeln("$indent    height: $height,");
          buffer.writeln("$indent    fit: $fit,");
          buffer.writeln("$indent  ),");
          buffer.write("$indent)");
        } else {
          buffer.writeln("Image.network(");
          buffer.writeln("$indent  '$srcVal',");
          if (width != null) buffer.writeln("$indent    width: $width,");
          if (height != null) buffer.writeln("$indent    height: $height,");
          buffer.writeln("$indent  fit: $fit,");
          buffer.write("$indent)");
        }
        break;

      case 'Icon':
        final iconVal = getProp('icon') ?? 'help';
        final colorStr = _formatColor(getProp('color'));
        final size = PropertyParser.tryParseDouble(getProp('size')) ?? 24.0;

        buffer.writeln("Icon(");
        buffer.writeln("$indent  Icons.$iconVal,");
        buffer.writeln("$indent  size: $size,");
        if (colorStr != 'null') buffer.writeln("$indent  color: $colorStr,");
        buffer.write("$indent)");
        break;

      case 'Divider':
        final height = PropertyParser.tryParseDouble(getProp('height')) ?? 16.0;
        final thickness = PropertyParser.tryParseDouble(getProp('thickness')) ?? 1.0;
        final colorStr = _formatColor(getProp('color'));

        buffer.writeln("Divider(");
        buffer.writeln("$indent  height: $height,");
        buffer.writeln("$indent  thickness: $thickness,");
        if (colorStr != 'null') buffer.writeln("$indent  color: $colorStr,");
        buffer.write("$indent)");
        break;

      // ================== INPUTS ==================
      case 'TextField':
        final fieldName = getProp('fieldName') ?? node.id;
        final camel = _toCamelCase(fieldName.toString());
        final label = getProp('label') ?? fieldName;
        final hint = getProp('hint') ?? '';
        final isRequired = getProp('required') == true;

        buffer.writeln("TextFormField(");
        buffer.writeln("$indent  controller: controller.${camel}Controller,");
        buffer.writeln("$indent  decoration: InputDecoration(");
        buffer.writeln("$indent    labelText: '$label',");
        if (hint.isNotEmpty) buffer.writeln("$indent    hintText: '$hint',");
        buffer.writeln("$indent    border: const OutlineInputBorder(),");
        buffer.writeln("$indent  ),");
        if (isRequired) {
          buffer.writeln("$indent  validator: (val) {");
          buffer.writeln("$indent    if (val == null || val.isEmpty) {");
          buffer.writeln("$indent      return '$label is required';");
          buffer.writeln("$indent    }");
          buffer.writeln("$indent    return null;");
          buffer.writeln("$indent  },");
        }
        buffer.write("$indent)");
        break;

      case 'Dropdown':
        final fieldName = getProp('fieldName') ?? node.id;
        final camel = _toCamelCase(fieldName.toString());
        final label = getProp('label') ?? fieldName;
        final isRequired = getProp('required') == true;
        final optionsList = getProp('options') ?? ['Option One', 'Option Two'];

        buffer.writeln("Obx(() => DropdownButtonFormField<String>(");
        buffer.writeln("$indent  value: controller.$camel.value.isEmpty ? null : controller.$camel.value,");
        buffer.writeln("$indent  decoration: InputDecoration(");
        buffer.writeln("$indent    labelText: '$label',");
        buffer.writeln("$indent    border: const OutlineInputBorder(),");
        buffer.writeln("$indent  ),");
        buffer.writeln("$indent  items: const [");
        for (final opt in optionsList) {
          buffer.writeln("$indent    DropdownMenuItem(value: '$opt', child: Text('$opt')),");
        }
        buffer.writeln("$indent  ],");
        buffer.writeln("$indent  onChanged: (val) => controller.$camel.value = val ?? '',");
        if (isRequired) {
          buffer.writeln("$indent  validator: (val) {");
          buffer.writeln("$indent    if (val == null || val.isEmpty) {");
          buffer.writeln("$indent      return 'Please select an option';");
          buffer.writeln("$indent    }");
          buffer.writeln("$indent    return null;");
          buffer.writeln("$indent  },");
        }
        buffer.write("$indent))");
        break;

      case 'Checkbox':
        final fieldName = getProp('fieldName') ?? node.id;
        final camel = _toCamelCase(fieldName.toString());
        final label = getProp('label') ?? fieldName;

        buffer.writeln("Obx(() => CheckboxListTile(");
        buffer.writeln("$indent  title: Text('$label', style: GoogleFonts.inter(fontSize: 14)),");
        buffer.writeln("$indent  value: controller.$camel.value,");
        buffer.writeln("$indent  onChanged: (val) => controller.$camel.value = val ?? false,");
        buffer.writeln("$indent  controlAffinity: ListTileControlAffinity.leading,");
        buffer.write("$indent))");
        break;

      case 'Switch':
        final fieldName = getProp('fieldName') ?? node.id;
        final camel = _toCamelCase(fieldName.toString());
        final label = getProp('label') ?? fieldName;

        buffer.writeln("Obx(() => SwitchListTile(");
        buffer.writeln("$indent  title: Text('$label', style: GoogleFonts.inter(fontSize: 14)),");
        buffer.writeln("$indent  value: controller.$camel.value,");
        buffer.writeln("$indent  onChanged: (val) => controller.$camel.value = val ?? false,");
        buffer.write("$indent))");
        break;

      case 'DatePicker':
        final fieldName = getProp('fieldName') ?? node.id;
        final camel = _toCamelCase(fieldName.toString());
        final label = getProp('label') ?? fieldName;
        final isRequired = getProp('required') == true;

        buffer.writeln("TextFormField(");
        buffer.writeln("$indent  controller: controller.${camel}Controller,");
        buffer.writeln("$indent  readOnly: true,");
        buffer.writeln("$indent  decoration: InputDecoration(");
        buffer.writeln("$indent    labelText: '$label',");
        buffer.writeln("$indent    suffixIcon: const Icon(Icons.calendar_today_rounded),");
        buffer.writeln("$indent    border: const OutlineInputBorder(),");
        buffer.writeln("$indent  ),");
        buffer.writeln("$indent  onTap: () async {");
        buffer.writeln("$indent    final date = await showDatePicker(");
        buffer.writeln("$indent      context: context,");
        buffer.writeln("$indent      initialDate: DateTime.now(),");
        buffer.writeln("$indent      firstDate: DateTime(1900),");
        buffer.writeln("$indent      lastDate: DateTime(2100),");
        buffer.writeln("$indent    );");
        buffer.writeln("$indent    if (date != null) {");
        buffer.writeln("$indent      controller.${camel}Controller.text = '\${date.year}-\${date.month.toString().padLeft(2, '0')}-\${date.day.toString().padLeft(2, '0')}';");
        buffer.writeln("$indent    }");
        buffer.writeln("$indent  },");
        if (isRequired) {
          buffer.writeln("$indent  validator: (val) {");
          buffer.writeln("$indent    if (val == null || val.isEmpty) {");
          buffer.writeln("$indent      return 'Please pick a date';");
          buffer.writeln("$indent    }");
          buffer.writeln("$indent    return null;");
          buffer.writeln("$indent  },");
        }
        buffer.write("$indent)");
        break;

      case 'Spacer':
        buffer.write("const Spacer()");
        break;

      case 'SizedBox':
        final width = PropertyParser.tryParseDouble(getProp('width'));
        final height = PropertyParser.tryParseDouble(getProp('height'));
        final child = compileChild('child');

        buffer.writeln("SizedBox(");
        if (width != null) buffer.writeln("$indent  width: $width,");
        if (height != null) buffer.writeln("$indent  height: $height,");
        if (child != 'null') buffer.writeln("$indent  child: $child,");
        buffer.write("$indent)");
        break;

      case 'Expanded':
        final child = compileChild('child');
        buffer.writeln("Expanded(");
        buffer.writeln("$indent  child: ${child != 'null' ? child : 'const SizedBox.shrink()'},");
        buffer.write("$indent)");
        break;

      case 'Flexible':
        final child = compileChild('child');
        buffer.writeln("Flexible(");
        buffer.writeln("$indent  child: ${child != 'null' ? child : 'const SizedBox.shrink()'},");
        buffer.write("$indent)");
        break;

      case 'SafeArea':
        final child = compileChild('child');
        buffer.writeln("SafeArea(");
        buffer.writeln("$indent  child: ${child != 'null' ? child : 'const SizedBox.shrink()'},");
        buffer.write("$indent)");
        break;

      default:
        // Render unsupported widget placeholder
        buffer.writeln("Container(");
        buffer.writeln("$indent  padding: const EdgeInsets.all(12),");
        buffer.writeln("$indent  color: Colors.red[50],");
        buffer.writeln("$indent  child: Text('Layout Widget: $type', style: const TextStyle(color: Colors.red)),");
        buffer.write("$indent)");
        break;
    }

    return buffer.toString();
  }

  // --- Static Helper Formatters ---

  static String _formatColor(dynamic val) {
    if (val == null) return 'null';
    final color = PropertyParser.parseColor(val);
    if (color == null) return 'null';
    
    if (color == Colors.white) return 'Colors.white';
    if (color == Colors.black) return 'Colors.black';
    if (color == Colors.transparent) return 'Colors.transparent';
    if (color == Colors.blue) return 'Colors.blue';
    if (color == Colors.green) return 'Colors.green';
    if (color == Colors.red) return 'Colors.red';

    final hexStr = color.value.toRadixString(16).toUpperCase().padLeft(8, '0');
    return 'const Color(0x$hexStr)';
  }

  static String _formatGradient(ComponentNode node) {
    final gradientStyle = node.styles['backgroundImage'] ?? node.styles['gradient'];
    if (gradientStyle == null) return 'null';

    final gradients = PropertyParser.parseGradients(gradientStyle);
    if (gradients.isEmpty) {
      final start = PropertyParser.parseColor(node.styles['gradientStart']);
      final end = PropertyParser.parseColor(node.styles['gradientEnd']);
      if (start != null && end != null) {
        return 'const LinearGradient(colors: [${_formatColor(start)}, ${_formatColor(end)}], begin: Alignment.topLeft, end: Alignment.bottomRight)';
      }
      return 'null';
    }

    final g = gradients.first;
    if (g is LinearGradient) {
      final colorsStr = g.colors.map((c) => _formatColor(c)).join(', ');
      final beginAlign = _formatAlignment(g.begin);
      final endAlign = _formatAlignment(g.end);
      return 'const LinearGradient(colors: [$colorsStr], begin: $beginAlign, end: $endAlign)';
    } else if (g is RadialGradient) {
      final colorsStr = g.colors.map((c) => _formatColor(c)).join(', ');
      final centerAlign = _formatAlignment(g.center);
      return 'const RadialGradient(colors: [$colorsStr], center: $centerAlign, radius: ${g.radius})';
    }

    return 'null';
  }

  static String _formatPadding(dynamic val) {
    if (val == null) return 'EdgeInsets.zero';
    final pad = PropertyParser.parsePadding(val);
    if (pad == EdgeInsets.zero) return 'EdgeInsets.zero';

    if (pad is EdgeInsets) {
      final edge = pad;
      if (edge.left == edge.top && edge.left == edge.right && edge.left == edge.bottom) {
        return 'const EdgeInsets.all(${edge.left})';
      }
      if (edge.left == edge.right && edge.top == edge.bottom) {
        return 'const EdgeInsets.symmetric(horizontal: ${edge.left}, vertical: ${edge.top})';
      }
      return 'const EdgeInsets.fromLTRB(${edge.left}, ${edge.top}, ${edge.right}, ${edge.bottom})';
    }
    return 'EdgeInsets.zero';
  }

  static String _formatAlignment(dynamic val) {
    if (val == null) return 'Alignment.center';
    if (val is Alignment) {
      if (val == Alignment.topLeft) return 'Alignment.topLeft';
      if (val == Alignment.topCenter) return 'Alignment.topCenter';
      if (val == Alignment.topRight) return 'Alignment.topRight';
      if (val == Alignment.centerLeft) return 'Alignment.centerLeft';
      if (val == Alignment.center) return 'Alignment.center';
      if (val == Alignment.centerRight) return 'Alignment.centerRight';
      if (val == Alignment.bottomLeft) return 'Alignment.bottomLeft';
      if (val == Alignment.bottomCenter) return 'Alignment.bottomCenter';
      if (val == Alignment.bottomRight) return 'Alignment.bottomRight';
    }
    
    final str = val.toString().toLowerCase().trim();
    if (str.contains('topleft') || str.contains('top_left')) return 'Alignment.topLeft';
    if (str.contains('topcenter') || str.contains('top_center')) return 'Alignment.topCenter';
    if (str.contains('topright') || str.contains('top_right')) return 'Alignment.topRight';
    if (str.contains('centerleft') || str.contains('center_left')) return 'Alignment.centerLeft';
    if (str.contains('centerright') || str.contains('center_right')) return 'Alignment.centerRight';
    if (str.contains('bottomleft') || str.contains('bottom_left')) return 'Alignment.bottomLeft';
    if (str.contains('bottomcenter') || str.contains('bottom_center')) return 'Alignment.bottomCenter';
    if (str.contains('bottomright') || str.contains('bottom_right')) return 'Alignment.bottomRight';
    return 'Alignment.center';
  }

  static String _formatMainAlign(dynamic val) {
    if (val == null) return 'MainAxisAlignment.start';
    final str = val.toString().toLowerCase().trim().replaceAll('_', '').replaceAll(' ', '');
    switch (str) {
      case 'center': return 'MainAxisAlignment.center';
      case 'end': return 'MainAxisAlignment.end';
      case 'spacebetween': return 'MainAxisAlignment.spaceBetween';
      case 'spacearound': return 'MainAxisAlignment.spaceAround';
      case 'spaceevenly': return 'MainAxisAlignment.spaceEvenly';
      default: return 'MainAxisAlignment.start';
    }
  }

  static String _formatCrossAlign(dynamic val) {
    if (val == null) return 'CrossAxisAlignment.center';
    final str = val.toString().toLowerCase().trim().replaceAll('_', '').replaceAll(' ', '');
    switch (str) {
      case 'start': return 'CrossAxisAlignment.start';
      case 'end': return 'CrossAxisAlignment.end';
      case 'stretch': return 'CrossAxisAlignment.stretch';
      case 'baseline': return 'CrossAxisAlignment.baseline';
      default: return 'CrossAxisAlignment.center';
    }
  }

  static String _formatFontWeight(dynamic val) {
    if (val == null) return 'FontWeight.normal';
    final str = val.toString().toLowerCase().trim();
    switch (str) {
      case 'bold': return 'FontWeight.bold';
      case 'w100': return 'FontWeight.w100';
      case 'w200': return 'FontWeight.w200';
      case 'w300': return 'FontWeight.w300';
      case 'w400': return 'FontWeight.w400';
      case 'w500': return 'FontWeight.w500';
      case 'w600': return 'FontWeight.w600';
      case 'w700': return 'FontWeight.w700';
      case 'w800': return 'FontWeight.w800';
      case 'w900': return 'FontWeight.w900';
      default: return 'FontWeight.normal';
    }
  }

  static String _formatTextAlign(dynamic val) {
    if (val == null) return 'TextAlign.start';
    switch (val.toString().toLowerCase().trim()) {
      case 'left': return 'TextAlign.left';
      case 'right': return 'TextAlign.right';
      case 'center': return 'TextAlign.center';
      case 'justify': return 'TextAlign.justify';
      default: return 'TextAlign.start';
    }
  }

  static String _formatBoxFit(dynamic val) {
    if (val == null) return 'BoxFit.cover';
    switch (val.toString().toLowerCase().trim()) {
      case 'fill': return 'BoxFit.fill';
      case 'contain': return 'BoxFit.contain';
      case 'fitwidth': return 'BoxFit.fitWidth';
      case 'fitheight': return 'BoxFit.fitHeight';
      case 'none': return 'BoxFit.none';
      case 'scaledown': return 'BoxFit.scaleDown';
      default: return 'BoxFit.cover';
    }
  }

  static String _toCamelCase(String s) {
    final clean = s.replaceAll(RegExp(r'[^a-zA-Z0-9\s_\-]'), '').trim();
    if (clean.isEmpty) return '';
    final parts = clean.split(RegExp(r'[\s_\-]+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.write(parts.first.toLowerCase());
    for (int i = 1; i < parts.length; i++) {
      final p = parts[i];
      buffer.write(p[0].toUpperCase() + p.substring(1).toLowerCase());
    }
    return buffer.toString();
  }

  static void _findInputFields(ComponentNode node, List<ComponentNode> inputFields) {
    const inputTypes = {'TextField', 'Dropdown', 'Radio', 'Checkbox', 'DatePicker', 'Switch', 'Slider', 'OTP', 'Search'};
    if (inputTypes.contains(node.type)) {
      inputFields.add(node);
    }
    for (final child in node.children) {
      _findInputFields(child, inputFields);
    }
    for (final slotChild in node.slots.values) {
      if (slotChild != null) {
        _findInputFields(slotChild, inputFields);
      }
    }
  }
}
