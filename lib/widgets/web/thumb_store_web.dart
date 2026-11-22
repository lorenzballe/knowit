import 'thumb_store_base.dart';

export 'thumb_store_base.dart';

/// On the web the browser keeps what it fetched; the app keeps nothing more
/// than a run's worth.
ThumbStore thumbStoreOnThisPhone() => MemoryThumbStore();
