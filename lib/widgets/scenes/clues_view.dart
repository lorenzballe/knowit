import 'package:flutter/material.dart';

import '../../models/scene.dart';

/// Plays a [CluesScene]: to be built.
class CluesSceneView extends StatelessWidget {
  final CluesScene scene;
  final Color ink;
  final Color ground;
  const CluesSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
