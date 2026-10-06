import 'package:flutter/material.dart';

import '../../models/scene.dart';

/// Plays a [HoldScene]: to be built.
class HoldSceneView extends StatelessWidget {
  final HoldScene scene;
  final Color ink;
  final Color ground;
  const HoldSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
