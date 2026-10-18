import 'subject_icons.dart';

/// The marks beside the profile's rows: what each one is, in a line.
///
/// Drawn on the subjects' own grid (subject_icons.dart) — 24 units, one
/// stroke of 1.9, round ends and round joins — so a bookmark beside a flask
/// reads as one hand rather than as a second icon set laid over the app.
/// Drawn here for the same reason the subjects are: an icon font's marks are
/// somebody else's hand, and they come out at its weight, not this one.
///
/// The like is the subjects' heart, Human body's, so the two hearts in the
/// app are one heart.
abstract final class ProfileMarks {
  /// Saved: the ribbon a page is kept with.
  static const String bookmark =
      'M7 3h10a2 2 0 0 1 2 2v16l-7-4.2L5 21V5a2 2 0 0 1 2-2z';

  /// Liked.
  static final String heart = kSubjectIcons['Human body']!;

  /// The archive: a clock with its hand wound back.
  static const String clock =
      'M3 12a9 9 0 1 0 2.64-6.36L3 8.5 M3 4v4.5h4.5 M12 7.5v4.7l3.3 2';

  /// Where you live: a pin with the place in it.
  static const String pin =
      'M12 22S4 15.6 4 10a8 8 0 0 1 16 0c0 5.6-8 12-8 12z '
      'M15 10a3 3 0 1 1-6 0 3 3 0 0 1 6 0z';

  /// The plan: a rosette with a plus in it, Astute+'s.
  static const String plan =
      'M8.72 4.08A3.8 3.8 0 0 1 15.28 4.08A3.8 3.8 0 0 1 19.92 8.72'
      'A3.8 3.8 0 0 1 19.92 15.28A3.8 3.8 0 0 1 15.28 19.92'
      'A3.8 3.8 0 0 1 8.72 19.92A3.8 3.8 0 0 1 4.08 15.28'
      'A3.8 3.8 0 0 1 4.08 8.72A3.8 3.8 0 0 1 8.72 4.08z '
      'M12 8.2v7.6 M8.2 12h7.6';

  /// Signing out: through the door, and away from it.
  static const String exit =
      'M9 20.5H5.5a2 2 0 0 1-2-2v-13a2 2 0 0 1 2-2H9 '
      'M16 16.5l4.5-4.5L16 7.5 M20.5 12H9';

  /// Signing in: through the door, and into it.
  static const String enter =
      'M15 3.5h3.5a2 2 0 0 1 2 2v13a2 2 0 0 1-2 2H15 '
      'M10 16.5l4.5-4.5L10 7.5 M14.5 12H3.5';

  /// How the cards are written: a quill.
  static const String quill =
      'M6 18C5 11 12 3 21 3c0 9-7 16-15 15z M3 21L16 8 M9.8 14.2h6';

  /// Usage data: three bars.
  static const String chart = 'M6 20v-6 M12 20V4.5 M18 20v-9.5';

  /// The music cards' sound: a speaker and two waves.
  static const String sound =
      'M4 9.5h3.5L12 5.5v13l-4.5-4H4z '
      'M15.6 9.2a4 4 0 0 1 0 5.6 M18.4 6.4a8 8 0 0 1 0 11.2';

  /// Deleting the account: a bin.
  static const String bin =
      'M3.5 6h17 M9 6V4.5A1.5 1.5 0 0 1 10.5 3h3A1.5 1.5 0 0 1 15 4.5V6 '
      'M5.8 6l.9 13.2a2 2 0 0 0 2 1.8h6.6a2 2 0 0 0 2-1.8l.9-13.2 '
      'M10 10.5v6.5 M14 10.5v6.5';

  /// The privacy policy: a shield with a tick on it.
  static const String shield =
      'M12 3l7.5 3v5.5c0 4.6-3.2 8.3-7.5 9.5-4.3-1.2-7.5-4.9-7.5-9.5V6z '
      'M8.8 12.2l2.2 2.2 4.3-4.4';

  /// The terms: a page with its corner turned and two lines on it.
  static const String page =
      'M7 3h7l4.5 4.5V19a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z '
      'M14 3v4.5h4.5 M8.5 12.5h7 M8.5 16h5';

  /// Where a row goes.
  static const String chevron = 'M9 6l6 6-6 6';
}

/// [path] as a standalone SVG document, which is what the renderer takes:
/// white, to be recoloured by whatever draws it, as the subjects' marks are.
String profileMarkSvg(String path, {double stroke = 1.9}) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="$path" fill="none" stroke="#ffffff" stroke-width="$stroke" '
    'stroke-linecap="round" stroke-linejoin="round"/></svg>';
