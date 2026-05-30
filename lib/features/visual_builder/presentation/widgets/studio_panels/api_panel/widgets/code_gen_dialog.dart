import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/core/component_engine/models/api_config.dart';
import 'package:revojourneytryone/features/visual_builder/presentation/widgets/studio_panels/api_panel/controllers/dart_model_generator.dart';

class RevoCodeGenDialog extends StatelessWidget {
  final ApiConfig config;
  final String? lastResponseBody;
  final String Function(String) substituteEnvVars;

  const RevoCodeGenDialog({
    super.key,
    required this.config,
    required this.lastResponseBody,
    required this.substituteEnvVars,
  });

  String _generateCurl() {
    final method = config.method.toUpperCase();
    final substitutedUrl = substituteEnvVars(config.baseUrl + config.endpoint);
    final buffer = StringBuffer('curl -X $method "$substitutedUrl"');

    config.headers.forEach((key, val) {
      buffer.write(' \\\n  -H "$key: ${substituteEnvVars(val)}"');
    });

    if (config.authentication == 'Bearer Token' && config.authPassword.isNotEmpty) {
      buffer.write(' \\\n  -H "Authorization: Bearer ${substituteEnvVars(config.authPassword)}"');
    } else if (config.authentication == 'Basic Auth') {
      final user = substituteEnvVars(config.authUsername);
      final pass = substituteEnvVars(config.authPassword);
      final creds = base64Encode(utf8.encode('$user:$pass'));
      buffer.write(' \\\n  -H "Authorization: Basic $creds"');
    } else if (config.authentication == 'API Key' && config.apiKeyLocation == 'header') {
      buffer.write(' \\\n  -H "${config.apiKeyName}: ${substituteEnvVars(config.apiKeyValue)}"');
    }

    if (method != 'GET' && config.requestBody.trim().isNotEmpty) {
      final escapedBody = config.requestBody.replaceAll("'", "'\\''");
      buffer.write(' \\\n  -d \'$escapedBody\'');
    }

    return buffer.toString();
  }

  String _generateResponseModel() {
    final rootClassName = '${_cleanName(config.name)}Response';
    final generator = DartModelGenerator();
    if (lastResponseBody != null && lastResponseBody!.trim().isNotEmpty) {
      try {
        final decoded = json.decode(lastResponseBody!);
        return generator.generate(rootClassName, decoded);
      } catch (_) {}
    }
    
    // Fallback basic schema
    return generator.generate(rootClassName, {
      "success": true,
      "message": "Simulated default response payload"
    });
  }

  String _generateDioRepository() {
    final name = _cleanName(config.name);
    final rootClassName = '${name}Response';
    final method = config.method.toLowerCase();
    final buffer = StringBuffer();

    buffer.writeln("import 'package:dio/dio.dart';");
    buffer.writeln("import '${config.name.toLowerCase().replaceAll(' ', '_')}_model.dart';\n");

    if (config.jwtRefreshEnabled) {
      buffer.writeln('''// ─── JWT Auto-Refresh Interceptor ───────────────────────────────────────────
class JwtRefreshInterceptor extends Interceptor {
  final Dio dio;
  final String refreshUrl = '${config.jwtRefreshUrl.isNotEmpty ? config.jwtRefreshUrl : "/v1/auth/refresh"}';
  final int refreshIntervalMinutes = ${config.jwtRefreshInterval};
  
  String? _accessToken;
  String? _refreshToken;
  bool _isRefreshing = false;
  
  JwtRefreshInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_accessToken != null) {
      options.headers['Authorization'] = 'Bearer \$_accessToken';
    }
    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && _refreshToken != null && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshResponse = await dio.post(
          refreshUrl,
          data: ${config.jwtRefreshBody.isNotEmpty ? config.jwtRefreshBody : '{"refresh_token": _refreshToken}'},
        );
        
        final data = refreshResponse.data;
        _accessToken = data['${config.jwtAccessTokenPath}'];
        _refreshToken = data['${config.jwtRefreshTokenPath}'];
        _isRefreshing = false;
        
        // Retry original request
        final requestOptions = err.requestOptions;
        requestOptions.headers['Authorization'] = 'Bearer \$_accessToken';
        final cloneReq = await dio.fetch(requestOptions);
        return handler.resolve(cloneReq);
      } catch (e) {
        _isRefreshing = false;
        return handler.reject(err);
      }
    }
    super.onError(err, handler);
  }
}
''');
    }

    buffer.writeln('''class ${name}Repository {
  final Dio _dio;

  ${name}Repository(this._dio) {
    ${config.jwtRefreshEnabled ? "_dio.interceptors.add(JwtRefreshInterceptor(_dio));" : ""}
  }

  Future<$rootClassName> execute() async {
    try {
      final response = await _dio.$method(
        '${config.endpoint}',
        ${method == 'get' ? 'queryParameters: const {}' : 'data: ${config.requestBody.isNotEmpty ? config.requestBody : 'const {}'}'},
        options: Options(
          headers: const {
            ${config.headers.entries.map((e) => "'${e.key}': '${e.value}'").join(',\n            ')}
          },
        ),
      );
      return $rootClassName.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Dio execution failure: \${e.message}');
    }
  }
}''');

    return buffer.toString();
  }

