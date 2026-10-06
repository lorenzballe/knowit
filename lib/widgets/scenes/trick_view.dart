import 'package:flutter/material.dart';

import '../../models/scene.dart';

/// Plays a [TrickScene]: to be built.
class TrickSceneView extends StatelessWidget {
  final TrickScene scene;
  final Color ink;
  final Color ground;
  const TrickSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
