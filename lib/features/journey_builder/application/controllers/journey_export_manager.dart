import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/journey_models.dart';

mixin JourneyExportManager on StateNotifier<JourneyConfig> {
  
  String exportToJson() {
    return jsonEncode(state.toJson());
  }
}