import 'package:flutter/material.dart';

import '../../models/scene.dart';

/// Plays a [WhyScene]: to be built.
class WhySceneView extends StatelessWidget {
  final WhyScene scene;
  final Color ink;
  final Color ground;
  const WhySceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
