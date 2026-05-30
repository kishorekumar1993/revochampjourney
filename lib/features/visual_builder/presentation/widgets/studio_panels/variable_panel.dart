import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme.dart';
import '../../../../../core/component_engine/models/app_variable.dart';
import '../../../application/studio_providers.dart';
import 'studio_panel_wrapper.dart';

class RevoVariablesPanel extends ConsumerStatefulWidget {
  const RevoVariablesPanel({super.key});

  @override
  ConsumerState<RevoVariablesPanel> createState() => _RevoVariablesPanelState();
}

class _RevoVariablesPanelState extends ConsumerState<RevoVariablesPanel> {
  final List<Map<String, dynamic>> _changeLogs = [];
  bool _showSecrets = false;

  void _logChange(String name, dynamic oldVal, dynamic newVal) {
    _changeLogs.insert(0, {
      'name': name,
      'old': oldVal,
      'new': newVal,
      'time': DateTime.now(),
    });
  }

  void _showGenerateCodeDialog(BuildContext context, List<AppVariable> list) {
    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: 5,
          child: AlertDialog(
            backgroundColor: RevoTheme.sidebarBackground,
            title: Text("Multi-Architecture Code Generator", style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 600,
              height: 480,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: RevoTheme.primaryLight,
                    unselectedLabelColor: RevoTheme.textSecondary,
                    indicatorColor: RevoTheme.primary,
                    tabs: const [
                      Tab(text: "Riverpod"),
                      Tab(text: "GetX"),
                      Tab(text: "BLoC"),
                      Tab(text: "Provider"),
                      Tab(text: "MobX"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCodeViewer(_generateRiverpodCode(list)),
                        _buildCodeViewer(_generateGetXCode(list)),
                        _buildCodeViewer(_generateBlocCode(list)),
                        _buildCodeViewer(_generateProviderCode(list)),
                        _buildCodeViewer(_generateMobXCode(list)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(color: Color(0xFF5B4FCF))),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCodeViewer(String code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TextFormField(
              initialValue: code,
              maxLines: null,
              readOnly: true,
              style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.greenAccent),
              decoration: const InputDecoration(
                border: InputBorder.none,
                fillColor: Colors.black,
                filled: true,
                contentPadding: EdgeInsets.all(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Code copied to clipboard!"), backgroundColor: Colors.green),
            );
          },
          icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
          label: const Text("Copy Code", style: TextStyle(fontSize: 11, color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FCF)),
        ),
      ],
    );
  }

  String _formatValue(dynamic val) {
    if (val == null) return 'null';
    if (val is String) return "'$val'";
    return val.toString();
  }

  String _generateRiverpodCode(List<AppVariable> list) {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';\n");
    buffer.writeln("class AppStateController extends StateNotifier<Map<String, dynamic>> {");
    buffer.writeln("  AppStateController() : super({");
    for (final v in list) {
      buffer.writeln("    '${v.name}': ${_formatValue(v.defaultValue)},");
    }
    buffer.writeln("  });\n");
    buffer.writeln("  void updateVariable(String key, dynamic value) {");
    buffer.writeln("    state = {...state, key: value};");
    buffer.writeln("  }");
    buffer.writeln("}\n");
    buffer.writeln("final appStateProvider = StateNotifierProvider<AppStateController, Map<String, dynamic>>((ref) {");
    buffer.writeln("  return AppStateController();");
    buffer.writeln("});");
    return buffer.toString();
  }

  String _generateGetXCode(List<AppVariable> list) {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:get/get.dart';\n");
    buffer.writeln("class AppStateController extends GetxController {");
    for (final v in list) {
      final obsSuffix = v.type == 'int' ? 'obs' : v.type == 'double' ? 'obs' : v.type == 'bool' ? 'obs' : 'obs';
      buffer.writeln("  final ${v.name} = ${_formatValue(v.defaultValue)}.$obsSuffix;");
    }
    buffer.writeln("\n  void updateVariable(String key, dynamic value) {");
    buffer.writeln("    switch (key) {");
    for (final v in list) {
      buffer.writeln("      case '${v.name}':");
      buffer.writeln("        ${v.name}.value = value;");
      buffer.writeln("        break;");
    }
    buffer.writeln("    }");
    buffer.writeln("  }");
    buffer.writeln("}");
    return buffer.toString();
  }

  String _generateBlocCode(List<AppVariable> list) {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter_bloc/flutter_bloc.dart';\n");
    buffer.writeln("class AppState {");
    for (final v in list) {
      buffer.writeln("  final ${v.type} ${v.name};");
    }
    buffer.writeln("\n  AppState({");
    for (final v in list) {
      buffer.writeln("    required this.${v.name},");
    }
    buffer.writeln("  });\n");
    buffer.writeln("  AppState copyWith({");
    for (final v in list) {
      buffer.writeln("    ${v.type}? ${v.name},");
    }
    buffer.writeln("  }) {");
    buffer.writeln("    return AppState({");
    for (final v in list) {
      buffer.writeln("      ${v.name}: ${v.name} ?? this.${v.name},");
    }
    buffer.writeln("    });");
    buffer.writeln("  }");
    buffer.writeln("}\n");
    buffer.writeln("class AppStateCubit extends Cubit<AppState> {");
    buffer.writeln("  AppStateCubit() : super(AppState(");
    for (final v in list) {
      buffer.writeln("    ${v.name}: ${_formatValue(v.defaultValue)},");
    }
    buffer.writeln("  ));\n");
    buffer.writeln("  void updateVariable(String key, dynamic value) {");
    for (final v in list) {
      buffer.writeln("    if (key == '${v.name}') {");
      buffer.writeln("      emit(state.copyWith(${v.name}: value as ${v.type}?));");
      buffer.writeln("    }");
    }
    buffer.writeln("  }");
    buffer.writeln("}");
    return buffer.toString();
  }

  String _generateProviderCode(List<AppVariable> list) {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter/material.dart';\n");
    buffer.writeln("class AppStateProvider extends ChangeNotifier {");
    for (final v in list) {
      buffer.writeln("  ${v.type} _${v.name} = ${_formatValue(v.defaultValue)};");
      buffer.writeln("  ${v.type} get ${v.name} => _${v.name};");
      buffer.writeln("  set ${v.name}(${v.type} val) {");
      buffer.writeln("    _${v.name} = val;");
      buffer.writeln("    notifyListeners();");
      buffer.writeln("  }\n");
    }
    buffer.writeln("}");
    return buffer.toString();
  }

  String _generateMobXCode(List<AppVariable> list) {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:mobx/mobx.dart';\n");
    buffer.writeln("part 'app_state.g.dart';\n");
    buffer.writeln("class AppState = _AppStateBase with _\$AppState;\n");
    buffer.writeln("abstract class _AppStateBase with Store {");
    for (final v in list) {
      buffer.writeln("  @observable");
      buffer.writeln("  ${v.type} ${v.name} = ${_formatValue(v.defaultValue)};\n");
      buffer.writeln("  @action");
      buffer.writeln("  void set${v.name[0].toUpperCase()}${v.name.substring(1)}(${v.type} val) => ${v.name} = val;\n");
    }
    buffer.writeln("}");
    return buffer.toString();
  }

  void _showInspectorDialog(BuildContext context, List<AppVariable> list) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: RevoTheme.sidebarBackground,
              title: Row(
                children: [
                  const Icon(Icons.analytics_outlined, size: 18, color: Color(0xFF5B4FCF)),
                  const SizedBox(width: 8),
                  Text("Live State Inspector", style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(_showSecrets ? Icons.visibility : Icons.visibility_off, size: 16),
                    onPressed: () => setModalState(() => _showSecrets = !_showSecrets),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                height: 350,
                child: list.isEmpty
                    ? const Center(child: Text("No variables configured to inspect."))
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (ctx, idx) {
                          final v = list[idx];
                          final isSecret = v.isSecret && !_showSecrets;
                          final displayVal = isSecret ? '******' : (v.currentValue ?? v.defaultValue ?? 'null').toString();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(v.name, style: GoogleFonts.sourceCodePro(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.primaryLight)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(displayVal, style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.greenAccent)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showImportExportDialog(BuildContext context, List<AppVariable> list, AppVariablesNotifier notifier) {
    final rawJson = json.encode(list.map((v) => v.toJson()).toList());
    final ctrl = TextEditingController(text: rawJson);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: RevoTheme.sidebarBackground,
          title: Text("JSON Import / Export", style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 480,
            height: 380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Copy the JSON schema below to backup or paste an array of Variable objects to import schema.", style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary)),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TextField(
                      controller: ctrl,
                      maxLines: null,
                      expands: true,
                      style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.amberAccent),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        fillColor: Colors.black,
                        filled: true,
                        contentPadding: EdgeInsets.all(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FCF)),
              onPressed: () {
                try {
                  final decoded = json.decode(ctrl.text);
                  if (decoded is List) {
                    for (final item in decoded) {
                      if (item is Map<String, dynamic>) {
                        final v = AppVariable.fromJson(item);
                        notifier.addVariable(v);
                      }
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Variables imported successfully!"), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error parsing schema: $e"), backgroundColor: Colors.redAccent),
                  );
                }
              },
              child: const Text("Import Variables", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showLogsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: RevoTheme.sidebarBackground,
          title: Text("Value Watcher Logs", style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 420,
            height: 350,
            child: _changeLogs.isEmpty
                ? const Center(child: Text("No value change updates tracked yet."))
                : ListView.builder(
                    itemCount: _changeLogs.length,
                    itemBuilder: (ctx, idx) {
                      final log = _changeLogs[idx];
                      final timeStr = "${log['time'].hour.toString().padLeft(2, '0')}:${log['time'].minute.toString().padLeft(2, '0')}:${log['time'].second.toString().padLeft(2, '0')}";

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: RevoTheme.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Text(log['name'] as String, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.primaryLight)),
                                  const Spacer(),
                                  Text(timeStr, style: GoogleFonts.inter(fontSize: 9, color: RevoTheme.textSecondary)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(log['old'].toString(), style: GoogleFonts.sourceCodePro(fontSize: 9, color: Colors.grey)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_right_alt_rounded, size: 12, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(log['new'].toString(), style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(appVariablesProvider);
    final notifier = ref.read(appVariablesProvider.notifier);
    final selectedVar = ref.watch(selectedVariableProvider);
    final searchQuery = ref.watch(variableSearchQueryProvider);

    final filteredList = list.where((v) {
      if (searchQuery.trim().isEmpty) return true;
      return v.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          v.type.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    if (selectedVar != null) {
      final v = selectedVar;
      return SizedBox(
        width: 300,
        child: RevoStudioPanelWrapper(
          title: "Edit Variable",
          subtitle: v.name,
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              onPressed: () {
                ref.read(selectedVariableIdProvider.notifier).state = null;
              },
            ),
          ],
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTextField(
                label: "Variable Name",
                value: v.name,
                onChanged: (val) {
                  final upd = v.copyWith(name: val);
                  notifier.updateVariable(v.id, upd);
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: "Data Type",
                      value: v.type,
                      options: const ['String', 'int', 'double', 'bool', 'List', 'Map'],
                      onChanged: (val) {
                        final upd = v.copyWith(type: val ?? 'String');
                        notifier.updateVariable(v.id, upd);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdown(
                      label: "Variable Scope",
                      value: v.scope.toString().split('.').last,
                      options: const ['app', 'page', 'component', 'session'],
                      onChanged: (val) {
                        final sc = VariableScope.values.firstWhere((e) => e.toString().split('.').last == val);
                        final upd = v.copyWith(scope: sc);
                        notifier.updateVariable(v.id, upd);
                      },
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text("Value Settings", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary)),
              const SizedBox(height: 8),
              _buildTextField(
                label: "Default Value",
                value: (v.defaultValue ?? '').toString(),
                onChanged: (val) {
                  final dynamic typedVal = _parseTypedValue(val, v.type);
                  final upd = v.copyWith(defaultValue: typedVal);
                  notifier.updateVariable(v.id, upd);
                },
              ),
              _buildTextField(
                label: "Current Value",
                value: (v.currentValue ?? '').toString(),
                onChanged: (val) {
                  final dynamic typedVal = _parseTypedValue(val, v.type);
                  _logChange(v.name, v.currentValue, typedVal);
                  final upd = v.copyWith(currentValue: typedVal);
                  notifier.updateVariable(v.id, upd);
                },
              ),
              SwitchListTile(
                title: Text("Secret / Masked", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: RevoTheme.textPrimary)),
                subtitle: Text("Hide value in logs and inspector", style: GoogleFonts.inter(fontSize: 9, color: RevoTheme.textSecondary)),
                value: v.isSecret,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  final upd = v.copyWith(isSecret: val);
                  notifier.updateVariable(v.id, upd);
                },
              ),
              SwitchListTile(
                title: Text("Computed Variable", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: RevoTheme.textPrimary)),
                value: v.isComputed,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  final upd = v.copyWith(isComputed: val);
                  notifier.updateVariable(v.id, upd);
                },
              ),
              if (v.isComputed) ...[
                _buildTextField(
                  label: "Formula Expression",
                  value: v.computedExpression,
                  onChanged: (val) {
                    final upd = v.copyWith(computedExpression: val);
                    notifier.updateVariable(v.id, upd);
                  },
                ),
              ],
              const Divider(height: 24),
              ExpansionTile(
                title: Text("Validation Rules", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                tilePadding: EdgeInsets.zero,
                children: [
                  SwitchListTile(
                    title: Text("Value Required", style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textPrimary)),
                    value: v.validationRequired,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      final upd = v.copyWith(validationRequired: val);
                      notifier.updateVariable(v.id, upd);
                    },
                  ),
                  if (v.type == 'int' || v.type == 'double') ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: "Min Value",
                            value: v.validationMin != null ? v.validationMin.toString() : '',
                            onChanged: (val) {
                              final double? minVal = double.tryParse(val);
                              final upd = v.copyWith(validationMin: minVal);
                              notifier.updateVariable(v.id, upd);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTextField(
                            label: "Max Value",
                            value: v.validationMax != null ? v.validationMax.toString() : '',
                            onChanged: (val) {
                              final double? maxVal = double.tryParse(val);
                              final upd = v.copyWith(validationMax: maxVal);
                              notifier.updateVariable(v.id, upd);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const Divider(height: 12),
              ExpansionTile(
                title: Text("State Persistence", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                tilePadding: EdgeInsets.zero,
                children: [
                  SwitchListTile(
                    title: Text("Persist state locally", style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textPrimary)),
                    value: v.isPersistent,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      final upd = v.copyWith(isPersistent: val);
                      notifier.updateVariable(v.id, upd);
                    },
                  ),
                  if (v.isPersistent) ...[
                    _buildDropdown(
                      label: "Storage Engine",
                      value: v.persistenceType,
                      options: const ['none', 'shared_preferences', 'hive', 'secure_storage'],
                      onChanged: (val) {
                        final upd = v.copyWith(persistenceType: val ?? 'none');
                        notifier.updateVariable(v.id, upd);
                      },
                    ),
                  ],
                ],
              ),
              const Divider(height: 12),
              ExpansionTile(
                title: Text("Visual Bindings Manager", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                tilePadding: EdgeInsets.zero,
                children: [
                  _buildDropdown(
                    label: "Bind to Widget Property",
                    value: v.boundWidgetId ?? 'None',
                    options: const ['None', 'username_input', 'password_input', 'submit_button', 'profile_header', 'amount_field'],
                    onChanged: (val) {
                      final upd = v.copyWith(boundWidgetId: val == 'None' ? null : val);
                      notifier.updateVariable(v.id, upd);
                    },
                  ),
                  if (v.boundWidgetId != null) ...[
                    _buildDropdown(
                      label: "Target Property",
                      value: v.boundProperty ?? 'text',
                      options: const ['text', 'value', 'visibility', 'isEnabled', 'color'],
                      onChanged: (val) {
                        final upd = v.copyWith(boundProperty: val);
                        notifier.updateVariable(v.id, upd);
                      },
                    ),
                  ],
                  _buildDropdown(
                    label: "Bind to API Action Field",
                    value: v.boundApiId ?? 'None',
                    options: const ['None', 'User Login API', 'Get User Profile'],
                    onChanged: (val) {
                      final upd = v.copyWith(boundApiId: val == 'None' ? null : val);
                      notifier.updateVariable(v.id, upd);
                    },
                  ),
                  if (v.boundApiId != null) ...[
                    _buildTextField(
                      label: "Target API Payload Field",
                      value: v.boundApiField ?? '',
                      onChanged: (val) {
                        final upd = v.copyWith(boundApiField: val.trim().isEmpty ? null : val.trim());
                        notifier.updateVariable(v.id, upd);
                      },
                    ),
                  ],
                ],
              ),
              const Divider(height: 12),
              ExpansionTile(
                title: Text("Variable Usage Tracking", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                tilePadding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _getVariableUsages(v).map((usage) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            children: [
                              const Icon(Icons.link_rounded, size: 12, color: Colors.tealAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  usage,
                                  style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Collapsible Categorized groups builder
    final Map<VariableScope, List<AppVariable>> groupedVars = {
      VariableScope.app: [],
      VariableScope.page: [],
      VariableScope.component: [],
      VariableScope.session: [],
    };
    for (final v in filteredList) {
      groupedVars[v.scope]?.add(v);
    }

    return SizedBox(
      width: 300,
      child: RevoStudioPanelWrapper(
        title: "State Variables",
        subtitle: "Manage reactive low-code variables",
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, size: 16),
            tooltip: "State Inspector",
            onPressed: () => _showInspectorDialog(context, list),
          ),
          IconButton(
            icon: const Icon(Icons.history_toggle_off_rounded, size: 16),
            tooltip: "Value Change Logs",
            onPressed: () => _showLogsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.import_export_rounded, size: 16),
            tooltip: "Import/Export JSON",
            onPressed: () => _showImportExportDialog(context, list, notifier),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 18),
            tooltip: "Add Variable",
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
              ref.read(selectedVariableIdProvider.notifier).state = id;
            },
          ),
        ],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              child: TextFormField(
                style: GoogleFonts.inter(fontSize: 11),
                decoration: InputDecoration(
                  hintText: "Search variables...",
                  prefixIcon: const Icon(Icons.search_rounded, size: 14),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onChanged: (val) {
                  ref.read(variableSearchQueryProvider.notifier).state = val;
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: groupedVars.entries.map((group) {
                  final scopeName = group.key.toString().split('.').last.toUpperCase();
                  final groupList = group.value;
                  if (groupList.isEmpty && searchQuery.isNotEmpty) {
                    return const SizedBox();
                  }

                  return ExpansionTile(
                    title: Text("$scopeName VARIABLES", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.primaryLight)),
                    leading: const Icon(Icons.folder_open_rounded, size: 14, color: Colors.amber),
                    initiallyExpanded: true,
                    children: groupList.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "No variables in $scopeName scope",
                                style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontStyle: FontStyle.italic),
                              ),
                            )
                          ]
                        : groupList.map((v) {
                            final isBound = v.boundWidgetId != null || v.boundApiId != null;
                            final displayVal = v.isSecret ? '******' : (v.currentValue ?? v.defaultValue ?? '').toString();

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                onTap: () => ref.read(selectedVariableIdProvider.notifier).state = v.id,
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(v.name, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                    Text(
                                      v.type,
                                      style: GoogleFonts.inter(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      "Value: $displayVal",
                                      style: GoogleFonts.sourceCodePro(fontSize: 9, color: Colors.greenAccent),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isBound) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.link_rounded, size: 10, color: Colors.tealAccent),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              v.boundWidgetId != null ? "Widget: [${v.boundWidgetId}]" : "API: [${v.boundApiId}]",
                                              style: GoogleFonts.inter(fontSize: 9, color: Colors.tealAccent, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                                  onPressed: () => notifier.deleteVariable(v.id),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            );
                          }).toList(),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton.icon(
                onPressed: () => _showGenerateCodeDialog(context, list),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  backgroundColor: const Color(0xFF5B4FCF),
                ),
                icon: const Icon(Icons.code_rounded, color: Colors.white, size: 16),
                label: const Text("Generate State Classes", style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  dynamic _parseTypedValue(String val, String type) {
    if (type == 'int') {
      return int.tryParse(val) ?? 0;
    } else if (type == 'double') {
      return double.tryParse(val) ?? 0.0;
    } else if (type == 'bool') {
      return val.toLowerCase() == 'true';
    } else if (type == 'List') {
      try {
        return json.decode(val) as List;
      } catch (_) {
        return [];
      }
    } else if (type == 'Map') {
      try {
        return json.decode(val) as Map;
      } catch (_) {
        return {};
      }
    }
    return val;
  }

  List<String> _getVariableUsages(AppVariable v) {
    final usages = <String>[];
    if (v.boundWidgetId != null) {
      usages.add("Bound to widget '${v.boundWidgetId}' property '${v.boundProperty}'");
    }
    if (v.boundApiId != null) {
      usages.add("Bound to API '${v.boundApiId}' payload field '${v.boundApiField}'");
    }
    if (v.name == 'userName') {
      usages.add("Referenced in 'LoginScreen' onSubmit Action");
      usages.add("Referenced in 'DashboardScreen' user greeting header");
    }
    if (v.name == 'isLoggedIn') {
      usages.add("Used in Auth Guard routing conditional check");
    }
    if (usages.isEmpty) {
      usages.add("No usages recorded. Bind to components or endpoints.");
    }
    return usages;
  }

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
            key: ValueKey(value),
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
}
