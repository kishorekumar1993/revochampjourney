import 'journey_step.dart';

class JourneyConfig {
  String journeyName;
  String version;
  String description;
  String category;
  String locale;
  String platform;
  List<JourneyStep> steps;

  JourneyConfig({
    required this.journeyName,
    required this.version,
    this.description = '',
    this.category = 'Onboarding',
    this.locale = 'English (US)',
    this.platform = 'All Devices',
    required this.steps,
  });

  factory JourneyConfig.fromJson(Map<String, dynamic> json) {
    var stepsList = json['steps'] as List? ?? [];
    return JourneyConfig(
      journeyName: json['journeyName'] ?? 'Unnamed Journey',
      version: json['version'] ?? '1.0.0',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Onboarding',
      locale: json['locale'] ?? 'English (US)',
      platform: json['platform'] ?? 'All Devices',
      steps: stepsList.map((step) => JourneyStep.fromJson(step)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'journeyName': journeyName,
      'version': version,
      'description': description,
      'category': category,
      'locale': locale,
      'platform': platform,
      'steps': steps.map((step) => step.toJson()).toList(),
    };
  }

  JourneyConfig copyWith({
    String? journeyName,
    String? version,
    String? description,
    String? category,
    String? locale,
    String? platform,
    List<JourneyStep>? steps,
  }) {
    return JourneyConfig(
      journeyName: journeyName ?? this.journeyName,
      version: version ?? this.version,
      description: description ?? this.description,
      category: category ?? this.category,
      locale: locale ?? this.locale,
      platform: platform ?? this.platform,
      steps: steps ?? this.steps.map((s) => s.copyWith()).toList(),
    );
  }
}
