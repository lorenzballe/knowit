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

const Map<String, TopicStyle> kTopics = {
  'space': TopicStyle(
    name: 'Space',
    color: Color(0xFF2B4BFF),
    ink: Color(0xFFFFFFFF),
    tint: Color(0xFFE6EAFF),
  ),
  'technology': TopicStyle(
    name: 'Technology',
    color: Color(0xFF0092C7),
    ink: Color(0xFFFFFFFF),
    tint: Color(0xFFD7F1FA),
  ),
  'language': TopicStyle(
    name: 'Language',
    color: Color(0xFF00B083),
    ink: Color(0xFFFFFFFF),
    tint: Color(0xFFD9F5EC),
  ),
  'nature': TopicStyle(
    name: 'Nature',
    color: Color(0xFF2FA84F),
    ink: Color(0xFFFFFFFF),
    tint: Color(0xFFE1F6E6),
  ),
  'economics': TopicStyle(
    name: 'Economics',
    color: Color(0xFFC6F24E),
    ink: Color(0xFF17200A),
    tint: Color(0xFFF0FBD4),
  ),
  'pop_culture': TopicStyle(
    name: 'Pop culture',
    color: Color(0xFFFFC93C),
    ink: Color(0xFF2B2400),
    tint: Color(0xFFFFF3D3),
  ),
  'science': TopicStyle(
    name: 'Science',
    color: Color(0xFFFF9500),
    ink: Color(0xFF2B1400),
    tint: Color(0xFFFFEAD1),
  ),
  'history': TopicStyle(
    name: 'History',
    color: Color(0xFFE0602A),
    ink: Color(0xFFFFFFFF),
    tint: Color(0xFFFBE0D3),
  ),
  'psychology': TopicStyle(
    name: 'Psychology',
    color: Color(0xFFFF4E2D),
    ink: Color(0xFFFFFFFF),
    tint: Color(0xFFFFE9E3),
  ),
  'weird_facts': TopicStyle(
    name: 'Weird facts',
    color: Color(0xFFFF2E9C),
    ink: Color(0xFFFFFFFF),
    tint: Color(0xFFFFE0F0),
  ),
  'human_body': TopicStyle(
    name: 'Human body',
    color: Color(0xFF7A5CFF),
    ink: Color(0xFFFFFFFF),
    tint: Color(0xFFECE7FF),
  ),
  'philosophy': TopicStyle(
    name: 'Philosophy',
    color: Color(0xFFA94BE0),
    ink: Color(0xFFFFFFFF),
    tint: Color(0xFFF3E1FB),
  ),
};
