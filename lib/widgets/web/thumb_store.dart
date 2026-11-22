/// Where the cards' pictures are kept between runs: files in the app's cache
/// on a phone, nothing on the web, whose browser keeps its own.
library;

export 'thumb_store_io.dart'
    if (dart.library.js_interop) 'thumb_store_web.dart';
