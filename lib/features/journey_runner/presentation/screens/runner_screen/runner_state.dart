import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RunnerLayoutStyle {
  split,
  focus,
  timeline,
  tabbed,
  curasole,
  masterdetail,
  accordion,
  form,
  wizard,
  review,
  dashboard,
  chat,
  kanban,
  stepper,
}

final runnerLayoutStyleProvider = StateProvider<RunnerLayoutStyle>((ref) {
  return RunnerLayoutStyle.split;
});
