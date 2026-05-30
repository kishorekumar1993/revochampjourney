import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/core/component_engine/models/api_config.dart';

class RevoJsonBodyEditor extends StatelessWidget {
  final ApiConfig config;
  final ValueChanged<ApiConfig> onConfigUpdated;

  const RevoJsonBodyEditor({
    super.key,
    required this.config,
    required this.onConfigUpdated,
  });

  void _beautifyJson(BuildContext context) {
    try {
      if (config.requestBody.trim().isEmpty) return;
      final decoded = json.decode(config.requestBody);
      final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
      onConfigUpdated(config.copyWith(requestBody: pretty));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JSON beautified successfully!'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid JSON formatting: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _validateJson(BuildContext context) {
    try {
      if (config.requestBody.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JSON body is empty (valid)'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      json.decode(config.requestBody);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JSON is valid!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSON Syntax Error: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              "Request Body (JSON)",
              style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _beautifyJson(context),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 20), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Beautify', style: TextStyle(fontSize: 10)),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _validateJson(context),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 20), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Validate', style: TextStyle(fontSize: 10)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: ValueKey('${config.id}_request_body_field'),
          initialValue: config.requestBody,
          onChanged: (val) {
            onConfigUpdated(config.copyWith(requestBody: val));
          },
          maxLines: 4,
          style: GoogleFonts.sourceCodePro(fontSize: 11, color: RevoTheme.textPrimary),
          decoration: const InputDecoration(
            isDense: true,
            hintText: '{\n  "key": "value"\n}',
            contentPadding: EdgeInsets.all(8),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
