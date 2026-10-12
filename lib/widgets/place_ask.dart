import 'package:flutter/material.dart';

import '../analytics.dart';
import '../data/topics.dart';
import '../l10n/l10n.dart';
import '../legal.dart';
import '../models/place.dart';
import '../state/app_state.dart';
import '../sync/place_finder.dart';
import '../theme.dart';
import 'ui.dart';

/// The place as a reader would name it: the city, or, where the phone gave
/// none, the region, and failing that the country.
String placeName(Place place) =>
    place.city ?? place.regionName ?? place.region ?? place.country;

/// Asks the reader whether Astute may learn where they live: the app's own
/// sheet first, and the system's prompt only after a yes on it. What it
/// leads to is one place, read and named on the phone, and nothing finer
/// than a city kept (see Place).
///
/// For a reader who asked: Explore's "Where you live" shelf, which offers
/// it with [from] `explore`, and Profile, with `profile`. Where the system
/// will no longer ask, it offers the phone's settings instead of a sheet
/// that could lead nowhere; where nothing can be read — the web, a phone
/// with location switched off — it says so.
Future<void> askForPlace(
  BuildContext context,
  AppState app, {
  required String from,
}) async {
  await _askForPlace(context, app, from: from, offered: false);
}

/// The same sheet at the app's own moment, after a finished day
/// (AppState.shouldAskForPlace, chosen in lib/main.dart). Nobody asked for
/// it, so where it could not lead anywhere it is not shown at all. True
/// when the sheet was put.
Future<bool> offerPlace(BuildContext context, AppState app) =>
    _askForPlace(context, app, from: 'day done', offered: true);

Future<bool> _askForPlace(
  BuildContext context,
  AppState app, {
  required String from,
  required bool offered,
}) async {
  final PlaceFinder finder = PlaceFinder.instance;
  final _Say say = _Say.of(context);
  if (!finder.canAsk) {
    if (!offered) say(say.l.placeNotHere);
    return false;
  }
  final LocationAccess before = await finder.access();
  if (!context.mounted) return false;
  switch (before) {
    case LocationAccess.unavailable:
      if (!offered) say(say.l.placeServicesOff);
      return false;
    case LocationAccess.deniedForever:
      // The system will not ask again, so a sheet leading to its prompt
      // would lead nowhere: the phone's settings are the only way back.
      if (!offered) await _offerSettings(context, app);
      return false;
    case LocationAccess.notAsked:
    case LocationAccess.granted:
    case LocationAccess.denied:
      break;
  }
  await app.notedPlaceAsked();
  Analytics.capture('place asked', {'from': from, 'nth': app.placeAsks});
  if (!context.mounted) return false;
  final bool yes = await showPlaceAsk(context) ?? false;
  Analytics.capture('place answered', {'choice': yes ? 'yes' : 'not_now'});
  if (!yes) {
    await app.notedPlaceDeferred();
    return true;
  }
  await _useLocation(app, from: from, access: before, say: say);
  return true;
}

/// The reader said yes — on the sheet, or with "Use my location now" in
/// Profile: the system's prompt where it is still to be put, then the
/// place. A no to the prompt is taken as said, with a word on where to
/// change it later; nothing is pushed at the reader who has just said it.
Future<void> _useLocation(
  AppState app, {
  required String from,
  required LocationAccess access,
  required _Say say,
}) async {
  final PlaceFinder finder = PlaceFinder.instance;
  LocationAccess now = access;
  if (now != LocationAccess.granted) {
    now = await finder.ask();
    final bool granted = now == LocationAccess.granted;
    Analytics.capture('location permission answered', {
      'granted': granted,
      'precise': granted ? await finder.precise() : null,
    });
  }
  switch (now) {
    case LocationAccess.granted:
      await app.notedLocationPermission(AppState.kLocationGranted);
      final Place? found = await app.readPlace(from: from);
      say(
        found == null
            ? say.l.placeNotFound
            : say.l.placeSetTo(placeName(found)),
      );
    case LocationAccess.denied:
    case LocationAccess.deniedForever:
      await app.notedLocationPermission(AppState.kLocationDenied);
      say(say.l.placeDeniedNote);
    case LocationAccess.unavailable:
      say(say.l.placeServicesOff);
    case LocationAccess.notAsked:
      // The prompt went without an answer: nothing was said.
      break;
  }
}

/// "Use my location now", from Profile: the place read again at once, for
/// a reader who keeps one and has just moved.
Future<void> _readAgain(BuildContext context, AppState app) async {
  final PlaceFinder finder = PlaceFinder.instance;
  final _Say say = _Say.of(context);
  if (!finder.canAsk) {
    say(say.l.placeNotHere);
    return;
  }
  final LocationAccess access = await finder.access();
  if (!context.mounted) return;
  switch (access) {
    case LocationAccess.unavailable:
      say(say.l.placeServicesOff);
    case LocationAccess.deniedForever:
      await _offerSettings(context, app);
    case LocationAccess.notAsked:
    case LocationAccess.granted:
    case LocationAccess.denied:
      await _useLocation(app, from: 'profile', access: access, say: say);
  }
}