  String _generateCleanArchitecture() {
    final name = _cleanName(config.name);
    return '''// ─── Domain Entity ───────────────────────────────────────────────────────────
class ${name}Entity {
  final String status;
  final Map<String, dynamic> rawPayload;
  
  const ${name}Entity({
    required this.status,
    required this.rawPayload,
  });
}

// ─── Data Source Contract ────────────────────────────────────────────────────
abstract class ${name}RemoteDataSource {
  Future<${name}Response> callApi();
}

class ${name}RemoteDataSourceImpl implements ${name}RemoteDataSource {
  final Dio _dio;
  ${name}RemoteDataSourceImpl(this._dio);

  @override
  Future<${name}Response> callApi() async {
    final response = await _dio.${config.method.toLowerCase()}('${config.endpoint}');
    return ${name}Response.fromJson(response.data as Map<String, dynamic>);
  }
}

// ─── Domain Repository Contract ──────────────────────────────────────────────
abstract class ${name}Repository {
  Future<${name}Entity> execute();
}

class ${name}RepositoryImpl implements ${name}Repository {
  final ${name}RemoteDataSource dataSource;
  ${name}RepositoryImpl(this.dataSource);

  @override
  Future<${name}Entity> execute() async {
    try {
      final model = await dataSource.callApi();
      return ${name}Entity(
        status: '200 OK',
        rawPayload: model.toJson(),
      );
    } catch (e) {
      throw Exception('Repository error: \$e');
    }
  }
}
''';
  }

  String _cleanName(String s) {
    return s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  void _copyToClipboard(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied code to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final curlCode = _generateCurl();
    final modelCode = _generateResponseModel();
    final dioCode = _generateDioRepository();
    final cleanArch = _generateCleanArchitecture();

    return DefaultTabController(
      length: 4,
      child: AlertDialog(
        backgroundColor: RevoTheme.sidebarBackground,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Developer Integration Hub",
              style: GoogleFonts.outfit(
                color: RevoTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 480,
          child: Column(
            children: [
              TabBar(
                labelColor: RevoTheme.primary,
                unselectedLabelColor: RevoTheme.textSecondary,
                indicatorColor: RevoTheme.primary,
                labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "cURL"),
                  Tab(text: "Dart Model"),
                  Tab(text: "Dio Repo"),
                  Tab(text: "Clean Arch"),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildCodeView(context, curlCode),
                    _buildCodeView(context, modelCode),
                    _buildCodeView(context, dioCode),
                    _buildCodeView(context, cleanArch),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeView(BuildContext context, String code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF5B4FCF)),
              label: Text(
                "Copy Code",
                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5B4FCF)),
              ),
              onPressed: () => _copyToClipboard(context, code),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                code,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 10,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
