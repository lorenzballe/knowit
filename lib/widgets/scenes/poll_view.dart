import 'package:flutter/material.dart';

import '../../models/scene.dart';

/// Plays a [PollScene]: to be built.
class PollSceneView extends StatelessWidget {
  final PollScene scene;
  final Color ink;
  final Color ground;
  const PollSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
