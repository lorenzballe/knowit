/// Bets: estimate it before you open it (docs/explore, round 139).
///
/// Every piece of the round is a block the server can place anywhere in
/// Explore, each a different way of putting a number on a card before it
/// is opened: a range, narrow or wide (139a), and the slip the day's bets
/// land on; a stake from the day's hundred points (139b), and a card to
/// send a friend; a number set on steppers, and the bigger of two figures
/// (139c); three steps of more or less, and orders of magnitude (139d);
/// the bet of the day (139e). docs/explore/bets.md has every piece, what
/// it needs and what a section of it may say.
library;

import '../explore_block.dart';
import 'bets/bigger.dart';
import 'bets/closer.dart';
import 'bets/day.dart';
import 'bets/friend.dart';
import 'bets/magnitude.dart';
import 'bets/number.dart';
import 'bets/range.dart';
import 'bets/slip.dart';
import 'bets/stake.dart';

/// The blocks of this family, in the order the catalogue lists them.
const List<ExploreBlock> blocks = [
  RangeBlock(),
  BetSlipBlock(),
  StakeBlock(),
  FriendBlock(),
  NumberBlock(),
  BiggerBlock(),
  CloserBlock(),
  MagnitudeBlock(),
  DayBlock(),
];
