class ApiConfig {
  final String id;
  final String name;
  final String baseUrl;
  final String endpoint;
  final String method; // GET, POST, PUT, PATCH, DELETE
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final String requestBody;
  final String authentication; // None, Bearer, Basic, API Key, OAuth2
  final Map<String, String> responseMapping; // mapping of JSON keys/paths to variables

  // Grouping / Collection Folders
  final String group;

  // Authentication credentials
  final String authUsername;
  final String authPassword;
  final String apiKeyName;
  final String apiKeyValue;
  final String apiKeyLocation; // header or query
  final String oauthTokenUrl;
  final String oauthClientId;
  final String oauthClientSecret;

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
    this.authUsername = '',
    this.authPassword = '',
    this.apiKeyName = '',
    this.apiKeyValue = '',
    this.apiKeyLocation = 'header',
    this.oauthTokenUrl = '',
    this.oauthClientId = '',
    this.oauthClientSecret = '',
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
      authUsername: json['authUsername'] ?? '',
      authPassword: json['authPassword'] ?? '',
      apiKeyName: json['apiKeyName'] ?? '',
      apiKeyValue: json['apiKeyValue'] ?? '',
      apiKeyLocation: json['apiKeyLocation'] ?? 'header',
      oauthTokenUrl: json['oauthTokenUrl'] ?? '',
      oauthClientId: json['oauthClientId'] ?? '',
      oauthClientSecret: json['oauthClientSecret'] ?? '',
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
      'authUsername': authUsername,
      'authPassword': authPassword,
      'apiKeyName': apiKeyName,
      'apiKeyValue': apiKeyValue,
      'apiKeyLocation': apiKeyLocation,
      'oauthTokenUrl': oauthTokenUrl,
      'oauthClientId': oauthClientId,
      'oauthClientSecret': oauthClientSecret,
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
    String? authUsername,
    String? authPassword,
    String? apiKeyName,
    String? apiKeyValue,
    String? apiKeyLocation,
    String? oauthTokenUrl,
    String? oauthClientId,
    String? oauthClientSecret,
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
      authUsername: authUsername ?? this.authUsername,
      authPassword: authPassword ?? this.authPassword,
      apiKeyName: apiKeyName ?? this.apiKeyName,
      apiKeyValue: apiKeyValue ?? this.apiKeyValue,
      apiKeyLocation: apiKeyLocation ?? this.apiKeyLocation,
      oauthTokenUrl: oauthTokenUrl ?? this.oauthTokenUrl,
      oauthClientId: oauthClientId ?? this.oauthClientId,
      oauthClientSecret: oauthClientSecret ?? this.oauthClientSecret,
      isMockEnabled: isMockEnabled ?? this.isMockEnabled,
      mockDelay: mockDelay ?? this.mockDelay,
      mockResponse: mockResponse ?? this.mockResponse,
      mockError: mockError ?? this.mockError,
    );
  }
}
