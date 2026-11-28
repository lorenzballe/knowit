/// Where the small player of a book read aloud may sit
/// (lib/books/book_player_view.dart), as the screens say it: not while
/// Today's deck is on the table, not while a screen of cards is open, and
/// not under a sheet or a dialog, because nothing covers a card. A file of
/// its own, so the screens of cards can say so without knowing the player.
library;

import 'package:flutter/widgets.dart';

/// Where the small player may sit, as the screens say it: not while Today's
/// deck is on the table, and not while a screen of cards is open, because
/// nothing covers a card.
abstract final class BookPlayerRoom {
  /// True while Today's five, or the card after them, are on the table and
  /// Today is the tab in front (main.dart says so).
  static final ValueNotifier<bool> todayDeck = ValueNotifier<bool>(false);

  /// How many screens of cards are open (the deck viewer, a card's page):
  /// each says so as it opens and closes.
  static final ValueNotifier<int> cards = ValueNotifier<int>(0);

  static void cardsOpened() => cards.value++;
  static void cardsClosed() => cards.value = (cards.value - 1).clamp(0, 999);

  /// As at a launch: no deck, no cards, no routes. For the tests, which
  /// build one app after another.
  @visibleForTesting
  static void reset() {
    todayDeck.value = false;
    cards.value = 0;
    routes._stack.clear();
    routes.revision.value++;
  }

  /// The routes on the app's navigator, as far as the small player needs
  /// them: how many full pages are open, and whether a sheet or a dialog
  /// is on top.
  static final BookRoutes routes = BookRoutes();

  /// The app's navigator, so the small player, which sits above it, can
  /// open the whole player under it.
  static final GlobalKey<NavigatorState> navigator =
      GlobalKey<NavigatorState>();
}

/// The app's routes, counted: [pages] full pages (the shell is the first),
/// and whether a sheet or a dialog is on top.
class BookRoutes extends NavigatorObserver {
  final List<Route<dynamic>> _stack = [];

  /// Changes whenever the routes do.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  int get pages => _stack.whereType<PageRoute<dynamic>>().length;
  bool get popupOnTop => _stack.isNotEmpty && _stack.last is PopupRoute;

  void _changed() {
    // Said after the frame: a route is pushed in the middle of one.
    WidgetsBinding.instance.addPostFrameCallback((_) => revision.value++);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _changed();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _changed();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _changed();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final int i = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (newRoute != null) {
      if (i >= 0) {
        _stack[i] = newRoute;
      } else {
        _stack.add(newRoute);
      }
    } else if (i >= 0) {
      _stack.removeAt(i);
    }
    _changed();
  }
}
