import 'package:flutter/material.dart';

import '../../models/scene.dart';

/// Plays a [MatchScene]: to be built.
class MatchSceneView extends StatelessWidget {
  final MatchScene scene;
  final Color ink;
  final Color ground;
  const MatchSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
