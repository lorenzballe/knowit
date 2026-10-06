import 'package:flutter/material.dart';

import '../../models/scene.dart';

/// Plays a [TranslateScene]: to be built.
class TranslateSceneView extends StatelessWidget {
  final TranslateScene scene;
  final Color ink;
  final Color ground;
  const TranslateSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
