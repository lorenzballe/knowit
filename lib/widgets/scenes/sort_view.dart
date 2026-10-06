import 'package:flutter/material.dart';

import '../../models/scene.dart';

/// Plays a [SortScene]: to be built.
class SortSceneView extends StatelessWidget {
  final SortScene scene;
  final Color ink;
  final Color ground;
  const SortSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
