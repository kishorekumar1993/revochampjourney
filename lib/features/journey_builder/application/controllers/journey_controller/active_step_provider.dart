import 'package:flutter_riverpod/flutter_riverpod.dart';

// Active step ID
final activeStepIdProvider = StateProvider<String>((ref) => "personal");

// Selected Field ID (the one selected in the design canvas)
final selectedFieldIdProvider = StateProvider<String?>((ref) => null);
