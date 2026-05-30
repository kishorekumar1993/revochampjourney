import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/core/component_engine/models/api_config.dart';
import 'package:revojourneytryone/features/visual_builder/application/studio_providers.dart';
import 'env_selector.dart';

class RevoApiAddressBar extends ConsumerWidget {
  final ApiConfig config;
  final ValueChanged<ApiConfig> onConfigUpdated;
  final bool isTesting;
  final VoidCallback onSendPressed;

  const RevoApiAddressBar({
    super.key,
    required this.config,
    required this.onConfigUpdated,
    required this.isTesting,
    required this.onSendPressed,
  });

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.blue;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnv = ref.watch(activeEnvironmentProvider);
    final envVars = ref.watch(envVariablesProvider);
    final appVars = ref.watch(appVariablesProvider);

    // Resolve final URL for preview
    String baseUrl = config.baseUrl;
    if (config.inheritParentSettings && config.collectionId.isNotEmpty) {
      final collections = ref.read(apiCollectionsProvider);
      final parent = collections.firstWhere((c) => c.id == config.collectionId, orElse: () => ApiCollection(id: '', name: ''));
      if (parent.id.isNotEmpty && parent.baseUrl.isNotEmpty) {
        baseUrl = parent.baseUrl;
      }
    }

    final fullRawPath = '$baseUrl${config.endpoint}';
    final missingVars = RevoEnvSelector.findMissingVariables(
      text: fullRawPath,
      activeEnv: activeEnv,
      envVariables: envVars,
      appVariables: appVars,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // 1. Method Selector
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: _getMethodColor(config.method).withValues(alpha: 0.1),
                border: Border.all(color: _getMethodColor(config.method).withValues(alpha: 0.3)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                ),
              ),
              child: DropdownButton<String>(
                value: config.method,
                underline: const SizedBox(),
                isDense: true,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getMethodColor(config.method),
                ),
                dropdownColor: RevoTheme.sidebarBackground,
                onChanged: (val) {
                  if (val != null) {
                    onConfigUpdated(config.copyWith(method: val));
                  }
                },
                items: const ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'].map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
              ),
            ),
            // 2. URL Path TextFormField
            Expanded(
              child: SizedBox(
                height: 38,
                child: TextFormField(
                  key: ValueKey('${config.id}_path_field'),
                  initialValue: config.endpoint,
                  onChanged: (val) {
                    onConfigUpdated(config.copyWith(endpoint: val));
                  },
                  style: GoogleFonts.sourceCodePro(fontSize: 11, color: RevoTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: "/v1/users/profile",
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                        color: missingVars.isNotEmpty ? Colors.redAccent : RevoTheme.cardBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                        color: missingVars.isNotEmpty ? Colors.redAccent : RevoTheme.cardBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                        color: missingVars.isNotEmpty ? Colors.redAccent : RevoTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 3. Send / Test Button
            SizedBox(
              height: 38,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: isTesting ? null : onSendPressed,
                icon: isTesting
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 12),
                label: Text(
                  "Send",
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        // Live previews & warnings
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                "Inherits: ${config.inheritParentSettings ? (config.collectionId.isNotEmpty ? 'Base URL from folder' : 'No folder') : 'Manual URL Override'}",
                style: GoogleFonts.inter(fontSize: 9, color: RevoTheme.textSecondary),
              ),
            ),
            if (missingVars.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 10, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  Text(
                    "Missing keys: ${missingVars.join(', ')}",
                    style: GoogleFonts.inter(fontSize: 9, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
