String generateLocaltorInterface(
  String className,
  List<dynamic> configList,
  String fileName, // Not directly used in this snippet, but kept for signature
) {
  final buffer = StringBuffer();
  buffer.writeln('''
import  '../../data/repositoryimpl/${fileName.toLowerCase().replaceAll(" ", "_")}_repositoryimpl.dart';
import '../repository/${fileName.toLowerCase().replaceAll(" ", "_")}_repository.dart';
import '../../data/dataSource/${fileName.toLowerCase().replaceAll(" ", "_")}_data_source.dart';

import '../../../../../network/client/client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';



final connectionProvider = Provider<${className}Datasource>((ref) {
  final client = ref.watch(httpClientProvider);
  return ${className}DatasourceImpl(client);
});
final ${lowercapitalize(className)}ViewProvider = Provider<${className}Repository>((ref) {
  final dataSource = ref.watch(connectionProvider);
  return ${className}RepoImpl(dataSource);
});
''');

  return buffer.toString();
}

/// Helper function to capitalize the first letter of a string.
String capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Helper function to lowercase the first letter of a string.
String lowercapitalize(String s) =>
    s.isEmpty ? s : '${s[0].toLowerCase()}${s.substring(1)}';
