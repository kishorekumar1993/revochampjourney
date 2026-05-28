// Shared journey step metadata + code snippets for BLoC / GetX / Riverpod generators.

class JourneyStepCodegen {
  JourneyStepCodegen({
    required this.id,
    required this.title,
    required this.description,
    this.nextStep,
    this.apiCalls = const [],
    this.actions = const [],
    this.validations = const [],
    this.conditions = const [],
  });

  final String id;
  final String title;
  final String description;
  final String? nextStep;
  final List<Map<String, dynamic>> apiCalls;
  final List<Map<String, dynamic>> actions;
  final List<Map<String, dynamic>> validations;
  final List<Map<String, dynamic>> conditions;

  factory JourneyStepCodegen.fromJson(Map<String, dynamic> json) {
    return JourneyStepCodegen(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Step',
      description: json['description']?.toString() ?? '',
      nextStep: json['nextStep']?.toString(),
      apiCalls: _listOfMaps(json['apiCalls']),
      actions: _listOfMaps(json['actions']),
      validations: _listOfMaps(json['validations']),
      conditions: _listOfMaps(json['conditions']),
    );
  }

  static List<Map<String, dynamic>> _listOfMaps(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  bool get hasNextStep => nextStep != null && nextStep!.trim().isNotEmpty;

  String get primaryButtonLabel => hasNextStep ? 'Next' : 'Submit';

  String get escapedTitle => _escapeDart(title);

  String get escapedDescription => _escapeDart(description);

  String get escapedNextStep => _escapeDart(nextStep ?? '');

  bool get hasApiCalls => apiCalls.isNotEmpty;

  bool get hasActions => actions.isNotEmpty;

  bool get hasValidations => validations.isNotEmpty;

  /// Step header widgets (title + description).
  void writeFlutterStepHeader(StringBuffer b) {
    b.writeln('                Text(');
    b.writeln("                  '$escapedTitle',");
    b.writeln('                  style: const TextStyle(');
    b.writeln('                    fontSize: 24,');
    b.writeln('                    fontWeight: FontWeight.bold,');
    b.writeln('                  ),');
    b.writeln('                ),');
    if (description.trim().isNotEmpty) {
      b.writeln('                const SizedBox(height: 8),');
      b.writeln('                Text(');
      b.writeln("                  '$escapedDescription',");
      b.writeln('                  style: TextStyle(');
      b.writeln('                    fontSize: 14,');
      b.writeln('                    color: Colors.grey.shade600,');
      b.writeln('                  ),');
      b.writeln('                ),');
    }
    b.writeln('                const SizedBox(height: 24),');
  }

  /// GetX / Riverpod action button row.
  void writeFlutterActionButtons(
    StringBuffer b, {
    required String onPressedHandler,
    String loadingVar = 'isExecuting',
  }) {
    b.writeln('                const SizedBox(height: 24),');
    b.writeln('                Row(');
    b.writeln('                  mainAxisAlignment: MainAxisAlignment.end,');
    b.writeln('                  children: [');
    b.writeln('                    Obx(() => ElevatedButton(');
    b.writeln('                      onPressed: controller.$loadingVar.value ? null : $onPressedHandler,');
    b.writeln('                      child: controller.$loadingVar.value');
    b.writeln('                          ? const SizedBox(');
    b.writeln('                              width: 18,');
    b.writeln('                              height: 18,');
    b.writeln('                              child: CircularProgressIndicator(strokeWidth: 2),');
    b.writeln('                            )');
    b.writeln("                          : const Text('$primaryButtonLabel'),");
    b.writeln('                    )),');
    b.writeln('                  ],');
    b.writeln('                ),');
  }

  /// Riverpod action button (no Obx).
  void writeRiverpodActionButtons(
    StringBuffer b, {
    required String onPressedHandler,
    String loadingVar = '_isExecuting',
  }) {
    b.writeln('                const SizedBox(height: 24),');
    b.writeln('                Row(');
    b.writeln('                  mainAxisAlignment: MainAxisAlignment.end,');
    b.writeln('                  children: [');
    b.writeln('                    ElevatedButton(');
    b.writeln('                      onPressed: $loadingVar ? null : $onPressedHandler,');
    b.writeln('                      child: $loadingVar');
    b.writeln('                          ? const SizedBox(');
    b.writeln('                              width: 18,');
    b.writeln('                              height: 18,');
    b.writeln('                              child: CircularProgressIndicator(strokeWidth: 2),');
    b.writeln('                            )');
    b.writeln("                          : const Text('$primaryButtonLabel'),");
    b.writeln('                    ),');
    b.writeln('                  ],');
    b.writeln('                ),');
  }

  /// BLoC screen action button.
  void writeBlocActionButton(StringBuffer b, String featureName) {
    b.writeln('                const SizedBox(height: 24),');
    b.writeln('                BlocBuilder<${featureName}Bloc, ${featureName}State>(');
    b.writeln('                  buildWhen: (p, c) => p.isExecuting != c.isExecuting,');
    b.writeln('                  builder: (context, state) {');
    b.writeln('                    return AppFormButton(');
    b.writeln("                      label: '$primaryButtonLabel',");
    b.writeln("                      loadingLabel: 'Processing...',");
    b.writeln('                      state: state.isExecuting');
    b.writeln('                          ? AppButtonState.loading');
    b.writeln('                          : AppButtonState.idle,');
    b.writeln('                      onPressed: state.isExecuting');
    b.writeln('                          ? null');
    b.writeln('                          : () => context.read<${featureName}Bloc>()');
    b.writeln('                              .add(const ${featureName}PrimaryActionEvent()),');
    b.writeln('                    );');
    b.writeln('                  },');
    b.writeln('                ),');
  }

  /// Step constants block for generated classes.
  void writeStepConstants(StringBuffer b) {
    b.writeln("  static const String stepKey = '${_escapeDart(id)}';");
    b.writeln("  static const String stepTitle = '$escapedTitle';");
    if (hasNextStep) {
      b.writeln("  static const String nextStepId = '$escapedNextStep';");
    } else {
      b.writeln('  static const String? nextStepId = null;');
    }
  }

  /// HTTP API execution body (shared pattern).
  void writeApiExecutionMethods(StringBuffer b, {String indent = '  '}) {
    b.writeln('${indent}Future<void> executeStepApis({String trigger = \'onNext\'}) async {');
    for (var i = 0; i < apiCalls.length; i++) {
      final api = apiCalls[i];
      final apiTrigger = api['trigger']?.toString() ?? 'onSubmit';
      b.writeln("$indent  if (_matchesTrigger('$apiTrigger', trigger)) {");
      _writeSingleApiCall(b, api, 'api_$i', indent: '$indent    ');
      b.writeln('$indent  }');
    }
    for (var i = 0; i < actions.length; i++) {
      final action = actions[i];
      final type = action['actionType']?.toString() ?? '';
      if (type != 'apiCall') continue;
      final trigger = action['trigger']?.toString() ?? 'onSubmit';
      final details = action['details']?.toString() ?? '';
      b.writeln('$indent  if (_matchesTrigger(\'$trigger\', trigger)) {');
      b.writeln('$indent    // Action: $details');
      b.writeln('$indent    await _executeActionApi(\'$trigger\', \'$details\');');
      b.writeln('$indent  }');
    }
    b.writeln('$indent}');
    b.writeln();
    b.writeln('${indent}bool _matchesTrigger(String actionTrigger, String current) {');
    b.writeln('$indent  final a = actionTrigger.toLowerCase();');
    b.writeln('$indent  final c = current.toLowerCase();');
    b.writeln('$indent  if (a == c) return true;');
    b.writeln("$indent  if (a == 'onsubmit' && (c == 'submit' || c == 'next')) return true;");
    b.writeln("$indent  if (a == 'onnext' && c == 'next') return true;");
    b.writeln('$indent  return false;');
    b.writeln('$indent}');
    b.writeln();
    b.writeln('${indent}Future<void> _executeActionApi(String trigger, String details) async {');
    b.writeln("$indent  // Wire action URL in journey JSON apiCalls; details: \$details");
    b.writeln('$indent}');
  }

  void _writeSingleApiCall(
    StringBuffer b,
    Map<String, dynamic> api,
    String label, {
    required String indent,
  }) {
    final method = (api['method']?.toString() ?? 'GET').toUpperCase();
    final url = _escapeDart(api['url']?.toString() ?? '');
    final desc = _escapeDart(api['description']?.toString() ?? label);
    final body = _escapeDart(api['body']?.toString() ?? '');
    b.writeln('$indent// $desc');
    b.writeln('${indent}await _runHttpApi(');
    b.writeln("$indent  method: '$method',");
    b.writeln("$indent  url: '$url',");
    if (body.isNotEmpty) {
      b.writeln("$indent  body: '$body',");
    }
    b.writeln('$indent);');
  }

  /// Shared HTTP helper for generated controllers / blocs.
  static void writeHttpHelper(StringBuffer b, {String indent = '  '}) {
    b.writeln('${indent}Future<void> _runHttpApi({');
    b.writeln('$indent  required String method,');
    b.writeln('$indent  required String url,');
    b.writeln('$indent  Map<String, String>? headers,');
    b.writeln('$indent  String? body,');
    b.writeln('$indent}) async {');
    b.writeln("$indent  if (url.isEmpty) return;");
    b.writeln("$indent  final uri = Uri.parse(url);");
    b.writeln("$indent  if (!uri.hasScheme) return; // skip relative demo paths");
    b.writeln('$indent  final h = {');
    b.writeln("$indent    'Content-Type': 'application/json',");
    b.writeln("$indent    'Accept': 'application/json',");
    b.writeln('$indent    ...?headers,');
    b.writeln('$indent  };');
    b.writeln('$indent  http.Response response;');
    b.writeln('$indent  switch (method) {');
    b.writeln("    case 'POST':");
    b.writeln('$indent      response = await http.post(uri, headers: h, body: body);');
    b.writeln("    case 'PUT':");
    b.writeln('$indent      response = await http.put(uri, headers: h, body: body);');
    b.writeln("    case 'DELETE':");
    b.writeln('$indent      response = await http.delete(uri, headers: h, body: body);');
    b.writeln('    default:');
    b.writeln('$indent      response = await http.get(uri, headers: h);');
    b.writeln('$indent  }');
    b.writeln('$indent  if (response.statusCode < 200 || response.statusCode >= 300) {');
    b.writeln('$indent    throw Exception(');
    b.writeln("$indent      'API failed (\${response.statusCode}) for \$url',");
    b.writeln('$indent    );');
    b.writeln('$indent  }');
    b.writeln('$indent}');
  }

  void writeNavigateNextGetX(StringBuffer b, {String indent = '  '}) {
    if (hasNextStep) {
      b.writeln('${indent}if (nextStepId != null && nextStepId!.isNotEmpty) {');
      b.writeln("$indent  Get.toNamed('/journey/\$nextStepId');");
      b.writeln('$indent}');
    } else {
      b.writeln("${indent}Get.snackbar('Success', 'Journey step completed.');");
    }
  }

  static String _escapeDart(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\n')
        .replaceAll('\r', '');
  }
}
