import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/core/component_engine/models/api_config.dart';

class RevoAuthManager extends ConsumerWidget {
  final ApiConfig config;
  final ValueChanged<ApiConfig> onConfigUpdated;

  const RevoAuthManager({
    super.key,
    required this.config,
    required this.onConfigUpdated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authTypes = ['Inherit', 'None', 'Bearer Token', 'Basic Auth', 'API Key', 'OAuth2'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDropdown(
          label: "Authorization Type",
          value: config.authentication,
          options: authTypes,
          onChanged: (val) {
            onConfigUpdated(config.copyWith(authentication: val ?? 'None'));
          },
        ),
        if (config.authentication == 'Inherit') ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: RevoTheme.cardBorder.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "This endpoint inherits its base URL, headers, and authentication parameters directly from its parent collection folder.",
              style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontStyle: FontStyle.italic),
            ),
          ),
        ] else if (config.authentication == 'Bearer Token') ...[
          _buildTextField(
            label: "Token",
            value: config.authPassword,
            onChanged: (val) {
              onConfigUpdated(config.copyWith(authPassword: val));
            },
          ),
          const SizedBox(height: 4),
          // JWT Auto-Refresh Configuration
          Card(
            color: Colors.black.withValues(alpha: 0.2),
            child: ExpansionTile(
              title: Text(
                "JWT Auto-Refresh Settings",
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
              ),
              leading: const Icon(Icons.refresh_rounded, size: 14, color: Colors.blueAccent),
              childrenPadding: const EdgeInsets.all(12),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Enable Auto-Refresh Interceptor",
                      style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                    ),
                    Switch(
                      value: config.jwtRefreshEnabled,
                      onChanged: (v) {
                        onConfigUpdated(config.copyWith(jwtRefreshEnabled: v));
                      },
                    ),
                  ],
                ),
                if (config.jwtRefreshEnabled) ...[
                  const SizedBox(height: 8),
                  _buildTextField(
                    label: "Refresh Token Endpoint URL",
                    value: config.jwtRefreshUrl,
                    hint: "/v1/auth/refresh",
                    onChanged: (val) {
                      onConfigUpdated(config.copyWith(jwtRefreshUrl: val));
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: "Interval (Minutes)",
                          value: config.jwtRefreshInterval.toString(),
                          onChanged: (val) {
                            final parsed = int.tryParse(val) ?? 30;
                            onConfigUpdated(config.copyWith(jwtRefreshInterval: parsed));
                          },
                        ),
                      ),
                    ],
                  ),
                  _buildTextField(
                    label: "Refresh Request Body Template (JSON)",
                    value: config.jwtRefreshBody,
                    hint: '{"refresh_token": "{{refreshToken}}"}',
                    onChanged: (val) {
                      onConfigUpdated(config.copyWith(jwtRefreshBody: val));
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: "Access Token JSON Path",
                          value: config.jwtAccessTokenPath,
                          onChanged: (val) {
                            onConfigUpdated(config.copyWith(jwtAccessTokenPath: val));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          label: "Refresh Token JSON Path",
                          value: config.jwtRefreshTokenPath,
                          onChanged: (val) {
                            onConfigUpdated(config.copyWith(jwtRefreshTokenPath: val));
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ] else if (config.authentication == 'Basic Auth') ...[
          _buildTextField(
            label: "Username",
            value: config.authUsername,
            onChanged: (val) {
              onConfigUpdated(config.copyWith(authUsername: val));
            },
          ),
          _buildTextField(
            label: "Password",
            value: config.authPassword,
            onChanged: (val) {
              onConfigUpdated(config.copyWith(authPassword: val));
            },
          ),
        ] else if (config.authentication == 'API Key') ...[
          _buildTextField(
            label: "API Key Header/Query Name",
            value: config.apiKeyName,
            onChanged: (val) {
              onConfigUpdated(config.copyWith(apiKeyName: val));
            },
          ),
          _buildTextField(
            label: "API Key Value",
            value: config.apiKeyValue,
            onChanged: (val) {
              onConfigUpdated(config.copyWith(apiKeyValue: val));
            },
          ),
          _buildDropdown(
            label: "Key Location",
            value: config.apiKeyLocation,
            options: const ['header', 'query'],
            onChanged: (val) {
              onConfigUpdated(config.copyWith(apiKeyLocation: val ?? 'header'));
            },
          ),
        ] else if (config.authentication == 'OAuth2') ...[
          _buildTextField(
            label: "OAuth2 Client Token URL",
            value: config.oauthTokenUrl,
            onChanged: (val) {
              onConfigUpdated(config.copyWith(oauthTokenUrl: val));
            },
          ),
          _buildTextField(
            label: "Client ID",
            value: config.oauthClientId,
            onChanged: (val) {
              onConfigUpdated(config.copyWith(oauthClientId: val));
            },
          ),
          _buildTextField(
            label: "Client Secret",
            value: config.oauthClientSecret,
            onChanged: (val) {
              onConfigUpdated(config.copyWith(oauthClientSecret: val));
            },
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    String? hint,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: value,
            onChanged: onChanged,
            style: GoogleFonts.inter(fontSize: 11),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: options.contains(value) ? value : options.first,
            onChanged: onChanged,
            isDense: true,
            style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textPrimary),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
          ),
        ],
      ),
    );
  }
}
