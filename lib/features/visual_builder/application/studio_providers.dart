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

// ─── Theme Studio ─────────────────────────────────────────────────────────────

class ThemeEditorState {
  final ThemeTokens tokens;
  final bool canUndo;
  final bool canRedo;
  const ThemeEditorState({required this.tokens, this.canUndo = false, this.canRedo = false});
}

class ThemeVersion {
  final String id;
  final String name;
  final ThemeTokens tokens;
  final DateTime savedAt;
  ThemeVersion({required this.id, required this.name, required this.tokens, required this.savedAt});
}

class ThemeTokens {
  // Metadata
  final String themeName;
  final String themeVersion;
  final String themeAuthor;
  // Colors
  final String primaryColor;
  final String secondaryColor;
  final String backgroundColor;
  final String cardColor;
  final String textPrimaryColor;
  final String textSecondaryColor;
  final String errorColor;
  final String successColor;
  final String warningColor;
  // Gradients
  final String gradientStartColor;
  final String gradientEndColor;
  // Shadows
  final String shadowColor;
  final double shadowBlurRadius;
  final double shadowSpreadRadius;
  final double shadowOffsetX;
  final double shadowOffsetY;
  // Typography
  final String fontFamily;
  final double fontSizeXs;
  final double fontSizeSm;
  final double fontSizeMd;
  final double fontSizeLg;
  final double fontSizeXl;
  // Radius
  final double borderRadiusSm;
  final double borderRadius;
  final double borderRadiusLg;
  // Spacing
  final double spacingXs;
  final double spacingSm;
  final double spacingUnit;
  final double spacingLg;
  final double spacingXl;
  // Animations (ms)
  final int animationFast;
  final int animationMedium;
  final int animationSlow;
  // Elevation
  final double elevation1;
  final double elevation2;
  final double elevation3;
  // Icon sizes
  final double iconSizeSm;
  final double iconSizeMd;
  final double iconSizeLg;
  // Component styles
  final String buttonStyle;
  final String inputStyle;
  final String cardStyle;
  final String appBarStyle;
  final String chipStyle;
  final String dialogStyle;
  final String drawerStyle;
  final String bottomSheetStyle;
  final String tabBarStyle;
  final String navigationBarStyle;
  final String listTileStyle;
  final String tableStyle;
  final String stepperStyle;
  final String snackbarStyle;
  final String dataGridStyle;
  final String calendarStyle;
  final String treeViewStyle;
  final String chartsStyle;
  final String timelineStyle;
  final String kanbanStyle;
  // Dark mode
  final bool isDarkMode;

  const ThemeTokens({
    this.themeName = 'My Theme',
    this.themeVersion = '1.0.0',
    this.themeAuthor = '',
    this.primaryColor = '#5B4FCF',
    this.secondaryColor = '#6C757D',
    this.backgroundColor = '#FFFFFF',
    this.cardColor = '#FFFFFF',
    this.textPrimaryColor = '#1A1A2E',
    this.textSecondaryColor = '#6B7280',
    this.errorColor = '#EF4444',
    this.successColor = '#10B981',
    this.warningColor = '#F59E0B',
    this.gradientStartColor = '',
    this.gradientEndColor = '',
    this.shadowColor = '#000000',
    this.shadowBlurRadius = 0.0,
    this.shadowSpreadRadius = 0.0,
    this.shadowOffsetX = 0.0,
    this.shadowOffsetY = 0.0,
    this.fontFamily = 'Outfit',
    this.fontSizeXs = 10.0,
    this.fontSizeSm = 12.0,
    this.fontSizeMd = 14.0,
    this.fontSizeLg = 18.0,
    this.fontSizeXl = 24.0,
    this.borderRadiusSm = 4.0,
    this.borderRadius = 8.0,
    this.borderRadiusLg = 16.0,
    this.spacingXs = 4.0,
    this.spacingSm = 8.0,
    this.spacingUnit = 16.0,
    this.spacingLg = 24.0,
    this.spacingXl = 32.0,
    this.animationFast = 150,
    this.animationMedium = 300,
    this.animationSlow = 500,
    this.elevation1 = 1.0,
    this.elevation2 = 4.0,
    this.elevation3 = 8.0,
    this.iconSizeSm = 16.0,
    this.iconSizeMd = 24.0,
    this.iconSizeLg = 32.0,
    this.buttonStyle = 'elevated',
    this.inputStyle = 'outline',
    this.cardStyle = 'flat',
    this.appBarStyle = 'solid',
    this.chipStyle = 'filled',
    this.dialogStyle = 'elevated',
    this.drawerStyle = 'standard',
    this.bottomSheetStyle = 'flat',
    this.tabBarStyle = 'standard',
    this.navigationBarStyle = 'standard',
    this.listTileStyle = 'flat',
    this.tableStyle = 'standard',
    this.stepperStyle = 'standard',
    this.snackbarStyle = 'standard',
    this.dataGridStyle = 'compact',
    this.calendarStyle = 'minimalist',
    this.treeViewStyle = 'tree-lines',
    this.chartsStyle = 'solid',
    this.timelineStyle = 'left-align',
    this.kanbanStyle = 'board-flat',
    this.isDarkMode = false,
  });

