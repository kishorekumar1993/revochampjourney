import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../journey_builder/data/models.dart';

class _IT {
  static const brand = Color(0xFF5B4FCF);
  static const textDark = Color(0xFF1A1A2E);
  static const textMid = Color(0xFF6B7280);
  static const border = Color(0xFFE4E6F0);
  static const bg = Color(0xFFF7F6FB);
  static const success = Color(0xFF22C55E);
  static const rightBubble = Color(0xFFEEECFD);
}

class ChatRunnerView extends StatelessWidget {
  final JourneyConfig cfg;
  final JourneyStep activeStep;
  final int activeIdx;
  final Map<String, dynamic> formValues;
  final Widget Function(BuildContext, {bool isMobile}) formContentBuilder;
  final Widget Function() bottomBarBuilder;
  final Function(int)? onStepTap;

  const ChatRunnerView({
    super.key,
    required this.cfg,
    required this.activeStep,
    required this.activeIdx,
    required this.formValues,
    required this.formContentBuilder,
    required this.bottomBarBuilder,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 640;

    return Column(
      children: [
        Expanded(
          child: Container(
            color: _IT.bg,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                // Welcome message
                _buildSystemMessage('Welcome to ${cfg.journeyName}! I\'ll guide you step-by-step through the process. Let\'s get started.'),
                const SizedBox(height: 20),
                
                // History of completed steps as chat bubbles
                ...List.generate(activeIdx, (idx) {
                  final step = cfg.steps[idx];
                  return Column(
                    children: [
                      _buildBotPrompt('First, please complete the **${step.title}** section.', step.title),
                      const SizedBox(height: 12),
                      _buildUserResponseSummary(step, idx),
                      const SizedBox(height: 20),
                    ],
                  );
                }),

                // Active step card chat bubble
                _buildBotPrompt(
                  'Great! Now, let\'s fill in the **${activeStep.title}** details below:',
                  activeStep.title,
                ),
                const SizedBox(height: 12),
                
                // Embedded active form inside a conversational container
                _buildActiveFormBubble(context, isMobile),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
        bottomBarBuilder(),
      ],
    );
  }

  Widget _buildSystemMessage(String text) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _IT.border, width: 0.8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: _IT.textMid,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBotPrompt(String prompt, String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: _IT.brand,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RevoBot',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _IT.brand,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prompt,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _IT.textDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserResponseSummary(JourneyStep step, int idx) {
    // Collect some key values
    final fields = _flattenFields(step.fields)
        .where((f) => f.type.toLowerCase() != 'divider' && f.type.toLowerCase() != 'label')
        .toList();
        
    final filledFields = fields.where((f) {
      final val = formValues[f.id];
      return val != null && val.toString().trim().isNotEmpty;
    }).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            margin: const EdgeInsets.only(left: 48),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _IT.rightBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: _IT.brand.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: _IT.success, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Completed ${step.title}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _IT.brand,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (filledFields.isEmpty)
                  Text(
                    'No entries required',
                    style: GoogleFonts.poppins(fontSize: 12, color: _IT.textMid),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: filledFields.take(2).map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          '${f.label}: ${formValues[f.id]}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _IT.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                if (filledFields.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '+ ${filledFields.length - 2} more fields',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: _IT.textMid,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    if (onStepTap != null) onStepTap!(idx);
                  },
                  child: Text(
                    'Edit Section',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _IT.brand,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _IT.brand.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded, color: _IT.brand, size: 16),
        ),
      ],
    );
  }

  Widget _buildActiveFormBubble(BuildContext context, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 42), // Align with RevoBot prompt
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _IT.brand, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _IT.brand.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: formContentBuilder(context, isMobile: isMobile),
          ),
        ),
      ],
    );
  }

  List<JourneyField> _flattenFields(List<JourneyField> src) {
    final res = <JourneyField>[];
    for (final f in src) {
      res.add(f);
      if (f.nestedFields != null) {
        res.addAll(_flattenFields(f.nestedFields!));
      }
    }
    return res;
  }
}
