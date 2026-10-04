# Il kit: librerie, colori, strumenti

> Tutto quello che serve per **costruire** una carta. Le regole su *cosa* costruire sono in `../SCOPO.md`, `../CRITERI.md`, `../FORMATI.md`, `../STILE.md`.

## Come è fatto il kit

| File | Cosa fa |
|---|---|
| `astute-card.css` | La cornice di ogni carta: colore, bordo, etichetta, domanda, riquadro finale, fonte. Le misure sono in `cqh`/`cqw`, così la carta è uguale su ogni telefono |
| `astute-card.js` | Il mazzo (frecce, puntini) e gli aiuti: `Kit.fitSvg` / `Kit.fitCanvas` (disegni alla misura vera, scritte mai stirate), `Kit.show` / `Kit.hide`, `Kit.mk` (SVG), `Kit.rnd` / `Kit.gauss` (casualità ripetibile), `Kit.onShow[id]`, `Kit.play[id]` |
| `template.html` | Il punto di partenza di una pagina di carte |
| `vendor/` | Copie locali delle librerie, per provare le pagine senza rete |
| `../../../tool/cards/card_check.cjs` | **Il controllore della grafica** (vedi sotto) |

## Le librerie

Si usa quella che serve alla storia, non tutte. **Ogni carta di un gruppo deve usare una tecnica diversa** dalle altre.

| Libreria | Per cosa | Pubblicare (CDN) | Locale | Nell'app (Flutter) |
|---|---|---|---|---|
| **GSAP** 3.15 | Movimento: entrate, sequenze, numeri che contano, testo che vola | `https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/gsap.min.js` | `vendor/gsap.min.js` | `flutter_animate`, `AnimationController` |
| **Plugin GSAP** (gratis da GSAP 3.13) | `SplitText` testo che si spezza in lettere e parole · `DrawSVGPlugin` linee che si disegnano · `MorphSVGPlugin` una forma che diventa un'altra · `MotionPathPlugin` oggetti lungo un percorso · `Flip` elementi che cambiano posto con continuità · `ScrambleTextPlugin` testo che si "decifra" · `Physics2DPlugin` lanci e gravità · `CustomEase` curve su misura | `https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/<Nome>.min.js` | `vendor/gsap-plugins/` | `CustomPainter` + `AnimationController`, `path_drawing` |
| **Lottie** | Animazioni disegnate da un designer (After Effects), leggerissime | `https://cdn.jsdelivr.net/npm/lottie-web@5.13.0/build/player/lottie.min.js` | `vendor/lottie.min.js` | `lottie` (stesso file .json) |
| **Rive** | Animazioni interattive con stati (reagiscono al tocco) | `https://cdn.jsdelivr.net/npm/@rive-app/canvas@2.44.0/rive.js` | `vendor/rive.js` + `rive.wasm` | `rive` (stesso file .riv) |
| **p5.js** | Arte generativa e sketch interattivi | `https://cdn.jsdelivr.net/npm/p5@2.3.4/lib/p5.min.js` | `vendor/p5.min.js` (licenza LGPL, copia non modificata) | `CustomPainter` |
| **D3** | Grafici e dati veri: scale, assi, curve, mappe | `https://cdn.jsdelivr.net/npm/d3@7.9.0/dist/d3.min.js` | `vendor/d3.min.js` | `CustomPainter`, `fl_chart` |
| **rough.js** | Stile disegnato a mano, schizzi | `https://cdn.jsdelivr.net/npm/roughjs@4.6.6/bundled/rough.js` | `vendor/rough.js` | `CustomPainter` con tratti irregolari |
| **Matter.js** | Fisica: cose che cadono, rimbalzano, si urtano | `https://cdn.jsdelivr.net/npm/matter-js@0.20.0/build/matter.min.js` | `vendor/matter.min.js` | `forge2d` / `flame` |
| **three.js** | 3D: oggetti che ruotano, spazio, scale | `https://cdn.jsdelivr.net/npm/three@0.170.0/build/three.module.min.js` | `vendor/three.module.min.js` | `flutter_gl`, oppure video pre-renderizzati |
| **Tone.js** | Suono: note, ritmi, illusioni sonore | `https://cdn.jsdelivr.net/npm/tone@15.0.4/build/Tone.js` | `vendor/Tone.js` | `just_audio` + suoni generati |
| **Canvas e SVG** | Particelle, arte generativa, disegni su misura | (nel browser) | (nel browser) | `CustomPainter` |
| **Manim** (3Blue1Brown) | Video di spiegazioni matematiche, per le carte *Video* | `bash tool/cards/setup_manim.sh`, poi `/opt/manim-venv/bin/manim -qh scena.py Scena` | — | Il video (.mp4) si mette nella carta |

