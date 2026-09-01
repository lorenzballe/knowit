/// The subjects' own marks, taken from artboard 56.
///
/// SVG path data on a 24-unit grid at one stroke weight, drawn rather than
/// picked from an icon font: a flask for Science, a ringed planet for Space,
/// a temple for Philosophy. Kept as source paths so they are the artboard's
/// drawing and not a redrawing of it.
const Map<String, String> kSubjectIcons = {
  'Economics': 'M4 16l5-5 3 3 7-7 M15 7h5v5',
  'Sport': 'M7 4h10v4a5 5 0 0 1-10 0V4z M7 5H4v2a3 3 0 0 0 3 3 M17 5h3v2a3 3 0 0 1-3 3 M12 13v4 M9 20h6l-1-3h-4z',
  'Nature': 'M5 19C5 11 11 5 19 5c0 8-6 14-14 14z M9 15l6-6',
  'Science': 'M9 3h6 M10 3v6l-5.2 8.4A2 2 0 0 0 6.5 21h11a2 2 0 0 0 1.7-3.6L14 9V3 M7.5 15h9',
  'Language': 'M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H9l-5 4V6z M9 12l3-6 3 6 M10.2 10h3.6',
  'Technology': 'M9 9h6v6H9z M5 5h14v14H5z M9 5V2 M15 5V2 M9 22v-3 M15 22v-3 M5 9H2 M5 15H2 M22 9h-3 M22 15h-3',
  'Space': 'M12 4a8 8 0 1 0 0 16 8 8 0 0 0 0-16z M4.5 14.5c-2 1.5-2.8 3-2 3.9 1.4 1.6 7.3-.6 13.2-5s9.6-9.3 8.2-10.9c-.8-.9-2.4-.6-4.4.5',
  'Philosophy':
      'M3 9h18L12 3 3 9z M5.5 9v10 M9.8 9v10 M14.2 9v10 M18.5 9v10 M3 21h18',
  'Cinema': 'M3 8h18v12H3z M3 8l2-4h3l-2 4 M10 8l2-4h3l-2 4 M17 8l2-4h2',
  'Psychology': 'M20 12a8 8 0 1 0-4 6.9V22 M12 8a3 3 0 1 0 2 5.2',
  'Music': 'M9 18V6l10-2v12 M9 18a2.5 2.5 0 1 1-5 0 2.5 2.5 0 0 1 5 0z M19 16a2.5 2.5 0 1 1-5 0 2.5 2.5 0 0 1 5 0z M9 9l10-2',
  'Weird facts': 'M11 3l1.9 5.1L18 10l-5.1 1.9L11 17l-1.9-5.1L4 10l5.1-1.9L11 3z M19 4l.6 1.7 1.7.6-1.7.6-.6 1.7-.6-1.7-1.7-.6 1.7-.6L19 4z',
  'Art': 'M12 3a9 9 0 1 0 0 18 2 2 0 0 0 1.6-3.2 2 2 0 0 1 1.6-3.2H18a3 3 0 0 0 3-3c0-4.9-4-8.6-9-8.6z M7.6 10.6h.01 M10.1 7.1h.01 M14.6 7.6h.01 M6.6 14.1h.01',
  'Pop culture': 'M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1-5.4-2.9-5.4 2.9 1-6.1L3.2 9.5l6.1-.9L12 3z',
  'Human body':
      'M12 20s-7-4.6-7-9.4A4 4 0 0 1 12 8a4 4 0 0 1 7 2.6C19 15.4 12 20 12 20z',
  'Medicine': 'M10 3h4v7h7v4h-7v7h-4v-7H3v-4h7V3z',
  'Food': 'M6 3v7a2 2 0 0 0 4 0V3 M8 10v11 M17 3c-2 2-2 6 0 8v10',
  'History':
      'M7 3h10 M7 21h10 M7 3c0 4 5 5 5 9s-5 5-5 9 M17 3c0 4-5 5-5 9s5 5 5 9',
};

/// The icon wrapped as a standalone SVG document, which is what the renderer
/// takes. White, because it always sits on the subject's own fill.
String subjectIconSvg(String subject) {
  final path = kSubjectIcons[subject];
  if (path == null) return '';
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path d="$path" fill="none" stroke="#ffffff" stroke-width="1.9" '
      'stroke-linecap="round" stroke-linejoin="round"/></svg>';
}
