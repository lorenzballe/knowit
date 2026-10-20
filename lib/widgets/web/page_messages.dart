/// What a free card's page and the app say to each other.
///
/// The page side is docs/cards/kit/astute-bridge.js: one JSON object a
/// message, posted through a JavaScript channel on a phone and to the parent
/// window on the web build. This is the app side of the same vocabulary —
/// what the page may say ([PageMessage]) and what the app tells it about
/// where it is shown ([PageEnv]) — so the two can be read side by side.
library;

import 'dart:convert';
import 'dart:ui' show Color, Offset, Rect, Size;

import '../../models/pill.dart';

/// Something the page said. A message this build does not know, or cannot
/// read, is not one: [parse] passes it over, as an older build passes over
/// anything newer than itself.
sealed class PageMessage {
  const PageMessage();

  /// Reads one message, or null for one that says nothing this build knows.
  static PageMessage? parse(String text) {
    final Object? raw;
    try {
      raw = jsonDecode(text);
    } on FormatException {
      return null;
    }
    if (raw is! Map) return null;
    double? number(Object? v) => v is num && v.isFinite ? v.toDouble() : null;
    switch (raw['t']) {
      case 'ready':
        return const PageReady();
      case 'answer':
        final Object? choice = raw['choice'];
        final Object? correct = raw['correct'];
        final Object? sure = raw['sure'];
        if (choice is! String || choice.trim().isEmpty) return null;
        return PageAnswer(
          choice: choice.trim(),
          correct: correct is bool ? correct : null,
          sure: sure is num ? sure.round() : null,
        );
      case 'flip':
        return const PageFlip();
      case 'tap':
        return const PageTap();
      case 'done':
        return const PageDone();
      case 'haptic':
        final Object? kind = raw['kind'];
        return PageHaptic(kind is String ? kind : 'light');
      case 'open':
        final Uri? url = Uri.tryParse('${raw['url']}');
        if (url == null || !(url.isScheme('https') || url.isScheme('http'))) {
          return null;
        }
        return PageOpen(url);
      case 'zones':
        final Object? rects = raw['rects'];
        if (rects is! List) return null;
        return PageZones([
          for (final Object? r in rects)
            if (r is List && r.length == 4 && r.every((v) => v is num))
              Rect.fromLTWH(
                (r[0] as num).toDouble(),
                (r[1] as num).toDouble(),
                (r[2] as num).toDouble(),
                (r[3] as num).toDouble(),
              ),
        ]);
      case 'pan':
        final Object? phase = raw['phase'];
        if (phase is! String ||
            !const {'start', 'update', 'end'}.contains(phase)) {
          return null;
        }
        return PagePan(
          phase,
          delta: Offset(number(raw['dx']) ?? 0, number(raw['dy']) ?? 0),
          velocity: Offset(number(raw['vx']) ?? 0, number(raw['vy']) ?? 0),
        );
      case 'error':
        return PageError('${raw['message'] ?? ''}');
      default:
        return null;
    }
  }
}

/// The response a page's answer is kept as, in the form the card's own
/// challenge reads, so it is recorded, marked and shown back exactly as a
/// native card's: what the reader said with its mark, on a card the page
/// marks ([PageJudged]); the option, the side or the number, on a card the
/// app marks itself. Null for an answer the card cannot take — a choice out
/// of range, a page that marks its card and forgot to say right or wrong,
/// anything at all on a card that only tells.
String? pageResponse(Challenge challenge, PageAnswer answer) {
  String? index(int count) {
    final int? i = int.tryParse(answer.choice);
    return i != null && i >= 0 && i < count ? '$i' : null;
  }

  return switch (challenge) {
    PageJudged(:final graded) when graded && answer.correct == null => null,
    PageJudged(:final graded) => PageJudged.encode(
      answer.choice,
      graded ? answer.correct : null,
    ),
    PickOne(:final options) => index(options.length),
    TakeASide(:final positions) => index(positions.length),
    TypeNumber() || Estimate() =>
      TypeNumber.parse(answer.choice) == null ? null : answer.choice,
    NoChallenge() => null,
  };
}

/// The page's first frame is drawn: what it shows can replace the poster.
class PageReady extends PageMessage {
  const PageReady();
}

/// What the reader committed to on the page.
class PageAnswer extends PageMessage {
  /// What they said, in a few words; on a card whose kind the app marks
  /// itself (pickOne, number, estimate, debate), the response in that
  /// kind's own form — the option's index, the number.
  final String choice;

  /// Right or wrong, as the page marks it; null where nothing is.
  final bool? correct;

  /// How sure they said they were, 50 to 90; null where the page did not
  /// ask.
  final int? sure;

  const PageAnswer({required this.choice, this.correct, this.sure});
}

/// The page asks for the card to be turned over.
class PageFlip extends PageMessage {
  const PageFlip();
}