  ThemeTokens copyWith({
    String? themeName,
    String? themeVersion,
    String? themeAuthor,
    String? primaryColor,
    String? secondaryColor,
    String? backgroundColor,
    String? cardColor,
    String? textPrimaryColor,
    String? textSecondaryColor,
    String? errorColor,
    String? successColor,
    String? warningColor,
    String? gradientStartColor,
    String? gradientEndColor,
    String? shadowColor,
    double? shadowBlurRadius,
    double? shadowSpreadRadius,
    double? shadowOffsetX,
    double? shadowOffsetY,
    String? fontFamily,
    double? fontSizeXs,
    double? fontSizeSm,
    double? fontSizeMd,
    double? fontSizeLg,
    double? fontSizeXl,
    double? borderRadiusSm,
    double? borderRadius,
    double? borderRadiusLg,
    double? spacingXs,
    double? spacingSm,
    double? spacingUnit,
    double? spacingLg,
    double? spacingXl,
    int? animationFast,
    int? animationMedium,
    int? animationSlow,
    double? elevation1,
    double? elevation2,
    double? elevation3,
    double? iconSizeSm,
    double? iconSizeMd,
    double? iconSizeLg,
    String? buttonStyle,
    String? inputStyle,
    String? cardStyle,
    String? appBarStyle,
    String? chipStyle,
    String? dialogStyle,
    String? drawerStyle,
    String? bottomSheetStyle,
    String? tabBarStyle,
    String? navigationBarStyle,
    String? listTileStyle,
    String? tableStyle,
    String? stepperStyle,
    String? snackbarStyle,
    String? dataGridStyle,
    String? calendarStyle,
    String? treeViewStyle,
    String? chartsStyle,
    String? timelineStyle,
    String? kanbanStyle,
    bool? isDarkMode,
  }) {
    return ThemeTokens(
      themeName: themeName ?? this.themeName,
      themeVersion: themeVersion ?? this.themeVersion,
      themeAuthor: themeAuthor ?? this.themeAuthor,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      cardColor: cardColor ?? this.cardColor,
      textPrimaryColor: textPrimaryColor ?? this.textPrimaryColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      errorColor: errorColor ?? this.errorColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      gradientStartColor: gradientStartColor ?? this.gradientStartColor,
      gradientEndColor: gradientEndColor ?? this.gradientEndColor,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowSpreadRadius: shadowSpreadRadius ?? this.shadowSpreadRadius,
      shadowOffsetX: shadowOffsetX ?? this.shadowOffsetX,
      shadowOffsetY: shadowOffsetY ?? this.shadowOffsetY,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSizeXs: fontSizeXs ?? this.fontSizeXs,
      fontSizeSm: fontSizeSm ?? this.fontSizeSm,
      fontSizeMd: fontSizeMd ?? this.fontSizeMd,
      fontSizeLg: fontSizeLg ?? this.fontSizeLg,
      fontSizeXl: fontSizeXl ?? this.fontSizeXl,
      borderRadiusSm: borderRadiusSm ?? this.borderRadiusSm,
      borderRadius: borderRadius ?? this.borderRadius,
      borderRadiusLg: borderRadiusLg ?? this.borderRadiusLg,
      spacingXs: spacingXs ?? this.spacingXs,
      spacingSm: spacingSm ?? this.spacingSm,
      spacingUnit: spacingUnit ?? this.spacingUnit,
      spacingLg: spacingLg ?? this.spacingLg,
      spacingXl: spacingXl ?? this.spacingXl,
      animationFast: animationFast ?? this.animationFast,
      animationMedium: animationMedium ?? this.animationMedium,
      animationSlow: animationSlow ?? this.animationSlow,
      elevation1: elevation1 ?? this.elevation1,
      elevation2: elevation2 ?? this.elevation2,
      elevation3: elevation3 ?? this.elevation3,
      iconSizeSm: iconSizeSm ?? this.iconSizeSm,
      iconSizeMd: iconSizeMd ?? this.iconSizeMd,
      iconSizeLg: iconSizeLg ?? this.iconSizeLg,
      buttonStyle: buttonStyle ?? this.buttonStyle,
      inputStyle: inputStyle ?? this.inputStyle,
      cardStyle: cardStyle ?? this.cardStyle,
      appBarStyle: appBarStyle ?? this.appBarStyle,
      chipStyle: chipStyle ?? this.chipStyle,
      dialogStyle: dialogStyle ?? this.dialogStyle,
      drawerStyle: drawerStyle ?? this.drawerStyle,
      bottomSheetStyle: bottomSheetStyle ?? this.bottomSheetStyle,
      tabBarStyle: tabBarStyle ?? this.tabBarStyle,
      navigationBarStyle: navigationBarStyle ?? this.navigationBarStyle,
      listTileStyle: listTileStyle ?? this.listTileStyle,
      tableStyle: tableStyle ?? this.tableStyle,
      stepperStyle: stepperStyle ?? this.stepperStyle,
      snackbarStyle: snackbarStyle ?? this.snackbarStyle,
      dataGridStyle: dataGridStyle ?? this.dataGridStyle,
      calendarStyle: calendarStyle ?? this.calendarStyle,
      treeViewStyle: treeViewStyle ?? this.treeViewStyle,
      chartsStyle: chartsStyle ?? this.chartsStyle,
      timelineStyle: timelineStyle ?? this.timelineStyle,
      kanbanStyle: kanbanStyle ?? this.kanbanStyle,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeName': themeName, 'themeVersion': themeVersion, 'themeAuthor': themeAuthor,
    'primaryColor': primaryColor, 'secondaryColor': secondaryColor,
    'backgroundColor': backgroundColor, 'cardColor': cardColor,
    'textPrimaryColor': textPrimaryColor, 'textSecondaryColor': textSecondaryColor,
    'errorColor': errorColor, 'successColor': successColor, 'warningColor': warningColor,
    'gradientStartColor': gradientStartColor, 'gradientEndColor': gradientEndColor,
    'shadowColor': shadowColor, 'shadowBlurRadius': shadowBlurRadius,
    'shadowSpreadRadius': shadowSpreadRadius, 'shadowOffsetX': shadowOffsetX, 'shadowOffsetY': shadowOffsetY,
    'fontFamily': fontFamily,
    'fontSizeXs': fontSizeXs, 'fontSizeSm': fontSizeSm, 'fontSizeMd': fontSizeMd,
    'fontSizeLg': fontSizeLg, 'fontSizeXl': fontSizeXl,
    'borderRadiusSm': borderRadiusSm, 'borderRadius': borderRadius, 'borderRadiusLg': borderRadiusLg,
    'spacingXs': spacingXs, 'spacingSm': spacingSm, 'spacingUnit': spacingUnit,
    'spacingLg': spacingLg, 'spacingXl': spacingXl,
    'animationFast': animationFast, 'animationMedium': animationMedium, 'animationSlow': animationSlow,
    'elevation1': elevation1, 'elevation2': elevation2, 'elevation3': elevation3,
    'iconSizeSm': iconSizeSm, 'iconSizeMd': iconSizeMd, 'iconSizeLg': iconSizeLg,
    'buttonStyle': buttonStyle, 'inputStyle': inputStyle, 'cardStyle': cardStyle,
    'appBarStyle': appBarStyle, 'chipStyle': chipStyle,
    'dialogStyle': dialogStyle, 'drawerStyle': drawerStyle, 'bottomSheetStyle': bottomSheetStyle,
    'tabBarStyle': tabBarStyle, 'navigationBarStyle': navigationBarStyle, 'listTileStyle': listTileStyle,
    'tableStyle': tableStyle, 'stepperStyle': stepperStyle, 'snackbarStyle': snackbarStyle,
    'dataGridStyle': dataGridStyle, 'calendarStyle': calendarStyle, 'treeViewStyle': treeViewStyle,
    'chartsStyle': chartsStyle, 'timelineStyle': timelineStyle, 'kanbanStyle': kanbanStyle,
    'isDarkMode': isDarkMode,
  };

  factory ThemeTokens.fromJson(Map<String, dynamic> j) => ThemeTokens(
    themeName: j['themeName'] as String? ?? 'My Theme',
    themeVersion: j['themeVersion'] as String? ?? '1.0.0',
    themeAuthor: j['themeAuthor'] as String? ?? '',
    primaryColor: j['primaryColor'] as String? ?? '#5B4FCF',
    secondaryColor: j['secondaryColor'] as String? ?? '#6C757D',
    backgroundColor: j['backgroundColor'] as String? ?? '#FFFFFF',
    cardColor: j['cardColor'] as String? ?? '#FFFFFF',
    textPrimaryColor: j['textPrimaryColor'] as String? ?? '#1A1A2E',
    textSecondaryColor: j['textSecondaryColor'] as String? ?? '#6B7280',
    errorColor: j['errorColor'] as String? ?? '#EF4444',
    successColor: j['successColor'] as String? ?? '#10B981',
    warningColor: j['warningColor'] as String? ?? '#F59E0B',
    gradientStartColor: j['gradientStartColor'] as String? ?? '',
    gradientEndColor: j['gradientEndColor'] as String? ?? '',
    shadowColor: j['shadowColor'] as String? ?? '#000000',
    shadowBlurRadius: (j['shadowBlurRadius'] as num?)?.toDouble() ?? 0.0,
    shadowSpreadRadius: (j['shadowSpreadRadius'] as num?)?.toDouble() ?? 0.0,
    shadowOffsetX: (j['shadowOffsetX'] as num?)?.toDouble() ?? 0.0,
    shadowOffsetY: (j['shadowOffsetY'] as num?)?.toDouble() ?? 0.0,
    fontFamily: j['fontFamily'] as String? ?? 'Outfit',
    fontSizeXs: (j['fontSizeXs'] as num?)?.toDouble() ?? 10.0,
    fontSizeSm: (j['fontSizeSm'] as num?)?.toDouble() ?? 12.0,
    fontSizeMd: (j['fontSizeMd'] as num?)?.toDouble() ?? 14.0,
    fontSizeLg: (j['fontSizeLg'] as num?)?.toDouble() ?? 18.0,
    fontSizeXl: (j['fontSizeXl'] as num?)?.toDouble() ?? 24.0,
    borderRadiusSm: (j['borderRadiusSm'] as num?)?.toDouble() ?? 4.0,
    borderRadius: (j['borderRadius'] as num?)?.toDouble() ?? 8.0,
    borderRadiusLg: (j['borderRadiusLg'] as num?)?.toDouble() ?? 16.0,
    spacingXs: (j['spacingXs'] as num?)?.toDouble() ?? 4.0,
    spacingSm: (j['spacingSm'] as num?)?.toDouble() ?? 8.0,
    spacingUnit: (j['spacingUnit'] as num?)?.toDouble() ?? 16.0,
    spacingLg: (j['spacingLg'] as num?)?.toDouble() ?? 24.0,
    spacingXl: (j['spacingXl'] as num?)?.toDouble() ?? 32.0,
    animationFast: j['animationFast'] as int? ?? 150,
    animationMedium: j['animationMedium'] as int? ?? 300,
    animationSlow: j['animationSlow'] as int? ?? 500,
    elevation1: (j['elevation1'] as num?)?.toDouble() ?? 1.0,
    elevation2: (j['elevation2'] as num?)?.toDouble() ?? 4.0,
    elevation3: (j['elevation3'] as num?)?.toDouble() ?? 8.0,
    iconSizeSm: (j['iconSizeSm'] as num?)?.toDouble() ?? 16.0,
    iconSizeMd: (j['iconSizeMd'] as num?)?.toDouble() ?? 24.0,
    iconSizeLg: (j['iconSizeLg'] as num?)?.toDouble() ?? 32.0,
    buttonStyle: j['buttonStyle'] as String? ?? 'elevated',
    inputStyle: j['inputStyle'] as String? ?? 'outline',
    cardStyle: j['cardStyle'] as String? ?? 'flat',
    appBarStyle: j['appBarStyle'] as String? ?? 'solid',
    chipStyle: j['chipStyle'] as String? ?? 'filled',
    dialogStyle: j['dialogStyle'] as String? ?? 'elevated',
    drawerStyle: j['drawerStyle'] as String? ?? 'standard',
    bottomSheetStyle: j['bottomSheetStyle'] as String? ?? 'flat',
    tabBarStyle: j['tabBarStyle'] as String? ?? 'standard',
    navigationBarStyle: j['navigationBarStyle'] as String? ?? 'standard',
    listTileStyle: j['listTileStyle'] as String? ?? 'flat',
    tableStyle: j['tableStyle'] as String? ?? 'standard',
    stepperStyle: j['stepperStyle'] as String? ?? 'standard',
    snackbarStyle: j['snackbarStyle'] as String? ?? 'standard',
    dataGridStyle: j['dataGridStyle'] as String? ?? 'compact',
    calendarStyle: j['calendarStyle'] as String? ?? 'minimalist',
    treeViewStyle: j['treeViewStyle'] as String? ?? 'tree-lines',
    chartsStyle: j['chartsStyle'] as String? ?? 'solid',
    timelineStyle: j['timelineStyle'] as String? ?? 'left-align',
    kanbanStyle: j['kanbanStyle'] as String? ?? 'board-flat',
    isDarkMode: j['isDarkMode'] as bool? ?? false,
  );
}

class ThemeEditorNotifier extends StateNotifier<ThemeEditorState> {
  final List<ThemeTokens> _history = [];
  int _historyIndex = -1;
  static const int _maxHistory = 50;

