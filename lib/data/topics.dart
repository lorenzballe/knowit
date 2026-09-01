import 'package:flutter/material.dart';

class TopicStyle {
  final String name;
  final Color color;
  final Color ink;
  final Color tint;

  const TopicStyle({
    required this.name,
    required this.color,
    required this.ink,
    required this.tint,
  });
}

/// The wheel every subject is drawn from.
///
/// These are the hues the mix screen hands the reader, in its order, so a
/// subject is the same colour wherever it turns up — the tile you dragged,
/// the card you read, the row in your record. The app has no colour of its
/// own on purpose: the colour on screen belongs to whatever you are reading.
const List<Color> kSpectrum = [
  Color(0xFFFFE600),
  Color(0xFFA6FF00),
  Color(0xFF00D451),
  Color(0xFF00E5A0),
  Color(0xFF00D9D9),
  Color(0xFF00A6FF),
  Color(0xFF2B5CFF),
  Color(0xFF4C6FFF),
  Color(0xFF6E3AFF),
  Color(0xFF9B5CFF),
  Color(0xFFC13AFF),
  Color(0xFFE040FB),
  Color(0xFFFF00A8),
  Color(0xFFFF3D7F),
  Color(0xFFFF2D5F),
  Color(0xFFFF3B30),
  Color(0xFFFF7A1A),
  Color(0xFFFFB000),
];

/// Black or white, whichever the colour can carry.
///
/// Luminance rather than a hand-kept list: a hue that changes gets the right
/// ink without anyone remembering to change it too. The threshold is the
/// canvas's own.
Color inkOn(Color colour) =>
    colour.computeLuminance() > 0.34 ? const Color(0xFF10100C) : Colors.white;

/// The colour laid on the black ground, faint enough to read on.
Color tintOf(Color colour) =>
    Color.alphaBlend(colour.withValues(alpha: 0.14), const Color(0xFF07070A));

TopicStyle _topic(String name, Color colour) => TopicStyle(
  name: name,
  color: colour,
  ink: inkOn(colour),
  tint: tintOf(colour),
);

final Map<String, TopicStyle> kTopics = {
  'space': _topic('Space', kSpectrum[6]),
  'technology': _topic('Technology', kSpectrum[5]),
  'language': _topic('Language', kSpectrum[4]),
  'nature': _topic('Nature', kSpectrum[2]),
  'economics': _topic('Economics', kSpectrum[0]),
  'pop_culture': _topic('Pop culture', kSpectrum[13]),
  'science': _topic('Science', kSpectrum[3]),
  'history': _topic('History', kSpectrum[17]),
  'psychology': _topic('Psychology', kSpectrum[9]),
  'weird_facts': _topic('Weird facts', kSpectrum[11]),
  'human_body': _topic('Human body', kSpectrum[14]),
  // Thinking is not a subject. Its cards are not economics or space applied
  // to reasoning — they are the reasoning itself, which is the app's own
  // voice, so they carry no hue at all. White is the one card that is not a
  // colour, and it happens to solve what a single hue could not: more than
  // half the deck lives here, and any colour would have made the whole app
  // that colour.
  'thinking': TopicStyle(
    name: 'Thinking',
    color: kThinkingWhite,
    ink: Color(0xFF10100C),
    tint: Color(0xFF16161A),
  ),
  'philosophy': _topic('Philosophy', kSpectrum[7]),
};

/// The paper a reasoning card is printed on.
const Color kThinkingWhite = Color(0xFFF2F1EC);

/// Display order used by the topic picker and the profile chips.
const List<String> kTopicOrder = [
  'thinking',
  'science',
  'space',
  'psychology',
  'economics',
  'technology',
  'history',
  'human_body',
  'philosophy',
  'pop_culture',
  'nature',
  'language',
  'weird_facts',
];

/// Reverse lookup, display name -> key.
String? topicKeyForName(String name) {
  for (final e in kTopics.entries) {
    if (e.value.name == name) return e.key;
  }
  return null;
}
