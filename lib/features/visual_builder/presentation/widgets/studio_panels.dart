import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/component_engine/models/app_variable.dart';
import '../../../../core/component_engine/models/api_config.dart';
import '../../../../core/component_engine/models/database_config.dart';
import '../../../../core/component_engine/models/component_node.dart';
import '../../../journey_builder/application/controllers/journey_controller.dart';
import '../../application/studio_providers.dart';
import '../../application/visual_builder_controller.dart';

class RevoStudioPanelWrapper extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget>? actions;

  const RevoStudioPanelWrapper({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(right: BorderSide(color: RevoTheme.cardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: RevoTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (actions != null) ...actions!,
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: RevoTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// 1. Pages/Journey step switcher panel
class RevoPagesPanel extends ConsumerWidget {
  const RevoPagesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyConfig = ref.watch(journeyConfigProvider);
    final activeStepId = ref.watch(activeStepIdProvider);

    return RevoStudioPanelWrapper(
      title: "Pages & Journey",
      subtitle: "Configure journey screens and steps",
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: journeyConfig.steps.length,
        itemBuilder: (context, index) {
          final step = journeyConfig.steps[index];
          final isSelected = step.id == activeStepId;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Card(
              color: isSelected ? const Color(0x1F5B4FCF) : RevoTheme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.cardBorder,
                ),
              ),
              child: ListTile(
                onTap: () {
                  ref.read(activeStepIdProvider.notifier).state = step.id;
                },
                leading: Icon(
                  Icons.phone_android_rounded,
                  color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.textSecondary,
                  size: 20,
                ),
                title: Text(
                  step.title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: RevoTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  "Fields: ${step.fields.length}",
                  style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 2. Theme Studio customize panel
class RevoThemeStudioPanel extends ConsumerWidget {
  const RevoThemeStudioPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(themeTokensProvider);
    final notifier = ref.read(themeTokensProvider.notifier);

    void showGeneratedCode(BuildContext context, String code) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: RevoTheme.sidebarBackground,
            title: Text("Generated theme.dart", style: GoogleFonts.outfit(color: RevoTheme.textPrimary)),
            content: SizedBox(
              width: 500,
              height: 400,
              child: TextField(
                controller: TextEditingController(text: code),
                maxLines: null,
                readOnly: true,
                style: GoogleFonts.sourceCodePro(fontSize: 11, color: Colors.greenAccent),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  fillColor: Colors.black,
                  filled: true,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(color: Color(0xFF5B4FCF))),
              ),
            ],
          );
        },
      );
    }

    String generateThemeDart(ThemeTokens tk) {
      return '''
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GeneratedAppTheme {
  static const primaryColor = Color(0xFF${tk.primaryColor.replaceAll('#', '')});
  static const secondaryColor = Color(0xFF${tk.secondaryColor.replaceAll('#', '')});
  static const backgroundColor = Color(0xFF${tk.backgroundColor.replaceAll('#', '')});

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.${tk.fontFamily.toLowerCase()}TextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(${tk.borderRadius}),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: ${tk.inputStyle == 'outline' ? 'OutlineInputBorder(borderRadius: BorderRadius.circular(${tk.borderRadius}))' : 'UnderlineInputBorder()'},
      ),
    );
  }
}
''';
    }

    return RevoStudioPanelWrapper(
      title: "Theme Studio",
      subtitle: "Customize visual theme design tokens",
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTextField(
            label: "Primary Color (Hex)",
            value: tokens.primaryColor,
            onChanged: (val) => notifier.updateTheme(tokens.copyWith(primaryColor: val)),
          ),
          _buildTextField(
            label: "Secondary Color (Hex)",
            value: tokens.secondaryColor,
            onChanged: (val) => notifier.updateTheme(tokens.copyWith(secondaryColor: val)),
          ),
          _buildTextField(
            label: "Background Color (Hex)",
            value: tokens.backgroundColor,
            onChanged: (val) => notifier.updateTheme(tokens.copyWith(backgroundColor: val)),
          ),
          _buildDropdown(
            label: "Font Family",
            value: tokens.fontFamily,
            options: ['Outfit', 'Inter', 'Roboto', 'Poppins', 'Open Sans'],
            onChanged: (val) => notifier.updateTheme(tokens.copyWith(fontFamily: val)),
          ),
          const SizedBox(height: 8),
          Text(
            "Radius: ${tokens.borderRadius.toInt()} px",
            style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textPrimary, fontWeight: FontWeight.w600),
          ),
          Slider(
            min: 0,
            max: 24,
            value: tokens.borderRadius,
            onChanged: (val) => notifier.updateTheme(tokens.copyWith(borderRadius: val)),
          ),
          _buildDropdown(
            label: "Button Theme",
            value: tokens.buttonStyle,
            options: ['elevated', 'outlined', 'flat'],
            onChanged: (val) => notifier.updateTheme(tokens.copyWith(buttonStyle: val)),
          ),
          _buildDropdown(
            label: "Input Decoration Theme",
            value: tokens.inputStyle,
            options: ['outline', 'filled', 'underline'],
            onChanged: (val) => notifier.updateTheme(tokens.copyWith(inputStyle: val)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final code = generateThemeDart(tokens);
              showGeneratedCode(context, code);
            },
            icon: const Icon(Icons.code_rounded, size: 16, color: Colors.white),
            label: const Text("Generate theme.dart", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// 3. API Studio config panel
class RevoApiStudioPanel extends ConsumerStatefulWidget {
  const RevoApiStudioPanel({super.key});

  @override
  ConsumerState<RevoApiStudioPanel> createState() => _RevoApiStudioPanelState();
}

class _RevoApiStudioPanelState extends ConsumerState<RevoApiStudioPanel> {
  ApiConfig? _selectedConfig;

  void _showCodeSnippetDialog(String title, String code) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: RevoTheme.sidebarBackground,
          title: Text(title, style: GoogleFonts.outfit(color: RevoTheme.textPrimary)),
          content: SizedBox(
            width: 500,
            height: 400,
            child: TextField(
              controller: TextEditingController(text: code),
              maxLines: null,
              readOnly: true,
              style: GoogleFonts.sourceCodePro(fontSize: 11, color: Colors.greenAccent),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                fillColor: Colors.black,
                filled: true,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Color(0xFF5B4FCF))),
            ),
          ],
        );
      },
    );
  }

  String _generateResponseModel(ApiConfig config) {
    return '''
class ${config.name.replaceAll(' ', '')}Response {
  final bool success;
  final String message;
  final Map<String, dynamic> data;

  ${config.name.replaceAll(' ', '')}Response({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ${config.name.replaceAll(' ', '')}Response.fromJson(Map<String, dynamic> json) {
    return ${config.name.replaceAll(' ', '')}Response(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
    };
  }
}
''';
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(apiConfigsProvider);
    final notifier = ref.read(apiConfigsProvider.notifier);

    if (_selectedConfig != null) {
      final config = _selectedConfig!;
      return RevoStudioPanelWrapper(
        title: "Edit API Endpoint",
        subtitle: config.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            onPressed: () => setState(() => _selectedConfig = null),
          ),
        ],
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField(
              label: "API Name",
              value: config.name,
              onChanged: (val) {
                final upd = config.copyWith(name: val);
                setState(() => _selectedConfig = upd);
                notifier.updateConfig(config.id, upd);
              },
            ),
            _buildTextField(
              label: "Base URL",
              value: config.baseUrl,
              onChanged: (val) {
                final upd = config.copyWith(baseUrl: val);
                setState(() => _selectedConfig = upd);
                notifier.updateConfig(config.id, upd);
              },
            ),
            _buildTextField(
              label: "Endpoint Path",
              value: config.endpoint,
              onChanged: (val) {
                final upd = config.copyWith(endpoint: val);
                setState(() => _selectedConfig = upd);
                notifier.updateConfig(config.id, upd);
              },
            ),
            _buildDropdown(
              label: "HTTP Method",
              value: config.method,
              options: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
              onChanged: (val) {
                final upd = config.copyWith(method: val);
                setState(() => _selectedConfig = upd);
                notifier.updateConfig(config.id, upd);
              },
            ),
            _buildTextField(
              label: "Authorization Type",
              value: config.authentication,
              onChanged: (val) {
                final upd = config.copyWith(authentication: val);
                setState(() => _selectedConfig = upd);
                notifier.updateConfig(config.id, upd);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showCodeSnippetDialog(
                        "Test API Response simulation",
                        '{\n  "success": true,\n  "message": "API executed successfully",\n  "data": {\n    "id": "12345",\n    "status": "active"\n  }\n}',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: Colors.teal[700],
                    ),
                    child: const Text("Test Endpoint", style: TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showCodeSnippetDialog(
                        "Generated Response Model",
                        _generateResponseModel(config),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: const Color(0xFF5B4FCF),
                    ),
                    child: const Text("Generate Model", style: TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return RevoStudioPanelWrapper(
      title: "API Studio",
      subtitle: "Configure REST APIs & endpoints",
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded, size: 18),
          onPressed: () {
            final id = 'api_${DateTime.now().millisecondsSinceEpoch}';
            final newApi = ApiConfig(
              id: id,
              name: 'New Custom API',
              baseUrl: 'https://api.example.com',
              endpoint: '/v1/users',
              method: 'GET',
            );
            notifier.addConfig(newApi);
            setState(() => _selectedConfig = newApi);
          },
        ),
      ],
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final api = list[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Card(
              child: ListTile(
                onTap: () => setState(() => _selectedConfig = api),
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getMethodColor(api.method).withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    api.method,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _getMethodColor(api.method),
                    ),
                  ),
                ),
                title: Text(
                  api.name,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  api.endpoint,
                  style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                  onPressed: () => notifier.deleteConfig(api.id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.blue;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }
}

// 4. Database builder studio panel
class RevoDatabaseStudioPanel extends ConsumerStatefulWidget {
  const RevoDatabaseStudioPanel({super.key});

  @override
  ConsumerState<RevoDatabaseStudioPanel> createState() => _RevoDatabaseStudioPanelState();
}

class _RevoDatabaseStudioPanelState extends ConsumerState<RevoDatabaseStudioPanel> {
  TableConfig? _selectedTable;

  void _showGeneratedCode(String title, String code) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: RevoTheme.sidebarBackground,
          title: Text(title, style: GoogleFonts.outfit(color: RevoTheme.textPrimary)),
          content: SizedBox(
            width: 500,
            height: 400,
            child: TextField(
              controller: TextEditingController(text: code),
              maxLines: null,
              readOnly: true,
              style: GoogleFonts.sourceCodePro(fontSize: 11, color: Colors.greenAccent),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                fillColor: Colors.black,
                filled: true,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Color(0xFF5B4FCF))),
            ),
          ],
        );
      },
    );
  }

  String _generateRepository(TableConfig tc) {
    final capitalized = tc.name[0].toUpperCase() + tc.name.substring(1);
    return '''
import 'package:supabase_flutter/supabase_flutter.dart';

class ${capitalized}Repository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAll() async {
    final response = await _supabase.from('${tc.name}').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insert(Map<String, dynamic> data) async {
    await _supabase.from('${tc.name}').insert(data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _supabase.from('${tc.name}').update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _supabase.from('${tc.name}').delete().eq('id', id);
  }
}
''';
  }

  @override
  Widget build(BuildContext context) {
    final dbConfig = ref.watch(databaseConfigProvider);
    final notifier = ref.read(databaseConfigProvider.notifier);

    if (_selectedTable != null) {
      final table = _selectedTable!;
      return RevoStudioPanelWrapper(
        title: "Edit Table Scheme",
        subtitle: table.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            onPressed: () => setState(() => _selectedTable = null),
          ),
        ],
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTextField(
                    label: "Table Name",
                    value: table.name,
                    onChanged: (val) {
                      final upd = table.copyWith(name: val);
                      setState(() => _selectedTable = upd);
                      notifier.updateTable(table.name, upd);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Fields / Attributes", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF5B4FCF)),
                        onPressed: () {
                          final newField = FieldConfig(
                            name: 'field_${table.fields.length}',
                            type: 'String',
                          );
                          final upd = table.copyWith(fields: [...table.fields, newField]);
                          setState(() => _selectedTable = upd);
                          notifier.updateTable(table.name, upd);
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  ...table.fields.map((field) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              field.name,
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            field.type,
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5B4FCF)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                            onPressed: () {
                              final upd = table.copyWith(
                                fields: table.fields.where((f) => f.name != field.name).toList(),
                              );
                              setState(() => _selectedTable = upd);
                              notifier.updateTable(table.name, upd);
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  _showGeneratedCode(
                    "Generated Repository Class",
                    _generateRepository(table),
                  );
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.code_rounded, color: Colors.white),
                label: const Text("Generate Repository", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }

    return RevoStudioPanelWrapper(
      title: "Database Studio",
      subtitle: "Manage database models & endpoints",
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded, size: 18),
          onPressed: () {
            final table = TableConfig(
              name: 'new_table_${dbConfig.tables.length}',
              fields: [
                FieldConfig(name: 'id', type: 'String', isPrimaryKey: true, isNullable: false),
              ],
            );
            notifier.addTable(table);
            setState(() => _selectedTable = table);
          },
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: _buildDropdown(
              label: "Database Provider",
              value: dbConfig.type.toString().split('.').last,
              options: ['Firebase', 'Supabase', 'RestBackend'],
              onChanged: (val) {
                final type = DatabaseType.values.firstWhere((e) => e.toString().split('.').last == val);
                notifier.updateConfig(dbConfig.copyWith(type: type));
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: dbConfig.tables.length,
              itemBuilder: (context, index) {
                final table = dbConfig.tables[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Card(
                    child: ListTile(
                      onTap: () => setState(() => _selectedTable = table),
                      leading: const Icon(Icons.table_rows_rounded, color: Color(0xFF5B4FCF), size: 20),
                      title: Text(
                        table.name,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Columns: ${table.fields.length}",
                        style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                        onPressed: () => notifier.deleteTable(table.name),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 5. App Variables studio manager panel
class RevoVariablesPanel extends ConsumerWidget {
  const RevoVariablesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(appVariablesProvider);
    final notifier = ref.read(appVariablesProvider.notifier);

    void showGenerateSnippet(BuildContext context) {
      final code = '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppStateController extends StateNotifier<Map<String, dynamic>> {
  AppStateController() : super({
    ${list.map((v) => "'${v.name}': ${v.defaultValue is String ? "'${v.defaultValue}'" : v.defaultValue}").join(',\n    ')}
  });

  void updateVariable(String key, dynamic value) {
    state = {...state, key: value};
  }
}

final appStateProvider = StateNotifierProvider<AppStateController, Map<String, dynamic>>((ref) {
  return AppStateController();
});
''';

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: RevoTheme.sidebarBackground,
            title: Text("Generated Riverpod Provider", style: GoogleFonts.outfit(color: RevoTheme.textPrimary)),
            content: SizedBox(
              width: 500,
              height: 400,
              child: TextField(
                controller: TextEditingController(text: code),
                maxLines: null,
                readOnly: true,
                style: GoogleFonts.sourceCodePro(fontSize: 11, color: Colors.greenAccent),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  fillColor: Colors.black,
                  filled: true,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(color: Color(0xFF5B4FCF))),
              ),
            ],
          );
        },
      );
    }

    return RevoStudioPanelWrapper(
      title: "State Variables",
      subtitle: "Manage app-level reactive state variables",
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded, size: 18),
          onPressed: () {
            final id = 'var_${DateTime.now().millisecondsSinceEpoch}';
            final newVar = AppVariable(
              id: id,
              name: 'newVariable',
              type: 'String',
              defaultValue: 'Default',
              currentValue: 'Default',
              scope: VariableScope.app,
            );
            notifier.addVariable(newVar);
          },
        ),
      ],
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final v = list[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  v.name,
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                onPressed: () => notifier.deleteVariable(v.id),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  label: "Type",
                                  value: v.type,
                                  options: ['String', 'int', 'double', 'bool', 'List', 'Map'],
                                  onChanged: (val) {
                                    notifier.updateVariable(v.id, v.copyWith(type: val));
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildDropdown(
                                  label: "Scope",
                                  value: v.scope.toString().split('.').last,
                                  options: ['app', 'page', 'component', 'session'],
                                  onChanged: (val) {
                                    final sc = VariableScope.values.firstWhere((e) => e.toString().split('.').last == val);
                                    notifier.updateVariable(v.id, v.copyWith(scope: sc));
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => showGenerateSnippet(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              icon: const Icon(Icons.code_rounded, color: Colors.white),
              label: const Text("Generate Providers", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// 6. Action Flow sidebar panel listing node actions
class RevoActionFlowPanel extends ConsumerWidget {
  const RevoActionFlowPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builderState = ref.watch(visualBuilderProvider);
    final selectedNode = builderState.selectedNode;

    return RevoStudioPanelWrapper(
      title: "Action Flow Editor",
      subtitle: "Visual workflow actions for components",
      child: selectedNode == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "Select a component on the canvas to configure its actions flow.",
                  style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  "Event Triggers",
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // Triggers visual action editor on bottom sheet
                  },
                  icon: const Icon(Icons.alt_route_rounded, color: Colors.white),
                  label: const Text("Open Action Workflow Canvas", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
    );
  }
}

// 7. Assets list panel
class RevoAssetsPanel extends StatelessWidget {
  const RevoAssetsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final mockAssets = [
      {'name': 'app_logo.png', 'type': 'Image', 'size': '45 KB'},
      {'name': 'onboarding_hero.jpg', 'type': 'Image', 'size': '230 KB'},
      {'name': 'default_avatar.png', 'type': 'Image', 'size': '15 KB'},
      {'name': 'inter_font_regular.ttf', 'type': 'Font', 'size': '120 KB'},
    ];

    return RevoStudioPanelWrapper(
      title: "Assets Studio",
      subtitle: "Manage images, fonts, and assets",
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: mockAssets.length,
        itemBuilder: (context, index) {
          final asset = mockAssets[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Card(
              child: ListTile(
                leading: Icon(
                  asset['type'] == 'Image' ? Icons.image_outlined : Icons.font_download_outlined,
                  color: const Color(0xFF5B4FCF),
                ),
                title: Text(
                  asset['name']!,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${asset['type']} • ${asset['size']}",
                  style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                ),
                trailing: const Icon(Icons.more_vert_rounded, size: 18),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 8. Responsive configuration panel
class RevoResponsivePanel extends ConsumerWidget {
  const RevoResponsivePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builderState = ref.watch(visualBuilderProvider);
    final controller = ref.read(visualBuilderProvider.notifier);

    final devices = [
      {'name': 'Mobile (iPhone 14)', 'width': 390.0, 'height': 844.0, 'icon': Icons.phone_iphone_rounded},
      {'name': 'Tablet (iPad Pro 11)', 'width': 834.0, 'height': 1194.0, 'icon': Icons.tablet_mac_rounded},
      {'name': 'Desktop (MacBook Air)', 'width': 1280.0, 'height': 800.0, 'icon': Icons.laptop_chromebook_rounded},
    ];

    return RevoStudioPanelWrapper(
      title: "Responsive Canvas",
      subtitle: "Change canvas preview breakpoints",
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final dev = devices[index];
          final isSelected = builderState.canvasWidth == dev['width'];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Card(
              color: isSelected ? const Color(0x1F5B4FCF) : RevoTheme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.cardBorder,
                ),
              ),
              child: ListTile(
                onTap: () {
                  controller.setCanvasSize(dev['width'] as double, dev['height'] as double);
                },
                leading: Icon(
                  dev['icon'] as IconData,
                  color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.textSecondary,
                ),
                title: Text(
                  dev['name'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  "${dev['width']} x ${dev['height']} px",
                  style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 9. Project Settings panel
class RevoSettingsPanel extends StatelessWidget {
  const RevoSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return RevoStudioPanelWrapper(
      title: "Settings Studio",
      subtitle: "Visual builder settings and patterns",
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDropdown(
            label: "Export Code Pattern",
            value: "Clean Architecture",
            options: ["Clean Architecture", "MVC Pattern", "MVVM Pattern"],
            onChanged: (val) {},
          ),
          _buildDropdown(
            label: "State Management Pattern",
            value: "Riverpod v3",
            options: ["Riverpod v3", "GetX Controller", "BLoC Provider"],
            onChanged: (val) {},
          ),
          const SizedBox(height: 12),
          const Text(
            "Visual Guidelines",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text("Show Layout Outlines", style: TextStyle(fontSize: 12)),
            value: true,
            onChanged: (val) {},
          ),
          SwitchListTile(
            title: const Text("Snapping Grid Layout", style: TextStyle(fontSize: 12)),
            value: false,
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }
}

// --- Common UI helper widgets ---

Widget _buildTextField({
  required String label,
  required String value,
  required ValueChanged<String> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          style: GoogleFonts.inter(fontSize: 12),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDropdown({
  required String label,
  required String value,
  required List<String> options,
  required ValueChanged<String?> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: options.contains(value) ? value : options.first,
          onChanged: onChanged,
          isDense: true,
          style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          items: options
              .map((opt) => DropdownMenuItem(
                    value: opt,
                    child: Text(opt),
                  ))
              .toList(),
        ),
      ],
    ),
  );
}

class RevoGeneratedCodePanel extends ConsumerWidget {
  const RevoGeneratedCodePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builderState = ref.watch(visualBuilderProvider);
    final activeStepId = builderState.activeStepId;

    String generateUI() {
      if (activeStepId.isEmpty) return '// Select a screen step to generate code.';
      final buffer = StringBuffer();
      buffer.writeln("import 'package:flutter/material.dart';");
      buffer.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';\n");
      buffer.writeln("class ${activeStepId[0].toUpperCase()}${activeStepId.substring(1)}Screen extends ConsumerWidget {");
      buffer.writeln("  const ${activeStepId[0].toUpperCase()}${activeStepId.substring(1)}Screen({super.key});\n");
      buffer.writeln("  @override");
      buffer.writeln("  Widget build(BuildContext context, WidgetRef ref) {");
      buffer.writeln("    return Scaffold(");
      buffer.writeln("      appBar: AppBar(title: const Text('${activeStepId.toUpperCase()} SCREEN')),");
      buffer.writeln("      body: SingleChildScrollView(");
      buffer.writeln("        child: Padding(");
      buffer.writeln("          padding: const EdgeInsets.all(16.0),");
      buffer.writeln("          child: Column(");
      buffer.writeln("            children: [");
      _dumpNodeCode(builderState.rootNode, buffer, "              ");
      buffer.writeln("            ],");
      buffer.writeln("          ),");
      buffer.writeln("        ),");
      buffer.writeln("      ),");
      buffer.writeln("    );");
      buffer.writeln("  }");
      buffer.writeln("}");
      return buffer.toString();
    }

    return RevoStudioPanelWrapper(
      title: "Generated UI Code",
      subtitle: "Real-time Clean Architecture Flutter code",
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: SelectableText(
                  generateUI(),
                  style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.greenAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _dumpNodeCode(ComponentNode node, StringBuffer buffer, String indent) {
    buffer.writeln("$indent// Widget: ${node.type} (${node.id})");
    buffer.writeln("$indent${node.type}(");
    node.properties.forEach((key, val) {
      if (val != null && val is! List && val is! Map) {
        buffer.writeln("$indent  $key: ${val is String ? "'$val'" : val},");
      }
    });
    if (node.children.isNotEmpty) {
      buffer.writeln("$indent  children: [");
      for (final child in node.children) {
        _dumpNodeCode(child, buffer, "$indent    ");
      }
      buffer.writeln("$indent  ],");
    }
    buffer.writeln("$indent),");
  }
}
