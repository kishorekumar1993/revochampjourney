class ApiCollection {
  final String id;
  final String name;
  final String description;
  final String baseUrl;
  final Map<String, String> headers;
  final String authentication; // None, Bearer Token, Basic Auth, API Key, OAuth2
  final String authUsername;
  final String authPassword;
  final String apiKeyName;
  final String apiKeyValue;
  final String apiKeyLocation; // header or query

  ApiCollection({
    required this.id,
    required this.name,
    this.description = '',
    this.baseUrl = '',
    this.headers = const {},
    this.authentication = 'None',
    this.authUsername = '',
    this.authPassword = '',
    this.apiKeyName = '',
    this.apiKeyValue = '',
    this.apiKeyLocation = 'header',
  });

  factory ApiCollection.fromJson(Map<String, dynamic> json) {
    return ApiCollection(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      baseUrl: json['baseUrl'] ?? '',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      authentication: json['authentication'] ?? 'None',
      authUsername: json['authUsername'] ?? '',
      authPassword: json['authPassword'] ?? '',
      apiKeyName: json['apiKeyName'] ?? '',
      apiKeyValue: json['apiKeyValue'] ?? '',
      apiKeyLocation: json['apiKeyLocation'] ?? 'header',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'baseUrl': baseUrl,
      'headers': headers,
      'authentication': authentication,
      'authUsername': authUsername,
      'authPassword': authPassword,
      'apiKeyName': apiKeyName,
      'apiKeyValue': apiKeyValue,
      'apiKeyLocation': apiKeyLocation,
    };
  }

  ApiCollection copyWith({
    String? id,
    String? name,
    String? description,
    String? baseUrl,
    Map<String, String>? headers,
    String? authentication,
    String? authUsername,
    String? authPassword,
    String? apiKeyName,
    String? apiKeyValue,
    String? apiKeyLocation,
  }) {
    return ApiCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      baseUrl: baseUrl ?? this.baseUrl,
      headers: headers ?? this.headers,
      authentication: authentication ?? this.authentication,
      authUsername: authUsername ?? this.authUsername,
      authPassword: authPassword ?? this.authPassword,
      apiKeyName: apiKeyName ?? this.apiKeyName,
      apiKeyValue: apiKeyValue ?? this.apiKeyValue,
      apiKeyLocation: apiKeyLocation ?? this.apiKeyLocation,
    );
  }
}

class ApiConfig {
  final String id;
  final String name;
  final String baseUrl;
  final String endpoint;
  final String method; // GET, POST, PUT, PATCH, DELETE
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final String requestBody;
  final String authentication; // None, Bearer Token, Basic Auth, API Key, OAuth2, Inherit
  final Map<String, String> responseMapping; // mapping of JSON keys/paths to variables

  // Grouping / Collection Folders
  final String group;
  final String collectionId;
  final bool inheritParentSettings;

  // Authentication credentials
  final String authUsername;
  final String authPassword;
  final String apiKeyName;
  final String apiKeyValue;
  final String apiKeyLocation; // header or query
  final String oauthTokenUrl;
  final String oauthClientId;
  final String oauthClientSecret;

  // JWT auto-refresh parameters
  final bool jwtRefreshEnabled;
  final String jwtRefreshUrl;
  final int jwtRefreshInterval; // minutes
  final String jwtRefreshBody;
  final String jwtRefreshTokenPath;
  final String jwtAccessTokenPath;

  // Mocking parameters
  final bool isMockEnabled;
  final int mockDelay; // in seconds
  final String mockResponse;
  final String mockError;

  ApiConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.endpoint,
    required this.method,
    this.headers = const {},
    this.queryParams = const {},
    this.requestBody = '',
    this.authentication = 'None',
    this.responseMapping = const {},
    this.group = 'General',
    this.collectionId = '',
    this.inheritParentSettings = true,
    this.authUsername = '',
    this.authPassword = '',
    this.apiKeyName = '',
    this.apiKeyValue = '',
    this.apiKeyLocation = 'header',
    this.oauthTokenUrl = '',
    this.oauthClientId = '',
    this.oauthClientSecret = '',
    this.jwtRefreshEnabled = false,
    this.jwtRefreshUrl = '',
    this.jwtRefreshInterval = 30,
    this.jwtRefreshBody = '',
    this.jwtRefreshTokenPath = 'refresh_token',
    this.jwtAccessTokenPath = 'access_token',
    this.isMockEnabled = false,
    this.mockDelay = 1,
    this.mockResponse = '',
    this.mockError = '',
  });

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      baseUrl: json['baseUrl'] ?? '',
      endpoint: json['endpoint'] ?? '',
      method: json['method'] ?? 'GET',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      requestBody: json['requestBody'] ?? '',
      authentication: json['authentication'] ?? 'None',
      responseMapping: Map<String, String>.from(json['responseMapping'] ?? {}),
      group: json['group'] ?? 'General',
      collectionId: json['collectionId'] ?? '',
      inheritParentSettings: json['inheritParentSettings'] ?? true,
      authUsername: json['authUsername'] ?? '',
      authPassword: json['authPassword'] ?? '',
      apiKeyName: json['apiKeyName'] ?? '',
      apiKeyValue: json['apiKeyValue'] ?? '',
      apiKeyLocation: json['apiKeyLocation'] ?? 'header',
      oauthTokenUrl: json['oauthTokenUrl'] ?? '',
      oauthClientId: json['oauthClientId'] ?? '',
      oauthClientSecret: json['oauthClientSecret'] ?? '',
      jwtRefreshEnabled: json['jwtRefreshEnabled'] ?? false,
      jwtRefreshUrl: json['jwtRefreshUrl'] ?? '',
      jwtRefreshInterval: json['jwtRefreshInterval'] ?? 30,
      jwtRefreshBody: json['jwtRefreshBody'] ?? '',
      jwtRefreshTokenPath: json['jwtRefreshTokenPath'] ?? 'refresh_token',
      jwtAccessTokenPath: json['jwtAccessTokenPath'] ?? 'access_token',
      isMockEnabled: json['isMockEnabled'] ?? false,
      mockDelay: json['mockDelay'] ?? 1,
      mockResponse: json['mockResponse'] ?? '',
      mockError: json['mockError'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'endpoint': endpoint,
      'method': method,
      'headers': headers,
      'queryParams': queryParams,
      'requestBody': requestBody,
      'authentication': authentication,
      'responseMapping': responseMapping,
      'group': group,
      'collectionId': collectionId,
      'inheritParentSettings': inheritParentSettings,
      'authUsername': authUsername,
      'authPassword': authPassword,
      'apiKeyName': apiKeyName,
      'apiKeyValue': apiKeyValue,
      'apiKeyLocation': apiKeyLocation,
      'oauthTokenUrl': oauthTokenUrl,
      'oauthClientId': oauthClientId,
      'oauthClientSecret': oauthClientSecret,
      'jwtRefreshEnabled': jwtRefreshEnabled,
      'jwtRefreshUrl': jwtRefreshUrl,
      'jwtRefreshInterval': jwtRefreshInterval,
      'jwtRefreshBody': jwtRefreshBody,
      'jwtRefreshTokenPath': jwtRefreshTokenPath,
      'jwtAccessTokenPath': jwtAccessTokenPath,
      'isMockEnabled': isMockEnabled,
      'mockDelay': mockDelay,
      'mockResponse': mockResponse,
      'mockError': mockError,
    };
  }

  ApiConfig copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? endpoint,
    String? method,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? requestBody,
    String? authentication,
    Map<String, String>? responseMapping,
    String? group,
    String? collectionId,
    bool? inheritParentSettings,
    String? authUsername,
    String? authPassword,
    String? apiKeyName,
    String? apiKeyValue,
    String? apiKeyLocation,
    String? oauthTokenUrl,
    String? oauthClientId,
    String? oauthClientSecret,
    bool? jwtRefreshEnabled,
    String? jwtRefreshUrl,
    int? jwtRefreshInterval,
    String? jwtRefreshBody,
    String? jwtRefreshTokenPath,
    String? jwtAccessTokenPath,
    bool? isMockEnabled,
    int? mockDelay,
    String? mockResponse,
    String? mockError,
  }) {
    return ApiConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      requestBody: requestBody ?? this.requestBody,
      authentication: authentication ?? this.authentication,
      responseMapping: responseMapping ?? this.responseMapping,
      group: group ?? this.group,
      collectionId: collectionId ?? this.collectionId,
      inheritParentSettings: inheritParentSettings ?? this.inheritParentSettings,
      authUsername: authUsername ?? this.authUsername,
      authPassword: authPassword ?? this.authPassword,
      apiKeyName: apiKeyName ?? this.apiKeyName,
      apiKeyValue: apiKeyValue ?? this.apiKeyValue,
      apiKeyLocation: apiKeyLocation ?? this.apiKeyLocation,
      oauthTokenUrl: oauthTokenUrl ?? this.oauthTokenUrl,
      oauthClientId: oauthClientId ?? this.oauthClientId,
      oauthClientSecret: oauthClientSecret ?? this.oauthClientSecret,
      jwtRefreshEnabled: jwtRefreshEnabled ?? this.jwtRefreshEnabled,
      jwtRefreshUrl: jwtRefreshUrl ?? this.jwtRefreshUrl,
      jwtRefreshInterval: jwtRefreshInterval ?? this.jwtRefreshInterval,
      jwtRefreshBody: jwtRefreshBody ?? this.jwtRefreshBody,
      jwtRefreshTokenPath: jwtRefreshTokenPath ?? this.jwtRefreshTokenPath,
      jwtAccessTokenPath: jwtAccessTokenPath ?? this.jwtAccessTokenPath,
      isMockEnabled: isMockEnabled ?? this.isMockEnabled,
      mockDelay: mockDelay ?? this.mockDelay,
      mockResponse: mockResponse ?? this.mockResponse,
      mockError: mockError ?? this.mockError,
    );
  }
}
