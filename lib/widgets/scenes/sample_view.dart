import 'package:flutter/material.dart';

import '../../models/scene.dart';

/// Plays a [SampleScene]: to be built.
class SampleSceneView extends StatelessWidget {
  final SampleScene scene;
  final Color ink;
  final Color ground;
  const SampleSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
