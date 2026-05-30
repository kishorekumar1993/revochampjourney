import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/core/component_engine/models/api_config.dart';

class RevoMockingPanel extends StatelessWidget {
  final ApiConfig config;
  final ValueChanged<ApiConfig> onConfigUpdated;

  const RevoMockingPanel({
    super.key,
    required this.config,
    required this.onConfigUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.03),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.sim_card_outlined, size: 14, color: Colors.amber),
              const SizedBox(width: 6),
              Text(
                "API Mocking / Sandbox Mode",
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
              ),
              const Spacer(),
              Switch(
                value: config.isMockEnabled,
                onChanged: (v) {
                  onConfigUpdated(config.copyWith(isMockEnabled: v));
                },
              ),
            ],
          ),
          if (config.isMockEnabled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text("Delay: ", style: GoogleFonts.inter(fontSize: 9, color: RevoTheme.textSecondary)),
                Expanded(
                  child: Slider(
                    value: config.mockDelay.toDouble().clamp(0.0, 10.0),
                    min: 0.0,
                    max: 10.0,
                    divisions: 10,
                    label: '${config.mockDelay}s',
                    onChanged: (val) {
                      onConfigUpdated(config.copyWith(mockDelay: val.toInt()));
                    },
                  ),
                ),
                Text('${config.mockDelay}s', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            _buildTextField(
              label: "Mock Response Body (JSON)",
              value: config.mockResponse,
              hint: '{"status": "mocked"}',
              onChanged: (val) {
                onConfigUpdated(config.copyWith(mockResponse: val));
              },
            ),
            const SizedBox(height: 4),
            _buildTextField(
              label: "Trigger Failure Message (Empty for 200 Success)",
              value: config.mockError,
              hint: "e.g. Unauthorized access error",
              onChanged: (val) {
                onConfigUpdated(config.copyWith(mockError: val));
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          style: GoogleFonts.inter(fontSize: 11),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
        ),
      ],
    );
  }
}
