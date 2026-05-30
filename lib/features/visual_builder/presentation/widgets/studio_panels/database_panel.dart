import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme.dart';
import '../../../../../../core/component_engine/models/database_config.dart';

import '../../../application/studio_providers.dart';
import 'studio_panel_wrapper.dart';

// 4. Database builder studio panel
class RevoDatabaseStudioPanel extends ConsumerStatefulWidget {
  const RevoDatabaseStudioPanel({super.key});

  @override
  ConsumerState<RevoDatabaseStudioPanel> createState() => _RevoDatabaseStudioPanelState();
}

class _RevoDatabaseStudioPanelState extends ConsumerState<RevoDatabaseStudioPanel> {
  TableConfig? _selectedTable;

  void _showGeneratedCodeDialog(BuildContext context, TableConfig table) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: RevoTheme.sidebarBackground,
          title: Text("Generated Code for '${table.name}'", style: GoogleFonts.outfit(color: RevoTheme.textPrimary)),
          content: SizedBox(
            width: 600,
            height: 500,
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: const [
                      Tab(text: "Entity"),
                      Tab(text: "Model"),
                      Tab(text: "Repository"),
                      Tab(text: "SQL (DDL)"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCodeViewer(_generateEntity(table)),
                        _buildCodeViewer(_generateModel(table)),
                        _buildCodeViewer(_generateRepository(table)),
                        _buildCodeViewer(_generateSql(table, 'PostgreSQL')),
                      ],
                    ),
                  ),
                ],
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

  Widget _buildCodeViewer(String code) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: TextField(
        controller: TextEditingController(text: code),
        maxLines: null,
        readOnly: true,
        expands: true,
        style: GoogleFonts.sourceCodePro(fontSize: 11, color: Colors.greenAccent),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          fillColor: Colors.black,
          filled: true,
        ),
      ),
    );
  }

  String _mapDartType(String dbType) {
    switch (dbType.toLowerCase()) {
      case 'string':
      case 'text':
      case 'varchar':
      case 'uuid':
        return 'String';
      case 'int':
      case 'integer':
        return 'int';
      case 'double':
      case 'float':
      case 'numeric':
        return 'double';
      case 'bool':
      case 'boolean':
        return 'bool';
      case 'datetime':
      case 'timestamp':
        return 'DateTime';
      case 'json':
      case 'jsonb':
        return 'Map<String, dynamic>';
      default:
        return 'dynamic';
    }
  }

  String _generateEntity(TableConfig tc) {
    final className = '${tc.name[0].toUpperCase()}${tc.name.substring(1)}Entity';
    final buffer = StringBuffer();
    buffer.writeln("import 'package:equatable/equatable.dart';\n");
    buffer.writeln('class $className extends Equatable {');

    for (final field in tc.fields) {
      buffer.writeln('  final ${_mapDartType(field.type)}? ${field.name};');
    }
    buffer.writeln('');

    buffer.writeln('  const $className({');
    for (final field in tc.fields) {
      buffer.writeln('    this.${field.name},');
    }
    buffer.writeln('  });\n');

    buffer.writeln('  @override');
    buffer.writeln('  List<Object?> get props => [${tc.fields.map((f) => f.name).join(', ')}];');

    buffer.writeln('}');
    return buffer.toString();
  }

  String _generateModel(TableConfig tc) {
    final modelName = '${tc.name[0].toUpperCase()}${tc.name.substring(1)}Model';
    final entityName = '${tc.name[0].toUpperCase()}${tc.name.substring(1)}Entity';
    final buffer = StringBuffer();

    buffer.writeln('// TODO: Import entity file');
    buffer.writeln('// import \'./${tc.name}_entity.dart\';\n');

    buffer.writeln('class $modelName extends $entityName {');

    buffer.writeln('  const $modelName({');
    for (final field in tc.fields) {
      final type = _mapDartType(field.type);
      buffer.writeln('    ${field.isNullable ? '' : 'required'} $type? ${field.name},');
    }
    buffer.writeln('  }) : super(');
    for (final field in tc.fields) {
      buffer.writeln('    ${field.name}: ${field.name},');
    }
    buffer.writeln('  );\n');

    buffer.writeln('  factory $modelName.fromJson(Map<String, dynamic> json) {');
    buffer.writeln('    return $modelName(');
    for (final field in tc.fields) {
      buffer.writeln("      ${field.name}: json['${field.name}'], // TODO: Add proper type casting/parsing");
    }
    buffer.writeln('    );');
    buffer.writeln('  }\n');

    buffer.writeln('  Map<String, dynamic> toJson() {');
    buffer.writeln('    return {');
    for (final field in tc.fields) {
      buffer.writeln("      '${field.name}': ${field.name},");
    }
    buffer.writeln('    };');
    buffer.writeln('  }\n');

    buffer.writeln('  $modelName copyWith({');
    for (final field in tc.fields) {
      buffer.writeln('    ${_mapDartType(field.type)}? ${field.name},');
    }
    buffer.writeln('  }) {');
    buffer.writeln('    return $modelName(');
    for (final field in tc.fields) {
      buffer.writeln('      ${field.name}: ${field.name} ?? this.${field.name},');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');

    buffer.writeln('}');
    return buffer.toString();
  }

  String _generateRepository(TableConfig tc) {
    final capitalized = '${tc.name[0].toUpperCase()}${tc.name.substring(1)}';
    final modelName = '${capitalized}Model';
    final entityName = '${capitalized}Entity';
    final repoName = '${capitalized}Repository';
    final tableName = tc.name;
    final primaryKeyField = tc.fields.firstWhere((f) => f.isPrimaryKey, orElse: () => tc.fields.first);
    final primaryKeyType = _mapDartType(primaryKeyField.type);

    return '''
import 'package:supabase_flutter/supabase_flutter.dart';
// TODO: Import your generated model and entity files
// import '.../${tc.name}_model.dart';
// import '.../${tc.name}_entity.dart';

abstract class I$repoName {
  Future<List<$entityName>> getAll();
  Future<$entityName?> getById($primaryKeyType id);
  Future<$entityName> insert($modelName data);
  Future<$entityName> update($primaryKeyType id, $modelName data);
  Future<void> delete($primaryKeyType id);
}

class $repoName implements I$repoName {
  final _supabase = Supabase.instance.client;
  final _tableName = '$tableName';

  @override
  Future<List<$entityName>> getAll() async {
    final response = await _supabase.from(_tableName).select();
    return response.map((item) => $modelName.fromJson(item)).toList();
  }

  @override
  Future<$entityName?> getById($primaryKeyType id) async {
    final response = await _supabase.from(_tableName).select().eq('${primaryKeyField.name}', id).maybeSingle();
    return response == null ? null : $modelName.fromJson(response);
  }

  @override
  Future<$entityName> insert($modelName data) async {
    final response = await _supabase.from(_tableName).insert(data.toJson()).select().single();
    return $modelName.fromJson(response);
  }

  @override
  Future<$entityName> update($primaryKeyType id, $modelName data) async {
    final response = await _supabase.from(_tableName).update(data.toJson()).eq('${primaryKeyField.name}', id).select().single();
    return $modelName.fromJson(response);
  }

  @override
  Future<void> delete($primaryKeyType id) async {
    await _supabase.from(_tableName).delete().eq('${primaryKeyField.name}', id);
  }
}
''';
  }

  String _generateSql(TableConfig tc, String dialect) {
    final buffer = StringBuffer();
    buffer.writeln('CREATE TABLE "${tc.name}" (');

    final lines = <String>[];
    for (final field in tc.fields) {
      final line = StringBuffer();
      line.write('  "${field.name}" ${_mapSqlType(field.type, dialect)}');
      if (field.isPrimaryKey) {
        line.write(' PRIMARY KEY');
      }
      if (!field.isNullable) {
        line.write(' NOT NULL');
      }
    
      lines.add(line.toString());
    }
    buffer.write(lines.join(',\n'));
    buffer.writeln('\n);');

    return buffer.toString();
  }

  String _mapSqlType(String dartType, String dialect) {
    switch (dartType.toLowerCase()) {
      case 'string':
        return 'VARCHAR(255)';
      case 'text':
        return 'TEXT';
      case 'int':
        return 'INTEGER';
      case 'double':
        return 'DOUBLE PRECISION';
      case 'bool':
        return 'BOOLEAN';
      case 'datetime':
        return 'TIMESTAMP WITH TIME ZONE';
      case 'uuid':
        return 'UUID';
      case 'json':
        return 'JSONB';
      default:
        return 'TEXT';
    }
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
                  ...table.fields.asMap().entries.map((entry) {
                    return _buildFieldEditor(table, entry.value, entry.key);
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  _showGeneratedCodeDialog(context, table);
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.code_rounded, color: Colors.white),
                label: const Text("Generate Code", style: TextStyle(color: Colors.white)),
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

  Widget _buildFieldEditor(TableConfig table, FieldConfig field, int index) {
    final notifier = ref.read(databaseConfigProvider.notifier);

    void onUpdate(FieldConfig updatedField) {
      final updatedFields = List<FieldConfig>.from(table.fields);
      updatedFields[index] = updatedField;
      final originalTableName = table.name;
      final updatedTable = table.copyWith(fields: updatedFields);
      setState(() => _selectedTable = updatedTable);
      notifier.updateTable(originalTableName, updatedTable);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ExpansionTile(
        key: ValueKey(field.name),
        title: Text(field.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
        subtitle: Text(field.type, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5B4FCF))),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
          onPressed: () {
            final upd = table.copyWith(
              fields: table.fields.where((f) => f.name != field.name).toList(),
            );
            setState(() => _selectedTable = upd);
            notifier.updateTable(table.name, upd);
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _buildTextField(
                  label: "Field Name",
                  value: field.name,
                  onChanged: (val) => onUpdate(field.copyWith(name: val)),
                ),
                _buildDropdown(
                  label: "Data Type",
                  value: field.type,
                  options: const ['String', 'int', 'double', 'bool', 'DateTime', 'UUID', 'JSON', 'text'],
                  onChanged: (val) => onUpdate(field.copyWith(type: val)),
                ),
                // FIXME: Add `defaultValue` to FieldConfig model to enable this.
                // _buildTextField(
                //   label: "Default Value",
                //   value: field.defaultValue?.toString() ?? '',
                //   onChanged: (val) => onUpdate(field.copyWith(defaultValue: val)),
                // ),
                const Divider(height: 24),
                _buildSwitch(
                  label: "Primary Key",
                  value: field.isPrimaryKey,
                  onChanged: (val) => onUpdate(field.copyWith(isPrimaryKey: val)),
                ),
                _buildSwitch(
                  label: "Nullable",
                  value: field.isNullable,
                  onChanged: (val) => onUpdate(field.copyWith(isNullable: val)),
                ),
                
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary)),
          Switch(
            value: value,
            onChanged: onChanged,
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
          initialValue: options.contains(value) ? value : options.first,
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