/// The phone's settings, offered when the system will not ask again. A
/// reader who goes there has said yes to the app, so the place is read as
/// soon as they come back with the permission given
/// (AppState.refreshPlaceIfDue).
Future<void> _offerSettings(BuildContext context, AppState app) async {
  final l = context.l10n;
  final Palette p = context.p;
  final bool? open = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('place-settings'),
      backgroundColor: p.surface,
      title: Text(
        l.placeSettingsTitle,
        style: AppText.display(size: 19, color: p.ink),
      ),
      content: Text(
        l.placeSettingsBody,
        style: AppText.body(size: 14, height: 1.45, color: p.inkMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            l.placeAskNotNow,
            style: AppText.body(size: 14, color: p.ink),
          ),
        ),
        TextButton(
          key: const ValueKey('place-open-settings'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            l.placeSettingsOpen,
            style: AppText.body(
              size: 14,
              weight: FontWeight.w600,
              color: p.link,
            ),
          ),
        ),
      ],
    ),
  );
  if (open != true) return;
  await app.notedLocationPermission(AppState.kLocationDenied);
  await PlaceFinder.instance.openSettings();
}

/// What the flows say once they are done, on the screen they started from,
/// in its language — both taken while there was still a context to take
/// them from.
class _Say {
  _Say(this.l, this._messenger);

  factory _Say.of(BuildContext context) =>
      _Say(context.l10n, ScaffoldMessenger.maybeOf(context));

  final AppLocalizations l;
  final ScaffoldMessengerState? _messenger;

  void call(String text) => _messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Puts the sheet. True for "Use my location"; null for "Not now", or for a
/// sheet swiped away, which is a "Not now" too.
Future<bool?> showPlaceAsk(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) => const PlaceAsk(),
  );
}

/// The sheet: what a card about home looks like, what it costs — only the
/// city, never the position — and the two answers. Public so a test can lay
/// it out in every language.
class PlaceAsk extends StatelessWidget {
  const PlaceAsk({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return Container(
      key: const ValueKey('place-ask'),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.paddingOf(context).bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Handle(),
            const SizedBox(height: 20),
            Text(
              l.placeAskTitle,
              style: AppText.display(
                size: 20,
                weight: FontWeight.w600,
                spacing: -0.6,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.placeAskLine,
              style: AppText.body(size: 13.5, height: 1.4, color: p.inkMuted),
            ),
            const SizedBox(height: 16),
            const _PlacePreview(),
            const SizedBox(height: 16),
            Text(
              l.placeOnlyCity,
              key: const ValueKey('place-ask-promise'),
              style: AppText.body(
                size: 13.5,
                weight: FontWeight.w500,
                height: 1.4,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              key: const ValueKey('place-yes'),
              label: l.placeAskYes,
              height: 52,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 4),
            QuietButton(
              key: const ValueKey('place-not-now'),
              label: l.placeAskNotNow,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card about home, small: the line that says why it is there, and a
/// question of the kind it asks. History's colour, because a town's past
/// is where most of them start.
class _PlacePreview extends StatelessWidget {
  const _PlacePreview();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final TopicStyle topic = kTopics['history']!;
    final Color ink = topic.ink;
    return Container(
      key: const ValueKey('place-ask-preview'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: topic.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.place_rounded,
                size: 14,
                color: ink.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  l.placeAskPreviewLine,
                  style: AppText.label(
                    size: 11,
                    spacing: 0.6,
                    color: ink.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l.placeAskPreviewQuestion,
            style: AppText.display(
              size: 19,
              weight: FontWeight.w600,
              height: 1.2,
              spacing: -0.4,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: context.p.lineStrong,
          borderRadius: BorderRadius.circular(9),
        ),
      ),
    );
  }
}

/// Profile's "Where you live", for a reader who keeps a place: read it
/// again now, or remove it. Removing asks nothing more — switching it back
/// on is one tap away, on the same row.
Future<void> showPlaceOptions(BuildContext context, AppState app) async {
  final _Say say = _Say.of(context);
  final String? choice = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) => PlaceOptions(app: app),
  );
  if (!context.mounted) return;
  switch (choice) {
    case 'now':
      await _readAgain(context, app);
    case 'remove':
      await app.clearPlace();
      say(say.l.placeRemoved);
  }
}

/// The sheet behind Profile's row: the place as kept, the promise, and the
/// two things a reader can do with it. Public so a test can lay it out in
/// every language.
class PlaceOptions extends StatelessWidget {
  const PlaceOptions({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final Place? place = app.place;
    final String? region = place?.regionName ?? place?.region;
    final String where = place == null
        ? l.placeRowOff
        : [
            placeName(place),
            if (region != null && region != placeName(place)) region,
          ].join(' · ');
    return Container(
      key: const ValueKey('place-options'),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.paddingOf(context).bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Handle(),
            const SizedBox(height: 20),
            Eyebrow(l.placeRowTitle),
            const SizedBox(height: 8),
            Text(
              where,
              style: AppText.display(
                size: 20,
                weight: FontWeight.w600,
                spacing: -0.6,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.placeOnlyCity,
              style: AppText.body(size: 13.5, height: 1.4, color: p.inkMuted),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              key: const ValueKey('place-use-now'),
              label: l.placeUseNow,
              height: 52,
              onPressed: () => Navigator.of(context).pop('now'),
            ),
            const SizedBox(height: 4),
            Semantics(
              button: true,
              child: GestureDetector(
                key: const ValueKey('place-remove'),
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop('remove'),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.center,
                  child: Text(
                    l.placeRemove,
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: p.alert,
                    ),
                  ),
                ),
              ),
            ),
            // What the policy says of it, in full, for whoever wants more
            // than the one line above.
            QuietButton(
              key: const ValueKey('place-policy'),
              label: l.privacyPolicy,
              onPressed: () => openLink(placePolicyUrl(l.localeName)),
            ),
          ],
        ),
      ),
    );
  }
}
