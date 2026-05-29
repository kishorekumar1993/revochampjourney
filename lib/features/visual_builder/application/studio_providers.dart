import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/component_engine/models/app_variable.dart';
import '../../../core/component_engine/models/api_config.dart';
import '../../../core/component_engine/models/database_config.dart';

// App Variables notifier
class AppVariablesNotifier extends StateNotifier<List<AppVariable>> {
  AppVariablesNotifier() : super([
    AppVariable(
      id: 'var_user_name',
      name: 'userName',
      type: 'String',
      defaultValue: 'Guest',
      currentValue: 'Guest',
      scope: VariableScope.app,
    ),
    AppVariable(
      id: 'var_is_logged_in',
      name: 'isLoggedIn',
      type: 'bool',
      defaultValue: false,
      currentValue: false,
      scope: VariableScope.session,
    ),
  ]);

  void addVariable(AppVariable variable) {
    state = [...state, variable];
  }

  void updateVariable(String id, AppVariable updated) {
    state = state.map((v) => v.id == id ? updated : v).toList();
  }

  void deleteVariable(String id) {
    state = state.where((v) => v.id != id).toList();
  }
}

final appVariablesProvider = StateNotifierProvider<AppVariablesNotifier, List<AppVariable>>((ref) {
  return AppVariablesNotifier();
});

// API Config notifier
class ApiConfigsNotifier extends StateNotifier<List<ApiConfig>> {
  ApiConfigsNotifier() : super([
    ApiConfig(
      id: 'api_login',
      name: 'User Login API',
      baseUrl: 'https://api.revochamp.com',
      endpoint: '/v1/auth/login',
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      queryParams: {},
      requestBody: '{"email": "", "password": ""}',
      authentication: 'None',
      responseMapping: {'token': 'sessionToken'},
    ),
    ApiConfig(
      id: 'api_get_profile',
      name: 'Get User Profile',
      baseUrl: 'https://api.revochamp.com',
      endpoint: '/v1/users/profile',
      method: 'GET',
      headers: {'Authorization': 'Bearer {token}'},
      queryParams: {},
      requestBody: '',
      authentication: 'Bearer Token',
      responseMapping: {'name': 'userName'},
    ),
  ]);

  void addConfig(ApiConfig config) {
    state = [...state, config];
  }

  void updateConfig(String id, ApiConfig updated) {
    state = state.map((c) => c.id == id ? updated : c).toList();
  }

  void deleteConfig(String id) {
    state = state.where((c) => c.id != id).toList();
  }
}

final apiConfigsProvider = StateNotifierProvider<ApiConfigsNotifier, List<ApiConfig>>((ref) {
  return ApiConfigsNotifier();
});

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

// Theme Studio token configuration
class ThemeTokens {
  final String primaryColor;
  final String secondaryColor;
  final String backgroundColor;
  final String fontFamily;
  final double borderRadius;
  final double spacingUnit;
  final String buttonStyle; // elevated, outlined, flat
  final String inputStyle; // outline, filled, underline

  ThemeTokens({
    this.primaryColor = '#5B4FCF',
    this.secondaryColor = '#6C757D',
    this.backgroundColor = '#FFFFFF',
    this.fontFamily = 'Outfit',
    this.borderRadius = 8.0,
    this.spacingUnit = 16.0,
    this.buttonStyle = 'elevated',
    this.inputStyle = 'outline',
  });

  ThemeTokens copyWith({
    String? primaryColor,
    String? secondaryColor,
    String? backgroundColor,
    String? fontFamily,
    double? borderRadius,
    double? spacingUnit,
    String? buttonStyle,
    String? inputStyle,
  }) {
    return ThemeTokens(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontFamily: fontFamily ?? this.fontFamily,
      borderRadius: borderRadius ?? this.borderRadius,
      spacingUnit: spacingUnit ?? this.spacingUnit,
      buttonStyle: buttonStyle ?? this.buttonStyle,
      inputStyle: inputStyle ?? this.inputStyle,
    );
  }
}

class ThemeTokensNotifier extends StateNotifier<ThemeTokens> {
  ThemeTokensNotifier() : super(ThemeTokens());

  void updateTheme(ThemeTokens updated) {
    state = updated;
  }
}

final themeTokensProvider = StateNotifierProvider<ThemeTokensNotifier, ThemeTokens>((ref) {
  return ThemeTokensNotifier();
});
