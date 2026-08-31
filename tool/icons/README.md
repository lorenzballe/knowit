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

Only the in-app mark follows the theme: `assets/brand/mark-*.png` ship in both
and `BrandMark` picks, while the web favicon swaps on `prefers-color-scheme`.
A home-screen icon follows the phone's theme on neither platform — Android's
themed icons are a monochrome layer, and iOS 18's dark variant is a separate
entry in the asset catalogue. Neither is set up here.
