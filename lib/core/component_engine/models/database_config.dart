// ignore_for_file: constant_identifier_names

enum DatabaseType { Firebase, Supabase, RestBackend }

class DatabaseConfig {
  final DatabaseType type;
  final String url;
  final String apiKey;
  final List<TableConfig> tables;

  DatabaseConfig({
    required this.type,
    this.url = '',
    this.apiKey = '',
    this.tables = const [],
  });

  factory DatabaseConfig.fromJson(Map<String, dynamic> json) {
    var tablesList = json['tables'] as List? ?? [];
    return DatabaseConfig(
      type: DatabaseType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => DatabaseType.Firebase,
      ),
      url: json['url'] ?? '',
      apiKey: json['apiKey'] ?? '',
      tables: tablesList.map((t) => TableConfig.fromJson(Map<String, dynamic>.from(t))).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'url': url,
      'apiKey': apiKey,
      'tables': tables.map((t) => t.toJson()).toList(),
    };
  }

  DatabaseConfig copyWith({
    DatabaseType? type,
    String? url,
    String? apiKey,
    List<TableConfig>? tables,
  }) {
    return DatabaseConfig(
      type: type ?? this.type,
      url: url ?? this.url,
      apiKey: apiKey ?? this.apiKey,
      tables: tables ?? this.tables.map((t) => t.copyWith()).toList(),
    );
  }
}

class TableConfig {
  final String name;
  final List<FieldConfig> fields;

  TableConfig({
    required this.name,
    required this.fields,
  });

  factory TableConfig.fromJson(Map<String, dynamic> json) {
    var fieldsList = json['fields'] as List? ?? [];
    return TableConfig(
      name: json['name'] ?? '',
      fields: fieldsList.map((f) => FieldConfig.fromJson(Map<String, dynamic>.from(f))).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'fields': fields.map((f) => f.toJson()).toList(),
    };
  }

  TableConfig copyWith({
    String? name,
    List<FieldConfig>? fields,
  }) {
    return TableConfig(
      name: name ?? this.name,
      fields: fields ?? this.fields.map((f) => f.copyWith()).toList(),
    );
  }
}

class FieldConfig {
  final String name;
  final String type; // int, double, String, bool, DateTime, Relation
  final bool isPrimaryKey;
  final bool isNullable;
  final String? relationTable;

  FieldConfig({
    required this.name,
    required this.type,
    this.isPrimaryKey = false,
    this.isNullable = true,
    this.relationTable,
  });

  factory FieldConfig.fromJson(Map<String, dynamic> json) {
    return FieldConfig(
      name: json['name'] ?? '',
      type: json['type'] ?? 'String',
      isPrimaryKey: json['isPrimaryKey'] ?? false,
      isNullable: json['isNullable'] ?? true,
      relationTable: json['relationTable'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'isPrimaryKey': isPrimaryKey,
      'isNullable': isNullable,
      if (relationTable != null) 'relationTable': relationTable,
    };
  }

  FieldConfig copyWith({
    String? name,
    String? type,
    bool? isPrimaryKey,
    bool? isNullable,
    String? relationTable,
  }) {
    return FieldConfig(
      name: name ?? this.name,
      type: type ?? this.type,
      isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
      isNullable: isNullable ?? this.isNullable,
      relationTable: relationTable ?? this.relationTable,
    );
  }
}
