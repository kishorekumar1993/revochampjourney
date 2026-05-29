import 'package:revojourneytryone/codegenerator/filegegnerator/journey_step_codegen.dart';

void generateDefaultLayout(
  StringBuffer buffer,
  JourneyStepCodegen stepMeta,
  String className,
) {
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
  buffer.writeln("              Center(");
  buffer.writeln("                child: ConstrainedBox(");
  buffer.writeln("                  constraints: const BoxConstraints(maxWidth: 720),");
  buffer.writeln("                  child: Container(");
  buffer.writeln("                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),");
  buffer.writeln("                    padding: const EdgeInsets.all(28),");
  buffer.writeln("                    decoration: BoxDecoration(");
  buffer.writeln("                      color: Colors.white,");
  buffer.writeln("                      borderRadius: BorderRadius.circular(20),");
  buffer.writeln("                      boxShadow: const [");
  buffer.writeln("                        BoxShadow(");
  buffer.writeln("                          color: Color(0x065B4FCF),");
  buffer.writeln("                          blurRadius: 30,");
  buffer.writeln("                          offset: Offset(0, 8),");
  buffer.writeln("                        ),");
  buffer.writeln("                      ],");
  buffer.writeln("                    ),");
  buffer.writeln("                    child: SingleChildScrollView(");
  buffer.writeln("                      child: _buildFormContent(context),");
  buffer.writeln("                    ),");
  buffer.writeln("                  ),");
  buffer.writeln("                ),");
  buffer.writeln("              ),");
  buffer.writeln("              _buildLoadingOverlay(),");
  buffer.writeln("            ],");
  buffer.writeln("          ),");
  buffer.writeln("        ),");
  buffer.writeln("      ),");
  buffer.writeln("    );");
}
