/// The pieces Explore is built from, and what each one is given to build
/// itself.
///
/// Explore is a list of sections, each drawn by a block. The list comes
/// from the server (the `explore` part of the remote document, see
/// docs/REMOTE.md) or, when the server says nothing, from the build's own
/// list; the engine reads it, aims each section at its audience, and asks
/// the section's block to draw it. A block never reaches into the Explore
/// screen: everything it may do — find its cards, open one, record an
/// answer, say what it showed — goes through the [ExploreHost] it is
/// handed, which is what lets the same block sit anywhere in the list, and
/// lets a test hand it a fake one.
///
/// The blocks themselves live in `lib/explore/blocks/`, one file per family,
/// and are listed in `lib/explore/catalogue.dart`.
library;

import 'package:flutter/widgets.dart';

import '../models/pill.dart';
import '../state/app_state.dart';

/// One section of Explore, as the remote document or the build's own list
/// gives it: which block draws it, and whatever that block reads.
@immutable
class ExploreSection {
  /// The section's own name: what its cards are noted under, and what tells
  /// two sections drawn by the same block apart.
  final String id;

  /// The block that draws it.
  final String block;

  /// Everything the section says, as it came. Each block reads its own
  /// fields from here, defensively.
  final Map<String, Object?> json;

  const ExploreSection({
    required this.id,
    required this.block,
    this.json = const {},
  });

  /// Reads a section. Throws [FormatException] on one without an id or a
  /// block, which the engine then leaves out.
  factory ExploreSection.fromJson(Map<String, Object?> json) {
    final Object? id = json['id'];
    final Object? block = json['block'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('a section has an id');
    }
    if (block is! String || block.isEmpty) {
      throw FormatException('section $id has no block');
    }
    return ExploreSection(id: id, block: block, json: json);
  }

  /// A field written per language — `{"en": "…", "it": "…"}` — or as one
  /// plain string for every language: the reader's language, English when
  /// it has none, null when the section says nothing.
  String? text(String field, String language) {
    final Object? raw = json[field];
    if (raw is String) return raw.isEmpty ? null : raw;
    if (raw is! Map) return null;
    final Object? own = raw[language];
    if (own is String && own.isNotEmpty) return own;
    final Object? english = raw['en'];
    return english is String && english.isNotEmpty ? english : null;
  }

  /// The section's title, when the document gives one; otherwise the block
  /// uses its own.
  String? title(String language) => text('title', language);

  /// The line under the title, likewise.
  String? subtitle(String language) => text('subtitle', language);

  /// Where the section's cards come from (see [ExploreHost.cardsFor]).
  Object? get source => json['source'];

  /// The size of its tiles, in the block's own words: `xs` … `xl`, and so
  /// on.
  String? get size => _string('size');

  /// How it looks beyond its size: colours, tone, density — each block says
  /// which keys it reads.
  Map<String, Object?> get style {
    final Object? raw = json['style'];
    return raw is Map<String, Object?> ? raw : const {};
  }

  /// The most cards it shows.
  int? get limit {
    final Object? raw = json['limit'];
    return raw is num && raw > 0 ? raw.toInt() : null;
  }

  /// Who it is for, and when (Audience.allows in lib/remote/remote.dart).
  Object? get audience => json['audience'];

  /// A field of the type the block expects, or null.
  T? get<T>(String key) {
    final Object? raw = json[key];
    return raw is T ? raw : null;
  }

  String? _string(String key) {
    final Object? raw = json[key];
    return raw is String && raw.isNotEmpty ? raw : null;
  }
}

/// What Explore hands a block: the reader, the cards, and every way a shelf
/// passes a card on. The Explore screen is the real one; tests and cameras
/// use a fake.
abstract class ExploreHost {
  /// The reader's state: what they read, saved, answered, their plan.
  AppState get app;

  /// The language Explore is shown in: `en`, `it`, …
  String get language;

  /// The subject Explore is narrowed to by its chips, or null for all.
  String? get subject;

  /// The cards [section] asks for through its `source`, in order, at most
  /// [limit] (the section's own `limit` when it has one), already narrowed
  /// to [subject]. Empty when there are none, and the block then usually
  /// has nothing to show.
  List<Pill> cardsFor(ExploreSection section, {int? limit});

  /// Whether the reader has read [pill].
  bool isRead(Pill pill);

  /// Opens [pill] the way every shelf does: the deck viewer over the tabs,
  /// the rest of [shelf] a swipe away, the card counted as read.
  void open(ExploreSection section, List<Pill> shelf, Pill pill);

  /// A true story played full screen out of the tile at [from].
  void playStory(
    ExploreSection section,
    List<Pill> shelf,
    Pill pill,
    Rect? from,
  );

  /// An answer given on the shelf itself, recorded as the card would record
  /// it, and the card counted as read.
  Future<void> commit(Pill pill, String response);

  /// A side taken on a debate from the shelf, and how sure, 0 to 100.
  Future<void> lean(Pill pill, int side, int confidence);

  /// A card [section] showed: counted once, for the shelf's own numbers.
  void seen(ExploreSection section, Pill pill);

  /// Wraps a section so Explore can tell when it is on screen, and how far
  /// down the reader went.
  Widget watch(ExploreSection section, Widget child);

  /// The Astute+ plans, opened from [from] (a paywall source).
  void openPlans(String from);

  /// Narrows Explore to [subject], as its chip does.
  void openSubject(String subject);

  /// Notes something a reader did in a section that the app has no other
  /// record of — a reaction, a bet, a stance — under [event], with [facts].
  void note(ExploreSection section, String event, Map<String, Object?> facts);
}

/// One kind of section.
abstract class ExploreBlock {
  const ExploreBlock();

  /// The `block` the document names it by.
  String get name;

  /// Draws [section], or returns null when there is nothing to show — no
  /// cards for it, nothing for this reader — and Explore leaves it out
  /// altogether, title and all.
  Widget? build(BuildContext context, ExploreHost host, ExploreSection section);
}
