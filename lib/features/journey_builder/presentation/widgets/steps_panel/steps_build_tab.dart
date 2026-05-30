import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/data/models.dart';
import 'build_audit_provider.dart';

class StepsBuildTab extends ConsumerStatefulWidget {
  final JourneyConfig config;

  const StepsBuildTab({
    super.key,
    required this.config,
  });

  @override
  ConsumerState<StepsBuildTab> createState() => _StepsBuildTabState();
}

class _StepsBuildTabState extends ConsumerState<StepsBuildTab> {
  bool _compiling = false;
  bool _buildRan = false;

  Widget _buildIssueTile(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 6, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textPrimary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auditResult = ref.watch(buildAuditProvider);
    final buildErrors = auditResult.errors;
    final buildWarnings = auditResult.warnings;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Compile & Verify",
            style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            "Validate structural integrity, configurations, and API integrity checks.",
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: RevoTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _compiling
                ? null
                : () async {
                    setState(() {
                      _compiling = true;
                      _buildRan = false;
                    });
                    await Future.delayed(const Duration(milliseconds: 1000));
                    if (!mounted) return;
                    setState(() {
                      _compiling = false;
                      _buildRan = true;
                    });
                  },
            icon: _compiling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.flash_on_rounded, size: 16, color: Colors.white),
            label: Text(_compiling ? "Compiling..." : "Run Journey Audit", style: const TextStyle(color: Colors.white)),
          ),

          const SizedBox(height: 20),
          Expanded(
            child: _compiling
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Compiling rules and paths...", style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textSecondary)),
                        const SizedBox(height: 12),
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      ],
                    ),
                  )
                : !_buildRan
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.terminal_rounded, size: 36, color: RevoTheme.textSecondary.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text(
                              "Click button above to compile and run build checks.",
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary, height: 1.4),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: buildErrors.isEmpty ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: buildErrors.isEmpty ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    buildErrors.isEmpty ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
                                    color: buildErrors.isEmpty ? Colors.greenAccent : Colors.redAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          buildErrors.isEmpty ? "Build Verified Successfully" : "Build Verification Failed",
                                          style: TextStyle(fontFamily: 'Inter', 
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: buildErrors.isEmpty ? Colors.greenAccent : Colors.redAccent,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${buildErrors.length} Errors, ${buildWarnings.length} Warnings found.",
                                          style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            if (buildErrors.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text("Errors (${buildErrors.length})", style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                              const SizedBox(height: 6),
                              ...buildErrors.map((err) => _buildIssueTile(err, Colors.redAccent)),
                            ],

                            if (buildWarnings.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text("Warnings (${buildWarnings.length})", style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                              const SizedBox(height: 6),
                              ...buildWarnings.map((warn) => _buildIssueTile(warn, Colors.orangeAccent)),
                            ],

                            if (buildErrors.isEmpty && buildWarnings.isEmpty) ...[
                              const SizedBox(height: 40),
                              Icon(Icons.done_all_rounded, size: 48, color: RevoTheme.success.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                "Excellent! All structural logic is verified and compiled cleanly.",
                                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.success, height: 1.4),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
