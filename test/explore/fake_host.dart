// A stand-in for the Explore screen, for testing and photographing blocks on
// their own: it hands out cards from the bank and writes down everything a
// block asks it to do.
import 'package:flutter/widgets.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';

class FakeExploreHost implements ExploreHost {
  FakeExploreHost(this.app, {this.language = 'en', this.subject});

  @override
  final AppState app;

  @override
  final String language;

  @override
  final String? subject;

  /// Cards a test wants a section to get, by section id; otherwise the
  /// section's `source.ids`, or the first cards of the bank.
  final Map<String, List<Pill>> cards = {};

  final List<(String, String)> opened = [];
  final List<(String, String)> answered = [];
  final List<(String, int, int)> leaned = [];
  final List<(String, String)> shown = [];
  final List<String> plans = [];
  final List<String> subjects = [];
  final List<(String, String, Map<String, Object?>)> notes = [];

  @override
  List<Pill> cardsFor(ExploreSection section, {int? limit}) {
    final int most = limit ?? section.limit ?? 12;
    final List<Pill>? given = cards[section.id];
    if (given != null) return given.take(most).toList();
    final Object? source = section.source;
    if (source is Map && source['ids'] is List) {
      return [
        for (final Object? id in source['ids'] as List)
          if (id is String && PillBank.byId(id) != null) PillBank.byId(id)!,
      ].take(most).toList();
    }
    return PillBank.cards
        .where((p) => subject == null || p.topic == subject)
        .take(most)
        .toList();
  }

  @override
  bool isRead(Pill pill) => app.seenIds.contains(pill.id);

  @override
  void open(ExploreSection section, List<Pill> shelf, Pill pill) =>
      opened.add((section.id, pill.id));

  @override
  void playStory(
    ExploreSection section,
    List<Pill> shelf,
    Pill pill,
    Rect? from,
  ) => opened.add((section.id, pill.id));

  @override
  Future<void> commit(Pill pill, String response) async =>
      answered.add((pill.id, response));

  @override
  Future<void> lean(Pill pill, int side, int confidence) async =>
      leaned.add((pill.id, side, confidence));

  @override
  void seen(ExploreSection section, Pill pill) =>
      shown.add((section.id, pill.id));

  @override
  Widget watch(ExploreSection section, Widget child) => child;

  @override
  void openPlans(String from) => plans.add(from);

  @override
  void openSubject(String subject) => subjects.add(subject);

  @override
  void note(ExploreSection section, String event, Map<String, Object?> facts) =>
      notes.add((section.id, event, facts));
}
