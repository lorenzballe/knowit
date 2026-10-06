import 'package:flutter/material.dart';

import '../../models/scene.dart';

/// Plays a [DrawScene]: to be built.
class DrawSceneView extends StatelessWidget {
  final DrawScene scene;
  final Color ink;
  final Color ground;
  const DrawSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
