# Figures for cards

A card is a rectangle of one flat colour with a question on it. This is
what draws the picture that sometimes goes with the question — a hundred
dots with one of them filled, a circle inside another circle, a curve that
doubles — and the rules that make such a picture usable by the app rather
than merely correct.

Nothing here is wired into the app yet. The card generator will run on a
server, call `render.py` with a spec, and store the SVG beside the card.

## The rule everything follows

The app draws a figure with

```dart
SvgPicture.string(svg, colorFilter: ColorFilter.mode(pill.ink, BlendMode.srcIn))
```

`srcIn` recolours **every pixel that is not transparent**. So:

- a figure has exactly **one colour**, and what it has instead of colour is
  line weight, fill against outline, and space;
- a white page under the drawing arrives as a **slab of ink over the whole
  card** — the one failure that looks like the app is broken rather than
  like the figure is wrong;
- there is no room for a legend, a title or an axis label. The card
  already carries the words, and type inside a figure would be set in
  whatever font the server happened to have.

`astuto_figures/normalise.py` is the gate that enforces this, and
everything passes through it — the figures drawn here and anything a
library hands over.

## What is installed, and why that list

| | | |
|---|---|---|
| **drawsvg** | SVG primitives | Everything drawn rather than plotted. Pure Python, writes SVG, and rasterises when something needs pixels. |
| **schemdraw** | circuits, block diagrams | Physics and technology cards. Pure Python with **its own** SVG backend — `schemdraw.use("svg")`, or it quietly renders through matplotlib and drags it in behind. |
| matplotlib | plots | Only when a card needs a real plot: a distribution, a fit, a curve with data behind it. |
| networkx | graph layout | When *where the nodes go* has to be computed rather than chosen. Drawn through matplotlib. |
| sympy | symbolic maths | Not a drawing library. It is here so a generated card's algebra can be checked rather than trusted. |

The first two are `requirements.txt` and come to **31 MB**, pure Python,
no system libraries and no compiler. The rest are `requirements-plots.txt`
and add about **270 MB** — worth knowing before it lands in an image.

## Manim, measured

The one 3Blue1Brown wrote. Three things were checked here rather than
assumed, and together they say the same thing: it is the right tool for
something this app does not do yet.

1. **It cannot write SVG.** `--format` takes `png`, `gif`, `mp4`, `webm`
   and `mov`. Everything else here produces a vector the app recolours to
   the card's ink; manim produces pixels, which must ship at 3× and cannot
   follow the card's colour.
2. **It is not pip-installable on its own.** `manimpango` needs
   pangocairo ≥ 1.30 *with its headers* at build time — on this machine
   `pip install manim` failed until `libcairo2-dev`, `libpango1.0-dev` and
   `pkg-config` were installed. Anything that moves needs ffmpeg too, and
   `MathTex` needs a LaTeX install on top of that.
3. **It costs about 340 MB** on top of the core, and brings scipy,
   moderngl, pycairo, skia-pathops and av with it.

Rendering is not the problem: a still took **0.99 s**. The problem is that
a still is what a card wants, and a still is what manim is not for. When
there is somewhere in the app for something to *move* — a reveal that
builds a diagram a step at a time is the obvious one — then
`requirements-manim.txt` is here and it works.

## Using it

```sh
pip install -r requirements.txt          # 31 MB, drawing only
pip install -r requirements-plots.txt    # + matplotlib, networkx, sympy

# one figure, from a spec on stdin
echo '{"kind": "frequency_grid", "total": 100, "marked": 1, "flagged": 6}' \
  | python render.py > figure.svg

# every example, which is what the Dart test checks
python render.py --examples examples/
python from_libraries.py examples/
```

### The kinds

| kind | what it says | the cards it is for |
|---|---|---|
| `frequency_grid` | a crowd, and who in it the number is about | base rates, false positives, screening |
| `nested_sets` | one set inside another | conjunction — everyone with a car and panels also has a car |
| `curve` | a shape over time | exponential growth, decay, a gap closing |
| `rings` | a share of a whole, and a second share against it | what you claimed against what happened |
| `tree` | a branching count | coin flips, screening trees, compounding |

`frequency_grid` is the one worth having. "1 in 500, and the test flags
5%" is a sentence almost nobody can hold; a hundred dots of which one is
filled, with rings scattered where the test points, is the same fact at a
glance — which is the finding this app is built on. It is also why the ill
are drawn together, so they can be counted, while the false positives are
spread through the crowd, which is where they actually fall.

## The tests are in Dart, on purpose

`test/figures_test.dart`, in the app's own suite. The figures are produced
in another language by a program that will run somewhere else, so nothing
in the Dart build would notice if one came back as a black slab, an empty
document, or a file the renderer cannot parse. All three happened once
each while these rules were being worked out:

- matplotlib writes its background as `fill: none`, and a regex with a
  lookahead backtracked past the `none` and repainted it — a black
  rectangle over the whole card;
- stripping "anything that neither fills nor strokes" also stripped the
  `<path>` inside a `<clipPath>`, which left an empty clip and threw the
  whole figure away;
- schemdraw writes `stroke-dasharray:-` on every solid line. Chromium
  ignores it; `flutter_svg` reads it as a number and throws
  `FormatException: Invalid double`, and the figure does not draw at all.

The last one is the reason the tests are where they are. A figure checked
in a browser and shipped to a renderer hides its faults in the gap between
the two.
