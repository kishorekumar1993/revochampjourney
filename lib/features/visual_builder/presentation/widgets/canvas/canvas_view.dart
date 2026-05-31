import 'package:flutter/material.dart';
import '../../../../../../core/theme.dart';
import 'canvas_toolbar.dart';
import 'canvas_workspace.dart';

class RevoBuilderCanvas extends StatelessWidget {
  const RevoBuilderCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RevoTheme.background,
      child: const Column(
        children: [
          CanvasToolbar(),
          Expanded(child: CanvasWorkspace()),
        ],
      ),
    );
  }
}
