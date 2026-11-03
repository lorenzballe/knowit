/// Where the pages fetched are kept between runs: files in the app's cache
/// on a phone, nothing on the web, whose browser keeps its own.
library;

export 'card_page_store_io.dart'
    if (dart.library.js_interop) 'card_page_store_web.dart';
