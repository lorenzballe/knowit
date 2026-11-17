# App icon

`source/master-light.png` and `source/master-dark.png` are the artwork, as
supplied: 1024px, square, full bleed. Nothing here redraws them — `sizes.py`
only resizes, so what ships on a phone is the drawing itself.

```sh
python3 tool/icons/sizes.py
```

`source/supplied-*.png` are the other exports that came with the masters. They
are kept for reference and nothing reads them; the two masters are enough to
produce every size.

The source files live here rather than in `assets/` because `pubspec.yaml`
bundles everything under `assets/brand/`, and shipping five 1024px copies
inside the app to show one 26px mark is weight for nothing.

Three platform rules the script handles, each of which is otherwise found out
at submission time:

- **iOS ships square and opaque.** The system rounds the corners itself, and
  App Store Connect rejects an icon with an alpha channel, so those files are
  flattened onto the ground the artwork already sits on. The 1024 is
  byte-for-byte the supplied master.
- **Android and the web round their own corners** — 20%, matching the rounded
  exports that came with the masters.
- **A maskable icon gets cropped** to whatever shape the launcher uses, so the
  artwork shrinks to 80% and the ground runs full bleed.

The in-app mark follows the theme: `assets/brand/mark-*.png` ship in both and
`BrandMark` picks, while the web favicon swaps on `prefers-color-scheme`.

The home-screen icon follows the phone too:

```sh
python3 tool/icons/glass.py --preview /tmp/icon-check   # needs numpy too
```

It splits the masters into their layers (the A, the pink card, the blue card)
without redrawing them, and writes:

- `ios/Runner/AppIcon.icon`: the Icon Composer file. iOS 26 draws it as Liquid
  Glass, with the A in front of the cards, each with its own light and shadow,
  on a cream or near-black ground. Xcode makes the icons for older iOS from the
  same file, and uses it instead of the asset catalogue's `AppIcon`. The
  catalogue stays, with its light, dark and tinted entries, as Apple advises
  while the file format settles.
- Android's adaptive icon (`mipmap-anydpi-v26/ic_launcher.xml`): the mark over
  the cream ground, sized into the safe circle, plus the monochrome layer that
  Android 13 and later tint with the phone's theme.

`--preview` writes the layers put back together, which should match the
masters; the script prints how far off they are.
