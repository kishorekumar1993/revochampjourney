String generatebindingClass(String className, Map<String, dynamic> json, String fileName,
    {bool isNested = false}) {
  final buffer = StringBuffer();

  buffer.writeln("import 'package:get/get.dart';");
  buffer.writeln("import '../controllers/${fileName.toLowerCase()}_controller.dart';");
  buffer.writeln("import '../repository/${fileName.toLowerCase()}_repository.dart';");
  buffer.writeln("import '/core/service/api_service.dart';\n");

  buffer.writeln("class ${className}Binding extends Bindings {");
  buffer.writeln("  @override");
  buffer.writeln("  void dependencies() {");
  buffer.writeln("    final api = ApiService(baseUrl: '');");
  buffer.writeln("    Get.lazyPut(() => ${className}Controller(${className}Repository(api)));");
  buffer.writeln("  }");
  buffer.writeln("}");

  return buffer.toString();
}
