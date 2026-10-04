# Skill installate

Copiate in `.claude/skills/` da repository pubblici. Ognuna ha accanto la sua licenza (solo licenze libere: MIT, Apache 2.0, BSD) e un file `SOURCE.md` con l'origine. Il testo non è stato toccato, salvo il nome, che ha un prefisso per gruppo:

| Prefisso | Gruppo |
|---|---|
| *(nessuno)*, `taste-`, `hf-` | Design e gusto visivo (prima installazione) |
| `mo-` | Animazione, movimento, suono, video esplicativi |
| `fl-` | Flutter e Dart |
| `fb-` | Firebase |
| `rc-` | RevenueCat |
| `mk-` | Marketing e crescita |
| `aso-` | App Store e Play Store |
| `ct-` | Contenuti: spiegare, verificare, scrivere |
| `an-` | Altre di Anthropic |

Le skill si attivano da sole quando il lavoro le chiede. Quali usare per le carte lo dice la skill `astute-cards` (sezione 1b).

## Quale usare, per cosa

| Lavoro | Skill |
|---|---|
| **Creare una carta** | `astute-cards`, poi `frontend-design`, `taste-*`, le `mo-emil-*` (quando e come animare), `mo-gsap-*` (GSAP fatto bene), `mo-design-motion-principles` (controllo finale del movimento) |
| Carta con disegni che si tracciano, forme che cambiano | `mo-svg-animation`, `mo-gsap-plugins` |
| Carta generativa o interattiva | `algorithmic-art`, `mo-p5js` |
| Carta con suono | `mo-ui-sound-design` |
| Carta *Video* stile 3Blue1Brown | `mo-manim-composer`, `mo-manimce-best-practices`, `mo-manim-video`, `mo-3b1b-explainers` (Manim: `tool/cards/setup_manim.sh`) |
| Animazioni Lottie o Rive (leggere, perfette in Flutter) | `mo-lottie-motion-design`, `mo-text-to-lottie`, `mo-rive-interactive` |
| **Scrivere il testo** | `ct-feynman-technique` (prima il meccanismo, un'analogia onesta), `ct-humanizer` e `ct-avoid-ai-writing` (via i tic da IA) |
| **Verificare i fatti e le fonti** | `ct-fact-check-workflow`, `ct-source-verification`, `ct-fact-checker`, `ct-scientific-critical-thinking` (quanto è solido uno studio), `ct-citation-management` |
| Ricerca approfondita su un tema | `ct-research`, `ct-research-deep` |
| Grafici e dati | `dataviz`, `ct-data-storytelling`, `ct-data-visualization-discipline` |
| Domande e quiz | `ct-feynman-modes` (quiz socratico, analogie) |
| **Portare le carte nell'app** | `fl-animating-apps`, `fl-animations-mad`, `fl-flutter-animate`, `fl-z-custom-canvas-and-gestures`, `fl-z-motion-and-haptics`, `fl-fl-chart`, `fl-z-accessibility-as-code`, `fl-z-flutter-performance` |
| Test e qualità nell'app | `fl-flutter-add-widget-test`, `fl-z-widget-golden-and-a11y-testing`, `fl-flutter-fix-layout-issues` |
| Firebase | `fb-*` (regole di sicurezza: `fb-firebase-security-rules-auditor`) |
| Abbonamenti | `rc-*` (problemi: `rc-troubleshoot`; prove: `rc-testing-setup`) |
| Paywall, prezzi, prova gratuita | `aso-paywall-optimization`, `mk-paywalls`, `mk-pricing`, `rc-paywall-design`, `aso-subscription-lifecycle` |
| Onboarding e trattenere i lettori | `aso-onboarding-optimization`, `mk-onboarding`, `aso-retention-optimization`, `mk-churn-prevention` |
| Pagina negli store | `aso-keyword-research`, `aso-metadata-optimization`, `aso-screenshot-optimization`, `fl-store-screenshots`, `aso-localization` |
| Lancio | `aso-app-launch`, `mk-launch` |
| Social: video e caroselli dalle carte | `mk-social`, `mk-video`, `mk-instagram-carousel`, `hf-motion-graphics` |
| Testi del sito e degli store | `mk-copywriting`, `mk-copy-editing`, `mk-marketing-psychology` |
| Esperimenti e numeri (con PostHog) | `mk-ab-testing`, `mk-analytics` |
| Pubblicazione negli store, Codemagic | `fl-z-release-and-store-shipping`, `fl-codemagic` |

Le skill di marketing leggono prima `.claude/product-marketing.md` e `.claude/app-marketing-context.md`: la scheda di Astute (prodotto, lettori, prezzi, voce). Le voci **TO CONFIRM** vanno controllate dal proprietario.

## Prima installazione: design

| Skill | Fonte | Licenza |
|---|---|---|
| `frontend-design`, `algorithmic-art` | [anthropics/skills](https://github.com/anthropics/skills) | Apache 2.0 |
| `taste-taste-skill`, `taste-minimalist-skill`, `taste-soft-skill`, `taste-brutalist-skill`, `taste-redesign-skill` | [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) | MIT |
| `hf-hyperframes-animation`, `hf-hyperframes-keyframes`, `hf-motion-graphics` | [heygen-com/hyperframes](https://github.com/heygen-com/hyperframes) | Apache 2.0 |

Erano pensate per siti web: se ne prende il gusto e la tecnica, **dentro la cornice delle carte di Astute** (`STILE.md`).

## Seconda installazione: tutto il resto

### Animazione e movimento (per le carte)

| Skill | Fonte | Licenza |
|---|---|---|
| `mo-3b1b-explainers` | [AmitSubhash/3brown1blue](https://github.com/AmitSubhash/3brown1blue) | MIT |
| `mo-design-motion-principles` | [kylezantos/design-motion-principles](https://github.com/kylezantos/design-motion-principles) | MIT |
| `mo-emil-animate` | [emilkowalski/skills](https://github.com/emilkowalski/skills) | MIT |
| `mo-emil-animation-vocabulary` | [emilkowalski/skills](https://github.com/emilkowalski/skills) | MIT |
| `mo-emil-find-animation-opportunities` | [emilkowalski/skills](https://github.com/emilkowalski/skills) | MIT |
| `mo-emil-improve-animations` | [emilkowalski/skills](https://github.com/emilkowalski/skills) | MIT |
| `mo-emil-review-animations` | [emilkowalski/skills](https://github.com/emilkowalski/skills) | MIT |
| `mo-gsap-core` | [greensock/gsap-skills](https://github.com/greensock/gsap-skills) | MIT |
| `mo-gsap-performance` | [greensock/gsap-skills](https://github.com/greensock/gsap-skills) | MIT |
| `mo-gsap-plugins` | [greensock/gsap-skills](https://github.com/greensock/gsap-skills) | MIT |
| `mo-gsap-timeline` | [greensock/gsap-skills](https://github.com/greensock/gsap-skills) | MIT |
| `mo-gsap-utils` | [greensock/gsap-skills](https://github.com/greensock/gsap-skills) | MIT |
| `mo-lottie-motion-design` | [lottiefiles/motion-design-skill](https://github.com/lottiefiles/motion-design-skill) | MIT |
| `mo-manim-composer` | [adithya-s-k/manim_skill](https://github.com/adithya-s-k/manim_skill) | MIT |
| `mo-manim-video` | [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) | MIT |
| `mo-manimce-best-practices` | [adithya-s-k/manim_skill](https://github.com/adithya-s-k/manim_skill) | MIT |
| `mo-micro-interaction` | [iart-ai/web-animation-skills](https://github.com/iart-ai/web-animation-skills) | MIT |
| `mo-motion-canvas` | [apoorvlathey/motion-canvas-skills](https://github.com/apoorvlathey/motion-canvas-skills) | MIT |
| `mo-motion-graphic-beat` | [JakeB-5/motion-graphic-skill](https://github.com/JakeB-5/motion-graphic-skill) | MIT |
| `mo-p5js` | [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) | MIT |
| `mo-rive-interactive` | [freshtechbro/claudedesignskills](https://github.com/freshtechbro/claudedesignskills) | MIT |
| `mo-svg-animation` | [iart-ai/web-animation-skills](https://github.com/iart-ai/web-animation-skills) | MIT |
| `mo-text-to-lottie` | [diffusionstudio/lottie](https://github.com/diffusionstudio/lottie) | MIT |
| `mo-ui-sound-design` | [dannyjpwilliams/ui-sound-design-skill](https://github.com/dannyjpwilliams/ui-sound-design-skill) | MIT |

### Flutter e Dart (per portare le carte nell'app)

| Skill | Fonte | Licenza |
|---|---|---|
| `fl-animating-apps` | [flutter/skills](https://github.com/flutter/skills) (dalla cronologia) | BSD-3-Clause |
| `fl-animations-mad` | [madteacher/mad-agents-skills](https://github.com/madteacher/mad-agents-skills) | MIT |
| `fl-codemagic` | [Poorgramer-Zack/dart-expert-skills](https://github.com/Poorgramer-Zack/dart-expert-skills) | MIT |
| `fl-dart-add-unit-test` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-dart-collect-coverage` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-dart-fix-runtime-errors` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-dart-generate-test-mocks` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-dart-resolve-package-conflicts` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-dart-run-static-analysis` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-dart-use-doc-examples` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-dart-use-path-package` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-dart-use-pattern-matching` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-dart-use-primary-constructors` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-dart-write-documentation` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-fl-chart` | [Poorgramer-Zack/dart-expert-skills](https://github.com/Poorgramer-Zack/dart-expert-skills) | MIT |
| `fl-flutter-add-integration-test` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-flutter-add-widget-preview` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-flutter-add-widget-test` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-flutter-animate` | [Poorgramer-Zack/dart-expert-skills](https://github.com/Poorgramer-Zack/dart-expert-skills) | MIT |
| `fl-flutter-apply-architecture-best-practices` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-flutter-build-responsive-layout` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-flutter-fix-layout-issues` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-flutter-implement-json-serialization` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-flutter-setup-declarative-routing` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-flutter-setup-localization` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-flutter-use-http-package` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | BSD-3-Clause |
| `fl-k-dart-best-practices` | [kevmoo/dash_skills](https://github.com/kevmoo/dash_skills) | Apache-2.0 |
| `fl-k-dart-modern-features` | [kevmoo/dash_skills](https://github.com/kevmoo/dash_skills) | Apache-2.0 |
| `fl-k-profile-dart-code` | [kevmoo/dash_skills](https://github.com/kevmoo/dash_skills) | Apache-2.0 |
| `fl-store-screenshots` | [adamlyttleapps/claude-skill-aso-appstore-screenshots](https://github.com/adamlyttleapps/claude-skill-aso-appstore-screenshots) | MIT |
| `fl-z-accessibility-as-code` | [zakariaf/Flutter-Skills](https://github.com/zakariaf/Flutter-Skills) | MIT |
| `fl-z-ads-and-iap-monetization` | [zakariaf/Flutter-Skills](https://github.com/zakariaf/Flutter-Skills) | MIT |
| `fl-z-custom-canvas-and-gestures` | [zakariaf/Flutter-Skills](https://github.com/zakariaf/Flutter-Skills) | MIT |
| `fl-z-design-review-workflow` | [zakariaf/Flutter-Skills](https://github.com/zakariaf/Flutter-Skills) | MIT |
| `fl-z-flutter-performance` | [zakariaf/Flutter-Skills](https://github.com/zakariaf/Flutter-Skills) | MIT |
| `fl-z-i18n-rtl-l10n` | [zakariaf/Flutter-Skills](https://github.com/zakariaf/Flutter-Skills) | MIT |
| `fl-z-motion-and-haptics` | [zakariaf/Flutter-Skills](https://github.com/zakariaf/Flutter-Skills) | MIT |
| `fl-z-release-and-store-shipping` | [zakariaf/Flutter-Skills](https://github.com/zakariaf/Flutter-Skills) | MIT |
| `fl-z-ui-states-and-feedback` | [zakariaf/Flutter-Skills](https://github.com/zakariaf/Flutter-Skills) | MIT |
| `fl-z-widget-golden-and-a11y-testing` | [zakariaf/Flutter-Skills](https://github.com/zakariaf/Flutter-Skills) | MIT |

### Firebase

| Skill | Fonte | Licenza |
|---|---|---|
| `fb-firebase-auth-basics` | [firebase/agent-skills](https://github.com/firebase/agent-skills) | Apache-2.0 |
| `fb-firebase-basics` | [firebase/agent-skills](https://github.com/firebase/agent-skills) | Apache-2.0 |
| `fb-firebase-crashlytics` | [firebase/agent-skills](https://github.com/firebase/agent-skills) | Apache-2.0 |
| `fb-firebase-firestore` | [firebase/agent-skills](https://github.com/firebase/agent-skills) | Apache-2.0 |
| `fb-firebase-hosting-basics` | [firebase/agent-skills](https://github.com/firebase/agent-skills) | Apache-2.0 |
| `fb-firebase-remote-config-basics` | [firebase/agent-skills](https://github.com/firebase/agent-skills) | Apache-2.0 |
| `fb-firebase-security-rules-auditor` | [firebase/agent-skills](https://github.com/firebase/agent-skills) | Apache-2.0 |
| `fb-firestore-rules-creation` | [firebase/agent-skills](https://github.com/firebase/agent-skills) | Apache-2.0 |

### RevenueCat (abbonamenti)

| Skill | Fonte | Licenza |
|---|---|---|
| `rc-customer-center` | [RevenueCat/ai-toolkit](https://github.com/RevenueCat/ai-toolkit) | MIT |
| `rc-entitlements-gate` | [RevenueCat/ai-toolkit](https://github.com/RevenueCat/ai-toolkit) | MIT |
| `rc-experiments` | [RevenueCat/ai-toolkit](https://github.com/RevenueCat/ai-toolkit) | MIT |
| `rc-integrate-revenuecat` | [RevenueCat/ai-toolkit](https://github.com/RevenueCat/ai-toolkit) | MIT |
| `rc-paywall` | [RevenueCat/ai-toolkit](https://github.com/RevenueCat/ai-toolkit) | MIT |
| `rc-paywall-design` | [RevenueCat/ai-toolkit](https://github.com/RevenueCat/ai-toolkit) | MIT |
| `rc-purchase-flow` | [RevenueCat/ai-toolkit](https://github.com/RevenueCat/ai-toolkit) | MIT |
| `rc-revenuecat` | [RevenueCat/ai-toolkit](https://github.com/RevenueCat/ai-toolkit) | MIT |
| `rc-store-state` | [RevenueCat/ai-toolkit](https://github.com/RevenueCat/ai-toolkit) | MIT |
| `rc-testing-setup` | [RevenueCat/ai-toolkit](https://github.com/RevenueCat/ai-toolkit) | MIT |
| `rc-troubleshoot` | [RevenueCat/ai-toolkit](https://github.com/RevenueCat/ai-toolkit) | MIT |

### Marketing e crescita

| Skill | Fonte | Licenza |
|---|---|---|
| `mk-ab-testing` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-analytics` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-aso` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-churn-prevention` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-content-strategy` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-copy-editing` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-copywriting` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-cro` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-customer-research` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-emails` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-instagram-carousel` | [jeevanbavandla/instagram-carousel-skill](https://github.com/jeevanbavandla/instagram-carousel-skill) | MIT |
| `mk-launch` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-marketing-ideas` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-marketing-psychology` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-onboarding` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-paywalls` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-pricing` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-product-marketing` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-referrals` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-signup` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-social` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |
| `mk-video` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT |

### App Store e Play Store (ASO)

| Skill | Fonte | Licenza |
|---|---|---|
| `aso-app-launch` | [appeeky/aso-skills](https://github.com/appeeky/aso-skills) | MIT |
| `aso-app-marketing-context` | [appeeky/aso-skills](https://github.com/appeeky/aso-skills) | MIT |
| `aso-keyword-research` | [appeeky/aso-skills](https://github.com/appeeky/aso-skills) | MIT |
| `aso-localization` | [appeeky/aso-skills](https://github.com/appeeky/aso-skills) | MIT |
| `aso-metadata-optimization` | [appeeky/aso-skills](https://github.com/appeeky/aso-skills) | MIT |
| `aso-monetization-strategy` | [appeeky/aso-skills](https://github.com/appeeky/aso-skills) | MIT |
| `aso-onboarding-optimization` | [appeeky/aso-skills](https://github.com/appeeky/aso-skills) | MIT |
| `aso-paywall-optimization` | [appeeky/aso-skills](https://github.com/appeeky/aso-skills) | MIT |
| `aso-rating-prompt-strategy` | [appeeky/aso-skills](https://github.com/appeeky/aso-skills) | MIT |
| `aso-retention-optimization` | [appeeky/aso-skills](https://github.com/appeeky/aso-skills) | MIT |
| `aso-screenshot-optimization` | [appeeky/aso-skills](https://github.com/appeeky/aso-skills) | MIT |
| `aso-subscription-lifecycle` | [appeeky/aso-skills](https://github.com/appeeky/aso-skills) | MIT |
| `aso-web-to-app-funnel` | [appeeky/aso-skills](https://github.com/appeeky/aso-skills) | MIT |

### Contenuti: spiegare, verificare i fatti, scrivere da umano

| Skill | Fonte | Licenza |
|---|---|---|
| `ct-ai-writing-detox` | [jamditis/claude-skills-journalism](https://github.com/jamditis/claude-skills-journalism) | MIT |
| `ct-avoid-ai-writing` | [conorbronsdon/avoid-ai-writing](https://github.com/conorbronsdon/avoid-ai-writing) | MIT |
| `ct-citation-management` | [K-Dense-AI/claude-scientific-skills](https://github.com/K-Dense-AI/claude-scientific-skills) | MIT |
| `ct-data-journalism` | [jamditis/claude-skills-journalism](https://github.com/jamditis/claude-skills-journalism) | MIT |
| `ct-data-storytelling` | [wshobson/agents](https://github.com/wshobson/agents) | MIT |
| `ct-data-visualization-discipline` | [daymade/claude-code-skills](https://github.com/daymade/claude-code-skills) | MIT |
| `ct-excalidraw-diagram` | [axtonliu/axton-obsidian-visual-skills](https://github.com/axtonliu/axton-obsidian-visual-skills) | MIT |
| `ct-excalidraw-use` | [daymade/claude-code-skills](https://github.com/daymade/claude-code-skills) | MIT |
| `ct-fact-check-cards` | [petar-nauka/fact-check-skill](https://github.com/petar-nauka/fact-check-skill) | MIT |
| `ct-fact-check-workflow` | [jamditis/claude-skills-journalism](https://github.com/jamditis/claude-skills-journalism) | MIT |
| `ct-fact-checker` | [daymade/claude-code-skills](https://github.com/daymade/claude-code-skills) | MIT |
| `ct-feynman-modes` | [haunguyendev/feynman-skill](https://github.com/haunguyendev/feynman-skill) | MIT |
| `ct-feynman-technique` | [guicortei/feynman-technique](https://github.com/guicortei/feynman-technique) | MIT |
| `ct-humanizer` | [blader/humanizer](https://github.com/blader/humanizer) | MIT |
| `ct-markdown-mermaid-writing` | [K-Dense-AI/claude-scientific-skills](https://github.com/K-Dense-AI/claude-scientific-skills) | MIT |
| `ct-mermaid-visualizer` | [axtonliu/axton-obsidian-visual-skills](https://github.com/axtonliu/axton-obsidian-visual-skills) | MIT |
| `ct-newsroom-style` | [jamditis/claude-skills-journalism](https://github.com/jamditis/claude-skills-journalism) | MIT |
| `ct-research` | [Weizhena/Deep-Research-skills](https://github.com/Weizhena/Deep-Research-skills) | MIT |
| `ct-research-deep` | [Weizhena/Deep-Research-skills](https://github.com/Weizhena/Deep-Research-skills) | MIT |
| `ct-scientific-critical-thinking` | [K-Dense-AI/claude-scientific-skills](https://github.com/K-Dense-AI/claude-scientific-skills) | MIT |
| `ct-scientific-schematics` | [K-Dense-AI/claude-scientific-skills](https://github.com/K-Dense-AI/claude-scientific-skills) | MIT |
| `ct-scientific-visualization` | [K-Dense-AI/claude-scientific-skills](https://github.com/K-Dense-AI/claude-scientific-skills) | MIT |
| `ct-source-verification` | [jamditis/claude-skills-journalism](https://github.com/jamditis/claude-skills-journalism) | MIT |
| `ct-visual-explainer` | [jamditis/claude-skills-journalism](https://github.com/jamditis/claude-skills-journalism) | MIT |

### Anthropic, extra

| Skill | Fonte | Licenza |
|---|---|---|
| `an-canvas-design` | [anthropics/skills](https://github.com/anthropics/skills) | Apache-2.0 |
| `an-discernment-nudge` | [anthropics/skills](https://github.com/anthropics/skills) | Apache-2.0 |
| `an-theme-factory` | [anthropics/skills](https://github.com/anthropics/skills) | Apache-2.0 |


## Server MCP (`.mcp.json`)
Collegano il modello direttamente agli strumenti. Si attivano sul computer del proprietario, dove sono installati Dart e Firebase:
- **dart**: analisi del codice, test, hot reload, albero dei widget (serve Dart 3.9 o più nuovo).
- **firebase**: Firestore, regole, Auth (usa il login di `firebase login`).
- **revenuecat**: legge prodotti, offerte e abbonati (chiede il login a RevenueCat la prima volta).

## Scartate, e perché
- **remotion-dev/skills**, **CloudAI-X/threejs-skills**, **dgreenheck/webgpu**, **plyght/tonejs**, **lyndonkl/claude** (ottime su storytelling e pensiero critico), **coleam00/excalidraw**: senza licenza libera chiara. Si possono leggere, non copiare.
- **Linee guida Apple (HIG)**: copiano testi di Apple protetti.
- Doppioni e skill troppo corte o fuori tema: decine, elencate nelle ricerche.

## Da aggiungere con un clic (dal tuo account claude.ai)
Plugin del catalogo ufficiale che possono servire più avanti:
- **Figma**: se un giorno si disegnano le carte in Figma, per passarle al codice.
- **VectorLab UI/UX Skills**: motion, transizioni, tipografia, spaziature.
- **Codesign (IMG.LY)**: design modificabili ed esportazione in video, utile per i video social con le carte.
