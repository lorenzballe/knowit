import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/l10n/app_localizations.dart';

/// Russian and Polish say a count three ways (one, few, many), and Russian's
/// "one" is every number ending in 1 but 11: 21 cards, 31 points. A count
/// said as English says it ("5 дней" for one day, "+1 очко" for 21) reads as
/// a machine's.
void main() {
  final AppLocalizations ru = lookupAppLocalizations(const Locale('ru'));
  final AppLocalizations pl = lookupAppLocalizations(const Locale('pl'));

  test('Russian: one, few and many, 21 with one', () {
    expect(ru.keptDaysOfSeven(1), 'Засчитана — 1 день из семи.');
    expect(ru.keptDaysOfSeven(3), 'Засчитана — 3 дня из семи.');
    expect(ru.keptDaysOfSeven(5), 'Засчитана — 5 дней из семи.');
    expect(ru.overconfidentBy(1), 'Ты переоцениваешь себя на 1 пункт');
    expect(ru.overconfidentBy(22), 'Ты переоцениваешь себя на 22 пункта');
    expect(ru.overconfidentBy(17), 'Ты переоцениваешь себя на 17 пунктов');
    expect(ru.stepRead(4), 'ещё 4 карточки прочитать');
    expect(ru.saveNTopics(3), 'Сохранить 3 темы');
    expect(ru.saveNTopics(13), 'Сохранить 13 тем');
    expect(ru.startWithNTopics(21), 'Начать с 21 темой');
    expect(ru.subjectsInTheMix(12, 13), '12 из 13 тем в миксе');
    expect(ru.closerStepsRight(2, 3), 'Верно 2 из 3 шагов.');
    expect(ru.nudgeTwoWeeksBodyNoGap(2, '?'), 'Пока 2 ответа. Сегодня: ?');
    expect(ru.searchNCards(21), contains('21 карточки'));
    // Never a written 1 standing in for 21.
    expect(ru.threePoints(1), '+1 очко');
    expect(ru.threePoints(21), '+21 очко');
    expect(ru.threePoints(0), 'Нет очков');
    expect(ru.journeyReactedOf(21), 'из 21 карточки, которая спрашивала');
    expect(ru.answersRightOf(21, 30), '21 из 30 верно');
    // A first that has its own words keeps them.
    expect(ru.newsDaysAgo(1), 'Вчера');
    expect(ru.dailyFirst(1), startsWith('Первый игрок сегодня'));
    expect(ru.dailyFirst(3), startsWith('Среди первых 3 игроков'));
  });

  test('Polish: one, few and many, 12 to 14 with many', () {
    expect(pl.keptDaysOfSeven(1), 'Zaliczony — 1 dzień z siedmiu.');
    expect(pl.keptDaysOfSeven(3), 'Zaliczony — 3 dni z siedmiu.');
    expect(pl.stepRead(1), 'jeszcze 1 karta do przeczytania');
    expect(pl.stepRead(3), 'jeszcze 3 karty do przeczytania');
    expect(pl.stepRead(5), 'jeszcze 5 kart do przeczytania');
    expect(pl.stepRead(12), 'jeszcze 12 kart do przeczytania');
    expect(pl.stepRead(22), 'jeszcze 22 karty do przeczytania');
    expect(pl.overconfidentBy(2), 'Jesteś zbyt pewny o 2 punkty');
    expect(pl.overconfidentBy(15), 'Jesteś zbyt pewny o 15 punktów');
    expect(pl.saveNTopics(4), 'Zapisz 4 tematy');
    expect(pl.saveNTopics(13), 'Zapisz 13 tematów');
    expect(pl.subjectsInTheMix(12, 13), '12 z 13 tematów w miksie');
    expect(pl.seriesMeta(1, 3), '1 karta · około 3 min');
    expect(pl.threePoints(3), '+3 punkty');
    expect(pl.threePoints(25), '+25 punktów');
  });
}