  ThemeEditorNotifier() : super(const ThemeEditorState(tokens: ThemeTokens())) {
    _history.add(const ThemeTokens());
    _historyIndex = 0;
  }

  void updateTheme(ThemeTokens updated) {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(updated);
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    } else {
      _historyIndex++;
    }
    state = ThemeEditorState(tokens: updated, canUndo: _historyIndex > 0, canRedo: false);
  }

  void undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      state = ThemeEditorState(
        tokens: _history[_historyIndex],
        canUndo: _historyIndex > 0,
        canRedo: true,
      );
    }
  }

  void redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      state = ThemeEditorState(
        tokens: _history[_historyIndex],
        canUndo: _historyIndex > 0,
        canRedo: _historyIndex < _history.length - 1,
      );
    }
  }
}

final themeTokensProvider = StateNotifierProvider<ThemeEditorNotifier, ThemeEditorState>((ref) {
  return ThemeEditorNotifier();
});

class ThemeVersionsNotifier extends StateNotifier<List<ThemeVersion>> {
  ThemeVersionsNotifier() : super([]);

  void saveVersion(String name, ThemeTokens tokens) {
    state = [
      ...state,
      ThemeVersion(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        tokens: tokens,
        savedAt: DateTime.now(),
      ),
    ];
  }

  void deleteVersion(String id) {
    state = state.where((v) => v.id != id).toList();
  }
}

final themeVersionsProvider = StateNotifierProvider<ThemeVersionsNotifier, List<ThemeVersion>>((ref) {
  return ThemeVersionsNotifier();
});

final geminiApiKeyProvider = StateProvider<String>((ref) => "");

