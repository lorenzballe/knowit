import 'package:flutter/material.dart';

import '../../models/scene.dart';

/// Plays a [RankScene]: to be built.
class RankSceneView extends StatelessWidget {
  final RankScene scene;
  final Color ink;
  final Color ground;
  const RankSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
