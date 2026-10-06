import '../scene.dart';

/// `count`: to be built.
class CountScene extends Scene {
  const CountScene(super.raw);

  static CountScene parse(Map<String, Object?> raw, Object? id) => CountScene(raw);
}
