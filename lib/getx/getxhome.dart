// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'dart:js' as js;
import 'dart:convert';

class GetxMultiFileDownloader extends StatefulWidget {
  const GetxMultiFileDownloader({super.key});

  @override
  State<GetxMultiFileDownloader> createState() => _GetxMultiFileDownloaderState();
}

class _GetxMultiFileDownloaderState extends State<GetxMultiFileDownloader> {
  final TextEditingController mainController = TextEditingController();
  final TextEditingController submenuController = TextEditingController();

  // List to hold the logical structure for file generation
  List<Map<String, String>> logicalFiles = [];

  void generateFilesStructure(String baseName) {
    logicalFiles = [
      {
        "layer": "motorhome",
        "subfolder": "bindings",
        "textContent": "This is datasource content for $baseName.",
        "fileName": "${baseName.toLowerCase()}_datasource.dart",
      },
      {
        "layer": "motorhome",
        "subfolder": "controllers",
        "textContent": "This is repository implementation for $baseName.",
        "fileName": "${baseName.toLowerCase()}_repository_impl.dart",
      },
      {
        "layer": "motorhome",
        "subfolder": "models",
        "textContent": "This is locator content for $baseName.",
        "fileName": "${baseName.toLowerCase()}_locator.dart",
      },
      {
        "layer": "motorhome",
        "subfolder": "repository",
        "textContent": "This is repository content for $baseName.",
        "fileName": "${baseName.toLowerCase()}_repository.dart",
      },
      {
        "layer": "motorhome",
        "subfolder": "views",
        "textContent": "This is controller content for $baseName.",
        "fileName": "${baseName.toLowerCase()}_controller.dart",
      },
      // {
      //   "layer": "presentation",
      //   "subfolder": "page",
      //   "textContent": "This is page content for $baseName.",
      //   "fileName": "${baseName.toLowerCase()}_page.dart"
      // },
   
    ];
  }

  void saveMultipleFiles() {
    String baseName = mainController.text.trim();
    String subfoldername = submenuController.text.trim();

    if (baseName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid name')),
      );
      return;
    }

    generateFilesStructure(submenuController.text.trim());

    List<Map<String, String>> fileDataArray = logicalFiles.map((item) {
      String folderPath =
          "lib/features/$baseName/$subfoldername/${item['subfolder']}";
      // String folderPath =
      //     "lib/features/$baseName/${item['layer']}/${item['subfolder']}";
      return {
        "folderPath": folderPath,
        // "folderPath": folderPath,
        "fileName": item["fileName"]!,
        "textContent": item["textContent"]!,
      };
    }).toList();

    String jsonData = jsonEncode(fileDataArray);

    js.context.callMethod("saveMultipleFilesToFolders", [jsonData]);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AUTOMATION TOOL KIT',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: mainController,
                decoration: InputDecoration(
                  labelText: 'Enter Product Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: submenuController,
                decoration: InputDecoration(
                  labelText: 'Enter Screen Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: saveMultipleFiles,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Generate Files"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
