/// The subjects' own marks, from the design file's app screens (the
/// corrected set that replaced artboard 56: a ringed planet that reads as one,
/// a clapperboard with its hinge, a knife beside the fork).
///
/// SVG path data on a 24-unit grid at one stroke weight, drawn rather than
/// picked from an icon font: a flask for Science, a ringed planet for Space,
/// a temple for Philosophy. Kept as source paths so they are the artboard's
/// drawing and not a redrawing of it.
///
/// Thinking is not on the artboard — it is not a subject, and the canvas
/// never drew it one — but every card now carries its mark, and a card
/// with a hole where the mark should be reads as a fault rather than as a
/// choice. A bulb, on the same grid and at the same weight.
const Map<String, String> kSubjectIcons = {
  'Thinking': 'M9 18h6 M10 21h4 M12 3a6 6 0 0 0-3.5 10.9c.6.5 1 1.3 1 2.1h5c0-.8.4-1.6 1-2.1A6 6 0 0 0 12 3z',
  'Economics': 'M3 17l6-6 4 4 8-8 M15 7h6v6',
  'Sport': 'M7 4h10v4a5 5 0 0 1-10 0V4z M7 5H4.42v2a3 3 0 0 0 3 3 M17 5h2.58v2a3 3 0 0 1-3 3 M12 13v4 M9 20h6l-1-3h-4z',
  'Nature': 'M6 18C6 10 12 4 20 4c0 8-6 14-14 14z M4 20L15 9',
  'Science': 'M9 3h6 M10 3v6l-5.54 8.95A2 2 0 0 0 6.16 21h11.68a2 2 0 0 0 1.7-3.05L14 9V3 M6.29 15h11.42',
  'Language': 'M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H9l-5 4V6z M9 13l3-6 3 6 M10 11h4',
  'Technology': 'M7 5h10a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2z M10 9h4a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1h-4a1 1 0 0 1-1-1v-4a1 1 0 0 1 1-1z M9 5V3 M15 5V3 M9 21v-2 M15 21v-2 M5 9H3 M5 15H3 M21 9h-2 M21 15h-2',
  'Space': 'M12 5.5a6.5 6.5 0 1 0 0 13 6.5 6.5 0 1 0 0-13z M15.48 6.51A10.5 3.6 -30 1 1 5.51 12.27',
  'Philosophy':
      'M3 9h18L12 3 3 9z M5.5 9v12 M9.83 9v12 M14.17 9v12 M18.5 9v12 M3 21h18',
  'Cinema': 'M3 9h18v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9z M3 9V6a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v3 M8 4l-2 5 M13 4l-2 5 M18 4l-2 5',
  'Psychology': 'M20 11a8 8 0 1 0-4 6.93V21 M12 8a3 3 0 1 0 2.12 5.12',
  'Music': 'M9.5 17.75V5.75l10-2v12 M9.5 17.75a2.5 2.5 0 1 1-5 0 2.5 2.5 0 0 1 5 0z M19.5 15.75a2.5 2.5 0 1 1-5 0 2.5 2.5 0 0 1 5 0z M9.5 8.75l10-2',
  'Weird facts': 'M10 6.5l1.9 5.1 5.1 1.9-5.1 1.9-1.9 5.1-1.9-5.1-5.1-1.9 5.1-1.9z M18.5 3.5l.65 1.85 1.85.65-1.85.65-.65 1.85-.65-1.85-1.85-.65 1.85-.65z',
  'Art': 'M12 3a9 9 0 1 0 0 18 2 2 0 0 0 1.6-3.2 2 2 0 0 1 1.6-3.2H18a3 3 0 0 0 3-3c0-4.9-4-8.6-9-8.6z M6.83 13.88h.01 M7.02 9.68h.01 M10.12 6.83h.01 M14.32 7.02h.01',
  'Pop culture': 'M12 3.86l2.65 5.36 5.91.86-4.28 4.17 1.01 5.89L12 17.36l-5.29 2.78 1.01-5.89-4.28-4.17 5.91-.86z',
  'Human body': 'M12 19.63s-8-5.25-8-10.74A4.57 4.57 0 0 1 12 5.92a4.57 4.57 0 0 1 8 2.97c0 5.49-8 10.74-8 10.74z',
  'Medicine': 'M11 3h2a1 1 0 0 1 1 1v6h6a1 1 0 0 1 1 1v2a1 1 0 0 1-1 1h-6v6a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1v-6H4a1 1 0 0 1-1-1v-2a1 1 0 0 1 1-1h6V4a1 1 0 0 1 1-1z',
  'Food': 'M6 3v7a2 2 0 0 0 4 0V3 M8 12v9 M18 3v18 M18 3c-2.5 1.5-3.5 4.5-3.5 7.5a1.5 1.5 0 0 0 1.5 1.5H18',
  'History': 'M5 3h14 M5 21h14 M7 3c0 6 10 12 10 18 M17 3c0 6-10 12-10 18',
  'Life': 'M12 21v-9 M12 12c0-4 3-6 7-6 0 4-3 6-7 6z M12 15c0-3-2.5-5-6-5 0 3 2.5 5 6 5z',
};

/// The subjects whose fill is pale, which carry dark ink rather than white:
/// Life, which came after the saturated wheel was drawn.
const Set<String> kPaleSubjects = {'Life'};

/// The icon wrapped as a standalone SVG document, which is what the renderer
/// takes. White, because it always sits on the subject's own fill.
String subjectIconSvg(String subject, {double stroke = 1.9}) {
  final path = kSubjectIcons[subject];
  if (path == null) return '';
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path d="$path" fill="none" '
      'stroke="${kPaleSubjects.contains(subject) ? '#10100c' : '#ffffff'}" stroke-width="$stroke" '
      'stroke-linecap="round" stroke-linejoin="round"/></svg>';
}
