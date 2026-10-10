/// A free trial the store says will turn into a paid year: when it ends,
/// and what the year costs from then, in the store's own words.
///
/// Only a trial that will charge is one of these. A trial set not to renew
/// charges nothing and needs no warning, and one that has already turned
/// into the year has nothing left to warn about — both are null where a
/// trial is asked for.
///
/// The app keeps the last one the store described, the way it keeps the
/// plan: a launch with no network re-plans every notification, and one that
/// forgot the trial for want of an answer would cancel the very warning a
/// reader needs before the charge.
class FreeTrial {
  const FreeTrial({required this.endsAt, this.price});

  /// When the free days end, which is when the first year is charged.
  final DateTime endsAt;

  /// The year's price as the store writes it — "€29,99", "$29.99" — or null
  /// while the store has not said which plan the trial turns into. Nothing
  /// is promised about a charge whose price the app cannot name.
  final String? price;

  @override
  bool operator ==(Object other) =>
      other is FreeTrial &&
      other.endsAt.isAtSameMomentAs(endsAt) &&
      other.price == price;

  @override
  int get hashCode => Object.hash(endsAt.millisecondsSinceEpoch, price);

  @override
  String toString() => 'FreeTrial(ends $endsAt, $price)';
}
