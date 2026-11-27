import 'package:flutter/material.dart';

import '../data/goals.dart';
import '../data/topics.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart' show Palette;

/// An area as the reader reads it.
String goalName(AppLocalizations l, Goal g) => switch (g) {
  Goal.money => l.goalMoney,
  Goal.business => l.goalBusiness,
  Goal.people => l.goalPeople,
  Goal.news => l.goalNews,
  Goal.health => l.goalHealth,
  Goal.decide => l.goalDecide,
};

/// What an area trains, in a line.
String goalLine(AppLocalizations l, Goal g) => switch (g) {
  Goal.money => l.goalMoneyLine,
  Goal.business => l.goalBusinessLine,
  Goal.people => l.goalPeopleLine,
  Goal.news => l.goalNewsLine,
  Goal.health => l.goalHealthLine,
  Goal.decide => l.goalDecideLine,
};

/// An area's mark.
IconData goalIcon(Goal g) => switch (g) {
  Goal.money => Icons.savings_rounded,
  Goal.business => Icons.work_rounded,
  Goal.people => Icons.forum_rounded,
  Goal.news => Icons.newspaper_rounded,
  Goal.health => Icons.favorite_rounded,
  Goal.decide => Icons.alt_route_rounded,
};

/// An area's colour: the colour of the subject it leans on most.
Color goalHue(Goal g) {
  final String key = switch (g) {
    Goal.money => 'economics',
    Goal.business => 'technology',
    Goal.people => 'life',
    Goal.news => 'science',
    Goal.health => 'medicine',
    Goal.decide => 'psychology',
  };
  return kTopics[key]?.color ?? Colors.white;
}

/// An area's colour as a mark on [p]'s page: its subject's own at night,
/// where every one of them reads on the black; on paper the same hue
/// deepened, all six to about one lightness (OKLCH 0.58 to 0.6, chroma held
/// down), so Economics' yellow and Life's peach still draw a line on white,
/// at 4:1 and more, and no one area shouts over the others.
Color goalTone(Goal g, Palette p) => p.isDark
    ? goalHue(g)
    : switch (g) {
        // A yellow deepens through amber, never olive.
        Goal.money => const Color(0xFF9E7200),
        Goal.business => const Color(0xFF0081C7),
        Goal.people => const Color(0xFFB76935),
        Goal.news => const Color(0xFF009164),
        Goal.health => const Color(0xFFC35044),
        Goal.decide => const Color(0xFF8563C7),
      };
