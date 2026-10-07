import 'package:flutter/material.dart';

import '../../models/scene.dart';

/// Plays a [BeautyScene]: to be built.
class BeautySceneView extends StatelessWidget {
  final BeautyScene scene;
  final Color ink;
  final Color ground;
  const BeautySceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
