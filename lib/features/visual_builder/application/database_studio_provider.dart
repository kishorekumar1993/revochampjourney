// lib/features/visual_builder/application/database_studio_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/component_engine/models/database_config.dart';

// Database Config notifier
class DatabaseConfigNotifier extends StateNotifier<DatabaseConfig> {
  DatabaseConfigNotifier() : super(DatabaseConfig(
    type: DatabaseType.Firebase,
    url: 'https://revochamp-db.firebaseio.com',
    apiKey: 'AIzaSyA123-revochamp-key',
    tables: [
      TableConfig(
        name: 'users',
        fields: [
          FieldConfig(name: 'uid', type: 'String', isPrimaryKey: true, isNullable: false),
          FieldConfig(name: 'email', type: 'String', isPrimaryKey: false, isNullable: false),
          FieldConfig(name: 'displayName', type: 'String', isPrimaryKey: false, isNullable: true),
        ],
      ),
      TableConfig(
        name: 'transactions',
        fields: [
          FieldConfig(name: 'id', type: 'String', isPrimaryKey: true, isNullable: false),
          FieldConfig(name: 'userId', type: 'Relation', isPrimaryKey: false, isNullable: false, relationTable: 'users'),
          FieldConfig(name: 'amount', type: 'double', isPrimaryKey: false, isNullable: false),
          FieldConfig(name: 'timestamp', type: 'DateTime', isPrimaryKey: false, isNullable: false),
        ],
      ),
    ],
  ));

  void updateConfig(DatabaseConfig config) {
    state = config;
  }

  void addTable(TableConfig table) {
    state = state.copyWith(tables: [...state.tables, table]);
  }

  void updateTable(String oldName, TableConfig table) {
    state = state.copyWith(
      tables: state.tables.map((t) => t.name == oldName ? table : t).toList(),
    );
  }

  void deleteTable(String name) {
    state = state.copyWith(
      tables: state.tables.where((t) => t.name != name).toList(),
    );
  }
}

final databaseConfigProvider = StateNotifierProvider<DatabaseConfigNotifier, DatabaseConfig>((ref) {
  return DatabaseConfigNotifier();
});

final selectedTableNameProvider = StateProvider<String?>((ref) => null);
