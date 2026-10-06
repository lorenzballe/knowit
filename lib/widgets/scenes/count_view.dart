import 'package:flutter/material.dart';

import '../../models/scene.dart';

/// Plays a [CountScene]: to be built.
class CountSceneView extends StatelessWidget {
  final CountScene scene;
  final Color ink;
  final Color ground;
  const CountSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
