// The colours a hard card's page is told to draw itself in, ringed, as the app tells it (lib/widgets/hard_ring.dart,
// HardRing.pageOf): its ground (c), its ink (k: the drawing, the subject's name, what it asks), its question's ink (q),
// the ring the app draws round it (edge), and HARD in the reader's words (label). The checker photographs a page so
// (tool/cards/card_check.cjs, HARD=1 or HARD=day) and the camera takes a hard card's pictures so (tool/cards/thumbs.cjs).
//
//   const hardEnv = require('./hard_env.cjs');
//   hardEnv('maths')                          the night paper
//   hardEnv('maths', {day: true})             the day paper
//   hardEnv('maths', {label: 'DIFFICILE'})    HARD in Italian
//
// On the night paper: the night ground, the subject's colour as the ink (a deep one lifted until small words read in
// it), the question in the light ink. On the day paper: the raised paper, the subject's colour (a pale one taken to its
// darker tone, as Explore's shelf of the hardest takes it) as the ring, and as the ink taken down, its hue kept, until
// small words read in it on the paper (4.5 to 1), the question in the dark ink.
const fs = require('fs'), path = require('path');

const KIT = path.join(__dirname, '../../docs/cards/kit');
const NIGHT = {ground: '#0b0b0d', question: '#f2f1ec'};
const DAY = {ground: '#ffffff', question: '#131316'};
// Small words read on the paper at this contrast, as the web's rule for small type asks.
const READS = 4.5;

const rgbOf = hex => hex.slice(1).match(/../g).map(h => parseInt(h, 16));
const hexOf = c => '#' + c.map(v => Math.round(Math.max(0, Math.min(255, v))).toString(16).padStart(2, '0')).join('');
const lin = v => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); };
const luminance = c => 0.2126 * lin(c[0]) + 0.7152 * lin(c[1]) + 0.0722 * lin(c[2]);
const contrast = (a, b) => { const x = luminance(a), y = luminance(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05); };
const shade = (c, k) => c.map(v => Math.round(v * k));

// The subject's colour, as the kit has it (docs/cards/kit/astute-card.js, SUBJECTS).
function colourOf(topic) {
  const kit = fs.readFileSync(path.join(KIT, 'astute-card.js'), 'utf8');
  return (kit.match(new RegExp(`\\b${topic}: \\['[^']*', '(#[0-9A-Fa-f]{6})'`)) || [])[1] || '#F2F1EC';
}

function hardEnv(topic, {day = false, label = 'HARD'} = {}) {
  const colour = rgbOf(colourOf(topic));
  const paper = day ? DAY : NIGHT, ground = rgbOf(paper.ground);
  const accent = day && luminance(colour) > 0.45 ? shade(colour, 0.62) : colour;
  let ink = accent;
  if (!day && luminance(accent) < 0.16) ink = accent.map(v => v + (255 - v) * 0.4);
  if (day) for (let k = 0.98; contrast(ink, ground) < READS && k > 0.2; k -= 0.02) ink = shade(accent, k);
  return {c: paper.ground, k: hexOf(ink), q: paper.question, edge: hexOf(accent), label};
}

module.exports = hardEnv;
module.exports.contrast = (a, b) => contrast(rgbOf(a), rgbOf(b));
