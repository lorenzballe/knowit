import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:astuto/sync/subscription.dart';

/// A year on sale as the store would hand it over, with its introductory
/// offer, if it has one.
Offering _yearWith(IntroductoryPrice? intro) {
  const context = PresentedOfferingContext('default', null, null);
  final year = Package(
    '\$rc_annual',
    PackageType.annual,
    StoreProduct(
      'astuto_pro_year',
      'Astute+',
      'Astute+',
      29.99,
      '€29,99',
      'EUR',
      introductoryPrice: intro,
    ),
    context,
  );
  return Offering('default', '', const {}, [year], annual: year);
}

IntroductoryPrice _free(PeriodUnit unit, int units) => IntroductoryPrice(
  0,
  '€0,00',
  'P$units${unit.name[0].toUpperCase()}',
  1,
  unit,
  units,
);

void main() {
  test('the free days are the ones the store is set to give', () {
    final store = Subscription(keyOverride: '');
    // No store yet, or none at all: the plan as sold, two weeks.
    expect(store.trialDays, kTrialDays);
    expect(kTrialDays, 14);

    store.answerForTest(offering: _yearWith(_free(PeriodUnit.week, 2)));
    expect(store.trialDays, 14);
    // A store still set to a week says a week, never the two the app hopes.
    store.answerForTest(offering: _yearWith(_free(PeriodUnit.week, 1)));
    expect(store.trialDays, 7);
    store.answerForTest(offering: _yearWith(_free(PeriodUnit.day, 14)));
    expect(store.trialDays, 14);
    store.answerForTest(offering: _yearWith(_free(PeriodUnit.month, 1)));
    expect(store.trialDays, 30);

    // A year with no offer, or an offer that costs, starts with no free days.
    store.answerForTest(offering: _yearWith(null));
    expect(store.trialDays, isNull);
    store.answerForTest(
      offering: _yearWith(
        const IntroductoryPrice(0.99, '€0,99', 'P1W', 1, PeriodUnit.week, 1),
      ),
    );
    expect(store.trialDays, isNull);
  });

  test('a reader who has had the trial is not promised it again', () {
    final store = Subscription(keyOverride: '');
    final Offering offering = _yearWith(_free(PeriodUnit.week, 2));
    store.answerForTest(
      offering: offering,
      yearlyEligibility:
          IntroEligibilityStatus.introEligibilityStatusIneligible,
    );
    expect(store.trialDays, isNull);
    // Apple not knowing is not Apple saying no: the offer as the store has it.
    store.answerForTest(
      offering: offering,
      yearlyEligibility: IntroEligibilityStatus.introEligibilityStatusUnknown,
    );
    expect(store.trialDays, 14);
    store.answerForTest(
      offering: offering,
      yearlyEligibility: IntroEligibilityStatus.introEligibilityStatusEligible,
    );
    expect(store.trialDays, 14);
  });
}
