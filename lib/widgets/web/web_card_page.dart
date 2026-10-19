/// A free card's page, alive, and the deck's few of them.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../analytics.dart';
import '../../models/pill.dart';
import 'card_kit.dart';
import 'page_messages.dart';
import 'web_surface.dart';

/// The colour a free card is drawn on: its page's own ground, or its
/// subject's.
Color groundOf(Pill pill) => pill.web?.ground ?? pill.color;

/// Answers what a page says that only the app and the page need between
/// them — a tap of the phone, a link to open, something broken — and says
/// whether it did. Everything else is for whoever holds the page.
bool answerAside(PageMessage message, {String? pillId}) {
  switch (message) {
    case PageHaptic(:final kind):
      _tap(kind);
      return true;
    case PageOpen(:final url):
      launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      ).catchError((_) => false);
      return true;
    case PageError(:final message):
      debugPrint(
        'Astute: a page${pillId == null ? '' : ' on $pillId'} broke: $message',
      );
      Analytics.capture('card page error', {
        'pill_id': pillId,
        'message': message,
      });
      return true;
    default:
      return false;
  }
}

/// The phone's own feel for each word a page may use. Never the heaviest
/// for something going wrong: a wrong answer is acknowledged, not punished,
/// as on a native card.
void _tap(String kind) => switch (kind) {
  'selection' => HapticFeedback.selectionClick(),
  'medium' || 'success' => HapticFeedback.mediumImpact(),
  'heavy' => HapticFeedback.heavyImpact(),
  _ => HapticFeedback.lightImpact(),
};

/// One card's page, from the moment it is wanted to the moment it is let
/// go: its surface, whether its first frame is drawn, where it holds the
/// finger, and whether it is in front of the reader.
///
/// What only the page and the app need between them — ready, where the
/// finger goes, a tap of the phone, a link — is answered here. What only
/// the deck can do — record an answer, turn the card, send it on — goes to
/// [listener], which the card on top sets.
class WebCardPage extends ChangeNotifier {
  WebCardPage(this.pill, this._env) : surface = WebSurfaces.create() {
    surface.onMessage = _heard;
    _start();
  }

  final Pill pill;
  final WebSurface surface;

  /// How long a page has to draw its first frame before the card gives up
  /// on it and is drawn natively: long past any page that works, short of
  /// a reader wondering what is wrong.
  static const Duration patience = Duration(seconds: 6);

  PageEnv _env;
  PageEnv? _built;
  bool _ready = false;
  bool _failed = false;
  bool _shown = false;
  bool _gone = false;
  List<Rect> _zones = const [];
  Timer? _waiting;
  final Stopwatch _took = Stopwatch()..start();

  /// Whether the page has drawn its first frame, and so is shown in place
  /// of the poster.
  bool get ready => _ready;

  /// Whether the page could not be shown: the card is drawn natively.
  bool get failed => _failed;

  /// Where the page holds the finger itself, as it last said.
  List<Rect> get zones => _zones;

  /// The deck's ears, for what the page asks of the card on top.
  ValueChanged<PageMessage>? listener;

  Future<void> _start() async {
    if (!surface.available) return _fail('no web view');
    _waiting = Timer(patience, () => _fail('timeout'));
    try {
      final PageEnv env = _env.copyWith(shown: _shown);
      final String html = await CardKit.instance.page(pill.web!.html, env);
      if (_gone) return;
      _built = env;
      await surface.load(html, background: groundOf(pill));
    } catch (error) {
      debugPrint(
        'Astute: card ${pill.id} has a page that did not load: $error',
      );
      _fail('load', '$error');
    }
  }

  void _heard(PageMessage message) {
    if (_gone) return;
    switch (message) {
      case PageReady():
        if (_ready || _failed) return;
        _ready = true;
        _waiting?.cancel();
        // Anything said to the page before it could hear is said again now.
        if (_env.since(_built) case final Map<String, Object?> env) {
          surface.tell({'t': 'env', 'env': env});
        }
        if (_shown) surface.tell(const {'t': 'show'});
        Analytics.capture('card page ready', {
          'pill_id': pill.id,
          'ms': _took.elapsedMilliseconds,
        });
        notifyListeners();
      case PageZones(:final rects):
        _zones = rects;
      default:
        if (!answerAside(message, pillId: pill.id)) listener?.call(message);
    }
  }

  void _fail(String reason, [String? message]) {
    if (_failed || _ready || _gone) return;
    _failed = true;
    _waiting?.cancel();
    Analytics.capture('card page failed', {
      'pill_id': pill.id,
      'reason': reason,
      'message': message,
    });
    notifyListeners();
  }

  /// The card is in front of the reader: the page's clock runs.
  void show() {
    if (_shown) return;
    _shown = true;
    if (_ready) surface.tell(const {'t': 'show'});
  }

  /// The card has left the reader's sight: the page holds still.
  void hide() {
    if (!_shown) return;
    _shown = false;
    if (_ready) surface.tell(const {'t': 'hide'});
  }

  /// Something about where the page is shown has changed: the theme, the
  /// language, motion, sound.
  void update(PageEnv env) {
    final Map<String, Object?>? change = env.since(_env);
    _env = env;
    if (change != null && _ready) surface.tell({'t': 'env', 'env': change});
  }

  @override
  void dispose() {
    _gone = true;
    _waiting?.cancel();
    listener = null;
    surface.dispose();
    super.dispose();
  }
}

/// The pages a deck keeps alive: never more than two, the card on top and
/// the one under it.
///
/// The one under it is the point. Its page is loaded and drawn while the
/// reader is still on the card above, so when that one is thrown the next
/// is already itself — no poster, no wait. Two is also the most a phone
/// should hold: every live page is a browser engine's worth of memory.
class WebCardPool {
  /// The most pages a deck keeps alive.
  static const int capacity = 2;

  final Map<String, WebCardPage> _live = {};

  /// The live page of the card [id], if it has one.
  WebCardPage? operator [](String id) => _live[id];

  /// How many pages are alive.
  int get length => _live.length;

  /// Keeps alive the pages of the first [capacity] of [cards] that have
  /// one, making those it does not have yet with the env [envFor] gives,
  /// and lets every other page go.
  void keep(Iterable<Pill> cards, PageEnv Function(Pill pill) envFor) {
    final List<Pill> wanted = cards
        .where((p) => p.hasPage)
        .take(capacity)
        .toList();
    final Set<String> ids = {for (final Pill p in wanted) p.id};
    for (final String id in _live.keys.toList()) {
      if (!ids.contains(id)) _live.remove(id)!.dispose();
    }
    for (final Pill p in wanted) {
      _live.putIfAbsent(p.id, () => WebCardPage(p, envFor(p)));
    }
  }

  /// Tells every live page what has changed about where it is shown.
  void update(PageEnv Function(Pill pill) envFor) {
    for (final WebCardPage page in _live.values) {
      page.update(envFor(page.pill));
    }
  }

  /// Lets every page go.
  void dispose() {
    for (final WebCardPage page in _live.values) {
      page.dispose();
    }
    _live.clear();
  }
}
