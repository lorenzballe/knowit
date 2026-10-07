import '../scene.dart';

/// `news`: to be built.
class NewsScene extends Scene {
  const NewsScene(super.raw);

  static NewsScene parse(Map<String, Object?> raw, Object? id) => NewsScene(raw);
}
