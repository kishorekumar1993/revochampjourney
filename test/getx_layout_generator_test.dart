import 'package:flutter_test/flutter_test.dart';
import 'package:revojourneytryone/core/component_engine/models/component_node.dart';
import 'package:revojourneytryone/codegenerator/getx/getx_layout_generator.dart';

void main() {
  group('GetxLayoutGenerator - Nested Layout Generation', () {
    test('compiles nested Container -> Column -> Card -> Text structure correctly', () {
      final textNode = ComponentNode(
        id: 'nested-text',
        type: 'Text',
        properties: {'text': 'Hello Nested World'},
        children: [],
        actions: [],
      );

      final cardNode = ComponentNode(
        id: 'nested-card',
        type: 'Card',
        properties: {},
        children: [textNode],
        actions: [],
      );

      final columnNode = ComponentNode(
        id: 'nested-column',
        type: 'Column',
        properties: {'spacing': 10.0},
        children: [cardNode],
        actions: [],
      );

      final containerNode = ComponentNode(
        id: 'nested-container',
        type: 'Container',
        properties: {'width': 300.0, 'height': 200.0},
        children: [columnNode],
        actions: [],
      );

      final code = GetxLayoutGenerator.generateView(containerNode, 'MyCustomScreen', 'my_custom_screen');
      
      expect(code, contains('class MyCustomScreenView extends GetView<MyCustomScreenController>'));
      expect(code, contains('Container('));
      expect(code, contains('getValueForScreenType<double>(context: context, mobile: 300.0, tablet: 300.0, desktop: 300.0)'));
      expect(code, contains('getValueForScreenType<double>(context: context, mobile: 200.0, tablet: 200.0, desktop: 200.0)'));
      expect(code, contains('Column('));
      expect(code, contains('Card('));
      expect(code, contains('Text('));
      expect(code, contains('Hello Nested World'));
    });

    test('compiles 6-level deep nested structure Container -> Column -> Row -> Card -> Column -> Text correctly', () {
      final textNode = ComponentNode(
        id: 'deep-text',
        type: 'Text',
        properties: {'text': 'Deep Nesting Value'},
        children: [],
        actions: [],
      );

      final innerColumnNode = ComponentNode(
        id: 'inner-column',
        type: 'Column',
        properties: {},
        children: [textNode],
        actions: [],
      );

      final cardNode = ComponentNode(
        id: 'deep-card',
        type: 'Card',
        properties: {},
        children: [innerColumnNode],
        actions: [],
      );

      final rowNode = ComponentNode(
        id: 'deep-row',
        type: 'Row',
        properties: {},
        children: [cardNode],
        actions: [],
      );

      final columnNode = ComponentNode(
        id: 'deep-column',
        type: 'Column',
        properties: {},
        children: [rowNode],
        actions: [],
      );

      final containerNode = ComponentNode(
        id: 'deep-container',
        type: 'Container',
        properties: {},
        children: [columnNode],
        actions: [],
      );

      final code = GetxLayoutGenerator.generateView(containerNode, 'DeepScreen', 'deep_screen');
      
      expect(code, contains('Container('));
      expect(code, contains('Column('));
      expect(code, contains('Row('));
      expect(code, contains('Card('));
      expect(code, contains('Text('));
      expect(code, contains('Deep Nesting Value'));
    });
  });

  group('GetxLayoutGenerator - Charts & Complex Widgets delegation', () {
    test('delegates generic Chart type dynamically to LineChart, BarChart, or PieChart', () {
      final chartNode = ComponentNode(
        id: 'dashboard-chart',
        type: 'Chart',
        properties: {'chartType': 'bar'},
        children: [],
        actions: [],
      );

      final code = GetxLayoutGenerator.generateView(chartNode, 'Dash', 'dash');
      expect(code, contains('BarChart('));
      expect(code, contains('BarChartGroupData('));
    });

    test('compiles AreaChart using belowBarData correctly', () {
      final chartNode = ComponentNode(
        id: 'area-chart-node',
        type: 'AreaChart',
        properties: {},
        children: [],
        actions: [],
      );

      final code = GetxLayoutGenerator.generateView(chartNode, 'AreaDash', 'area_dash');
      expect(code, contains('LineChart('));
      expect(code, contains('belowBarData:'));
    });

    test('compiles advanced business widgets correctly', () {
      final dataTableNode = ComponentNode(
        id: 'business-table',
        type: 'DataTable',
        properties: {},
        children: [],
        actions: [],
      );

      final code = GetxLayoutGenerator.generateView(dataTableNode, 'Biz', 'biz');
      expect(code, contains('DataTable('));
      expect(code, contains('controller.tableColumns'));
      expect(code, contains('controller.tableRows'));
    });
  });

  group('GetxLayoutGenerator - Card Metric fallbacks & Dynamic Data Bindings', () {
    test('generates title and value column inside Card when no children are present', () {
      final cardNode = ComponentNode(
        id: 'leads-card',
        type: 'Card',
        properties: {'title': 'Active Leads', 'value': '{totalLeads}'},
        children: [],
        actions: [],
      );

      final code = GetxLayoutGenerator.generateView(cardNode, 'Dashboard', 'dashboard');
      expect(code, contains('Active Leads'));
      expect(code, contains('Obx('));
      expect(code, contains('controller.totalLeads.value'));
    });

    test('binds static values in text nodes dynamically to controller observables', () {
      final textNode = ComponentNode(
        id: 'metric-text',
        type: 'Text',
        properties: {'text': '124'},
        children: [],
        actions: [],
      );

      final code = GetxLayoutGenerator.generateView(textNode, 'Dashboard', 'dashboard');
      expect(code, contains('Obx('));
      expect(code, contains('controller.totalLeads.value'));
    });
  });

  group('GetxLayoutGenerator - Controller Fields', () {
    test('always generates pageSearchController text controller and disposes it', () {
      final textNode = ComponentNode(
        id: 'dummy-text',
        type: 'Text',
        properties: {'text': 'Hello'},
        children: [],
        actions: [],
      );

      final code = GetxLayoutGenerator.generateController(textNode, 'SearchScreen');
      expect(code, contains('final pageSearchController = TextEditingController();'));
      expect(code, contains('pageSearchController.dispose();'));
    });
  });

  group('GetxLayoutGenerator - Responsive Engine', () {
    test('injects getValueForScreenType helper method in class view', () {
      final textNode = ComponentNode(
        id: 'responsive-text',
        type: 'Text',
        properties: {'text': 'Mobile/Desktop test'},
        children: [],
        actions: [],
      );

      final code = GetxLayoutGenerator.generateView(textNode, 'Resp', 'resp');
      expect(code, contains('T getValueForScreenType<T>('));
    });

    test('wraps widgets in LayoutBuilder when visibleOnMobile is false', () {
      final textNode = ComponentNode(
        id: 'hidden-mobile-text',
        type: 'Text',
        properties: {'text': 'Desktop Only', 'visibleOnMobile': false},
        children: [],
        actions: [],
      );

      final code = GetxLayoutGenerator.generateView(textNode, 'Vis', 'vis');
      expect(code, contains('LayoutBuilder('));
      expect(code, contains('if (isMobile) isVisible = false;'));
    });

    test('always compiles spacing using getValueForScreenType', () {
      final children = [
        ComponentNode(id: 'c1', type: 'Text', properties: {'text': 'A'}, children: [], actions: []),
        ComponentNode(id: 'c2', type: 'Text', properties: {'text': 'B'}, children: [], actions: []),
      ];
      final colNode = ComponentNode(
        id: 'spacing-column',
        type: 'Column',
        properties: {'spacing': 15.0},
        children: children,
        actions: [],
      );

      final code = GetxLayoutGenerator.generateView(colNode, 'Spc', 'spc');
      expect(code, contains('getValueForScreenType<double>(context: context, mobile: 15.0, tablet: 15.0, desktop: 15.0)'));
    });

    test('automatically makes Row scrollable on mobile if it has more than 3 children', () {
      final children = List.generate(4, (i) => ComponentNode(
        id: 'item-$i',
        type: 'Text',
        properties: {'text': 'Nav $i'},
        children: [],
        actions: [],
      ));

      final rowNode = ComponentNode(
        id: 'nav-row',
        type: 'Row',
        properties: {},
        children: children,
        actions: [],
      );

      final code = GetxLayoutGenerator.generateView(rowNode, 'Nav', 'nav');
      expect(code, contains('SingleChildScrollView('));
      expect(code, contains('scrollDirection: Axis.horizontal,'));
    });
  });

  group('GetxLayoutGenerator - Safety rules & Flex parent check', () {
    test('strips Expanded helper if parent is NOT Row, Column, or Flex', () {
      final textNode = ComponentNode(
        id: 'nested-text',
        type: 'Text',
        properties: {'text': 'Hello'},
        children: [],
        actions: [],
      );

      final expandedNode = ComponentNode(
        id: 'expanded-node',
        type: 'Expanded',
        properties: {},
        children: [textNode],
        actions: [],
      );

      final containerNode = ComponentNode(
        id: 'parent-container',
        type: 'Container',
        properties: {},
        children: [expandedNode],
        actions: [],
      );

      final code = GetxLayoutGenerator.generateView(containerNode, 'Safety', 'safety');
      // Should compile Text child directly without Expanded(
      expect(code, isNot(contains('Expanded(')));
      expect(code, contains('Text('));
    });
  });

  group('GetxLayoutGenerator - Contrast logic for light badges', () {
    test('uses dark green text for light green badge backgrounds', () {
      final badgeNode = ComponentNode(
        id: 'success-badge',
        type: 'Badge',
        properties: {'label': 'Completed', 'color': '#DCFCE7'},
        children: [],
        actions: [],
      );

      final code = GetxLayoutGenerator.generateView(badgeNode, 'Status', 'status');
      expect(code, contains('const Color(0xFF166534)'));
    });

    test('uses indigo text for light blue badge backgrounds', () {
      final badgeNode = ComponentNode(
        id: 'blue-badge',
        type: 'Badge',
        properties: {'label': 'Q2 2025', 'color': '#EEF2FF'},
        children: [],
        actions: [],
      );

      final code = GetxLayoutGenerator.generateView(badgeNode, 'Status', 'status');
      expect(code, contains('const Color(0xFF4338CA)'));
    });

    test('uses amber text for light orange badge backgrounds', () {
      final badgeNode = ComponentNode(
        id: 'amber-badge',
        type: 'Badge',
        properties: {'label': 'Required: *', 'color': '#FEF3C7'},
        children: [],
        actions: [],
      );

      final code = GetxLayoutGenerator.generateView(badgeNode, 'Status', 'status');
      expect(code, contains('const Color(0xFF92400E)'));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // New widget cases added to fix placeholder rendering
  // ════════════════════════════════════════════════════════════════════════════

  group('GetxLayoutGenerator - Single-child Layout Widgets', () {
    test('compiles SingleChildScrollView with vertical axis by default', () {
      final textNode = ComponentNode(
        id: 'scs-text', type: 'Text',
        properties: {'text': 'Scrollable'}, children: [], actions: [],
      );
      final scsNode = ComponentNode(
        id: 'scs-root', type: 'SingleChildScrollView',
        properties: {}, children: [textNode], actions: [],
      );
      final code = GetxLayoutGenerator.generateView(scsNode, 'ScrollPage', 'scroll_page');
      expect(code, contains('SingleChildScrollView('));
      expect(code, contains('Axis.vertical'));
      expect(code, contains('Scrollable'));
    });

    test('compiles SingleChildScrollView with horizontal axis', () {
      final scsNode = ComponentNode(
        id: 'scs-h', type: 'SingleChildScrollView',
        properties: {'scrollDirection': 'horizontal'}, children: [], actions: [],
      );
      final code = GetxLayoutGenerator.generateView(scsNode, 'HScroll', 'h_scroll');
      expect(code, contains('Axis.horizontal'));
    });

    test('compiles Padding with default padding', () {
      final textNode = ComponentNode(
        id: 'pad-child', type: 'Text',
        properties: {'text': 'Padded'}, children: [], actions: [],
      );
      final padNode = ComponentNode(
        id: 'pad-root', type: 'Padding',
        properties: {}, children: [textNode], actions: [],
      );
      final code = GetxLayoutGenerator.generateView(padNode, 'PadPage', 'pad_page');
      expect(code, contains('Padding('));
      expect(code, contains('Padded'));
    });

    test('compiles Center wrapping a child', () {
      final textNode = ComponentNode(
        id: 'center-child', type: 'Text',
        properties: {'text': 'Centered'}, children: [], actions: [],
      );
      final centerNode = ComponentNode(
        id: 'center-root', type: 'Center',
        properties: {}, children: [textNode], actions: [],
      );
      final code = GetxLayoutGenerator.generateView(centerNode, 'CenterPage', 'center_page');
      expect(code, contains('Center('));
      expect(code, contains('Centered'));
    });

    test('compiles Align with alignment property', () {
      final textNode = ComponentNode(
        id: 'align-child', type: 'Text',
        properties: {'text': 'Aligned'}, children: [], actions: [],
      );
      final alignNode = ComponentNode(
        id: 'align-root', type: 'Align',
        properties: {'alignment': 'bottomRight'}, children: [textNode], actions: [],
      );
      final code = GetxLayoutGenerator.generateView(alignNode, 'AlignPage', 'align_page');
      expect(code, contains('Align('));
      expect(code, contains('Alignment.bottomRight'));
    });

    test('compiles Positioned with top and left offsets', () {
      final child = ComponentNode(
        id: 'pos-child', type: 'Text',
        properties: {'text': 'Positioned'}, children: [], actions: [],
      );
      final posNode = ComponentNode(
        id: 'pos-root', type: 'Positioned',
        properties: {'top': 20.0, 'left': 10.0}, children: [child], actions: [],
      );
      final code = GetxLayoutGenerator.generateView(posNode, 'PosPage', 'pos_page');
      expect(code, contains('Positioned('));
      expect(code, contains('top: 20.0'));
      expect(code, contains('left: 10.0'));
    });
  });

  group('GetxLayoutGenerator - Navigation & Misc Widgets', () {
    test('compiles BottomNavigationBar with items from JSON', () {
      final bnb = ComponentNode(
        id: 'bnb', type: 'BottomNavigationBar',
        properties: {
          'items': [
            {'label': 'Home', 'icon': 'home'},
            {'label': 'Search', 'icon': 'search'},
          ],
        },
        children: [], actions: [],
      );
      final code = GetxLayoutGenerator.generateView(bnb, 'NavPage', 'nav_page');
      expect(code, contains('BottomNavigationBar('));
      expect(code, contains('controller.selectedNavigationIndex.value'));
      expect(code, contains("label: 'Home'"));
      expect(code, contains("label: 'Search'"));
    });

    test('compiles FloatingActionButton with icon and method', () {
      final fab = ComponentNode(
        id: 'fab', type: 'FloatingActionButton',
        properties: {'icon': 'add', 'label': 'Add Item'},
        children: [], actions: [],
      );
      final code = GetxLayoutGenerator.generateView(fab, 'FabPage', 'fab_page');
      expect(code, contains('FloatingActionButton('));
      expect(code, contains('Icons.add'));
      expect(code, contains("controller.addItem()"));
    });

    test('compiles TabBarView recursively rendering children', () {
      final tab1 = ComponentNode(
        id: 'tab1', type: 'Text',
        properties: {'text': 'Overview Content'}, children: [], actions: [],
      );
      final tab2 = ComponentNode(
        id: 'tab2', type: 'Text',
        properties: {'text': 'Details Content'}, children: [], actions: [],
      );
      final tbv = ComponentNode(
        id: 'tbv', type: 'TabBarView',
        properties: {}, children: [tab1, tab2], actions: [],
      );
      final code = GetxLayoutGenerator.generateView(tbv, 'TabPage', 'tab_page');
      expect(code, contains('TabBarView('));
      expect(code, contains('Overview Content'));
      expect(code, contains('Details Content'));
      expect(code, contains('SingleChildScrollView(child:'));
    });

    test('compiles ListTile with icon, title, and subtitle', () {
      final tile = ComponentNode(
        id: 'tile', type: 'ListTile',
        properties: {
          'title': 'Contact Name',
          'subtitle': 'Active Lead',
          'icon': 'person',
        },
        children: [], actions: [],
      );
      final code = GetxLayoutGenerator.generateView(tile, 'TilePage', 'tile_page');
      expect(code, contains('ListTile('));
      expect(code, contains("'Contact Name'"));
      expect(code, contains("'Active Lead'"));
      expect(code, contains('Icons.person'));
    });
  });

  group('GetxLayoutGenerator - Additional Form Widgets', () {
    test('compiles Radio with value and groupValue binding', () {
      final radio = ComponentNode(
        id: 'radio-1', type: 'Radio',
        properties: {'fieldName': 'paymentType', 'label': 'Credit Card', 'value': 'credit'},
        children: [], actions: [],
      );
      final code = GetxLayoutGenerator.generateView(radio, 'RadioPage', 'radio_page');
      expect(code, contains('RadioListTile<String>('));
      expect(code, contains("value: 'credit'"));
      expect(code, contains('controller.paymentType.value'));
    });

    test('compiles Slider with min, max and controller binding', () {
      final slider = ComponentNode(
        id: 'slider-1', type: 'Slider',
        properties: {'fieldName': 'discount', 'label': 'Discount %', 'min': 0.0, 'max': 50.0},
        children: [], actions: [],
      );
      final code = GetxLayoutGenerator.generateView(slider, 'SliderPage', 'slider_page');
      expect(code, contains('Slider('));
      expect(code, contains('controller.discount.value'));
      expect(code, contains('min: 0.0'));
      expect(code, contains('max: 50.0'));
    });

    test('compiles OTP with 6 digit boxes', () {
      final otp = ComponentNode(
        id: 'otp-1', type: 'OTP',
        properties: {'fieldName': 'verificationCode', 'length': 6},
        children: [], actions: [],
      );
      final code = GetxLayoutGenerator.generateView(otp, 'OtpPage', 'otp_page');
      expect(code, contains('List.generate(6'));
      expect(code, contains('maxLength: 1'));
      expect(code, contains('controller.verificationCodeController'));
    });
  });

  group('GetxLayoutGenerator - Conditional Controller Variable Emission', () {
    ComponentNode _makeRoot(String widgetType, [Map<String, dynamic>? props]) =>
        ComponentNode(
          id: 'root', type: widgetType,
          properties: props ?? {}, children: [], actions: [],
        );

    test('does NOT emit tableColumns if no DataTable in tree', () {
      final root = _makeRoot('Column');
      final ctrl = GetxLayoutGenerator.generateController(root, 'MyCtrl');
      expect(ctrl, isNot(contains('tableColumns')));
      expect(ctrl, isNot(contains('tableRows')));
    });

    test('DOES emit tableColumns if DataTable is in tree', () {
      final table = ComponentNode(
        id: 'dt', type: 'DataTable',
        properties: {'columns': ['Name', 'Status']},
        children: [], actions: [],
      );
      final root = ComponentNode(
        id: 'root', type: 'Column',
        properties: {}, children: [table], actions: [],
      );
      final ctrl = GetxLayoutGenerator.generateController(root, 'MyCtrl');
      expect(ctrl, contains('tableColumns'));
      expect(ctrl, contains("'Name'"));
      expect(ctrl, contains("'Status'"));
    });

    test('does NOT emit gridItems if no GridView in tree', () {
      final root = _makeRoot('Container');
      final ctrl = GetxLayoutGenerator.generateController(root, 'MyCtrl');
      expect(ctrl, isNot(contains('gridItems')));
    });

    test('does NOT emit chartSpots if no chart widget in tree', () {
      final root = _makeRoot('Text', {'text': 'Hello'});
      final ctrl = GetxLayoutGenerator.generateController(root, 'MyCtrl');
      expect(ctrl, isNot(contains('chartSpots')));
    });

    test('DOES emit chartSpots if LineChart is in tree', () {
      final chart = ComponentNode(
        id: 'lc', type: 'LineChart',
        properties: {'data': [{'x': 1.0, 'y': 2.0}, {'x': 2.0, 'y': 4.0}]},
        children: [], actions: [],
      );
      final root = ComponentNode(
        id: 'root', type: 'Column',
        properties: {}, children: [chart], actions: [],
      );
      final ctrl = GetxLayoutGenerator.generateController(root, 'MyCtrl');
      expect(ctrl, contains('chartSpots'));
      expect(ctrl, contains("'x': 1.0, 'y': 2.0"));
    });

    test('does NOT emit stepperSteps if no Stepper in tree', () {
      final root = _makeRoot('Container');
      final ctrl = GetxLayoutGenerator.generateController(root, 'MyCtrl');
      expect(ctrl, isNot(contains('stepperSteps')));
      expect(ctrl, isNot(contains('currentStep')));
    });

    test('DOES emit stepperSteps and currentStep if Stepper is in tree', () {
      final stepper = ComponentNode(
        id: 'sp', type: 'Stepper',
        properties: {'steps': ['Step 1', 'Step 2', 'Step 3']},
        children: [], actions: [],
      );
      final root = ComponentNode(
        id: 'root', type: 'Column',
        properties: {}, children: [stepper], actions: [],
      );
      final ctrl = GetxLayoutGenerator.generateController(root, 'MyCtrl');
      expect(ctrl, contains('stepperSteps'));
      expect(ctrl, contains('currentStep'));
      expect(ctrl, contains("'Step 1'"));
    });

    test('does NOT emit selectedNavigationIndex if no NavigationRail or BottomNav in tree', () {
      final root = _makeRoot('Column');
      final ctrl = GetxLayoutGenerator.generateController(root, 'MyCtrl');
      expect(ctrl, isNot(contains('selectedNavigationIndex')));
    });

    test('DOES emit selectedNavigationIndex if NavigationRail is in tree', () {
      final nav = ComponentNode(
        id: 'nav', type: 'NavigationRail',
        properties: {}, children: [], actions: [],
      );
      final root = ComponentNode(
        id: 'root', type: 'Column',
        properties: {}, children: [nav], actions: [],
      );
      final ctrl = GetxLayoutGenerator.generateController(root, 'MyCtrl');
      expect(ctrl, contains('selectedNavigationIndex'));
    });

    test('always emits dashboard metric observables regardless of tree', () {
      final root = _makeRoot('Text', {'text': 'hello'});
      final ctrl = GetxLayoutGenerator.generateController(root, 'MyCtrl');
      expect(ctrl, contains('final totalLeads'));
      expect(ctrl, contains('final totalDeals'));
      expect(ctrl, contains('final activeTasks'));
      expect(ctrl, contains('final revenue'));
    });
  });
}

