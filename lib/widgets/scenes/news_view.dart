import 'package:flutter/material.dart';

import '../../models/scene.dart';

/// Plays a [NewsScene]: to be built.
class NewsSceneView extends StatelessWidget {
  final NewsScene scene;
  final Color ink;
  final Color ground;
  const NewsSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
