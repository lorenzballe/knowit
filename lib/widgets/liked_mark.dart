import 'package:flutter/material.dart';

import '../data/card_pages.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';

/// A liked card's mark: a heart in the card's ink, in the card's head on the
/// right, at the height of its subject — before the number a card on the
/// shelf prints there, or the tag a drawn card does.
class LikedMark extends StatelessWidget {
  const LikedMark({super.key, required this.ink, this.scale = 1});

  final Color ink;

  /// The card's size against the deck's own.
  final double scale;

  /// The heart's size on a card being read.
  static const double size = 15;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return KeyedSubtree(
      key: const ValueKey('liked-heart'),
      child: Semantics(
        label: context.l10n.liked,
        // It comes in as the hold's heart in the middle swells and goes.
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: still ? 1 : 0, end: 1),
          duration: Duration(milliseconds: still ? 0 : 320),
          curve: Curves.easeOut,
          builder: (context, t, heart) => Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.6 + 0.4 * t, child: heart),
          ),
          child: Icon(
            Icons.favorite_rounded,
            size: size * scale,
            color: ink.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}

/// The tag a drawn card prints on the right of its head ("RIGID?"), read from
/// its page, so a heart laid over the page can stand just before it.
abstract final class CardTags {
  static final Map<String, String?> _of = {};
  static final Map<String, Future<void>> _asked = {};
  static final RegExp _tag = RegExp(
    r'<span class="tag"[^>]*>(.*?)</span>',
    dotAll: true,
  );

  /// Whether the card's page has been read for its tag.
  static bool knows(String id) => _of.containsKey(id);

  /// The card's tag, or null when it has none or it is not known yet.
  static String? of(String id) => _of[id];

  /// Reads the tag from the card's page, as it is loaded.
  static void remember(String id, String html) {
    final Match? found = _tag.firstMatch(html);
    _of[id] = found == null ? null : _plain(found.group(1)!);
  }

  /// Reads the tag of [pill] from its page, fetching the page if it is not in
  /// hand. Done once per card however often it is asked.
  static Future<void> learn(Pill pill) {
    final WebFace? web = pill.web;
    if (web == null || knows(pill.id)) return Future<void>.value();
    return _asked[pill.id] ??= () async {
      try {
        remember(pill.id, await CardPages.instance.html(web));
      } catch (_) {
        _of[pill.id] = null;
      }
    }();
  }

  static String _plain(String html) => html
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&')
      .trim();

  /// How far in from a drawn card's right edge the heart's right side
  /// stands, in the page's points: past the card's margin and, on a card
  /// with a tag, the tag and the gap after it. The tag is measured as the
  /// kit sets it in the app (`.kit-app .tag` in docs/cards/kit/astute-card.css:
  /// 10 points, a tenth of that between letters, 9 either side), and the
  /// head stands 26 down, 20 high.
  static double heartRight(String? tag) {
    if (tag == null || tag.isEmpty) return margin;
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: tag.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Figtree',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final double width = painter.width;
    painter.dispose();
    return margin + width + 18 + 8;
  }

  /// The page's side margin, and the middle of its head, from the top.
  static const double margin = 28;
  static const double headMiddle = 36;
}
