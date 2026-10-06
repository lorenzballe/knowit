import '../scene.dart';

/// `story`: to be built.
class StoryScene extends Scene {
  const StoryScene(super.raw);

  static StoryScene parse(Map<String, Object?> raw, Object? id) => StoryScene(raw);
}