/// A tap the page did nothing with: on a native card it turns the card
/// over, and so it does here.
class PageTap extends PageMessage {
  const PageTap();
}

/// The page is finished with the card: it goes on, as a throw sends it.
class PageDone extends PageMessage {
  const PageDone();
}

/// A tap of the phone under the finger: `light`, `medium`, `heavy`,
/// `selection`, `success`, `warning` or `error`.
class PageHaptic extends PageMessage {
  final String kind;
  const PageHaptic(this.kind);
}

/// A link, opened outside the app.
class PageOpen extends PageMessage {
  final Uri url;
  const PageOpen(this.url);
}

/// Where the page holds the finger itself, in the page's own pixels, which
/// are the card face's logical pixels: a touch that starts there is the
/// page's, every touch of it.
class PageZones extends PageMessage {
  final List<Rect> rects;
  const PageZones(this.rects);
}

/// On the web build only, where the card is an iframe the app never sees a
/// finger on: a drag the page left to the deck, handed out to it.
class PagePan extends PageMessage {
  /// `start`, `update` or `end`.
  final String phase;
  final Offset delta;
  final Offset velocity;
  const PagePan(
    this.phase, {
    this.delta = Offset.zero,
    this.velocity = Offset.zero,
  });
}

/// Something on the page broke.
class PageError extends PageMessage {
  final String message;
  const PageError(this.message);
}

/// The subject a card is dressed in, as the page draws it: the colour and
/// ink of the card, its mark, its name in the reader's language.
class PageSubject {
  final String key;
  final String name;
  final Color colour;
  final Color ink;

  /// The mark, as SVG path data on a 24-unit grid (lib/data/subject_icons.dart).
  final String icon;

  const PageSubject({
    required this.key,
    required this.name,
    required this.colour,
    required this.ink,
    required this.icon,
  });

  Map<String, Object?> toJson() => {
    'key': key,
    'name': name,
    'c': _hex(colour),
    'k': _hex(ink),
    if (icon.isNotEmpty) 'icon': icon,
  };
}

/// Where the page is shown, as the app tells it: everything a card might
/// want to know about the reader and the phone, and nothing about who they
/// are.
class PageEnv {
  /// The app's theme, light or dark.
  final bool dark;

  /// The language the app is shown in: `en`, `it`, …
  final String language;

  /// Whether the reader asked for less motion.
  final bool calm;

  /// Whether sound is on (lib/state/music_sound.dart). Off, a card still
  /// shows and captions everything it would have played.
  final bool sound;

  /// How the page shares the finger with the deck.
  final WebTouch touch;

  /// `ios`, `android` or `web`: on the web build the page hands the deck
  /// its drags itself.
  final String platform;

  /// Whether the page is in front of the reader now.
  final bool shown;

  /// The size it is drawn at, in logical pixels.
  final Size size;

  /// The room the native save and share take in the bottom corner, inside
  /// the face's padding, which the page keeps clear; null where there are
  /// none.
  final Size? corner;

  /// The card's subject, for a card.
  final PageSubject? subject;

  /// The line a native card carries under its head (why it is here today),
  /// and the chip beside its subject (`AGAIN`, `FOR YOU`).
  final String? note;
  final String? chip;

  const PageEnv({
    this.dark = true,
    this.language = 'en',
    this.calm = false,
    this.sound = false,
    this.touch = WebTouch.taps,
    this.platform = 'ios',
    this.shown = false,
    this.size = Size.zero,
    this.corner,
    this.subject,
    this.note,
    this.chip,
  });

  PageEnv copyWith({bool? shown, Size? size}) => PageEnv(
    dark: dark,
    language: language,
    calm: calm,
    sound: sound,
    touch: touch,
    platform: platform,
    shown: shown ?? this.shown,
    size: size ?? this.size,
    corner: corner,
    subject: subject,
    note: note,
    chip: chip,
  );

  Map<String, Object?> toJson() => {
    'mode': 'app',
    'theme': dark ? 'dark' : 'light',
    'lang': language,
    'calm': calm,
    'sound': sound,
    'touch': touch.name,
    'platform': platform,
    'shown': shown,
    'size': {'w': size.width.round(), 'h': size.height.round()},
    'safe': const {'top': 0, 'right': 0, 'bottom': 0, 'left': 0},
    'corner': corner == null
        ? null
        : {'w': corner!.width.round(), 'h': corner!.height.round()},
    'subject': subject?.toJson(),
    'note': note,
    'chip': chip,
  };

  /// What changed from [old] that the page should be told, or null when
  /// nothing did.
  Map<String, Object?>? since(PageEnv? old) {
    final Map<String, Object?> now = toJson()..remove('shown');
    if (old == null) return now;
    final Map<String, Object?> was = old.toJson()..remove('shown');
    return jsonEncode(now) == jsonEncode(was) ? null : now;
  }
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}';
