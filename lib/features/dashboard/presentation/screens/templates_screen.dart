import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../journey_builder/data/models.dart';
import '../../../journey_builder/presentation/providers/journey_provider.dart';

class RevoTemplatesScreen extends ConsumerWidget {
  final VoidCallback onTemplateLoaded;

  const RevoTemplatesScreen({
    super.key,
    required this.onTemplateLoaded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = [
      {
        'id': 'motor_insurance',
        'title': 'Motor Insurance Journey',
        'badge': 'Featured',
        'badgeColor': RevoTheme.primaryLight,
        'description': 'A comprehensive insurance checkout flow with sections for personal details, vehicle specs, nominee declarations, documentation uploading, and premium verification.',
        'icon': Icons.directions_car_filled_outlined,
        'stepsCount': 7,
        'config': getInitialJourney(), // This helper returns the default motor insurance journey
      },
      {
        'id': 'kyc_onboarding',
        'title': 'User KYC Onboarding',
        'badge': 'Popular',
        'badgeColor': RevoTheme.secondary,
        'description': 'A standard customer identification verify flow, collecting applicant details, scanned ID proofs (PAN/Aadhaar), selfie uploads, and final verification checklists.',
        'icon': Icons.badge_outlined,
        'stepsCount': 4,
        'config': _getKycConfig(),
      },
      {
        'id': 'loan_application',
        'title': 'Personal Loan Application',
        'badge': 'Financial',
        'badgeColor': RevoTheme.accent,
        'description': 'A structured loan checking pipeline covering applicant information, employment classification, income statement PDF attachments, and bank disbursement accounts.',
        'icon': Icons.monetization_on_outlined,
        'stepsCount': 4,
        'config': _getLoanConfig(),
      },
      {
        'id': 'feedback_survey',
        'title': 'Service Feedback Survey',
        'badge': 'Utility',
        'badgeColor': RevoTheme.warning,
        'description': 'A lightweight user feedback collection form providing score selectors, detailed comments textareas, and email validation for representative follow-ups.',
        'icon': Icons.rate_review_outlined,
        'stepsCount': 3,
        'config': _getFeedbackConfig(),
      },
    ];

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Header
            Text(
              "Journey Templates",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: RevoTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Select a premade template structure to import and customize in the builder canvas.",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: RevoTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Templates Grid List
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.5,
                ),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final t = templates[index];
                  final color = t['badgeColor'] as Color;

                  return Container(
                    decoration: BoxDecoration(
                      color: RevoTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: RevoTheme.cardBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C000000),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row with Icon & Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color.withValues(alpha:0.4)),
                              ),
                              child: Icon(
                                t['icon'] as IconData,
                                color: color,
                                size: 24,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: color.withValues(alpha:0.4)),
                              ),
                              child: Text(
                                t['badge'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          t['title'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: RevoTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Description
                        Expanded(
                          child: Text(
                            t['description'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: RevoTheme.textSecondary,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bottom Actions Row (Steps Count & Use Button)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.layers_outlined, size: 14, color: RevoTheme.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  "${t['stepsCount']} Steps",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: RevoTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                final config = t['config'] as JourneyConfig;
                                // Reset journey provider config
                                ref.read(journeyConfigProvider.notifier).updateFromJson(json.encode(config.toJson()));
                                
                                // Show message and trigger navigate back to builder
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Loaded template: ${t['title']} successfully!"),
                                    backgroundColor: RevoTheme.success,
                                  ),
                                );
                                onTemplateLoaded();
                              },
                              icon: const Icon(Icons.check_rounded, size: 14),
                              label: const Text("Use Template"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                backgroundColor: RevoTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generate premade configurations
  JourneyConfig _getKycConfig() {
    return JourneyConfig(
      journeyName: "User KYC Onboarding",
      version: "1.0.0",
      steps: [
        JourneyStep(
          id: "personal",
          title: "Identity Details",
          description: "Provide personal identification details",
          nextStep: "documents",
          fields: [
            JourneyField(id: "firstName", label: "First Name", type: "text", required: true, placeholder: "Enter first name"),
            JourneyField(id: "lastName", label: "Last Name", type: "text", required: true, placeholder: "Enter last name"),
            JourneyField(id: "panNumber", label: "PAN Card Number", type: "text", required: true, placeholder: "e.g. ABCDE1234F"),
          ],
          validations: [
            StepValidation(type: "required", field: "firstName", message: "First Name is required"),
            StepValidation(type: "required", field: "panNumber", message: "PAN Number is required"),
          ],
        ),
        JourneyStep(
          id: "documents",
          title: "Upload KYC Proofs",
          description: "Upload necessary documents for scanning validation",
          nextStep: "selfie",
          fields: [
            JourneyField(id: "panDoc", label: "PAN Card Image", type: "file", required: true),
            JourneyField(id: "aadhaarFront", label: "Aadhaar Card Front", type: "file", required: true),
          ],
        ),
        JourneyStep(
          id: "selfie",
          title: "Facial Verification Selfie",
          description: "Upload a clear picture matching your documents",
          nextStep: "confirmation",
          fields: [
            JourneyField(id: "selfieDoc", label: "Facial Selfie Image", type: "file", required: true),
          ],
        ),
        JourneyStep(
          id: "confirmation",
          title: "Review & Sign Checklist",
          description: "Verify declarations before final submission",
          fields: [
            JourneyField(id: "kycChecked", label: "I verify that the details provided are correct", type: "switch", required: true, defaultValue: "false"),
          ],
        ),
      ],
    );
  }

  JourneyConfig _getLoanConfig() {
    return JourneyConfig(
      journeyName: "Personal Loan Application",
      version: "1.0.0",
      steps: [
        JourneyStep(
          id: "personal",
          title: "Borrower Information",
          description: "Provide basic information to calculate credit eligibility",
          nextStep: "employment",
          fields: [
            JourneyField(id: "fullName", label: "Full Name", type: "text", required: true, placeholder: "Enter full name"),
            JourneyField(id: "loanAmount", label: "Loan Amount (\$)", type: "text", required: true, placeholder: "e.g. 15000"),
          ],
        ),
        JourneyStep(
          id: "employment",
          title: "Employment Details",
          description: "Enter business or employment particulars",
          nextStep: "documents",
          fields: [
            JourneyField(id: "companyName", label: "Current Employer Name", type: "text", required: true, placeholder: "Enter company name"),
            JourneyField(id: "monthlyIncome", label: "Monthly Income", type: "text", required: true, placeholder: "e.g. 5000"),
            JourneyField(
              id: "employmentType",
              label: "Employment Category",
              type: "dropdown",
              required: true,
              placeholder: "Select category",
              options: ["Salaried", "Self-Employed", "Business Owner", "Freelancer"],
            ),
          ],
        ),
        JourneyStep(
          id: "documents",
          title: "Proof of Income Upload",
          description: "Upload salary slip and bank statements",
          nextStep: "disbursement",
          fields: [
            JourneyField(id: "bankStatements", label: "3 Months Bank Statements (PDF)", type: "file", required: true),
            JourneyField(id: "salarySlip", label: "Latest Salary Slip", type: "file", required: true),
          ],
        ),
        JourneyStep(
          id: "disbursement",
          title: "Disbursement Bank Info",
          description: "Supply bank details for loan payment transfer",
          fields: [
            JourneyField(id: "bankName", label: "Receiving Bank", type: "text", required: true, placeholder: "e.g. Chase Bank"),
            JourneyField(id: "accountNumber", label: "Account Number", type: "text", required: true, placeholder: "Enter account number"),
          ],
        ),
      ],
    );
  }

  JourneyConfig _getFeedbackConfig() {
    return JourneyConfig(
      journeyName: "Service Feedback Survey",
      version: "1.0.0",
      steps: [
        JourneyStep(
          id: "rating",
          title: "Service Ratings",
          description: "Select how you evaluate our help",
          nextStep: "comments",
          fields: [
            JourneyField(
              id: "overallRating",
              label: "Rate Overall Experience",
              type: "dropdown",
              required: true,
              placeholder: "Select score",
              options: ["5 - Highly Satisfied", "4 - Satisfied", "3 - Neutral", "2 - Dissatisfied", "1 - Very Dissatisfied"],
            ),
          ],
        ),
        JourneyStep(
          id: "comments",
          title: "Written Feedback",
          description: "Help us understand what we did well or poorly",
          nextStep: "contact",
          fields: [
            JourneyField(id: "feedbackComments", label: "Additional Suggestions", type: "textarea", placeholder: "Type your feedback here..."),
          ],
        ),
        JourneyStep(
          id: "contact",
          title: "Follow Up Contact",
          description: "Provide contact information for representative replies",
          fields: [
            JourneyField(id: "followUpEmail", label: "Contact Email", type: "text", placeholder: "Enter email address"),
          ],
        ),
      ],
    );
  }
}
