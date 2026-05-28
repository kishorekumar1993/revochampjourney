String generateBindingClass({
  required String className,
  required String fileName,
  bool useFenix = true,
  bool permanentController = false,
  String baseUrl = '',
  String customApiServiceImport = '/core/service/api_service.dart',
}) {
  final buffer = StringBuffer();

  final snakeFileName = _toSnakeCase(fileName);

  buffer.writeln("import 'package:get/get.dart';");
  buffer.writeln("import '../controllers/${snakeFileName}_controller.dart';");
  buffer.writeln("import '../repository/${snakeFileName}_repository.dart';");
  buffer.writeln("import '$customApiServiceImport';");
  buffer.writeln();

  buffer.writeln("class ${className}Binding extends Bindings {");

  buffer.writeln("  @override");
  buffer.writeln("  void dependencies() {");

  if (baseUrl.isNotEmpty) {
    buffer.writeln("    if (!Get.isRegistered<ApiService>()) {");
    buffer.writeln("      Get.lazyPut<ApiService>(");
    buffer.writeln("        () => ApiService(baseUrl: '$baseUrl'),");
    buffer.writeln("        fenix: $useFenix,");
    buffer.writeln("      );");
    buffer.writeln("    }");
    buffer.writeln();
  }

  buffer.writeln("    Get.lazyPut<${className}Repository>(");
  buffer.writeln("      () => ${className}Repository(");
  buffer.writeln("        Get.find<ApiService>(),");
  buffer.writeln("      ),");
  buffer.writeln("      fenix: $useFenix,");
  buffer.writeln("    );");
  buffer.writeln();

  if (permanentController) {
    buffer.writeln("    Get.put<${className}Controller>(");
    buffer.writeln("      ${className}Controller(");
    buffer.writeln("        repository:  Get.find<${className}Repository>(),");
    buffer.writeln("      ),");
    buffer.writeln("      permanent: true,");
    buffer.writeln("    );");
  } else {
    buffer.writeln("    Get.lazyPut<${className}Controller>(");
    buffer.writeln("      () => ${className}Controller(");
    buffer.writeln("         repository: Get.find<${className}Repository>(),");
    buffer.writeln("      ),");
    buffer.writeln("    );");
  }

  buffer.writeln("  }");
  buffer.writeln("}");

  return buffer.toString();
}

String _toSnakeCase(String value) {
  if (value.contains('_')) return value.toLowerCase();
  final snake = value
      .replaceAllMapped(
        RegExp(r'(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])'),
        (match) => '_',
      )
      .toLowerCase();
  return snake;
}
