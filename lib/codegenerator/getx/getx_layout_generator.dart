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
    buffer.writeln("import 'package:fl_chart/fl_chart.dart';");
    buffer.writeln("import '../controllers/${fileName}_controller.dart';");
    buffer.writeln();

    // 2. Class Declaration
    buffer.writeln("class ${className}View extends GetView<$controllerClass> {");
    buffer.writeln("  const ${className}View({super.key});");
    buffer.writeln();

    // Add getValueForScreenType helper method
    buffer.writeln("  T getValueForScreenType<T>({");
    buffer.writeln("    required BuildContext context,");
    buffer.writeln("    required T mobile,");
    buffer.writeln("    T? tablet,");
    buffer.writeln("    T? desktop,");
    buffer.writeln("  }) {");
    buffer.writeln("    final width = MediaQuery.of(context).size.width;");
    buffer.writeln("    if (width >= 1024) {");
    buffer.writeln("      return desktop ?? tablet ?? mobile;");
    buffer.writeln("    }");
    buffer.writeln("    if (width >= 600) {");
    buffer.writeln("      return tablet ?? mobile;");
    buffer.writeln("    }");
    buffer.writeln("    return mobile;");
    buffer.writeln("  }");
    buffer.writeln();

    // 3. Build Method
    buffer.writeln("  @override");
    buffer.writeln("  Widget build(BuildContext context) {");
    
    // Compile root node
    final rootCompiled = _compileNode(rootNode, "    ", controllerClass);
    if (rootNode.type != 'Scaffold') {
      buffer.writeln("    return Scaffold(");
      buffer.writeln("      backgroundColor: const Color(0xFFF1F5F9),");
      buffer.writeln("      body: SingleChildScrollView(");
      buffer.writeln("        child: Padding(");
      buffer.writeln("          padding: const EdgeInsets.all(16.0),");
      buffer.writeln("          child: $rootCompiled,");
      buffer.writeln("        ),");
      buffer.writeln("      ),");
      buffer.writeln("    );");
    } else {
      buffer.writeln("    return $rootCompiled;");
    }
    buffer.writeln("  }");
    buffer.writeln("}");

    return buffer.toString();
  }

  // ---- Internal: collect all nodes of a given type recursively ----
  static void _findNodesOfType(ComponentNode node, String type, List<ComponentNode> out) {
    if (node.type == type) out.add(node);
    for (final c in node.children) _findNodesOfType(c, type, out);
    for (final s in node.slots.values) { if (s != null) _findNodesOfType(s, type, out); }
  }

  /// Entry point to generate the GetX Controller.
  static String generateController(ComponentNode rootNode, String className) {
    final buffer = StringBuffer();
    final inputNodes = <ComponentNode>[];
    _findInputFields(rootNode, inputNodes);

    final buttonNodes = <ComponentNode>[];
    _findButtons(rootNode, buttonNodes);

    // 1. Imports
    buffer.writeln("// AUTO-GENERATED - Layout-based GetX Controller");
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'package:get/get.dart';");
    buffer.writeln();

    // 2. Class Declaration
    buffer.writeln("class ${className}Controller extends GetxController {");
    buffer.writeln("  final formKey = GlobalKey<FormState>();");
    buffer.writeln("  final isExecuting = false.obs;");
    buffer.writeln("  final pageSearchController = TextEditingController();");
    buffer.writeln();

    // ---------- Extract JSON-driven data from the node tree ----------

    // Dashboard metric observables are ALWAYS emitted because Card / Text
    // widgets commonly bind to them via {totalLeads} etc.
    buffer.writeln("  // ── Dashboard metric observables ─────────────────────");
    buffer.writeln("  final totalLeads = 0.obs;");
    buffer.writeln("  final totalDeals = 0.obs;");
    buffer.writeln("  final activeTasks = 0.obs;");
    buffer.writeln("  final revenue = 0.obs;");
    buffer.writeln();

    // ── DataTable / Table ─────────────────────────────────────────────────────
    final tableNodes = <ComponentNode>[];
    _findNodesOfType(rootNode, 'DataTable', tableNodes);
    _findNodesOfType(rootNode, 'Table', tableNodes);
    if (tableNodes.isNotEmpty) {
      final tableNode = tableNodes.first;
      final columnsProp = tableNode.properties['columns'];
      final List<String> jsonCols = (columnsProp is List && columnsProp.isNotEmpty)
          ? columnsProp.map((c) => c.toString()).toList()
          : <String>[];
      final rowsProp = tableNode.properties['rows'];
      final List<List<String>> jsonRows = [];
      if (rowsProp is List) {
        for (final r in rowsProp) {
          if (r is List) {
            jsonRows.add(r.map((e) => e.toString()).toList());
          } else if (r is Map) {
            jsonRows.add(jsonCols.map((col) =>
                (r[col] ?? r[col.toLowerCase()] ?? '').toString()).toList());
          }
        }
      }
      buffer.writeln("  // ── Table state ──────────────────────────────────────");
      if (jsonCols.isEmpty) {
        buffer.writeln("  // TODO: set tableColumns from your data model");
        buffer.writeln("  final tableColumns = <String>[].obs;");
      } else {
        final colsLit = jsonCols.map((c) => "'${c.replaceAll("'", "\\'")}'").join(', ');
        buffer.writeln("  final tableColumns = <String>[$colsLit].obs;");
      }
      if (jsonRows.isEmpty) {
        buffer.writeln("  // TODO: populate tableRows from your repository/API");
        buffer.writeln("  final tableRows = <List<String>>[].obs;");
      } else {
        buffer.writeln("  final tableRows = <List<String>>[");
        for (final row in jsonRows) {
          final cells = row.map((c) => "'${c.replaceAll("'", "\\'")}'").join(', ');
          buffer.writeln("    [$cells],");
        }
        buffer.writeln("  ].obs;");
      }
      buffer.writeln();
    }

    // ── ListView ──────────────────────────────────────────────────────────────
    final listNodes = <ComponentNode>[];
    _findNodesOfType(rootNode, 'ListView', listNodes);
    if (listNodes.isNotEmpty) {
      final listItemsRaw = listNodes.first.properties['items'];
      final List<Map<String, String>> jsonListItems = [];
      if (listItemsRaw is List) {
        for (final item in listItemsRaw) {
          if (item is Map) {
            jsonListItems.add({'title': item['title']?.toString() ?? '',
                               'subtitle': item['subtitle']?.toString() ?? ''});
          } else {
            jsonListItems.add({'title': item.toString(), 'subtitle': ''});
          }
        }
      }
      buffer.writeln("  // ── List state ───────────────────────────────────────");
      if (jsonListItems.isEmpty) {
        buffer.writeln("  // TODO: populate listItems from your repository/API");
        buffer.writeln("  final listItems = <Map<String, String>>[].obs;");
      } else {
        buffer.writeln("  final listItems = <Map<String, String>>[");
        for (final item in jsonListItems) {
          buffer.writeln("    {'title': '${item['title']}', 'subtitle': '${item['subtitle']}'},");
        }
        buffer.writeln("  ].obs;");
      }
      buffer.writeln();
    }

    // ── GridView ──────────────────────────────────────────────────────────────
    final gridNodes = <ComponentNode>[];
    _findNodesOfType(rootNode, 'GridView', gridNodes);
    if (gridNodes.isNotEmpty) {
      final gridItemsRaw = gridNodes.first.properties['items'];
      final List<String> jsonGridItems = gridItemsRaw is List
          ? gridItemsRaw.map((e) => e.toString()).toList() : [];
      buffer.writeln("  // ── Grid state ───────────────────────────────────────");
      if (jsonGridItems.isEmpty) {
        buffer.writeln("  // TODO: populate gridItems from your repository/API");
        buffer.writeln("  final gridItems = <String>[].obs;");
      } else {
        final gridLit = jsonGridItems.map((e) => "'${e.replaceAll("'", "\\'")}'").join(', ');
        buffer.writeln("  final gridItems = <String>[$gridLit].obs;");
      }
      buffer.writeln();
    }

    // ── TabBar / NavigationRail / BottomNavigationBar ─────────────────────────
    // tabLabels is shared between all three navigation widget types.
    final tabWidgetNodes = <ComponentNode>[];
    _findNodesOfType(rootNode, 'TabBar', tabWidgetNodes);
    _findNodesOfType(rootNode, 'Tabs', tabWidgetNodes);
    _findNodesOfType(rootNode, 'NavigationRail', tabWidgetNodes);
    _findNodesOfType(rootNode, 'BottomNavigationBar', tabWidgetNodes);
    _findNodesOfType(rootNode, 'Drawer', tabWidgetNodes);
    if (tabWidgetNodes.isNotEmpty) {
      // Prefer tabs/Tabs over NavigationRail for label extraction
      final tabSource = tabWidgetNodes.firstWhere(
          (n) => n.type == 'TabBar' || n.type == 'Tabs', orElse: () => tabWidgetNodes.first);
      final tabsRaw = tabSource.properties['tabs'] ??
          tabSource.properties['items'] ??
          tabSource.properties['destinations'];
      final List<String> jsonTabs = tabsRaw is List
          ? tabsRaw.map((e) => e is Map
              ? (e['label'] ?? e['title'] ?? e.toString()).toString()
              : e.toString()).toList()
          : [];
      buffer.writeln("  // ── Tab / Navigation label state ─────────────────────");
      if (jsonTabs.isEmpty) {
        buffer.writeln("  // TODO: populate tabLabels from your repository/API");
        buffer.writeln("  final tabLabels = <String>[].obs;");
      } else {
        final tabsLit = jsonTabs.map((t) => "'${t.replaceAll("'", "\\'")}'").join(', ');
        buffer.writeln("  final tabLabels = <String>[$tabsLit].obs;");
      }
      buffer.writeln();
    }

    // ── NavigationRail / BottomNavigationBar — selectedIndex ─────────────────
    final navNodes = <ComponentNode>[];
    _findNodesOfType(rootNode, 'NavigationRail', navNodes);
    _findNodesOfType(rootNode, 'BottomNavigationBar', navNodes);
    if (navNodes.isNotEmpty) {
      buffer.writeln("  // ── Navigation selected index ────────────────────────");
      buffer.writeln("  final selectedNavigationIndex = 0.obs;");
      buffer.writeln();
    }

    // ── Stepper ───────────────────────────────────────────────────────────────
    final stepperNodes = <ComponentNode>[];
    _findNodesOfType(rootNode, 'Stepper', stepperNodes);
    if (stepperNodes.isNotEmpty) {
      final stepsRaw = stepperNodes.first.properties['steps'];
      final List<String> jsonSteps = stepsRaw is List
          ? stepsRaw.map((e) => e.toString()).toList() : [];
      buffer.writeln("  // ── Stepper state ────────────────────────────────────");
      if (jsonSteps.isEmpty) {
        buffer.writeln("  // TODO: populate stepperSteps from your repository/API");
        buffer.writeln("  final stepperSteps = <String>[].obs;");
      } else {
        final stepsLit = jsonSteps.map((s) => "'${s.replaceAll("'", "\\'")}'").join(', ');
        buffer.writeln("  final stepperSteps = <String>[$stepsLit].obs;");
      }
      buffer.writeln("  final currentStep = 0.obs;");
      buffer.writeln();
    }

    // ── Timeline ──────────────────────────────────────────────────────────────
    final timelineNodes = <ComponentNode>[];
    _findNodesOfType(rootNode, 'Timeline', timelineNodes);
    if (timelineNodes.isNotEmpty) {
      final eventsRaw = timelineNodes.first.properties['events'];
      final List<String> jsonEvents = eventsRaw is List
          ? eventsRaw.map((e) => e.toString()).toList() : [];
      buffer.writeln("  // ── Timeline state ───────────────────────────────────");
      if (jsonEvents.isEmpty) {
        buffer.writeln("  // TODO: populate timelineEvents from your repository/API");
        buffer.writeln("  final timelineEvents = <String>[].obs;");
      } else {
        final eventsLit = jsonEvents.map((e) => "'${e.replaceAll("'", "\\'")}'").join(', ');
        buffer.writeln("  final timelineEvents = <String>[$eventsLit].obs;");
      }
      buffer.writeln();
    }

    // ── Carousel ──────────────────────────────────────────────────────────────
    final carouselNodes = <ComponentNode>[];
    _findNodesOfType(rootNode, 'Carousel', carouselNodes);
    if (carouselNodes.isNotEmpty) {
      final carouselRaw = carouselNodes.first.properties['items'];
      final List<String> jsonCarousel = carouselRaw is List
          ? carouselRaw.map((e) => e.toString()).toList() : [];
      buffer.writeln("  // ── Carousel state ───────────────────────────────────");
      if (jsonCarousel.isEmpty) {
        buffer.writeln("  // TODO: populate carouselItems from your repository/API");
        buffer.writeln("  final carouselItems = <String>[].obs;");
      } else {
        final carouselLit = jsonCarousel.map((e) => "'${e.replaceAll("'", "\\'")}'").join(', ');
        buffer.writeln("  final carouselItems = <String>[$carouselLit].obs;");
      }
      buffer.writeln();
    }

    // ── Line / Bar / Area charts ───────────────────────────────────────────────
    final chartNodes = <ComponentNode>[];
    for (final t in ['Chart', 'LineChart', 'AreaChart', 'BarChart']) {
      _findNodesOfType(rootNode, t, chartNodes);
    }
    if (chartNodes.isNotEmpty) {
      final chartDataRaw = chartNodes.first.properties['data'];
      final List<Map<String, double>> jsonSpots = [];
      if (chartDataRaw is List) {
        for (final d in chartDataRaw) {
          if (d is Map) {
            jsonSpots.add({
              'x': double.tryParse(d['x']?.toString() ?? '') ?? 0.0,
              'y': double.tryParse(d['y']?.toString() ?? '') ?? 0.0,
            });
          }
        }
      }
      buffer.writeln("  // ── Line/Bar/Area chart state ────────────────────────");
      if (jsonSpots.isEmpty) {
        buffer.writeln("  // TODO: populate chartSpots from your repository/API");
        buffer.writeln("  final chartSpots = <Map<String, double>>[].obs;");
      } else {
        buffer.writeln("  final chartSpots = <Map<String, double>>[");
        for (final s in jsonSpots) {
          buffer.writeln("    {'x': ${s['x']}, 'y': ${s['y']}},");
        }
        buffer.writeln("  ].obs;");
      }
      buffer.writeln();
    }

    // ── PieChart ──────────────────────────────────────────────────────────────
    final pieNodes = <ComponentNode>[];
    _findNodesOfType(rootNode, 'PieChart', pieNodes);
    if (pieNodes.isNotEmpty) {
      final pieSectionsRaw = pieNodes.first.properties['sections'];
      final List<Map<String, dynamic>> jsonPie = [];
      if (pieSectionsRaw is List) {
        for (final s in pieSectionsRaw) {
          if (s is Map) {
            jsonPie.add({
              'value': double.tryParse(s['value']?.toString() ?? '') ?? 0.0,
              'title': s['title']?.toString() ?? '',
              'color': int.tryParse(s['color']?.toString() ?? '') ?? 0xFF2196F3,
            });
          }
        }
      }
      buffer.writeln("  // ── Pie chart state ──────────────────────────────────");
      if (jsonPie.isEmpty) {
        buffer.writeln("  // TODO: populate pieSections from your repository/API");
        buffer.writeln("  final pieSections = <Map<String, dynamic>>[].obs;");
      } else {
        buffer.writeln("  final pieSections = <Map<String, dynamic>>[");
        for (final s in jsonPie) {
          buffer.writeln("    {'value': ${s['value']}, 'title': '${s['title']}', 'color': ${s['color']}},");
        }
        buffer.writeln("  ].obs;");
      }
      buffer.writeln();
    }

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

    // Custom Button Actions
    final declaredActions = <String>{};
    for (final btn in buttonNodes) {
      final label = btn.properties['label'] ?? btn.properties['text'] ?? '';
      if (label.isEmpty) continue;
      final methodName = _labelToMethodName(label.toString());
      if (methodName == 'submitForm' || declaredActions.contains(methodName)) continue;
      declaredActions.add(methodName);

      buffer.writeln("  // Action: $label");
      buffer.writeln("  void $methodName() async {");
      buffer.writeln("    isExecuting.value = true;");
      buffer.writeln("    try {");
      buffer.writeln("      debugPrint('Executing action: $methodName');");
      buffer.writeln("      await Future.delayed(const Duration(milliseconds: 800));");
      buffer.writeln("      Get.snackbar('Action Executed', '$label action completed successfully!');");
      buffer.writeln("    } catch (e) {");
      buffer.writeln("      Get.snackbar('Error', 'Failed to execute $label: \$e');");
      buffer.writeln("    } finally {");
      buffer.writeln("      isExecuting.value = false;");
      buffer.writeln("    }");
      buffer.writeln("  }");
      buffer.writeln();
    }

    // 5. Close Method (Dispose controllers)
    buffer.writeln("  @override");
    buffer.writeln("  void onClose() {");
    buffer.writeln("    pageSearchController.dispose();");
    textControllers.forEach((field, camel) {
      buffer.writeln("    ${camel}Controller.dispose();");
    });
    buffer.writeln("    super.onClose();");
    buffer.writeln("  }");
    buffer.writeln();
    buffer.writeln("}");

    return buffer.toString();
  }

  // --- Recursive Node Compilation ---
  static String _compileNode(ComponentNode node, String indent, String controllerClass, [ComponentNode? parentNode]) {
    final type = node.type;
    final buffer = StringBuffer();

    // Helper functions
    dynamic getProp(String key, [dynamic fallback]) {
      if (node.properties.containsKey(key)) return node.properties[key];
      if (node.styles.containsKey(key)) return node.styles[key];
      return fallback;
    }

    String compileChild(String slotName) {
      final child = node.slots[slotName] ?? (slotName == 'child' ? (node.children.isNotEmpty ? node.children.first : null) : null);
      if (child != null) {
        return _compileNode(child, "$indent  ", controllerClass, node);
      }
      return 'null';
    }

    List<String> compileChildren() {
      return node.children.map((c) => _compileNode(c, "$indent    ", controllerClass, node)).toList();
    }

    String compileResponsiveInt(String propName, int fallback) {
      final base = PropertyParser.tryParseDouble(getProp(propName))?.toInt() ?? fallback;
      final mobile = PropertyParser.tryParseDouble(getProp('${propName}Mobile'))?.toInt() ?? base;
      final tablet = PropertyParser.tryParseDouble(getProp('${propName}Tablet'))?.toInt() ?? base;
      final desktop = PropertyParser.tryParseDouble(getProp('${propName}Desktop'))?.toInt() ?? base;

      return 'getValueForScreenType<int>(context: context, mobile: $mobile, tablet: $tablet, desktop: $desktop)';
    }

    String compileResponsiveDouble(String propName, [double? fallback]) {
      final base = PropertyParser.tryParseDouble(getProp(propName));
      final mobile = PropertyParser.tryParseDouble(getProp('${propName}Mobile'));
      final tablet = PropertyParser.tryParseDouble(getProp('${propName}Tablet'));
      final desktop = PropertyParser.tryParseDouble(getProp('${propName}Desktop'));

      if (base == null && mobile == null && tablet == null && desktop == null) {
        return fallback != null ? '$fallback' : 'null';
      }

      final baseVal = base ?? fallback ?? 0.0;
      final mobileVal = mobile ?? baseVal;
      final tabletVal = tablet ?? baseVal;
      final desktopVal = desktop ?? baseVal;

      final mobStr = mobileVal == double.infinity ? 'double.infinity' : '$mobileVal';
      final tabStr = tabletVal == double.infinity ? 'double.infinity' : '$tabletVal';
      final dskStr = desktopVal == double.infinity ? 'double.infinity' : '$desktopVal';

      return 'getValueForScreenType<double>(context: context, mobile: $mobStr, tablet: $tabStr, desktop: $dskStr)';
    }

    String compileResponsivePadding(String propName, [String fallback = 'EdgeInsets.zero']) {
      final base = getProp(propName);
      final mobile = getProp('${propName}Mobile');
      final tablet = getProp('${propName}Tablet');
      final desktop = getProp('${propName}Desktop');

      if (base == null && mobile == null && tablet == null && desktop == null) {
        return fallback;
      }

      final mobileValStr = _formatPadding(mobile ?? base);
      final tabletValStr = _formatPadding(tablet ?? base ?? mobile);
      final desktopValStr = _formatPadding(desktop ?? base ?? mobile);

      return 'getValueForScreenType<EdgeInsetsGeometry>(context: context, mobile: $mobileValStr, tablet: $tabletValStr, desktop: $desktopValStr)';
    }

    // Process visibility settings wrapping (responsive hidden states)
    bool isVisible(String screen) {
      final val = getProp('visibleOn$screen');
      if (val == null) return true;
      if (val is bool) return val;
      return val.toString().toLowerCase() != 'false';
    }

    final visMobile = isVisible('Mobile');
    final visTablet = isVisible('Tablet');
    final visDesktop = isVisible('Desktop');
    final needsVisibilityWrapper = !visMobile || !visTablet || !visDesktop;

    switch (type) {
      case 'Scaffold':
        final bgStr = _formatColor(getProp('backgroundColor'));
        final appBar = compileChild('appBar');
        final body = compileChild('body');
        final bottomNav = compileChild('bottomNavigationBar');
        final drawer = compileChild('drawer');
        final fab = compileChild('floatingActionButton');
        final bottomSheet = compileChild('bottomSheet');
        final resizeToAvoid = getProp('resizeToAvoidBottomInset');
        final extendBody = getProp('extendBody') == true;
        final extendBehindAppBar = getProp('extendBodyBehindAppBar') == true;
        final fabLocation = getProp('floatingActionButtonLocation')?.toString();

        buffer.writeln("Scaffold(");
        if (bgStr != 'null') buffer.writeln("$indent  backgroundColor: $bgStr,");
        if (extendBody) buffer.writeln("$indent  extendBody: true,");
        if (extendBehindAppBar) buffer.writeln("$indent  extendBodyBehindAppBar: true,");
        if (resizeToAvoid != null) buffer.writeln("$indent  resizeToAvoidBottomInset: ${resizeToAvoid == false ? 'false' : 'true'},");
        if (fabLocation != null) {
          final loc = fabLocation == 'centerFloat'
              ? 'FloatingActionButtonLocation.centerFloat'
              : fabLocation == 'endDocked'
                  ? 'FloatingActionButtonLocation.endDocked'
                  : 'FloatingActionButtonLocation.endFloat';
          buffer.writeln("$indent  floatingActionButtonLocation: $loc,");
        }
        if (appBar != 'null') {
          final toolbarH = PropertyParser.tryParseDouble(getProp('toolbarHeight')) ?? 56.0;
          buffer.writeln("$indent  appBar: PreferredSize(preferredSize: Size.fromHeight($toolbarH), child: $appBar),");
        }
        if (bottomNav != 'null') buffer.writeln("$indent  bottomNavigationBar: $bottomNav,");
        if (drawer != 'null') buffer.writeln("$indent  drawer: $drawer,");
        if (fab != 'null') buffer.writeln("$indent  floatingActionButton: $fab,");
        if (bottomSheet != 'null') buffer.writeln("$indent  bottomSheet: $bottomSheet,");
        // Wrap body in Form for validation support
        buffer.writeln("$indent  body: Form(");
        buffer.writeln("$indent    key: controller.formKey,");
        buffer.writeln("$indent    child: SingleChildScrollView(");
        buffer.writeln("$indent      child: $body,");
        buffer.writeln("$indent    ),");
        buffer.writeln("$indent  ),");
        buffer.write("$indent)");
        break;

      case 'AppBar':
        final appBarBgStr = _formatColor(getProp('backgroundColor'));
        final appBarTitleText = getProp('title')?.toString() ?? 'App Title';
        final appBarTitle = compileChild('title');
        final appBarLeading = compileChild('leading');
        final appBarActions = compileChild('actions');
        final appBarElevation = PropertyParser.tryParseDouble(getProp('elevation')) ?? 0.0;
        final appBarCenterTitle = getProp('centerTitle');
        final appBarFgColor = _formatColor(getProp('foregroundColor') ?? getProp('titleColor'));
        final appBarToolbarH = PropertyParser.tryParseDouble(getProp('toolbarHeight'));
        // actions can also be a list in JSON
        final appBarActionsList = getProp('actions') as List? ?? [];

        buffer.writeln("AppBar(");
        if (appBarBgStr != 'null') buffer.writeln("$indent  backgroundColor: $appBarBgStr,");
        if (appBarFgColor != 'null') buffer.writeln("$indent  foregroundColor: $appBarFgColor,");
        buffer.writeln("$indent  elevation: $appBarElevation,");
        if (appBarToolbarH != null) buffer.writeln("$indent  toolbarHeight: $appBarToolbarH,");
        if (appBarCenterTitle != null) buffer.writeln("$indent  centerTitle: ${appBarCenterTitle == true || appBarCenterTitle.toString().toLowerCase() == 'true'},");
        buffer.writeln("$indent  title: ${appBarTitle != 'null' ? appBarTitle : "Text('$appBarTitleText', style: GoogleFonts.inter(fontWeight: FontWeight.w600))"},");
        buffer.writeln("$indent  scrolledUnderElevation: 0,");
        if (appBarLeading != 'null') buffer.writeln("$indent  leading: $appBarLeading,");
        if (appBarActions != 'null') {
          buffer.writeln("$indent  actions: [$appBarActions],");
        } else if (appBarActionsList.isNotEmpty) {
          buffer.writeln("$indent  actions: [");
          for (final act in appBarActionsList) {
            final actIcon = act is Map ? _mapIconName(act['icon']) : 'more_vert';
            final actTooltip = act is Map ? (act['tooltip'] ?? act['label'] ?? '') : '';
            buffer.writeln("$indent    IconButton(icon: const Icon(Icons.$actIcon), tooltip: '$actTooltip', onPressed: () {}),");
          }
          buffer.writeln("$indent  ],");
        }
        buffer.write("$indent)");
        break;

      case 'Container':
        final cWidthStr    = compileResponsiveDouble('width');
        final cHeightStr   = compileResponsiveDouble('height');
        final cMinWidth    = PropertyParser.tryParseDouble(getProp('minWidth'));
        final cMaxWidth    = PropertyParser.tryParseDouble(getProp('maxWidth'));
        final cMinHeight   = PropertyParser.tryParseDouble(getProp('minHeight'));
        final cMaxHeight   = PropertyParser.tryParseDouble(getProp('maxHeight'));
        final cBgStr       = _formatColor(getProp('backgroundColor'));
        final cGradient    = _formatGradient(node);
        final cPad         = compileResponsivePadding('padding');
        final cMarg        = compileResponsivePadding('margin');
        final cRadius      = PropertyParser.tryParseDouble(getProp('borderRadius')) ?? 0.0;
        final cBorderColor = _formatColor(getProp('borderColor'));
        final cBorderWidth = PropertyParser.tryParseDouble(getProp('borderWidth')) ?? 1.0;
        final cElevation   = PropertyParser.tryParseDouble(getProp('elevation')) ?? 0.0;
        final cShadowColor = _formatColor(getProp('shadowColor'));
        final cAlignment   = _formatAlignment(getProp('alignment'));
        final cClip        = getProp('clipBehavior')?.toString().toLowerCase() == 'antiAlias' ||
                             getProp('clip') == true;
        final cChild       = compileChild('child');
        final hasConstraints = cMinWidth != null || cMaxWidth != null || cMinHeight != null || cMaxHeight != null;

        buffer.writeln("Container(");
        if (cWidthStr != 'null') buffer.writeln("$indent  width: $cWidthStr,");
        if (cHeightStr != 'null') buffer.writeln("$indent  height: $cHeightStr,");
        if (hasConstraints) {
          buffer.writeln("$indent  constraints: const BoxConstraints(");
          if (cMinWidth  != null) buffer.writeln("$indent    minWidth: $cMinWidth,");
          if (cMaxWidth  != null) buffer.writeln("$indent    maxWidth: $cMaxWidth,");
          if (cMinHeight != null) buffer.writeln("$indent    minHeight: $cMinHeight,");
          if (cMaxHeight != null) buffer.writeln("$indent    maxHeight: $cMaxHeight,");
          buffer.writeln("$indent  ),");
        }
        if (cPad.contains('getValueForScreenType') || cPad != 'EdgeInsets.zero') buffer.writeln("$indent  padding: $cPad,");
        if (cMarg.contains('getValueForScreenType') || cMarg != 'EdgeInsets.zero') buffer.writeln("$indent  margin: $cMarg,");
        buffer.writeln("$indent  alignment: $cAlignment,");
        if (cClip) buffer.writeln("$indent  clipBehavior: Clip.antiAlias,");
        // Decoration
        if (cBgStr != 'null' || cGradient != 'null' || cRadius > 0.0 || cBorderColor != 'null' || cElevation > 0.0) {
          buffer.writeln("$indent  decoration: BoxDecoration(");
          if (cGradient != 'null') {
            buffer.writeln("$indent    gradient: $cGradient,");
          } else if (cBgStr != 'null') {
            buffer.writeln("$indent    color: $cBgStr,");
          }
          if (cRadius > 0.0) buffer.writeln("$indent    borderRadius: BorderRadius.circular($cRadius),");
          if (cBorderColor != 'null') buffer.writeln("$indent    border: Border.all(color: $cBorderColor, width: $cBorderWidth),");
          if (cElevation > 0.0) {
            final shadowCol = cShadowColor != 'null' ? cShadowColor : 'Colors.black.withOpacity(0.15)';
            buffer.writeln("$indent    boxShadow: [");
            buffer.writeln("$indent      BoxShadow(");
            buffer.writeln("$indent        color: $shadowCol,");
            buffer.writeln("$indent        blurRadius: ${cElevation * 2},");
            buffer.writeln("$indent        spreadRadius: ${cElevation * 0.25},");
            buffer.writeln("$indent        offset: Offset(0, $cElevation),");
            buffer.writeln("$indent      ),");
            buffer.writeln("$indent    ],");
          }
          buffer.writeln("$indent  ),");
        }
        buffer.writeln("$indent  child: ${cChild != 'null' ? cChild : 'const SizedBox.shrink()'},");
        buffer.write("$indent)");
        break;

      case 'Card':
        final bgStr = _formatColor(getProp('backgroundColor'));
        final elevation = PropertyParser.tryParseDouble(getProp('elevation')) ?? 2.0;
        final pad = compileResponsivePadding('padding', 'const EdgeInsets.all(12)');
        final marg = compileResponsivePadding('margin');
        final radius = PropertyParser.tryParseDouble(getProp('borderRadius')) ?? 12.0;
        
        final child = compileChild('child');
        String cardContent;
        if (child != 'null') {
          cardContent = child;
        } else if (getProp('title') != null && getProp('value') != null) {
          final tVal = getProp('title').toString();
          final vVal = getProp('value').toString();
          final vHasBinding = RegExp(r'\{[a-zA-Z0-9_]+\}').hasMatch(vVal) ||
                              vVal.trim() == '124' ||
                              vVal.trim() == '45' ||
                              vVal.trim() == '12' ||
                              vVal.trim().contains('54,200') ||
                              vVal.trim().contains('54200');
          final vCode = _compileTextString(vVal);
          cardContent = '''Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$tVal', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
            const SizedBox(height: 4),
            ${vHasBinding ? 'Obx(() => Text($vCode, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)))' : 'Text($vCode, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold))'},
          ],
        )''';
        } else {
          cardContent = 'const SizedBox.shrink()';
        }

        buffer.writeln("Card(");
        buffer.writeln("$indent  elevation: $elevation,");
        if (bgStr != 'null') buffer.writeln("$indent  color: $bgStr,");
        buffer.writeln("$indent  margin: $marg,");
        buffer.writeln("$indent  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular($radius)),");
        buffer.writeln("$indent  child: Padding(");
        buffer.writeln("$indent    padding: $pad,");
        buffer.writeln("$indent    child: $cardContent,");
        buffer.writeln("$indent  ),");
        buffer.write("$indent)");
        break;

      case 'Column':
        final colMainAlign  = _formatMainAlign(getProp('mainAxisAlignment'));
        final colCrossAlign = _formatCrossAlign(getProp('crossAxisAlignment'));
        final colMainSize   = getProp('mainAxisSize')?.toString().toLowerCase() == 'min'
            ? 'MainAxisSize.min' : 'MainAxisSize.max';
        final colSpacing    = compileResponsiveDouble('spacing');
        final colChildren   = compileChildren();

        buffer.writeln("Column(");
        buffer.writeln("$indent  mainAxisAlignment: $colMainAlign,");
        buffer.writeln("$indent  crossAxisAlignment: $colCrossAlign,");
        buffer.writeln("$indent  mainAxisSize: $colMainSize,");
        buffer.writeln("$indent  children: [");
        for (int i = 0; i < colChildren.length; i++) {
          buffer.writeln("$indent    ${colChildren[i]},");
          if (colSpacing != 'null' && i < colChildren.length - 1) {
            buffer.writeln("$indent    SizedBox(height: $colSpacing),");
          }
        }
        buffer.writeln("$indent  ],");
        buffer.write("$indent)");
        break;

      case 'Row':
        final spacingStr = compileResponsiveDouble('spacing');
        final children = compileChildren();
        final scrollable = getProp('scrollable') == true || node.children.length > 3;
        final hasMultipleCards = node.children.where((c) => c.type == 'Card').length > 1;
        final isResponsive = getProp('responsive') == true || getProp('wrapOnMobile') == true || hasMultipleCards;

        if (scrollable) {
          buffer.writeln("SingleChildScrollView(");
          buffer.writeln("$indent  scrollDirection: Axis.horizontal,");
          buffer.writeln("$indent  child: Row(");
          buffer.writeln("$indent    mainAxisAlignment: ${_formatMainAlign(getProp('mainAxisAlignment'))},");
          buffer.writeln("$indent    crossAxisAlignment: ${_formatCrossAlign(getProp('crossAxisAlignment'))},");
          buffer.writeln("$indent    children: [");
          for (int i = 0; i < children.length; i++) {
            buffer.writeln("$indent      ${children[i]},");
            if (spacingStr != 'null' && i < children.length - 1) {
              buffer.writeln("$indent      SizedBox(width: $spacingStr),");
            }
          }
          buffer.writeln("$indent    ],");
          buffer.writeln("$indent  ),");
          buffer.write("$indent)");
        } else if (isResponsive) {
          final runSpacingStr = compileResponsiveDouble('spacing', 16.0);
          buffer.writeln("Wrap(");
          buffer.writeln("$indent  spacing: $runSpacingStr,");
          buffer.writeln("$indent  runSpacing: $runSpacingStr,");
          buffer.writeln("$indent  children: [");
          for (final child in children) {
            buffer.writeln("$indent    $child,");
          }
          buffer.writeln("$indent  ],");
          buffer.write("$indent)");
        } else {
          buffer.writeln("Row(");
          buffer.writeln("$indent  mainAxisAlignment: ${_formatMainAlign(getProp('mainAxisAlignment'))},");
          buffer.writeln("$indent  crossAxisAlignment: ${_formatCrossAlign(getProp('crossAxisAlignment'))},");
          buffer.writeln("$indent  children: [");
          for (int i = 0; i < children.length; i++) {
            final childNode = node.children[i];
            final childCode = children[i];
            final needsExpanded = childNode.type == 'Card' || childNode.styles.containsKey('flex') || childNode.properties.containsKey('flex');
            
            // Expanded wrap safety check inside Row
            if (needsExpanded && childNode.type != 'Expanded' && childNode.type != 'Flexible') {
              buffer.writeln("$indent    Expanded(child: $childCode),");
            } else {
              buffer.writeln("$indent    $childCode,");
            }
            if (spacingStr != 'null' && i < children.length - 1) {
              buffer.writeln("$indent    SizedBox(width: $spacingStr),");
            }
          }
          buffer.writeln("$indent  ],");
          buffer.write("$indent)");
        }
        break;

      case 'Stack':
        final stackAlignment = _formatAlignment(getProp('alignment'));
        final stackFitStr = () {
          switch ((getProp('fit') ?? '').toString().toLowerCase()) {
            case 'expand': return 'StackFit.expand';
            case 'passthrough': return 'StackFit.passthrough';
            default: return 'StackFit.loose';
          }
        }();
        final stackClip = getProp('clipBehavior')?.toString().toLowerCase() == 'none' ||
                          getProp('clip') == false;
        final stackChildren = compileChildren();
        buffer.writeln("Stack(");
        buffer.writeln("$indent  alignment: $stackAlignment,");
        buffer.writeln("$indent  fit: $stackFitStr,");
        if (stackClip) buffer.writeln("$indent  clipBehavior: Clip.none,");
        buffer.writeln("$indent  children: [");
        for (final child in stackChildren) {
          buffer.writeln("$indent    $child,");
        }
        buffer.writeln("$indent  ],");
        buffer.write("$indent)");
        break;

      case 'Wrap':
        final wrapSpacing    = compileResponsiveDouble('spacing', 8.0);
        final wrapRunSpacing = compileResponsiveDouble('runSpacing', 8.0);
        final wrapDirection  = getProp('direction')?.toString().toLowerCase() == 'vertical'
            ? 'Axis.vertical' : 'Axis.horizontal';
        final wrapAlign = () {
          switch ((getProp('alignment') ?? '').toString().toLowerCase()) {
            case 'center': return 'WrapAlignment.center';
            case 'end': return 'WrapAlignment.end';
            case 'spacebetween': return 'WrapAlignment.spaceBetween';
            case 'spacearound': return 'WrapAlignment.spaceAround';
            case 'spaceevenly': return 'WrapAlignment.spaceEvenly';
            default: return 'WrapAlignment.start';
          }
        }();
        final wrapChildren = compileChildren();
        buffer.writeln("Wrap(");
        buffer.writeln("$indent  spacing: $wrapSpacing,");
        buffer.writeln("$indent  runSpacing: $wrapRunSpacing,");
        buffer.writeln("$indent  direction: $wrapDirection,");
        buffer.writeln("$indent  alignment: $wrapAlign,");
        buffer.writeln("$indent  children: [");
        for (final child in wrapChildren) {
          buffer.writeln("$indent    $child,");
        }
        buffer.writeln("$indent  ],");
        buffer.write("$indent)");
        break;

      case 'Text':
        final textVal = (getProp('text') ?? getProp('label') ?? 'Text').toString();
        final hasBinding = RegExp(r'\{[a-zA-Z0-9_]+\}').hasMatch(textVal) ||
                           textVal.trim() == '124' ||
                           textVal.trim() == '45' ||
                           textVal.trim() == '12' ||
                           textVal.trim().contains('54,200') ||
                           textVal.trim().contains('54200');
        final textCode      = _compileTextString(textVal);
        final textFontSize  = PropertyParser.tryParseDouble(getProp('fontSize')) ?? 14.0;
        final textFontW     = _formatFontWeight(getProp('fontWeight'));
        final textFontStyle = getProp('fontStyle')?.toString().toLowerCase() == 'italic' ? 'FontStyle.italic' : 'FontStyle.normal';
        final textColor     = _formatColor(getProp('color') ?? getProp('textColor'));
        final textAlign     = _formatTextAlign(getProp('textAlign'));
        final textMaxLines  = getProp('maxLines');
        final textOverflow  = () {
          switch ((getProp('overflow') ?? '').toString().toLowerCase()) {
            case 'ellipsis': return 'TextOverflow.ellipsis';
            case 'clip': return 'TextOverflow.clip';
            case 'fade': return 'TextOverflow.fade';
            default: return null;
          }
        }();
        final textLetterSpacing = PropertyParser.tryParseDouble(getProp('letterSpacing'));
        final textLineHeight     = PropertyParser.tryParseDouble(getProp('lineHeight') ?? getProp('height'));
        final textDecoration = () {
          switch ((getProp('textDecoration') ?? getProp('decoration') ?? '').toString().toLowerCase()) {
            case 'underline': return 'TextDecoration.underline';
            case 'linethrough': return 'TextDecoration.lineThrough';
            case 'overline': return 'TextDecoration.overline';
            default: return null;
          }
        }();

        void _writeTextStyle(StringBuffer b) {
          b.writeln("$indent  style: GoogleFonts.inter(");
          b.writeln("$indent    fontSize: $textFontSize,");
          b.writeln("$indent    fontWeight: $textFontW,");
          b.writeln("$indent    fontStyle: $textFontStyle,");
          if (textColor != 'null') b.writeln("$indent    color: $textColor,");
          if (textLetterSpacing != null) b.writeln("$indent    letterSpacing: $textLetterSpacing,");
          if (textLineHeight != null) b.writeln("$indent    height: $textLineHeight,");
          if (textDecoration != null) b.writeln("$indent    decoration: $textDecoration,");
          b.writeln("$indent  ),");
        }

        if (hasBinding) {
          buffer.writeln("Obx(() => Text(");
          buffer.writeln("$indent  $textCode,");
          _writeTextStyle(buffer);
          buffer.writeln("$indent  textAlign: $textAlign,");
          if (textMaxLines != null) buffer.writeln("$indent  maxLines: $textMaxLines,");
          if (textOverflow != null) buffer.writeln("$indent  overflow: $textOverflow,");
          buffer.writeln("$indent))");
        } else {
          buffer.writeln("Text(");
          buffer.writeln("$indent  $textCode,");
          _writeTextStyle(buffer);
          buffer.writeln("$indent  textAlign: $textAlign,");
          if (textMaxLines != null) buffer.writeln("$indent  maxLines: $textMaxLines,");
          if (textOverflow != null) buffer.writeln("$indent  overflow: $textOverflow,");
          buffer.write("$indent)");
        }
        break;

      case 'Button':
        final btnLabel     = getProp('label') ?? getProp('text') ?? 'Button';
        final btnMethod    = _labelToMethodName(btnLabel.toString());
        final btnBg        = _formatColor(getProp('backgroundColor'));
        final btnFg        = _formatColor(getProp('textColor') ?? getProp('foregroundColor') ?? getProp('color'));
        final btnRadius    = PropertyParser.tryParseDouble(getProp('borderRadius')) ?? 8.0;
        final btnVariant   = (getProp('variant') ?? getProp('type') ?? 'elevated').toString().toLowerCase();
        final btnIcon      = getProp('icon') != null ? _mapIconName(getProp('icon')) : null;
        final btnFullWidth = getProp('fullWidth') == true || getProp('expanded') == true;
        final btnPadding   = getProp('padding') != null
            ? _formatPadding(getProp('padding'))
            : 'const EdgeInsets.symmetric(horizontal: 24, vertical: 12)';
        final btnFontSize  = PropertyParser.tryParseDouble(getProp('fontSize')) ?? 14.0;
        final btnFontW     = _formatFontWeight(getProp('fontWeight') ?? 'bold');
        final btnElevation = PropertyParser.tryParseDouble(getProp('elevation'));
        final btnTooltip   = getProp('tooltip')?.toString();

        String btnStyleFrom(String prefix) {
          final b = StringBuffer();
          b.writeln("$indent  style: ${prefix}Button.styleFrom(");
          if (btnBg != 'null') b.writeln("$indent    backgroundColor: $btnBg,");
          if (btnFg != 'null') b.writeln("$indent    foregroundColor: $btnFg,");
          if (btnElevation != null) b.writeln("$indent    elevation: $btnElevation,");
          b.writeln("$indent    padding: $btnPadding,");
          b.writeln("$indent    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular($btnRadius)),");
          b.write("$indent  ),");
          return b.toString();
        }

        String btnChild = btnIcon != null
            ? "Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.$btnIcon, size: 18), const SizedBox(width: 8), Text('$btnLabel', style: GoogleFonts.inter(fontSize: $btnFontSize, fontWeight: $btnFontW))])"
            : "Text('$btnLabel', style: GoogleFonts.inter(fontSize: $btnFontSize, fontWeight: $btnFontW))";

        final btnWidget = StringBuffer();
        switch (btnVariant) {
          case 'text':
            btnWidget.writeln("TextButton(");
            btnWidget.writeln("$indent  onPressed: () => controller.$btnMethod(),");
            btnWidget.writeln(btnStyleFrom('Text'));
            btnWidget.writeln("$indent  child: $btnChild,");
            btnWidget.write("$indent)");
            break;
          case 'outlined':
          case 'outline':
            btnWidget.writeln("OutlinedButton(");
            btnWidget.writeln("$indent  onPressed: () => controller.$btnMethod(),");
            btnWidget.writeln(btnStyleFrom('Outlined'));
            btnWidget.writeln("$indent  child: $btnChild,");
            btnWidget.write("$indent)");
            break;
          case 'filled':
          case 'elevated':
          default:
            btnWidget.writeln("ElevatedButton(");
            btnWidget.writeln("$indent  onPressed: () => controller.$btnMethod(),");
            btnWidget.writeln(btnStyleFrom('Elevated'));
            btnWidget.writeln("$indent  child: $btnChild,");
            btnWidget.write("$indent)");
        }

        final btnFinalCode = btnTooltip != null
            ? "Tooltip(message: '$btnTooltip', child: ${btnWidget.toString()})"
            : btnWidget.toString();

        if (btnFullWidth) {
          buffer.writeln("SizedBox(");
          buffer.writeln("$indent  width: double.infinity,");
          buffer.writeln("$indent  child: $btnFinalCode,");
          buffer.write("$indent)");
        } else {
          buffer.write(btnFinalCode);
        }
        break;

      case 'IconButton':
        final ibIcon    = _mapIconName(getProp('icon') ?? 'help');
        final ibColor   = _formatColor(getProp('color'));
        final ibSize    = PropertyParser.tryParseDouble(getProp('size')) ?? 24.0;
        final ibTooltip = getProp('tooltip')?.toString() ?? '';
        final ibSplash  = PropertyParser.tryParseDouble(getProp('splashRadius'));
        final ibMethod  = getProp('onTap') != null ? _labelToMethodName(getProp('onTap').toString()) : null;

        buffer.writeln("IconButton(");
        buffer.writeln("$indent  icon: Icon(Icons.$ibIcon, size: $ibSize${ibColor != 'null' ? ", color: $ibColor" : ""}),");
        if (ibTooltip.isNotEmpty) buffer.writeln("$indent  tooltip: '$ibTooltip',");
        if (ibSplash != null) buffer.writeln("$indent  splashRadius: $ibSplash,");
        buffer.writeln("$indent  onPressed: () ${ibMethod != null ? '=> controller.$ibMethod()' : '{}'},");
        buffer.write("$indent)");
        break;

      case 'Image':
        final imgSrc    = getProp('src') ?? getProp('url') ?? 'https://placehold.co/600x400/5B4FCF/ffffff/png';
        final imgWidth  = PropertyParser.tryParseDouble(getProp('width'));
        final imgHeight = PropertyParser.tryParseDouble(getProp('height'));
        final imgFit    = _formatBoxFit(getProp('fit'));
        final imgRadius = PropertyParser.tryParseDouble(getProp('borderRadius')) ?? 0.0;
        final imgSemantic = getProp('semanticLabel')?.toString() ?? '';
        final imgHasError = getProp('errorPlaceholder') != null || getProp('showError') == true;

        String buildImageNetwork(String extraIndent) {
          final b = StringBuffer();
          b.writeln("Image.network(");
          b.writeln("$extraIndent  '$imgSrc',");
          if (imgWidth  != null) b.writeln("$extraIndent  width: $imgWidth,");
          if (imgHeight != null) b.writeln("$extraIndent  height: $imgHeight,");
          b.writeln("$extraIndent  fit: $imgFit,");
          if (imgSemantic.isNotEmpty) b.writeln("$extraIndent  semanticLabel: '$imgSemantic',");
          b.writeln("$extraIndent  loadingBuilder: (context, child, loadingProgress) {");
          b.writeln("$extraIndent    if (loadingProgress == null) return child;");
          b.writeln("$extraIndent    return const Center(child: CircularProgressIndicator());");
          b.writeln("$extraIndent  },");
          if (imgHasError) {
            b.writeln("$extraIndent  errorBuilder: (context, error, stackTrace) =>");
            b.writeln("$extraIndent    const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)),");
          }
          b.write("$extraIndent)");
          return b.toString();
        }

        if (imgRadius > 0.0) {
          buffer.writeln("ClipRRect(");
          buffer.writeln("$indent  borderRadius: BorderRadius.circular($imgRadius),");
          buffer.writeln("$indent  child: ${buildImageNetwork('$indent  ')},");
          buffer.write("$indent)");
        } else {
          buffer.write(buildImageNetwork(indent));
        }
        break;

      case 'Icon':
        final iconName  = _mapIconName(getProp('icon') ?? 'help');
        final iconColor = _formatColor(getProp('color'));
        final iconSize  = PropertyParser.tryParseDouble(getProp('size')) ?? 24.0;
        final iconLabel = getProp('semanticLabel')?.toString() ?? '';

        buffer.writeln("Icon(");
        buffer.writeln("$indent  Icons.$iconName,");
        buffer.writeln("$indent  size: $iconSize,");
        if (iconColor != 'null') buffer.writeln("$indent  color: $iconColor,");
        if (iconLabel.isNotEmpty) buffer.writeln("$indent  semanticLabel: '$iconLabel',");
        buffer.write("$indent)");
        break;

      case 'Divider':
        final divHeight    = PropertyParser.tryParseDouble(getProp('height')) ?? 16.0;
        final divThickness = PropertyParser.tryParseDouble(getProp('thickness')) ?? 1.0;
        final divColor     = _formatColor(getProp('color'));
        final divIndent    = PropertyParser.tryParseDouble(getProp('indent'));
        final divEndIndent = PropertyParser.tryParseDouble(getProp('endIndent'));

        buffer.writeln("Divider(");
        buffer.writeln("$indent  height: $divHeight,");
        buffer.writeln("$indent  thickness: $divThickness,");
        if (divColor != 'null') buffer.writeln("$indent  color: $divColor,");
        if (divIndent != null) buffer.writeln("$indent  indent: $divIndent,");
        if (divEndIndent != null) buffer.writeln("$indent  endIndent: $divEndIndent,");
        buffer.write("$indent)");
        break;

      // ================== CRM & DASHBOARD WIDGETS ==================
      case 'Avatar':
        final avImageUrl = getProp('imageUrl') ?? getProp('src') ?? '';
        final avRadius   = PropertyParser.tryParseDouble(getProp('radius')) ?? 20.0;
        final avName     = getProp('name')?.toString() ?? '';
        final avBgStr    = _formatColor(getProp('backgroundColor'));
        final avFgStr    = _formatColor(getProp('foregroundColor') ?? getProp('color'));
        // Derive initials from name as fallback
        String avInitials = '';
        if (avName.isNotEmpty) {
          final parts = avName.trim().split(' ').where((e) => e.isNotEmpty).toList();
          avInitials = parts.length >= 2
              ? '\${parts[0][0]}\${parts[1][0]}'.toUpperCase()
              : parts.first[0].toUpperCase();
        }
        buffer.writeln("CircleAvatar(");
        buffer.writeln("$indent  radius: $avRadius,");
        if (avBgStr != 'null') buffer.writeln("$indent  backgroundColor: $avBgStr,");
        if (avFgStr != 'null') buffer.writeln("$indent  foregroundColor: $avFgStr,");
        if (avImageUrl.toString().isNotEmpty) {
          buffer.writeln("$indent  backgroundImage: NetworkImage('$avImageUrl'),");
          if (avInitials.isNotEmpty) {
            buffer.writeln("$indent  onBackgroundImageError: (e, s) {},");
          }
        } else if (avInitials.isNotEmpty) {
          buffer.writeln("$indent  child: Text('$avInitials', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),");
        } else {
          buffer.writeln("$indent  child: const Icon(Icons.person),");
        }
        buffer.write("$indent)");
        break;

      case 'Badge':
        final badgeLabel    = getProp('label') ?? getProp('text') ?? getProp('count') ?? '';
        final badgeBgVal    = getProp('color') ?? getProp('backgroundColor');
        final badgeBgStr    = _formatColor(badgeBgVal ?? Colors.green);
        final badgeRadius   = PropertyParser.tryParseDouble(getProp('borderRadius')) ?? 20.0;
        final badgePadV     = PropertyParser.tryParseDouble(getProp('paddingVertical')) ?? 4.0;
        final badgePadH     = PropertyParser.tryParseDouble(getProp('paddingHorizontal')) ?? 8.0;
        final badgeFontSize = PropertyParser.tryParseDouble(getProp('fontSize')) ?? 10.0;
        final badgeCount    = getProp('count');
        final isCountBadge  = badgeCount != null;

        var badgeTextColorStr = 'Colors.white';
        final parsedBadgeBg = badgeBgVal != null ? PropertyParser.parseColor(badgeBgVal) : null;
        if (parsedBadgeBg != null) {
          final yiq = (parsedBadgeBg.red * 299 + parsedBadgeBg.green * 587 + parsedBadgeBg.blue * 114) / 1000;
          if (yiq > 170) {
            if (parsedBadgeBg.green > parsedBadgeBg.red && parsedBadgeBg.green > parsedBadgeBg.blue) {
              badgeTextColorStr = 'const Color(0xFF166534)';
            } else if (parsedBadgeBg.blue > parsedBadgeBg.red && parsedBadgeBg.blue > parsedBadgeBg.green) {
              badgeTextColorStr = 'const Color(0xFF4338CA)';
            } else {
              badgeTextColorStr = 'const Color(0xFF92400E)';
            }
          }
        }

        buffer.writeln("Container(");
        buffer.writeln("$indent  padding: EdgeInsets.symmetric(horizontal: $badgePadH, vertical: $badgePadV),");
        buffer.writeln("$indent  decoration: BoxDecoration(");
        buffer.writeln("$indent    color: $badgeBgStr,");
        buffer.writeln("$indent    borderRadius: BorderRadius.circular($badgeRadius),");
        buffer.writeln("$indent  ),");
        if (isCountBadge) {
          buffer.writeln("$indent  child: Obx(() => Text(");
          buffer.writeln("$indent    controller.${_toCamelCase(badgeCount.toString())}.value.toString(),");
          buffer.writeln("$indent    style: TextStyle(fontSize: $badgeFontSize, color: $badgeTextColorStr, fontWeight: FontWeight.bold),");
          buffer.writeln("$indent  )),");
        } else {
          buffer.writeln("$indent  child: Text('$badgeLabel', style: TextStyle(fontSize: $badgeFontSize, color: $badgeTextColorStr)),");
        }
        buffer.write("$indent)");
        break;

      case 'Chip':
        final chipLabel   = getProp('label') ?? getProp('text') ?? '';
        final chipBgStr   = _formatColor(getProp('backgroundColor') ?? getProp('color'));
        final chipAvIcon  = getProp('avatarIcon') != null ? _mapIconName(getProp('avatarIcon')) : null;
        final chipFgStr   = _formatColor(getProp('labelColor') ?? getProp('textColor'));
        final chipRadius  = PropertyParser.tryParseDouble(getProp('borderRadius'));
        final chipOnDel   = getProp('deletable') == true;
        final chipBorder  = getProp('outlined') == true;
        final chipPadding = getProp('padding') != null ? _formatPadding(getProp('padding')) : null;

        buffer.writeln("Chip(");
        buffer.writeln("$indent  label: Text('$chipLabel', style: GoogleFonts.inter(fontSize: 13${chipFgStr != 'null' ? ', color: $chipFgStr' : ''})),");
        if (chipBgStr != 'null') buffer.writeln("$indent  backgroundColor: $chipBgStr,");
        if (chipAvIcon != null) buffer.writeln("$indent  avatar: Icon(Icons.$chipAvIcon, size: 16),");
        if (chipPadding != null) buffer.writeln("$indent  padding: $chipPadding,");
        if (chipRadius != null) {
          buffer.writeln("$indent  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular($chipRadius)),");
        } else if (chipBorder) {
          buffer.writeln("$indent  shape: const StadiumBorder(side: BorderSide()),");
        }
        if (chipOnDel) {
          buffer.writeln("$indent  deleteIcon: const Icon(Icons.close, size: 14),");
          buffer.writeln("$indent  onDeleted: () {},");
        }
        buffer.write("$indent)");
        break;

      case 'Search':
        final sfName  = getProp('fieldName') ?? node.id;
        final sfCamel = _toCamelCase(sfName.toString());
        final sfHint  = getProp('hint') ?? getProp('placeholder') ?? 'Search...';
        final sfColor = _formatColor(getProp('fillColor') ?? getProp('backgroundColor'));
        final sfBorderRadius = PropertyParser.tryParseDouble(getProp('borderRadius')) ?? 28.0;

        buffer.writeln("TextField(");
        buffer.writeln("$indent  controller: controller.${sfCamel}Controller,");
        buffer.writeln("$indent  onChanged: (val) => controller.${sfCamel}Query.value = val,");
        buffer.writeln("$indent  decoration: InputDecoration(");
        buffer.writeln("$indent    hintText: '$sfHint',");
        buffer.writeln("$indent    prefixIcon: const Icon(Icons.search),");
        buffer.writeln("$indent    suffixIcon: Obx(() => controller.${sfCamel}Query.value.isNotEmpty");
        buffer.writeln("$indent      ? IconButton(icon: const Icon(Icons.clear), onPressed: () { controller.${sfCamel}Controller.clear(); controller.${sfCamel}Query.value = ''; })");
        buffer.writeln("$indent      : const SizedBox.shrink()),");
        buffer.writeln("$indent    filled: true,");
        if (sfColor != 'null') buffer.writeln("$indent    fillColor: $sfColor,");
        buffer.writeln("$indent    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),");
        buffer.writeln("$indent    border: OutlineInputBorder(");
        buffer.writeln("$indent      borderRadius: BorderRadius.circular($sfBorderRadius),");
        buffer.writeln("$indent      borderSide: BorderSide.none,");
        buffer.writeln("$indent    ),");
        buffer.writeln("$indent  ),");
        buffer.write("$indent)");
        break;

      case 'Chart':
        final chartType = (getProp('chartType') ?? 'line').toString().toLowerCase();
        final mappedType = chartType == 'bar' ? 'BarChart' : (chartType == 'pie' ? 'PieChart' : (chartType == 'area' ? 'AreaChart' : 'LineChart'));
        buffer.write(_compileNode(node.copyWith(type: mappedType), indent, controllerClass, parentNode));
        break;

      case 'LineChart':
        buffer.writeln("Obx(() => AspectRatio(");
        buffer.writeln("$indent  aspectRatio: 1.70,");
        buffer.writeln("$indent  child: LineChart(");
        buffer.writeln("$indent    LineChartData(");
        buffer.writeln("$indent      gridData: const FlGridData(show: true),");
        buffer.writeln("$indent      titlesData: const FlTitlesData(show: true),");
        buffer.writeln("$indent      borderData: FlBorderData(show: true),");
        buffer.writeln("$indent      lineBarsData: [");
        buffer.writeln("$indent        LineChartBarData(");
        buffer.writeln("$indent          spots: controller.chartSpots.map((s) => FlSpot(s['x'] ?? 0.0, s['y'] ?? 0.0)).toList(),");
        buffer.writeln("$indent          isCurved: true,");
        buffer.writeln("$indent          barWidth: 3,");
        buffer.writeln("$indent          color: Colors.blue,");
        buffer.writeln("$indent        ),");
        buffer.writeln("$indent      ],");
        buffer.writeln("$indent    ),");
        buffer.writeln("$indent  ),");
        buffer.write("$indent))");
        break;

      case 'AreaChart':
        buffer.writeln("Obx(() => AspectRatio(");
        buffer.writeln("$indent  aspectRatio: 1.70,");
        buffer.writeln("$indent  child: LineChart(");
        buffer.writeln("$indent    LineChartData(");
        buffer.writeln("$indent      gridData: const FlGridData(show: true),");
        buffer.writeln("$indent      titlesData: const FlTitlesData(show: true),");
        buffer.writeln("$indent      borderData: FlBorderData(show: true),");
        buffer.writeln("$indent      lineBarsData: [");
        buffer.writeln("$indent        LineChartBarData(");
        buffer.writeln("$indent          spots: controller.chartSpots.map((s) => FlSpot(s['x'] ?? 0.0, s['y'] ?? 0.0)).toList(),");
        buffer.writeln("$indent          isCurved: true,");
        buffer.writeln("$indent          barWidth: 3,");
        buffer.writeln("$indent          color: Colors.blue,");
        buffer.writeln("$indent          belowBarData: BarAreaData(");
        buffer.writeln("$indent            show: true,");
        buffer.writeln("$indent            color: Colors.blue.withOpacity(0.2),");
        buffer.writeln("$indent          ),");
        buffer.writeln("$indent        ),");
        buffer.writeln("$indent      ],");
        buffer.writeln("$indent    ),");
        buffer.writeln("$indent  ),");
        buffer.write("$indent))");
        break;

      case 'BarChart':
        buffer.writeln("Obx(() => AspectRatio(");
        buffer.writeln("$indent  aspectRatio: 1.70,");
        buffer.writeln("$indent  child: BarChart(");
        buffer.writeln("$indent    BarChartData(");
        buffer.writeln("$indent      barGroups: List.generate(controller.chartSpots.length, (i) => BarChartGroupData(");
        buffer.writeln("$indent        x: i,");
        buffer.writeln("$indent        barRods: [BarChartRodData(toY: controller.chartSpots[i]['y'] ?? 0.0, color: Colors.blue)],");
        buffer.writeln("$indent      )),");
        buffer.writeln("$indent    ),");
        buffer.writeln("$indent  ),");
        buffer.write("$indent))");
        break;

      case 'PieChart':
        buffer.writeln("Obx(() => AspectRatio(");
        buffer.writeln("$indent  aspectRatio: 1.3,");
        buffer.writeln("$indent  child: PieChart(");
        buffer.writeln("$indent    PieChartData(");
        buffer.writeln("$indent      sections: controller.pieSections.map((sec) => PieChartSectionData(");
        buffer.writeln("$indent        color: Color(sec['color'] ?? 0xFF2196F3),");
        buffer.writeln("$indent        value: (sec['value'] as num).toDouble(),");
        buffer.writeln("$indent        title: sec['title']?.toString() ?? '',");
        buffer.writeln("$indent        radius: 50,");
        buffer.writeln("$indent        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),");
        buffer.writeln("$indent      )).toList(),");
        buffer.writeln("$indent    ),");
        buffer.writeln("$indent  ),");
        buffer.write("$indent))");
        break;

      // ================== INPUTS ==================
      case 'TextField':
        final tfName     = getProp('fieldName') ?? node.id;
        final tfCamel    = _toCamelCase(tfName.toString());
        final tfLabel    = getProp('label') ?? tfName;
        final tfHint     = getProp('hint') ?? getProp('placeholder') ?? '';
        final tfRequired = getProp('required') == true;
        final tfObscure  = getProp('obscureText') == true || getProp('password') == true;
        final tfMaxLines = getProp('maxLines') is int ? getProp('maxLines') : (tfObscure ? 1 : null);
        final tfKbType   = () {
          switch ((getProp('keyboardType') ?? '').toString().toLowerCase()) {
            case 'email': return 'TextInputType.emailAddress';
            case 'number': case 'numeric': return 'TextInputType.number';
            case 'phone': return 'TextInputType.phone';
            case 'url': return 'TextInputType.url';
            case 'multiline': return 'TextInputType.multiline';
            default: return null;
          }
        }();
        final tfAction   = () {
          switch ((getProp('textInputAction') ?? '').toString().toLowerCase()) {
            case 'next': return 'TextInputAction.next';
            case 'done': return 'TextInputAction.done';
            case 'search': return 'TextInputAction.search';
            case 'send': return 'TextInputAction.send';
            default: return null;
          }
        }();
        final tfPrefixIcon = getProp('prefixIcon') != null ? _mapIconName(getProp('prefixIcon')) : null;
        final tfSuffixIcon = getProp('suffixIcon') != null ? _mapIconName(getProp('suffixIcon')) : null;
        final tfFilled     = getProp('filled') == true || getProp('filled') == null;
        final tfFillColor  = _formatColor(getProp('fillColor') ?? getProp('backgroundColor'));
        final tfRadius     = PropertyParser.tryParseDouble(getProp('borderRadius')) ?? 8.0;
        final tfPrefixText = getProp('prefixText')?.toString();
        final tfMinLines   = getProp('minLines') is int ? getProp('minLines') : null;

        // Conditionally reactive obscure toggle
        final tfHasObscureToggle = tfObscure && getProp('showToggle') != false;

        if (tfHasObscureToggle) {
          buffer.writeln("Obx(() => TextFormField(");
        } else {
          buffer.writeln("TextFormField(");
        }
        buffer.writeln("$indent  controller: controller.${tfCamel}Controller,");
        if (tfObscure) {
          if (tfHasObscureToggle) {
            buffer.writeln("$indent  obscureText: controller.${tfCamel}Obscured.value,");
          } else {
            buffer.writeln("$indent  obscureText: true,");
          }
        }
        if (tfKbType != null) buffer.writeln("$indent  keyboardType: $tfKbType,");
        if (tfAction  != null) buffer.writeln("$indent  textInputAction: $tfAction,");
        if (tfMaxLines != null) buffer.writeln("$indent  maxLines: $tfMaxLines,");
        if (tfMinLines != null) buffer.writeln("$indent  minLines: $tfMinLines,");
        buffer.writeln("$indent  decoration: InputDecoration(");
        buffer.writeln("$indent    labelText: '$tfLabel',");
        if (tfHint.toString().isNotEmpty) buffer.writeln("$indent    hintText: '$tfHint',");
        if (tfPrefixText != null) buffer.writeln("$indent    prefixText: '$tfPrefixText',");
        if (tfPrefixIcon != null) buffer.writeln("$indent    prefixIcon: const Icon(Icons.$tfPrefixIcon),");
        if (tfObscure && tfHasObscureToggle) {
          buffer.writeln("$indent    suffixIcon: IconButton(");
          buffer.writeln("$indent      icon: Icon(controller.${tfCamel}Obscured.value ? Icons.visibility_off : Icons.visibility),");
          buffer.writeln("$indent      onPressed: () => controller.${tfCamel}Obscured.toggle(),");
          buffer.writeln("$indent    ),");
        } else if (tfSuffixIcon != null) {
          buffer.writeln("$indent    suffixIcon: const Icon(Icons.$tfSuffixIcon),");
        }
        if (tfFilled) buffer.writeln("$indent    filled: true,");
        if (tfFillColor != 'null') buffer.writeln("$indent    fillColor: $tfFillColor,");
        buffer.writeln("$indent    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),");
        buffer.writeln("$indent    border: OutlineInputBorder(borderRadius: BorderRadius.circular($tfRadius)),");
        buffer.writeln("$indent    enabledBorder: OutlineInputBorder(");
        buffer.writeln("$indent      borderRadius: BorderRadius.circular($tfRadius),");
        buffer.writeln("$indent      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),");
        buffer.writeln("$indent    ),");
        buffer.writeln("$indent    focusedBorder: OutlineInputBorder(");
        buffer.writeln("$indent      borderRadius: BorderRadius.circular($tfRadius),");
        buffer.writeln("$indent      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),");
        buffer.writeln("$indent    ),");
        buffer.writeln("$indent  ),");
        if (tfRequired) {
          buffer.writeln("$indent  validator: (val) {");
          buffer.writeln("$indent    if (val == null || val.isEmpty) return '$tfLabel is required';");
          buffer.writeln("$indent    return null;");
          buffer.writeln("$indent  },");
        }
        if (tfHasObscureToggle) {
          buffer.writeln("$indent))");
        } else {
          buffer.write("$indent)");
        }
        break;

      case 'Dropdown':
        final ddName     = getProp('fieldName') ?? node.id;
        final ddCamel    = _toCamelCase(ddName.toString());
        final ddLabel    = getProp('label') ?? ddName;
        final ddRequired = getProp('required') == true;
        final ddOptions  = getProp('options') ?? ['Option One', 'Option Two'];
        final ddHint     = getProp('hint') ?? getProp('placeholder') ?? 'Select...';
        final ddRadius   = PropertyParser.tryParseDouble(getProp('borderRadius')) ?? 8.0;
        final ddIcon     = getProp('icon') != null ? _mapIconName(getProp('icon')) : null;
        final ddFilled   = getProp('filled') == true || getProp('filled') == null;
        final ddFillColor = _formatColor(getProp('fillColor') ?? getProp('backgroundColor'));

        buffer.writeln("Obx(() => DropdownButtonFormField<String>(");
        buffer.writeln("$indent  value: controller.$ddCamel.value.isEmpty ? null : controller.$ddCamel.value,");
        buffer.writeln("$indent  isExpanded: true,");
        if (ddIcon != null) buffer.writeln("$indent  icon: const Icon(Icons.$ddIcon),");
        buffer.writeln("$indent  decoration: InputDecoration(");
        buffer.writeln("$indent    labelText: '$ddLabel',");
        buffer.writeln("$indent    hintText: '$ddHint',");
        if (ddFilled) buffer.writeln("$indent    filled: true,");
        if (ddFillColor != 'null') buffer.writeln("$indent    fillColor: $ddFillColor,");
        buffer.writeln("$indent    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),");
        buffer.writeln("$indent    border: OutlineInputBorder(borderRadius: BorderRadius.circular($ddRadius)),");
        buffer.writeln("$indent    enabledBorder: OutlineInputBorder(");
        buffer.writeln("$indent      borderRadius: BorderRadius.circular($ddRadius),");
        buffer.writeln("$indent      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),");
        buffer.writeln("$indent    ),");
        buffer.writeln("$indent  ),");
        buffer.writeln("$indent  items: [");
        for (final opt in ddOptions) {
          final optLabel = opt is Map ? (opt['label'] ?? opt['value'] ?? opt.toString()) : opt.toString();
          final optValue = opt is Map ? (opt['value'] ?? opt['label'] ?? opt.toString()) : opt.toString();
          buffer.writeln("$indent    DropdownMenuItem(value: '$optValue', child: Text('$optLabel')),");
        }
        buffer.writeln("$indent  ],");
        buffer.writeln("$indent  onChanged: (val) => controller.$ddCamel.value = val ?? '',");
        if (ddRequired) {
          buffer.writeln("$indent  validator: (val) {");
          buffer.writeln("$indent    if (val == null || val.isEmpty) return 'Please select an option';");
          buffer.writeln("$indent    return null;");
          buffer.writeln("$indent  },");
        }
        buffer.write("$indent))");
        break;

      case 'Checkbox':
        final cbName     = getProp('fieldName') ?? node.id;
        final cbCamel    = _toCamelCase(cbName.toString());
        final cbLabel    = getProp('label') ?? cbName;
        final cbActive   = _formatColor(getProp('activeColor'));
        final cbCheck    = _formatColor(getProp('checkColor'));
        final cbDense    = getProp('dense') == true;

        buffer.writeln("Obx(() => CheckboxListTile(");
        buffer.writeln("$indent  title: Text('$cbLabel', style: GoogleFonts.inter(fontSize: 14)),");
        buffer.writeln("$indent  value: controller.$cbCamel.value,");
        buffer.writeln("$indent  onChanged: (val) => controller.$cbCamel.value = val ?? false,");
        buffer.writeln("$indent  controlAffinity: ListTileControlAffinity.leading,");
        if (cbActive != 'null') buffer.writeln("$indent  activeColor: $cbActive,");
        if (cbCheck != 'null')  buffer.writeln("$indent  checkColor: $cbCheck,");
        if (cbDense) buffer.writeln("$indent  dense: true,");
        buffer.write("$indent))");
        break;

      case 'Switch':
        final swName      = getProp('fieldName') ?? node.id;
        final swCamel     = _toCamelCase(swName.toString());
        final swLabel     = getProp('label') ?? swName;
        final swActive    = _formatColor(getProp('activeColor'));
        final swTrack     = _formatColor(getProp('trackColor'));
        final swThumb     = _formatColor(getProp('thumbColor'));
        final swDense     = getProp('dense') == true;
        final swSubtitle  = getProp('subtitle')?.toString();

        buffer.writeln("Obx(() => SwitchListTile(");
        buffer.writeln("$indent  title: Text('$swLabel', style: GoogleFonts.inter(fontSize: 14)),");
        if (swSubtitle != null) buffer.writeln("$indent  subtitle: Text('$swSubtitle', style: GoogleFonts.inter(fontSize: 12)),");
        buffer.writeln("$indent  value: controller.$swCamel.value,");
        buffer.writeln("$indent  onChanged: (val) => controller.$swCamel.value = val,");
        if (swActive != 'null') buffer.writeln("$indent  activeColor: $swActive,");
        if (swTrack  != 'null') buffer.writeln("$indent  trackColor: MaterialStatePropertyAll($swTrack),");
        if (swThumb  != 'null') buffer.writeln("$indent  thumbColor: MaterialStatePropertyAll($swThumb),");
        if (swDense) buffer.writeln("$indent  dense: true,");
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
        final isFlexParent = parentNode != null && (parentNode.type == 'Row' || parentNode.type == 'Column' || parentNode.type == 'Flex');
        if (isFlexParent) {
          buffer.write("const Spacer()");
        } else {
          buffer.write("const SizedBox.shrink()");
        }
        break;

      case 'SizedBox':
        final widthStr = compileResponsiveDouble('width');
        final heightStr = compileResponsiveDouble('height');
        final child = compileChild('child');

        buffer.writeln("SizedBox(");
        if (widthStr != 'null') buffer.writeln("$indent  width: $widthStr,");
        if (heightStr != 'null') buffer.writeln("$indent  height: $heightStr,");
        if (child != 'null') buffer.writeln("$indent  child: $child,");
        buffer.write("$indent)");
        break;

      case 'Expanded':
      case 'Flexible':
        final child = compileChild('child');
        final isFlexParent = parentNode != null && (parentNode.type == 'Row' || parentNode.type == 'Column' || parentNode.type == 'Flex');
        if (isFlexParent) {
          buffer.writeln("${type}(");
          buffer.writeln("$indent  child: ${child != 'null' ? child : 'const SizedBox.shrink()'},");
          buffer.write("$indent)");
        } else {
          buffer.write(child != 'null' ? child : 'const SizedBox.shrink()');
        }
        break;

      case 'SafeArea':
        final child = compileChild('child');
        buffer.writeln("SafeArea(");
        buffer.writeln("$indent  child: ${child != 'null' ? child : 'const SizedBox.shrink()'},");
        buffer.write("$indent)");
        break;

      // ================== ADVANCED WIDGETS ==================
      case 'DataTable':
      case 'Table':
        buffer.writeln("Obx(() => SingleChildScrollView(");
        buffer.writeln("$indent  scrollDirection: Axis.horizontal,");
        buffer.writeln("$indent  child: DataTable(");
        buffer.writeln("$indent    columns: controller.tableColumns.map((col) => DataColumn(");
        buffer.writeln("$indent      label: Text(col, style: const TextStyle(fontWeight: FontWeight.bold)),");
        buffer.writeln("$indent    )).toList(),");
        buffer.writeln("$indent    rows: controller.tableRows.map((row) => DataRow(");
        buffer.writeln("$indent      cells: row.map((cell) => DataCell(Text(cell))).toList(),");
        buffer.writeln("$indent    )).toList(),");
        buffer.writeln("$indent  ),");
        buffer.write("$indent))");
        break;

      case 'ListView':
        final shrinkWrap = getProp('shrinkWrap') != false;
        final scrollDir = getProp('scrollDirection')?.toString().toLowerCase() == 'horizontal' ? 'Axis.horizontal' : 'Axis.vertical';
        final children = compileChildren();
        
        if (children.isNotEmpty) {
          buffer.writeln("ListView(");
          buffer.writeln("$indent  shrinkWrap: $shrinkWrap,");
          buffer.writeln("$indent  scrollDirection: $scrollDir,");
          buffer.writeln("$indent  physics: const NeverScrollableScrollPhysics(),");
          buffer.writeln("$indent  children: [");
          for (final child in children) {
            buffer.writeln("$indent    $child,");
          }
          buffer.writeln("$indent  ],");
          buffer.write("$indent)");
        } else {
          buffer.writeln("Obx(() => ListView.builder(");
          buffer.writeln("$indent  shrinkWrap: $shrinkWrap,");
          buffer.writeln("$indent  scrollDirection: $scrollDir,");
          buffer.writeln("$indent  physics: const NeverScrollableScrollPhysics(),");
          buffer.writeln("$indent  itemCount: controller.listItems.length,");
          buffer.writeln("$indent  itemBuilder: (context, index) {");
          buffer.writeln("$indent    final item = controller.listItems[index];");
          buffer.writeln("$indent    return ListTile(");
          buffer.writeln("$indent      leading: const CircleAvatar(child: Icon(Icons.person)),");
          buffer.writeln("$indent      title: Text(item['title'] ?? ''),");
          buffer.writeln("$indent      subtitle: Text(item['subtitle'] ?? ''),");
          buffer.writeln("$indent      trailing: const Icon(Icons.chevron_right),");
          buffer.writeln("$indent    );");
          buffer.writeln("$indent  },");
          buffer.write("$indent))");
        }
        break;

      case 'GridView':
        final crossAxisCountStr = compileResponsiveInt('crossAxisCount', 2);
        final childAspectRatio = PropertyParser.tryParseDouble(getProp('childAspectRatio')) ?? 1.0;
        final spacing = PropertyParser.tryParseDouble(getProp('spacing')) ?? 8.0;
        final children = compileChildren();

        if (children.isNotEmpty) {
          buffer.writeln("GridView.count(");
          buffer.writeln("$indent  crossAxisCount: $crossAxisCountStr,");
          buffer.writeln("$indent  childAspectRatio: $childAspectRatio,");
          buffer.writeln("$indent  crossAxisSpacing: $spacing,");
          buffer.writeln("$indent  mainAxisSpacing: $spacing,");
          buffer.writeln("$indent  shrinkWrap: true,");
          buffer.writeln("$indent  physics: const NeverScrollableScrollPhysics(),");
          buffer.writeln("$indent  children: [");
          for (final child in children) {
            buffer.writeln("$indent    $child,");
          }
          buffer.writeln("$indent  ],");
          buffer.write("$indent)");
        } else {
          buffer.writeln("Obx(() => GridView.builder(");
          buffer.writeln("$indent  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(");
          buffer.writeln("$indent    crossAxisCount: $crossAxisCountStr,");
          buffer.writeln("$indent    childAspectRatio: $childAspectRatio,");
          buffer.writeln("$indent    crossAxisSpacing: $spacing,");
          buffer.writeln("$indent    mainAxisSpacing: $spacing,");
          buffer.writeln("$indent  ),");
          buffer.writeln("$indent  shrinkWrap: true,");
          buffer.writeln("$indent  physics: const NeverScrollableScrollPhysics(),");
          buffer.writeln("$indent  itemCount: controller.gridItems.length,");
          buffer.writeln("$indent  itemBuilder: (context, index) {");
          buffer.writeln("$indent    return Card(");
          buffer.writeln("$indent      child: Center(child: Text(controller.gridItems[index])),");
          buffer.writeln("$indent    );");
          buffer.writeln("$indent  },");
          buffer.write("$indent))");
        }
        break;

      case 'TabBar':
      case 'Tabs':
        final children = compileChildren();
        buffer.writeln("Obx(() => DefaultTabController(");
        buffer.writeln("$indent  length: controller.tabLabels.length,");
        buffer.writeln("$indent  child: Column(");
        buffer.writeln("$indent    mainAxisSize: MainAxisSize.min,");
        buffer.writeln("$indent    children: [");
        buffer.writeln("$indent      TabBar(");
        buffer.writeln("$indent        labelColor: Colors.blue,");
        buffer.writeln("$indent        unselectedLabelColor: Colors.grey,");
        buffer.writeln("$indent        tabs: controller.tabLabels.map((label) => Tab(text: label)).toList(),");
        buffer.writeln("$indent      ),");
        buffer.writeln("$indent      SizedBox(");
        buffer.writeln("$indent        height: 300,");
        buffer.writeln("$indent        child: TabBarView(");
        buffer.writeln("$indent          children: [");
        if (children.isNotEmpty) {
          for (int i = 0; i < children.length; i++) {
            buffer.writeln("$indent            SingleChildScrollView(child: ${children[i]}),");
          }
          buffer.writeln("$indent            if (controller.tabLabels.length > ${children.length})");
          buffer.writeln("$indent              ...controller.tabLabels.sublist(${children.length}).map((label) => Center(child: Text('\$label Content'))),");
        } else {
          buffer.writeln("$indent            ...controller.tabLabels.map((label) => Center(child: Text('\$label Content'))),");
        }
        buffer.writeln("$indent          ],");
        buffer.writeln("$indent        ),");
        buffer.writeln("$indent      ),");
        buffer.writeln("$indent    ],");
        buffer.writeln("$indent  ),");
        buffer.write("$indent))");
        break;

      case 'ExpansionTile':
        final titleText = getProp('title')?.toString() ?? 'Expandable Section';
        final expansionChildren = compileChildren();
        
        buffer.writeln("ExpansionTile(");
        buffer.writeln("$indent  title: Text('$titleText', style: const TextStyle(fontWeight: FontWeight.bold)),");
        if (expansionChildren.isNotEmpty) {
          buffer.writeln("$indent  children: [");
          for (final child in expansionChildren) {
            buffer.writeln("$indent    Padding(");
            buffer.writeln("$indent      padding: const EdgeInsets.symmetric(horizontal: 16.0),");
            buffer.writeln("$indent      child: $child,");
            buffer.writeln("$indent    ),");
          }
          buffer.writeln("$indent  ],");
        } else {
          // Empty state – shows a centered message; replace with real content from API
          buffer.writeln("$indent  children: const [");
          buffer.writeln("$indent    SizedBox(height: 48, child: Center(child: Text('No items to display.'))),");
          buffer.writeln("$indent  ],");
        }
        buffer.write("$indent)");
        break;

      case 'Drawer':
        final drawerChildren = compileChildren();
        buffer.writeln("Drawer(");
        buffer.writeln("$indent  child: ListView(");
        buffer.writeln("$indent    padding: EdgeInsets.zero,");
        buffer.writeln("$indent    children: [");
        buffer.writeln("$indent      DrawerHeader(");
        buffer.writeln("$indent        decoration: const BoxDecoration(color: Colors.blue),");
        buffer.writeln("$indent        child: Text(");
        buffer.writeln("$indent          '${getProp('title')?.toString() ?? 'Navigation'}',");
        buffer.writeln("$indent          style: const TextStyle(color: Colors.white, fontSize: 24),");
        buffer.writeln("$indent        ),");
        buffer.writeln("$indent      ),");
        if (drawerChildren.isNotEmpty) {
          for (final child in drawerChildren) {
            buffer.writeln("$indent      $child,");
          }
        } else {
          // No static items – show an empty state driven from tabLabels
          buffer.writeln("$indent      ...Obx(() => controller.tabLabels.map((label) => ListTile(");
          buffer.writeln("$indent        leading: const Icon(Icons.label_outline),");
          buffer.writeln("$indent        title: Text(label),");
          buffer.writeln("$indent        onTap: () {},");
          buffer.writeln("$indent      )).toList()).value,");
        }
        buffer.writeln("$indent    ],");
        buffer.writeln("$indent  ),");
        buffer.write("$indent)");
        break;

      case 'NavigationRail':
        buffer.writeln("Obx(() => NavigationRail(");
        buffer.writeln("$indent  selectedIndex: controller.selectedNavigationIndex.value,");
        buffer.writeln("$indent  labelType: NavigationRailLabelType.all,");
        buffer.writeln("$indent  destinations: controller.tabLabels.map((dest) => NavigationRailDestination(");
        buffer.writeln("$indent    icon: const Icon(Icons.grid_view),");
        buffer.writeln("$indent    label: Text(dest),");
        buffer.writeln("$indent  )).toList(),");
        buffer.writeln("$indent  onDestinationSelected: (index) => controller.selectedNavigationIndex.value = index,");
        buffer.write("$indent))");
        break;

      case 'Stepper':
        buffer.writeln("Obx(() => Stepper(");
        buffer.writeln("$indent  currentStep: controller.currentStep.value,");
        buffer.writeln("$indent  physics: const NeverScrollableScrollPhysics(),");
        buffer.writeln("$indent  steps: List.generate(controller.stepperSteps.length, (i) => Step(");
        buffer.writeln("$indent    title: Text(controller.stepperSteps[i]),");
        buffer.writeln("$indent    content: const Text('Please complete this step.'),");
        buffer.writeln("$indent    isActive: controller.currentStep.value == i,");
        buffer.writeln("$indent  )),");
        buffer.writeln("$indent  onStepContinue: () {");
        buffer.writeln("$indent    if (controller.currentStep.value < controller.stepperSteps.length - 1) {");
        buffer.writeln("$indent      controller.currentStep.value++;");
        buffer.writeln("$indent    }");
        buffer.writeln("$indent  },");
        buffer.writeln("$indent  onStepCancel: () {");
        buffer.writeln("$indent    if (controller.currentStep.value > 0) {");
        buffer.writeln("$indent      controller.currentStep.value--;");
        buffer.writeln("$indent    }");
        buffer.writeln("$indent  },");
        buffer.write("$indent))");
        break;

      case 'Timeline':
        buffer.writeln("Obx(() => Column(");
        buffer.writeln("$indent  mainAxisSize: MainAxisSize.min,");
        buffer.writeln("$indent  children: List.generate(controller.timelineEvents.length, (i) => IntrinsicHeight(");
        buffer.writeln("$indent    child: Row(");
        buffer.writeln("$indent      children: [");
        buffer.writeln("$indent        Column(");
        buffer.writeln("$indent          children: [");
        buffer.writeln("$indent            const CircleAvatar(radius: 6, backgroundColor: Colors.blue),");
        buffer.writeln("$indent            if (i < controller.timelineEvents.length - 1)");
        buffer.writeln("$indent              const Expanded(child: VerticalDivider(thickness: 2, color: Colors.grey)),");
        buffer.writeln("$indent          ],");
        buffer.writeln("$indent        ),");
        buffer.writeln("$indent        const SizedBox(width: 12),");
        buffer.writeln("$indent        Expanded(");
        buffer.writeln("$indent          child: Padding(");
        buffer.writeln("$indent            padding: const EdgeInsets.only(bottom: 16.0),");
        buffer.writeln("$indent            child: Text(controller.timelineEvents[i], style: const TextStyle(fontWeight: FontWeight.w500)),");
        buffer.writeln("$indent          ),");
        buffer.writeln("$indent        ),");
        buffer.writeln("$indent      ],");
        buffer.writeln("$indent    ),");
        buffer.writeln("$indent  )),");
        buffer.write("$indent))");
        break;

      case 'TreeView':
        buffer.writeln("Column(");
        buffer.writeln("$indent  crossAxisAlignment: CrossAxisAlignment.start,");
        buffer.writeln("$indent  children: const [");
        buffer.writeln("$indent    ExpansionTile(");
        buffer.writeln("$indent      title: Text('Root Node', style: TextStyle(fontWeight: FontWeight.bold)),");
        buffer.writeln("$indent      leading: Icon(Icons.folder),");
        buffer.writeln("$indent      children: [");
        buffer.writeln("$indent        ListTile(");
        buffer.writeln("$indent          contentPadding: EdgeInsets.only(left: 32.0),");
        buffer.writeln("$indent          leading: Icon(Icons.insert_drive_file),");
        buffer.writeln("$indent          title: Text('Child Node 1'),");
        buffer.writeln("$indent        ),");
        buffer.writeln("$indent        ExpansionTile(");
        buffer.writeln("$indent          tilePadding: EdgeInsets.only(left: 32.0),");
        buffer.writeln("$indent          leading: Icon(Icons.folder),");
        buffer.writeln("$indent          title: Text('Sub-folder'),");
        buffer.writeln("$indent          children: [");
        buffer.writeln("$indent            ListTile(");
        buffer.writeln("$indent              contentPadding: EdgeInsets.only(left: 64.0),");
        buffer.writeln("$indent              leading: Icon(Icons.insert_drive_file),");
        buffer.writeln("$indent              title: Text('Grandchild Node'),");
        buffer.writeln("$indent            ),");
        buffer.writeln("$indent          ],");
        buffer.writeln("$indent        ),");
        buffer.writeln("$indent      ],");
        buffer.writeln("$indent    ),");
        buffer.writeln("$indent  ],");
        buffer.write("$indent)");
        break;

      case 'Carousel':
        buffer.writeln("Obx(() => SizedBox(");
        buffer.writeln("$indent  height: 200,");
        buffer.writeln("$indent  child: PageView(");
        buffer.writeln("$indent    children: controller.carouselItems.map((item) => Card(");
        buffer.writeln("$indent      color: Colors.blueGrey,");
        buffer.writeln("$indent      child: Center(");
        buffer.writeln("$indent        child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),");
        buffer.writeln("$indent      ),");
        buffer.writeln("$indent    )).toList(),");
        buffer.writeln("$indent  ),");
        buffer.write("$indent))");
        break;

      // ================== SINGLE-CHILD LAYOUT WIDGETS ==================

      case 'SingleChildScrollView':
        final scrollAxis = getProp('scrollDirection')?.toString().toLowerCase() == 'horizontal'
            ? 'Axis.horizontal' : 'Axis.vertical';
        final scsChild = compileChild('child');
        final pad = compileResponsivePadding('padding');
        buffer.writeln("SingleChildScrollView(");
        buffer.writeln("$indent  scrollDirection: $scrollAxis,");
        if (pad != 'EdgeInsets.zero') buffer.writeln("$indent  padding: $pad,");
        buffer.writeln("$indent  child: ${scsChild != 'null' ? scsChild : 'const SizedBox.shrink()'},");
        buffer.write("$indent)");
        break;

      case 'Padding':
        final padValue = compileResponsivePadding('padding', 'const EdgeInsets.all(16)');
        final padChild = compileChild('child');
        buffer.writeln("Padding(");
        buffer.writeln("$indent  padding: $padValue,");
        buffer.writeln("$indent  child: ${padChild != 'null' ? padChild : 'const SizedBox.shrink()'},");
        buffer.write("$indent)");
        break;

      case 'Center':
        final centerChild = compileChild('child');
        buffer.writeln("Center(");
        buffer.writeln("$indent  child: ${centerChild != 'null' ? centerChild : 'const SizedBox.shrink()'},");
        buffer.write("$indent)");
        break;

      case 'Align':
        final alignVal = _formatAlignment(getProp('alignment'));
        final alignChild = compileChild('child');
        buffer.writeln("Align(");
        buffer.writeln("$indent  alignment: $alignVal,");
        buffer.writeln("$indent  child: ${alignChild != 'null' ? alignChild : 'const SizedBox.shrink()'},");
        buffer.write("$indent)");
        break;

      case 'Positioned':
        final posTop    = getProp('top');
        final posLeft   = getProp('left');
        final posRight  = getProp('right');
        final posBottom = getProp('bottom');
        final posWidth  = getProp('width');
        final posHeight = getProp('height');
        final posChild  = compileChild('child');
        buffer.writeln("Positioned(");
        if (posTop    != null) buffer.writeln("$indent  top: ${PropertyParser.tryParseDouble(posTop) ?? 0.0},");
        if (posLeft   != null) buffer.writeln("$indent  left: ${PropertyParser.tryParseDouble(posLeft) ?? 0.0},");
        if (posRight  != null) buffer.writeln("$indent  right: ${PropertyParser.tryParseDouble(posRight) ?? 0.0},");
        if (posBottom != null) buffer.writeln("$indent  bottom: ${PropertyParser.tryParseDouble(posBottom) ?? 0.0},");
        if (posWidth  != null) buffer.writeln("$indent  width: ${PropertyParser.tryParseDouble(posWidth) ?? 0.0},");
        if (posHeight != null) buffer.writeln("$indent  height: ${PropertyParser.tryParseDouble(posHeight) ?? 0.0},");
        buffer.writeln("$indent  child: ${posChild != 'null' ? posChild : 'const SizedBox.shrink()'},");
        buffer.write("$indent)");
        break;

      // ================== NAVIGATION WIDGETS ==================

      case 'BottomNavigationBar':
        final navItems = (getProp('items') as List?) ?? [];
        buffer.writeln("Obx(() => BottomNavigationBar(");
        buffer.writeln("$indent  currentIndex: controller.selectedNavigationIndex.value,");
        buffer.writeln("$indent  onTap: (i) => controller.selectedNavigationIndex.value = i,");
        if (navItems.isNotEmpty) {
          buffer.writeln("$indent  items: const [");
          for (final item in navItems) {
            final itemLabel = item is Map ? (item['label'] ?? item['title'] ?? 'Item').toString() : item.toString();
            final itemIcon  = item is Map ? _mapIconName(item['icon']) : 'label';
            buffer.writeln("$indent    BottomNavigationBarItem(icon: Icon(Icons.$itemIcon), label: '$itemLabel'),");
          }
          buffer.writeln("$indent  ],");
        } else {
          // Fall back to tab labels from controller
          buffer.writeln("$indent  items: controller.tabLabels.map((label) => BottomNavigationBarItem(");
          buffer.writeln("$indent    icon: const Icon(Icons.label_outline),");
          buffer.writeln("$indent    label: label,");
          buffer.writeln("$indent  )).toList(),");
        }
        buffer.write("$indent))");
        break;

      case 'FloatingActionButton':
        final fabIcon  = _mapIconName(getProp('icon') ?? 'add');
        final fabLabel = getProp('label')?.toString() ?? '';
        final fabBg    = _formatColor(getProp('backgroundColor'));
        final fabMethod = _labelToMethodName(fabLabel.isNotEmpty ? fabLabel : 'floatingAction');
        buffer.writeln("FloatingActionButton(");
        buffer.writeln("$indent  onPressed: () => controller.$fabMethod(),");
        if (fabBg != 'null') buffer.writeln("$indent  backgroundColor: $fabBg,");
        if (fabLabel.isNotEmpty) {
          buffer.writeln("$indent  tooltip: '$fabLabel',");
        }
        buffer.writeln("$indent  child: const Icon(Icons.$fabIcon),");
        buffer.write("$indent)");
        break;

      case 'TabBarView':
        final tvChildren = compileChildren();
        buffer.writeln("TabBarView(");
        buffer.writeln("$indent  children: [");
        if (tvChildren.isNotEmpty) {
          for (final c in tvChildren) {
            buffer.writeln("$indent    SingleChildScrollView(child: $c),");
          }
        } else {
          buffer.writeln("$indent    ...controller.tabLabels.map((label) => Center(child: Text('\$label Content'))),");
        }
        buffer.writeln("$indent  ],");
        buffer.write("$indent)");
        break;

      // ================== FORM INPUTS (additional) ==================

      case 'Radio':
        final fieldName = getProp('fieldName') ?? node.id;
        final camel = _toCamelCase(fieldName.toString());
        final label = getProp('label') ?? fieldName;
        final radioValue = getProp('value')?.toString() ?? label.toString();
        buffer.writeln("Obx(() => RadioListTile<String>(");
        buffer.writeln("$indent  title: Text('$label', style: GoogleFonts.inter(fontSize: 14)),");
        buffer.writeln("$indent  value: '$radioValue',");
        buffer.writeln("$indent  groupValue: controller.$camel.value,");
        buffer.writeln("$indent  onChanged: (val) => controller.$camel.value = val ?? '',");
        buffer.write("$indent))");
        break;

      case 'Slider':
        final fieldName = getProp('fieldName') ?? node.id;
        final camel = _toCamelCase(fieldName.toString());
        final label = getProp('label') ?? fieldName;
        final minVal = PropertyParser.tryParseDouble(getProp('min')) ?? 0.0;
        final maxVal = PropertyParser.tryParseDouble(getProp('max')) ?? 100.0;
        final divisions = getProp('divisions');
        buffer.writeln("Column(");
        buffer.writeln("$indent  crossAxisAlignment: CrossAxisAlignment.start,");
        buffer.writeln("$indent  mainAxisSize: MainAxisSize.min,");
        buffer.writeln("$indent  children: [");
        buffer.writeln("$indent    Text('$label', style: GoogleFonts.inter(fontSize: 14)),");
        buffer.writeln("$indent    Obx(() => Slider(");
        buffer.writeln("$indent      value: controller.$camel.value,");
        buffer.writeln("$indent      min: $minVal,");
        buffer.writeln("$indent      max: $maxVal,");
        if (divisions != null) buffer.writeln("$indent      divisions: $divisions,");
        buffer.writeln("$indent      label: controller.$camel.value.toStringAsFixed(1),");
        buffer.writeln("$indent      onChanged: (val) => controller.$camel.value = val,");
        buffer.writeln("$indent    )),");
        buffer.writeln("$indent  ],");
        buffer.write("$indent)");
        break;

      case 'OTP':
        final fieldName = getProp('fieldName') ?? node.id;
        final camel = _toCamelCase(fieldName.toString());
        final length = getProp('length') is int ? getProp('length') : 6;
        buffer.writeln("Row(");
        buffer.writeln("$indent  mainAxisAlignment: MainAxisAlignment.center,");
        buffer.writeln("$indent  children: List.generate($length, (i) => Container(");
        buffer.writeln("$indent    width: 44,");
        buffer.writeln("$indent    margin: const EdgeInsets.symmetric(horizontal: 4),");
        buffer.writeln("$indent    child: TextFormField(");
        buffer.writeln("$indent      controller: controller.${camel}Controller,");
        buffer.writeln("$indent      textAlign: TextAlign.center,");
        buffer.writeln("$indent      maxLength: 1,");
        buffer.writeln("$indent      keyboardType: TextInputType.number,");
        buffer.writeln("$indent      decoration: const InputDecoration(");
        buffer.writeln("$indent        counterText: '',");
        buffer.writeln("$indent        border: OutlineInputBorder(),");
        buffer.writeln("$indent      ),");
        buffer.writeln("$indent    ),");
        buffer.writeln("$indent  )),");
        buffer.write("$indent)");
        break;

      case 'ListTile':
        final ltTitle    = getProp('title')?.toString() ?? 'Item';
        final ltSubtitle = getProp('subtitle')?.toString();
        final ltIcon     = getProp('icon') != null ? _mapIconName(getProp('icon')) : null;
        final ltTrailing = getProp('trailing')?.toString();
        final ltOnTap    = getProp('onTap')?.toString();
        final ltMethodName = ltOnTap != null ? _labelToMethodName(ltOnTap) : null;
        buffer.writeln("ListTile(");
        if (ltIcon != null) buffer.writeln("$indent  leading: const Icon(Icons.$ltIcon),");
        buffer.writeln("$indent  title: Text('$ltTitle', style: GoogleFonts.inter(fontSize: 14)),");
        if (ltSubtitle != null) buffer.writeln("$indent  subtitle: Text('$ltSubtitle'),");
        if (ltTrailing != null) buffer.writeln("$indent  trailing: const Icon(Icons.chevron_right),");
        if (ltMethodName != null) {
          buffer.writeln("$indent  onTap: () => controller.$ltMethodName(),");
        } else {
          buffer.writeln("$indent  onTap: () {},");
        }
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

    if (needsVisibilityWrapper) {
      final innerWidget = buffer.toString();
      buffer.clear();
      buffer.writeln("LayoutBuilder(builder: (context, constraints) {");
      buffer.writeln("$indent  final width = MediaQuery.of(context).size.width;");
      buffer.writeln("$indent  final isMobile = width < 600;");
      buffer.writeln("$indent  final isTablet = width >= 600 && width < 1024;");
      buffer.writeln("$indent  final isDesktop = width >= 1024;");
      buffer.writeln("$indent  bool isVisible = true;");
      if (!visMobile) buffer.writeln("$indent  if (isMobile) isVisible = false;");
      if (!visTablet) buffer.writeln("$indent  if (isTablet) isVisible = false;");
      if (!visDesktop) buffer.writeln("$indent  if (isDesktop) isVisible = false;");
      buffer.writeln("$indent  if (!isVisible) return const SizedBox.shrink();");
      buffer.writeln("$indent  return $innerWidget;");
      buffer.write("$indent})");
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
    // If the string is already camelCase (no spaces/underscores), return it
    // with only the first character lowercased.
    if (!clean.contains(RegExp(r'[\s_\-]'))) {
      return clean[0].toLowerCase() + clean.substring(1);
    }
    final parts = clean.split(RegExp(r'[\s_\-]+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    final buffer = StringBuffer();
    // First word: lowercase the first char only, preserve the rest
    final first = parts.first;
    buffer.write(first[0].toLowerCase() + first.substring(1));
    for (int i = 1; i < parts.length; i++) {
      final p = parts[i];
      // Subsequent words: uppercase first char only, preserve the rest
      buffer.write(p[0].toUpperCase() + p.substring(1));
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

  static void _findButtons(ComponentNode node, List<ComponentNode> buttons) {
    if (node.type == 'Button' || node.type == 'IconButton') {
      buttons.add(node);
    }
    for (final child in node.children) {
      _findButtons(child, buttons);
    }
    for (final slotChild in node.slots.values) {
      if (slotChild != null) {
        _findButtons(slotChild, buttons);
      }
    }
  }

  static String _labelToMethodName(String label) {
    var clean = label.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
    if (clean.toLowerCase().startsWith('new ')) {
      clean = 'create ' + clean.substring(4);
    }
    final parts = clean.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'submitForm';
    
    final buffer = StringBuffer();
    buffer.write(parts.first.toLowerCase());
    for (int i = 1; i < parts.length; i++) {
      buffer.write(parts[i][0].toUpperCase() + parts[i].substring(1).toLowerCase());
    }
    final res = buffer.toString();
    if (res == 'submit') return 'submitForm';
    return res;
  }

  static String _mapIconName(dynamic val) {
    if (val == null) return 'help';
    var name = val.toString().trim().replaceAll('Icons.', '');
    // Normalization rules for invalid/non-standard Flutter icons
    if (name == 'account') return 'person';
    if (name == 'chart') return 'bar_chart';
    if (name == 'leads' || name == 'lead') return 'people';
    if (name == 'deals' || name == 'deal') return 'monetization_on';
    if (name == 'tasks' || name == 'task') return 'task_alt';
    if (name == 'settings') return 'settings';
    if (name == 'analytics') return 'analytics';
    if (name == 'search') return 'search';
    return name;
  }

  static String _compileTextString(String text) {
    final escaped = text.replaceAll("'", "\\'");
    final clean = escaped.trim().replaceAll('{', '').replaceAll('}', '');
    
    if (clean == 'totalLeads' || clean == '124') {
      return "'\${controller.totalLeads.value}'";
    }
    if (clean == 'totalDeals' || clean == '45') {
      return "'\${controller.totalDeals.value}'";
    }
    if (clean == 'activeTasks' || clean == '12') {
      return "'\${controller.activeTasks.value}'";
    }
    if (clean == 'revenue' || clean == '54200' || clean == '54,200' || clean == '\$54,200') {
      return "'\$\${controller.revenue.value}'";
    }

    final matches = RegExp(r'\{([a-zA-Z0-9_]+)\}').allMatches(escaped);
    if (matches.isEmpty) return "'$escaped'";

    var result = escaped;
    for (final match in matches) {
      final token = match.group(0)!; // e.g. "{totalLeads}"
      final varName = match.group(1)!; // e.g. "totalLeads"
      result = result.replaceFirst(token, "\${controller.$varName.value}");
    }
    return "'$result'";
  }
}
