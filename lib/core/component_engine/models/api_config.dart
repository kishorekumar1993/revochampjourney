class ApiConfig {
  final String id;
  final String name;
  final String baseUrl;
  final String endpoint;
  final String method; // GET, POST, PUT, PATCH, DELETE
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final String requestBody;
  final String authentication; // None, Bearer, Basic
  final Map<String, String> responseMapping; // mapping of JSON keys/paths to variables

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
    );
  }
}
