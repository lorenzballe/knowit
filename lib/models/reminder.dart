/// One notification, planned: when it lands and what it says.
///
/// The app plans a fortnight of these at a time and hands the whole plan
/// over, rather than one repeating reminder. A repeating reminder can only
/// ever say one thing; a fortnight of single ones can each carry the
/// question of the day they land on, and say something else on the days
/// that ask for it.
class Reminder {
  const Reminder({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
  });

  /// Stable per slot, so re-planning replaces rather than piles up.
  final int id;
  final DateTime when;
  final String title;
  final String body;

  @override
  String toString() => 'Reminder($id, $when, $title: $body)';
}