Altre da considerare quando servono: **Motion Canvas** (video animati da codice, c'è la skill `mo-motion-canvas`). **Remotion** no: la licenza non è libera per le aziende.

Come usare bene ognuna: le skill `mo-*` (vedi `SKILLS.md`).

## I colori delle materie

| Materia | Colore `--c` | Inchiostro `--k` | Bordo `--edge` |
|---|---|---|---|
| Economics | `#FFE600` | `#10100c` | `#9c8d00` |
| Sport | `#A6FF00` | `#10100c` | `#5f9400` |
| Nature | `#00D451` | `#10100c` | `#007a2f` |
| Science | `#00E5A0` | `#10100c` | `#00835b` |
| Language | `#00D9D9` | `#10100c` | `#007f80` |
| Technology | `#00A6FF` | `#10100c` | `#005e91` |
| Space | `#2B5CFF` | `#ffffff` | `#152f8f` |
| Philosophy | `#4C6FFF` | `#ffffff` | `#2a3fa3` |
| Cinema | `#6E3AFF` | `#ffffff` | `#3d1e99` |
| Psychology | `#9B5CFF` | `#ffffff` | `#5a2ea6` |
| Music | `#C13AFF` | `#ffffff` | `#6e1a99` |
| Weird facts | `#E040FB` | `#ffffff` | `#82208f` |
| Art | `#FF00A8` | `#ffffff` | `#990066` |
| Pop culture | `#FF3D7F` | `#ffffff` | `#a3204d` |
| Human body | `#FF2D5F` | `#ffffff` | `#9e1638` |
| Medicine | `#FF3B30` | `#ffffff` | `#9e1c14` |
| Food | `#FF7A1A` | `#10100c` | `#a3470a` |
| History | `#FFB000` | `#10100c` | `#a06c00` |
| Life | `#FFC49B` | `#10100c` | `#a8714a` |
| Thinking | `#F2F1EC` | `#10100c` | `#8f8d84` |

Una carta "notte" (fondo scuro, accento della materia) è ammessa per il bello e lo spazio, con parsimonia.

## Il controllore della grafica

Ogni pagina di carte passa da qui **prima** di essere mostrata a qualcuno:

```
node tool/cards/card_check.cjs <pagina.html> [cartella-screenshot]
```

- Fotografa ogni carta su **tre telefoni** (piccolo, medio, grande).
- Se la pagina registra `Kit.play[id]`, la **gioca fino in fondo** e la rifotografa: molti difetti compaiono solo dopo (etichette che si sovrappongono a un grafico appena disegnato).
- Segnala: colonna che trabocca, elementi fuori dalla carta, **scritte che si sovrappongono** nei disegni, grandi spazi vuoti, errori del codice.

Il controllore **non basta da solo**. Dopo che dice "clear", **si guardano gli screenshot uno per uno**, come li vedrebbe il lettore: allineamenti, scritte storte o troppo piccole, spazi vuoti, cose brutte. Poi passa al critico (vedi `CRITERI.md`).

Nota: per provare in locale le pagine usano `vendor/`; per pubblicarle si usano i link CDN.

## Ispirazione: come darla

Instagram e YouTube non sono raggiungibili da qui, quindi i profili non si possono guardare direttamente. Il modo che funziona:
- **screenshot e video** mandati in chat, o caricati in una cartella: si salvano in `../ispirazione/` e si descrivono in `../ISPIRAZIONE.md`;
- **nomi** di profili, canali, designer e libri: chi crea le carte li conosce spesso già, e li usa come riferimento di stile.
