import 'package:revojourneytryone/codegenerator/filegegnerator/journey_step_codegen.dart';

void generateCarouselLayout(
  StringBuffer buffer,
  JourneyStepCodegen stepMeta,
  String className,
  List<dynamic> stepsList,
  int activeIdxClamp,
) {
  final total = stepsList.length;
  buffer.writeln("    final total = $total;");
  buffer.writeln("    final activeIdx = $activeIdxClamp;");
  buffer.writeln("    final hasPrev = activeIdx > 0;");
  buffer.writeln("    final hasNext = activeIdx < total - 1;");
  buffer.writeln("    final prevStepId = hasPrev ? _getStepId(activeIdx - 1) : '';");
  buffer.writeln("    final nextStepId = hasNext ? _getStepId(activeIdx + 1) : '';");
  buffer.writeln();
  buffer.writeln("    return Scaffold(");
  buffer.writeln("      backgroundColor: const Color(0xFFF0F0FF),");
  buffer.writeln("      appBar: AppBar(");
  buffer.writeln("        title: const Text('${stepMeta.escapedTitle}'),");
  buffer.writeln("        backgroundColor: Colors.white,");
  buffer.writeln("        foregroundColor: const Color(0xFF1A1A2E),");
  buffer.writeln("        elevation: 0,");
  buffer.writeln("        centerTitle: true,");
  buffer.writeln("      ),");
  buffer.writeln("      body: GestureDetector(");
  buffer.writeln("        onTap: () => FocusScope.of(context).unfocus(),");
  buffer.writeln("        child: SafeArea(");
  buffer.writeln("          child: Stack(");
  buffer.writeln("            children: [");
  buffer.writeln("              Column(");
  buffer.writeln("                children: [");
  buffer.writeln("                  const SizedBox(height: 16),");
  buffer.writeln("                  _buildCarouselIndicator(total, activeIdx),");
  buffer.writeln("                  Expanded(");
  buffer.writeln("                    child: Center(");
  buffer.writeln("                      child: SingleChildScrollView(");
  buffer.writeln("                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),");
  buffer.writeln("                        child: Row(");
  buffer.writeln("                          mainAxisAlignment: MainAxisAlignment.center,");
  buffer.writeln("                          children: [");
  buffer.writeln("                            if (MediaQuery.of(context).size.width > 640) ...[");
  buffer.writeln("                              _buildNavigationChevron(");
  buffer.writeln("                                icon: Icons.chevron_left_rounded,");
  buffer.writeln("                                onTap: hasPrev ? () => Get.toNamed('/\$prevStepId') : null,");
  buffer.writeln("                              ),");
  buffer.writeln("                              const SizedBox(width: 24),");
  buffer.writeln("                            ],");
  buffer.writeln("                            ConstrainedBox(");
  buffer.writeln("                              constraints: const BoxConstraints(maxWidth: 620),");
  buffer.writeln("                              child: Container(");
  buffer.writeln("                                padding: const EdgeInsets.all(32),");
  buffer.writeln("                                decoration: BoxDecoration(");
  buffer.writeln("                                  color: Colors.white,");
  buffer.writeln("                                  borderRadius: BorderRadius.circular(28),");
  buffer.writeln("                                  boxShadow: const [");
  buffer.writeln("                                    BoxShadow(");
  buffer.writeln("                                      color: Color(0x0C5B4FCF),");
  buffer.writeln("                                      blurRadius: 35,");
  buffer.writeln("                                      offset: Offset(0, 8),");
  buffer.writeln("                                    ),");
  buffer.writeln("                                  ],");
  buffer.writeln("                                ),");
  buffer.writeln("                                child: _buildFormContent(context),");
  buffer.writeln("                              ),");
  buffer.writeln("                            ),");
  buffer.writeln("                            if (MediaQuery.of(context).size.width > 640) ...[");
  buffer.writeln("                              const SizedBox(width: 24),");
  buffer.writeln("                              _buildNavigationChevron(");
  buffer.writeln("                                icon: Icons.chevron_right_rounded,");
  buffer.writeln("                                onTap: hasNext ? () => Get.toNamed('/\$nextStepId') : null,");
  buffer.writeln("                              ),");
  buffer.writeln("                            ],");
  buffer.writeln("                          ],");
  buffer.writeln("                        ),");
  buffer.writeln("                      ),");
  buffer.writeln("                    ),");
  buffer.writeln("                  ),");
  buffer.writeln("                ],");
  buffer.writeln("              ),");
  buffer.writeln("              _buildLoadingOverlay(),");
  buffer.writeln("            ],");
  buffer.writeln("          ),");
  buffer.writeln("        ),");
  buffer.writeln("      ),");
  buffer.writeln("    );");
}

void generateCarouselHelpers(StringBuffer buffer) {
  buffer.writeln("  Widget _buildNavigationChevron({required IconData icon, VoidCallback? onTap}) {");
  buffer.writeln("    final disabled = onTap == null;");
  buffer.writeln("    return GestureDetector(");
  buffer.writeln("      onTap: onTap,");
  buffer.writeln("      child: Container(");
  buffer.writeln("        width: 44,");
  buffer.writeln("        height: 44,");
  buffer.writeln("        decoration: BoxDecoration(");
  buffer.writeln("          color: disabled ? Colors.grey.shade100 : const Color(0xFFEEECFD),");
  buffer.writeln("          shape: BoxShape.circle,");
  buffer.writeln("          border: Border.all(color: disabled ? Colors.transparent : const Color(0xFF5B4FCF).withValues(alpha: 0.2)),");
  buffer.writeln("        ),");
  buffer.writeln("        child: Icon(");
  buffer.writeln("          icon,");
  buffer.writeln("          color: disabled ? Colors.grey.shade400 : const Color(0xFF5B4FCF),");
  buffer.writeln("          size: 24,");
  buffer.writeln("        ),");
  buffer.writeln("      ),");
  buffer.writeln("    );");
  buffer.writeln("  }");
  buffer.writeln();

  buffer.writeln("  Widget _buildCarouselIndicator(int total, int activeIdx) {");
  buffer.writeln("    if (total <= 1) return const SizedBox.shrink();");
  buffer.writeln("    return Row(");
  buffer.writeln("      mainAxisAlignment: MainAxisAlignment.center,");
  buffer.writeln("      children: List.generate(total, (index) {");
  buffer.writeln("        final isActive = index == activeIdx;");
  buffer.writeln("        final isCompleted = index < activeIdx;");
  buffer.writeln("        return AnimatedContainer(");
  buffer.writeln("          duration: const Duration(milliseconds: 200),");
  buffer.writeln("          width: isActive ? 24 : 8,");
  buffer.writeln("          height: 8,");
  buffer.writeln("          margin: const EdgeInsets.symmetric(horizontal: 4),");
  buffer.writeln("          decoration: BoxDecoration(");
  buffer.writeln("            color: isActive");
  buffer.writeln("                ? const Color(0xFF5B4FCF)");
  buffer.writeln("                : isCompleted");
  buffer.writeln("                    ? const Color(0xFF5B4FCF).withValues(alpha: 0.4)");
  buffer.writeln("                    : const Color(0xFFE4E6F0),");
  buffer.writeln("            borderRadius: BorderRadius.circular(4),");
  buffer.writeln("          ),");
  buffer.writeln("        );");
  buffer.writeln("      }),");
  buffer.writeln("    );");
  buffer.writeln("  }");
  buffer.writeln();
}
