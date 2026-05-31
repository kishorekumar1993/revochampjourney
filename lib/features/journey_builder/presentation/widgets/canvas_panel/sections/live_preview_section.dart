import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_validation_manager.dart';
import 'live_preview_mockups.dart';

class LivePreviewSection extends ConsumerStatefulWidget {
  final JourneyStep step;
  final Map<String, dynamic> formValues;
  final String? previousStepId;
  final String? nextStepId;
  final bool isMobilePreview;

  const LivePreviewSection({
    super.key,
    required this.step,
    required this.formValues,
    required this.previousStepId,
    required this.nextStepId,
    required this.isMobilePreview,
  });

  @override
  ConsumerState<LivePreviewSection> createState() => _LivePreviewSectionState();
}

class _LivePreviewSectionState extends ConsumerState<LivePreviewSection> with LivePreviewMockups {
  @override
  void initState() {
    super.initState();
    initMockupRegistry();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isMobilePreview) {
      // Laptop / Desktop Preview
      return Expanded(
        flex: 4,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: RevoTheme.cardBorder, width: 1),
            ),
            color: RevoTheme.background,
          ),
          padding: const EdgeInsets.all(20.0),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Laptop screen bezel
                Container(
                  width: 480,
                  height: 330,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: RevoTheme.cardBorder, width: 8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Web browser window header
                      Container(
                        height: 28,
                        color: RevoTheme.sidebarBackground,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            // Dots
                            Row(
                              children: [
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.amberAccent, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // URL Address Bar
                            Expanded(
                              child: Container(
                                height: 18,
                                decoration: BoxDecoration(
                                  color: RevoTheme.background,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  children: [
                                    Icon(Icons.lock_outline_rounded, size: 10, color: RevoTheme.success),
                                    const SizedBox(width: 4),
                                    Text(
                                      "revojourneytryone.com/run/journey",
                                      style: TextStyle(fontSize: 9, color: RevoTheme.textSecondary.withValues(alpha:0.7)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Browser Web Viewport
                      Expanded(
                        child: Container(
                          color: RevoTheme.background,
                          padding: const EdgeInsets.all(12),
                          alignment: Alignment.center,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 360,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: RevoTheme.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: RevoTheme.cardBorder, width: 1),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1F000000),
                                        blurRadius: 12,
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.step.title,
                                        style: TextStyle(fontFamily: 'Outfit',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: RevoTheme.textPrimary,
                                        ),
                                      ),
                                      if (widget.step.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.step.description,
                                          style: TextStyle(fontFamily: 'Inter',
                                            fontSize: 9,
                                            color: RevoTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),

                                      // Fields Mockups
                                      ...widget.step.fields.map((field) {
                                        final isVisible = EngineHelper.isFieldVisible(field, widget.formValues);
                                        if (!isVisible) return const SizedBox.shrink();

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 10.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (field.type != 'divider') ...[
                                                Row(
                                                  children: [
                                                    Text(
                                                      field.label,
                                                      style: TextStyle(fontFamily: 'Inter',
                                                        fontSize: 9,
                                                        color: RevoTheme.textSecondary,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    if (field.required)
                                                      const Text(" *", style: TextStyle(color: Colors.red, fontSize: 9)),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                              buildMobileFieldMockup(field, widget.formValues),
                                            ],
                                          ),
                                        );
                                      }),

                                      const SizedBox(height: 12),
                                      // Navigation Actions Mockup
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (widget.previousStepId != null)
                                            OutlinedButton(
                                              onPressed: () {
                                                ref.read(activeStepIdProvider.notifier).state = widget.previousStepId!;
                                                ref.read(selectedFieldIdProvider.notifier).state = null;
                                              },
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: const Text("Back", style: TextStyle(fontSize: 9)),
                                            )
                                          else
                                            const SizedBox.shrink(),
                                          ElevatedButton(
                                            onPressed: () {
                                              if (widget.nextStepId != null) {
                                                ref.read(activeStepIdProvider.notifier).state = widget.nextStepId!;
                                                ref.read(selectedFieldIdProvider.notifier).state = null;
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              widget.nextStepId == null ? "Submit" : "Next",
                                              style: const TextStyle(fontSize: 9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Laptop Hinge and base plate
                Container(
                  width: 500,
                  height: 8,
                  decoration: BoxDecoration(
                    color: RevoTheme.isDark ? const Color(0xFF3A3A4E) : const Color(0xFFCBD5E1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ),
                Container(
                  width: 530,
                  height: 10,
                  decoration: BoxDecoration(
                    color: RevoTheme.isDark ? const Color(0xFF222234) : const Color(0xFF94A3B8),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: RevoTheme.isDark ? Colors.black38 : Colors.white60,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Default Mobile View
    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: RevoTheme.cardBorder, width: 1),
          ),
          color: RevoTheme.background,
        ),
        padding: const EdgeInsets.all(24.0),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            width: 250,
            height: 520,
            decoration: BoxDecoration(
              color: RevoTheme.isDark ? Colors.black : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: RevoTheme.isDark ? RevoTheme.cardBorder : const Color(0xFF334155), width: 8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                color: RevoTheme.background,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    // Mobile status indicator bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "9:41",
                          style: TextStyle(fontFamily: 'Inter',
                            fontSize: 10,
                            color: RevoTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.wifi, size: 10, color: RevoTheme.textPrimary),
                            const SizedBox(width: 4),
                            Icon(Icons.signal_cellular_4_bar_rounded, size: 10, color: RevoTheme.textPrimary),
                            const SizedBox(width: 4),
                            Icon(Icons.battery_5_bar_rounded, size: 10, color: RevoTheme.textPrimary),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Screen Title
                    Text(
                      widget.step.title,
                      style: TextStyle(fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: RevoTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.step.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.step.description,
                        style: TextStyle(fontFamily: 'Inter',
                          fontSize: 9,
                          color: RevoTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Fields Renders inside Simulator
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.step.fields.length,
                        itemBuilder: (context, index) {
                          final field = widget.step.fields[index];
                          final isVisible = EngineHelper.isFieldVisible(field, widget.formValues);
                          if (!isVisible) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (field.type != 'divider') ...[
                                  Row(
                                    children: [
                                      Text(
                                        field.label,
                                        style: TextStyle(fontFamily: 'Inter',
                                          fontSize: 10,
                                          color: RevoTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (field.required)
                                        const Text(" *", style: TextStyle(color: Colors.red, fontSize: 10)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                buildMobileFieldMockup(field, widget.formValues),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Button actions inside simulator
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.nextStepId != null) {
                            ref.read(activeStepIdProvider.notifier).state = widget.nextStepId!;
                            ref.read(selectedFieldIdProvider.notifier).state = null;
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          widget.nextStepId == null ? "Submit" : "Next",
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
