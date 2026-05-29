import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/builder_mode.dart';

final builderModeProvider = StateProvider<BuilderMode>((ref) => BuilderMode.journey);

final showStepsPanelProvider = StateProvider<bool>((ref) => true);
final showPropertiesPanelProvider = StateProvider<bool>((ref) => true);
