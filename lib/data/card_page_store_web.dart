import 'card_page_store_base.dart';

export 'card_page_store_base.dart';

/// On the web the browser keeps what it fetched; the app keeps nothing.
PageStore pageStoreOnThisPhone() => MemoryPageStore();
