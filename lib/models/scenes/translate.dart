/// `translate`: translate it.
///
/// A short real piece of jargon — a clause of a gym contract, a line of a
/// radiology report, the back of a moisturiser — set as a printed document,
/// with two to four phrases marked in it. The reader taps a phrase and it is
/// selected, as in an editor, and retyped in plain words; a stub torn off the
/// foot of the document says why it was worded that way. When every phrase
/// is translated the stub says what to watch for next time.
///
/// The reasoning move is the guess before the reading. When one phrase is
/// marked as the catch, the reader's first tap is a bet on which phrase hides
/// it — the reader has to read the jargon suspiciously, the skill the card
/// teaches — and the catch, once translated, is printed solid.
///
/// A card of this kind is worth making only when the plain words differ from
/// what the jargon makes a reader assume: a word that sounds like praise and
/// is bad news, a promise that is a ceiling, a convenience that is a lock.
///
/// JSON fields:
///
/// - `type`: `"translate"`.
/// - `head`: the letterhead, what the document is ("Radiology report").
///   Up to 30 characters, set in small capitals.
/// - `ref` (optional): a reference at the right of the letterhead
///   ("Chest X-ray", "§ 7.2"). Up to 14 characters.
/// - `title` (optional): a heading set over the text ("Findings"). Up to 34
///   characters, one line.
/// - `body`: the jargon itself, as printed. 60 to 260 characters, and no
///   more than 280 once every phrase is replaced by its plain words.
/// - `phrases`: 2 to 4, each with:
///   - `text`: the phrase exactly as it appears in `body`, once. Up to 44
///     characters. Phrases may not overlap.
///   - `plain`: what it really means, in plain words. It replaces the phrase
///     in the document, so it should read on from the words around it.
///     Up to 64 characters.
///   - `why`: why it is worded that way, one or two short sentences on the
///     stub. Up to 110 characters.
///   - `catch` (optional): `true` on the one phrase that hides the catch.
///     With a catch, the reader's first tap is a guess.
/// - `ask`: the line on the stub before the first tap: the bet when there is
///   a catch ("One word here sounds like good news and isn't. Which?"), or
///   simply what to do. Up to 64 characters.
/// - `watch`: the line the stub ends on, what to watch for next time.
///   Up to 90 characters.
///
/// ```json
/// {
///   "type": "translate",
///   "head": "Radiology report",
///   "ref": "Chest X-ray",
///   "title": "Findings",
///   "body": "Heart and lungs are unremarkable. The shadow in the left lower lobe is impressive and suggests an occult infection.",
///   "phrases": [
///     {"text": "unremarkable", "plain": "normal, nothing worth a remark",
///      "why": "Written for other doctors: no remark is the best news."},
///     {"text": "impressive", "plain": "large and worrying", "catch": true,
///      "why": "It impresses the radiologist. That is not praise."},
///     {"text": "an occult infection", "plain": "an infection we cannot see yet",
///      "why": "Occult is Latin for hidden. Nothing supernatural."}
///   ],
///   "ask": "One word here sounds like good news and isn't. Which?",
///   "watch": "When a report seems to praise you, ask what the word means there."
/// }
/// ```
library;

import '../scene.dart';

/// One marked phrase of the document.
class TranslatePhrase {
  /// As printed, and where it sits in [TranslateScene.body].
  final String text;
  final int start;

  /// What it really means, and why it was not written that way.
  final String plain;
  final String why;

  /// Whether this is the phrase that hides the catch.
  final bool isCatch;

  const TranslatePhrase({
    required this.text,
    required this.start,
    required this.plain,
    required this.why,
    required this.isCatch,
  });

  int get end => start + text.length;
}

/// A run of the document: printed words between phrases, or a phrase.
///
/// [phrase] is the index into [TranslateScene.phrases], or -1 for the
/// printed words in [text].
typedef TranslateRun = ({String text, int phrase});

/// Jargon into plain words.
class TranslateScene extends Scene {
  final String head;
  final String ref;
  final String title;
  final String body;

  /// In the order they appear in [body].
  final List<TranslatePhrase> phrases;
  final String ask;
  final String watch;

  const TranslateScene(
    super.raw, {
    required this.head,
    required this.ref,
    required this.title,
    required this.body,
    required this.phrases,
    required this.ask,
    required this.watch,
  });

  /// The phrase that hides the catch, or -1 when there is none and the
  /// first tap is not a guess.
  int get catchIndex => phrases.indexWhere((p) => p.isCatch);

  bool get asksForGuess => catchIndex >= 0;

  /// The document cut into runs: printed words, phrase, printed words…
  List<TranslateRun> get runs {
    final out = <TranslateRun>[];
    var at = 0;
    for (var i = 0; i < phrases.length; i++) {
      final p = phrases[i];
      if (p.start > at) {
        out.add((text: body.substring(at, p.start), phrase: -1));
      }
      out.add((text: p.text, phrase: i));
      at = p.end;
    }
    if (at < body.length) out.add((text: body.substring(at), phrase: -1));
    return out;
  }

  /// The document as it reads with the phrases in [plain] translated.
  String reading(Set<int> plain) => [
    for (final r in runs)
      r.phrase < 0
          ? r.text
          : plain.contains(r.phrase)
          ? phrases[r.phrase].plain
          : r.text,
  ].join();

  static TranslateScene parse(Map<String, Object?> raw, Object? id) {
    String need(Map m, String k, String where) {
      final v = m[k];
      if (v is! String || v.trim().isEmpty) {
        throw FormatException('$where.$k must be a non-empty string', id);
      }
      return v.trim();
    }

    String opt(String k) => raw[k] is String ? (raw[k] as String).trim() : '';

    final body = need(raw, 'body', 'scene');
    final list = raw['phrases'];
    if (list is! List || list.length < 2) {
      throw FormatException('scene.phrases needs at least two phrases', id);
    }
    final phrases = <TranslatePhrase>[];
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      final where = 'scene.phrases[$i]';
      if (m is! Map) throw FormatException('$where is not an object', id);
      final text = need(m, 'text', where);
      final start = body.indexOf(text);
      if (start < 0) {
        throw FormatException('$where.text "$text" is not in the body', id);
      }
      if (body.indexOf(text, start + 1) >= 0) {
        throw FormatException('$where.text "$text" is in the body twice', id);
      }
      final c = m['catch'];
      if (c != null && c is! bool) {
        throw FormatException('$where.catch must be true or false', id);
      }
      phrases.add(
        TranslatePhrase(
          text: text,
          start: start,
          plain: need(m, 'plain', where),
          why: need(m, 'why', where),
          isCatch: c == true,
        ),
      );
    }
    phrases.sort((a, b) => a.start.compareTo(b.start));
    for (var i = 1; i < phrases.length; i++) {
      if (phrases[i].start < phrases[i - 1].end) {
        throw FormatException(
          'scene.phrases: "${phrases[i - 1].text}" and "${phrases[i].text}" overlap',
          id,
        );
      }
    }
    // Two catches would make the guess a coin with two winning sides.
    if (phrases.where((p) => p.isCatch).length > 1) {
      throw FormatException('scene.phrases: at most one catch', id);
    }
    return TranslateScene(
      raw,
      head: need(raw, 'head', 'scene'),
      ref: opt('ref'),
      title: opt('title'),
      body: body,
      phrases: phrases,
      ask: need(raw, 'ask', 'scene'),
      watch: need(raw, 'watch', 'scene'),
    );
  }
}
