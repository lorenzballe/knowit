import 'package:flutter/material.dart';

import '../../models/scene.dart';

/// Plays a [TimelineScene]: to be built.
class TimelineSceneView extends StatelessWidget {
  final TimelineScene scene;
  final Color ink;
  final Color ground;
  const TimelineSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
