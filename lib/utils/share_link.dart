/// Which share a link left the app in, as the site reads it in `ref`.
///
/// A card, a day or a record in someone else's chat is the only free
/// distribution the app has, and a bare address could not say which of the
/// three brought anybody back. So every shared link carries one of these,
/// and they live here, together, so that the site and the app agree on the
/// spelling and a new share cannot leave without one.
enum ShareRef {
  /// The day as five squares (`ShareDay`).
  day('share_day'),

  /// One card, from its share sheet.
  card('share_card'),

  /// The reader's record, from its share sheet.
  record('share_record');

  const ShareRef(this.ref);

  /// What the site reads in `ref`.
  final String ref;

  /// The site, carrying [ref].
  String get link => 'https://astutetheapp.com/?ref=$ref';
}
