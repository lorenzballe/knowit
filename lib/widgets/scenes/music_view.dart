import 'package:flutter/material.dart';

import '../../models/scene.dart';

/// Plays a [MusicScene]: to be built.
class MusicSceneView extends StatelessWidget {
  final MusicScene scene;
  final Color ink;
  final Color ground;
  const MusicSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
