import 'dart:convert';
// import 'package:revojourneytryone/colors.dart';
import 'package:revojourneytryone/getx/binding.dart';
import 'package:revojourneytryone/getx/controller.dart';
import 'package:revojourneytryone/getx/getx_temp.dart';
import 'dart:js' as js;

import 'package:revojourneytryone/getx/repository.dart';
import 'package:revojourneytryone/getx/viewscreen.dart';
import 'package:revojourneytryone/riverpod/riverpod_data_datasource.dart';
import 'package:revojourneytryone/riverpod/riverpod_data_notifier.dart';
import 'package:revojourneytryone/riverpod/riverpod_data_repositoryimpl.dart';
import 'package:revojourneytryone/riverpod/riverpod_domain_repository.dart';
import 'package:revojourneytryone/riverpod/riverpod_enitity_class.dart';
import 'package:revojourneytryone/riverpod/riverpod_locator.dart';
import 'package:revojourneytryone/riverpod/riverpod_presentation.dart';
import 'package:revojourneytryone/riverpod/riverpod_provider.dart';
import 'package:revojourneytryone/riverpod/riverpod_temp_model.dart';
import 'package:revojourneytryone/riverpod/riverpodapiservice.dart';


void saveRepositoryFile(
  List<Map<String, dynamic>> fieldJsonRaw,
  String? screenName,
  String? modelName,
  List<Map<String, String>>? logicalFiles,
) {
  // final fieldJson =
  //     fieldJsonRaw?.map((e) => Map<String, dynamic>.from(e)).toList();
  final fieldJson =
      fieldJsonRaw
          .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
          .toList();
  String baseName = screenName!;
  String className = '$screenName${modelName!}';
  String fileName = '${screenName}_$modelName';

  // final subfolder = 'repository';
  String repgenerated;
  repgenerated = generaterepositoryClass(className, fieldJson, fileName);
  String viewgenerated;

  viewgenerated = generateviewClass(
    '$screenName$modelName',
    fieldJson,
    fileName,
  );
  String bingenerated;

  bingenerated = generatebindingClass(className, fieldJson[0], fileName);
  String congenerated;

  congenerated = generatecontrollerClass(className, fieldJson, fileName);

  logicalFiles?.addAll([
    {
      "layer": "bindings",
      "textContent": bingenerated,
      "fileName": "${fileName}_binding".toLowerCase(),
    },
    {
      "layer": "controllers",
      "textContent": congenerated,
      "fileName": "${fileName}_controller".toLowerCase(),
    },
    {
      "layer": "repository",
      "textContent": repgenerated,
      "fileName": "${fileName}_repository".toLowerCase(),
    },
    {
      "layer": "presentation",
      "textContent": viewgenerated,
      "fileName": "${fileName}_view".toLowerCase(),
    },
  ]);

  List<Map<String, String>> fileDataArray = [];

  for (int i = 0; i < logicalFiles!.length; i++) {
    final item = logicalFiles[i];
    String folderPath = "lib/features/$baseName/${item['layer']}";
    // String fileName = "file$i.dart"; // file0.txt, file1.txt, etc.

    fileDataArray.add({
      "folderPath": folderPath,
      "fileName": "${item["fileName"]!}.dart",
      "textContent": item["textContent"]!,
    });
  }

  for (final item in fieldJson) {
    final textContent = item['dropdowndata'];

    // ✅ Skip if dropdowndata is null or empty
    if (textContent == null ||
        (textContent is List && textContent.isEmpty) ||
        (textContent is Map && textContent.isEmpty)) {
      continue;
    }

    // final subfolder = 'Model';

    // ✅ Safe label extraction
    final rawLabel = item['label'];
    final safeLabel =
        (rawLabel is String && rawLabel.trim().isNotEmpty)
            ? rawLabel
            : 'UnnamedModel';

    final fileName = safeLabel.toLowerCase();
    final modelClassName = "${safeLabel.toString().replaceAll(" ", "")}Model";

    String generated;

    if (textContent is List && textContent.isNotEmpty) {
      if (textContent.first is Map<String, dynamic>) {
        generated = generateClass(
          modelClassName,
          textContent.first as Map<String, dynamic>,
        );
      } else if (textContent.first is Map) {
        generated = generateClass(
          modelClassName,
          Map<String, dynamic>.from(textContent.first),
        );
      } else {
        generated = generateClass(modelClassName, {});
      }
    } else if (textContent is Map<String, dynamic>) {
      generated = generateClass(modelClassName, textContent);
    } else if (textContent is Map) {
      generated = generateClass(
        modelClassName,
        Map<String, dynamic>.from(textContent),
      );
    } else {
      generated = generateClass(modelClassName, {});
    }

    String folderPath = "lib/features/$baseName/model";

    fileDataArray.add({
      "folderPath": folderPath,
      "fileName": "${fileName.toString().replaceAll(" ", "_")}_model.dart",
      "textContent": generated,
    });
  }

  for (final item in fieldJson) {
    final textContent = item['dropdowndata'];

    // ✅ Skip if dropdowndata is null or empty
    if (textContent == null ||
        (textContent is List && textContent.isEmpty) ||
        (textContent is Map && textContent.isEmpty)) {
      continue;
    }

    // final subfolder = 'Model';

    // ✅ Safe label extraction
    final rawLabel = item['label'];
    final safeLabel =
        (rawLabel is String && rawLabel.trim().isNotEmpty)
            ? rawLabel
            : 'UnnamedModel';

    final fileName = safeLabel.toLowerCase().replaceAll(" ", "_");
    final modelClassName = safeLabel.toString().replaceAll(" ", "");

    String generatedEnrity;
    String generateModel;

    if (textContent is List && textContent.isNotEmpty) {
      if (textContent.first is Map<String, dynamic>) {
        generatedEnrity = generateEntityClass(
          '${modelClassName}Entity',
          textContent.first as Map<String, dynamic>,
          fileName,
        );
        generateModel = riverpodModelGenerateClass(
          modelClassName,
          textContent.first as Map<String, dynamic>,
          fileName,
        );
      } else if (textContent.first is Map) {
        generateModel = riverpodModelGenerateClass(
          modelClassName,
          textContent.first as Map<String, dynamic>,
          fileName,
        );

        generatedEnrity = generateEntityClass(
          '${modelClassName}Entity',
          Map<String, dynamic>.from(textContent.first),
          fileName,
        );
      } else {
        generateModel = riverpodModelGenerateClass(modelClassName, {}, '');

        generatedEnrity = generateEntityClass(modelClassName, {}, '');
      }
    } else if (textContent is Map<String, dynamic>) {
      generatedEnrity = generateEntityClass(
        '${modelClassName}Entity',
        textContent,
        fileName,
      );
      generateModel = riverpodModelGenerateClass(
        modelClassName,
        textContent,
        fileName,
      );
    } else if (textContent is Map) {
      generateModel = riverpodModelGenerateClass(
        modelClassName,
        Map<String, dynamic>.from(textContent),
        fileName,
      );

      generatedEnrity = generateEntityClass(
        '${modelClassName}Entity',
        Map<String, dynamic>.from(textContent),
        fileName,
      );
    } else {
      generatedEnrity = generateEntityClass(
        '${modelClassName}Entity',

        Map<String, dynamic>.from(textContent),
        fileName,
      );
      generateModel = riverpodModelGenerateClass(
        modelClassName,
        Map<String, dynamic>.from(textContent),
        fileName,
      );
    }

    String folderPathmodel = "lib/riverpod/features/$baseName/data/model";
    String folderPathentity = "lib/riverpod/features/$baseName/domain/entity";

    fileDataArray.add({
      "folderPath": folderPathmodel,
      "fileName": "${fileName.toString().replaceAll(" ", "_")}_model.dart",
      "textContent": generateModel,
    });
    fileDataArray.add({
      "folderPath": folderPathentity,
      "fileName": "${fileName.toString().replaceAll(" ", "_")}_entity.dart",
      "textContent": generatedEnrity,
    });
  }
  String riverpoddomaintrepository;
  riverpoddomaintrepository = generateRepositoryInterface(
    className,
    fieldJson,
    fileName,
  );
  String riverpoddomaintrepositoryimpl;
  riverpoddomaintrepositoryimpl = generateRepositoryImplInterface(
    className,
    fieldJson,
    fileName,
  );
  String riverpodpresentnotifier;
  riverpodpresentnotifier = generateNotifierImplInterface(
    className,
    fieldJson,
    fileName,
  );

  String riverpodApiservice;
  riverpodApiservice = generateapiserviceInterface();

  String riverpodlocator;
  riverpodlocator = generateLocaltorInterface(className, fieldJson, fileName);

  String riverpoddatasource;
  riverpoddatasource = generateDataSourceInterface(
    className,
    fieldJson,
    fileName,
  );
  String riverpodDataproviderSource;

  riverpodDataproviderSource = generateProviderInterface(
    className,
    fieldJson,
    fileName,
  );
  String riverpodviewSource;
  riverpodviewSource = generateriverpodviewClass(
    className,
    fieldJson,
    fileName,
  );

  String folderPathrapi = "lib/core/service";
  String folderPathreposirtory =
      "lib/riverpod/features/$baseName/domain/repository";
  String folderPathdatasource =
      "lib/riverpod/features/$baseName/data/dataSource";
  String folderPathLocator = "lib/riverpod/features/$baseName/domain/locator";
  String folderPathpresentnotifeir =
      "lib/riverpod/features/$baseName/presentation/controller";
  String folderPathpresentnotifeirprovider =
      "lib/riverpod/features/$baseName/presentation/provider";
  String folderPathpresentnotifeirscreen =
      "lib/riverpod/features/$baseName/presentation/view";
  String folderPathreposirtoryimpl =
      "lib/riverpod/features/$baseName/data/repositoryimpl";

  fileDataArray.add({
    "folderPath": folderPathpresentnotifeirscreen,
    "fileName":
        "${fileName.toString().toLowerCase().replaceAll(" ", "_")}_view.dart",
    "textContent": riverpodviewSource,
  });

  fileDataArray.add({
    "folderPath": folderPathpresentnotifeirprovider,
    "fileName":
        "${fileName.toString().toLowerCase().replaceAll(" ", "_")}_provider.dart",
    "textContent": riverpodDataproviderSource,
  });

  fileDataArray.add({
    "folderPath": folderPathdatasource,
    "fileName":
        "${fileName.toString().toLowerCase().replaceAll(" ", "_")}_data_source.dart",
    "textContent": riverpoddatasource,
  });

  fileDataArray.add({
    "folderPath": folderPathLocator,
    "fileName":
        "${fileName.toString().toLowerCase().replaceAll(" ", "_")}_locator.dart",
    "textContent": riverpodlocator,
  });

  fileDataArray.add({
    "folderPath": folderPathrapi,
    "fileName": "api_service.dart",
    "textContent": riverpodApiservice,
  });

  fileDataArray.add({
    "folderPath": folderPathreposirtory,
    "fileName":
        "${fileName.toString().toLowerCase().replaceAll(" ", "_")}_repository.dart",
    "textContent": riverpoddomaintrepository,
  });
  fileDataArray.add({
    "folderPath": folderPathreposirtoryimpl,
    "fileName":
        "${fileName.toString().toLowerCase().replaceAll(" ", "_")}_repositoryimpl.dart",
    "textContent": riverpoddomaintrepositoryimpl,
  });
  fileDataArray.add({
    "folderPath": folderPathpresentnotifeir,
    "fileName":
        "${fileName.toString().toLowerCase().replaceAll(" ", "_")}_notifier.dart",
    "textContent": riverpodpresentnotifier,
  });




  // ... then jsonEncode and save ...

  String jsonData = jsonEncode(
    fileDataArray,
  ); // still an array, but with one item

  js.context.callMethod("saveMultipleFilesToFolders", [jsonData]);
}
