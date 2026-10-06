import 'package:flutter/material.dart';

import '../../models/scene.dart';

/// Plays a [StoryScene]: to be built.
class StorySceneView extends StatelessWidget {
  final StoryScene scene;
  final Color ink;
  final Color ground;
  const StorySceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
