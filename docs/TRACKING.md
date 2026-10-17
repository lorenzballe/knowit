# Tracking plan

What the app measures, when, with which properties, why, and where it goes.
Kept next to the code: an event added without a line here is an event nobody
will find in six months.

## In breve (per il proprietario)

- **Cosa misura.** Ogni schermata: quanto ci resti, fin dove scorri, quanti
  tocchi e scorrimenti, da dove arrivi e dove vai (`screen left`). Ogni
  carta: quanto resta davanti e dietro, dopo quanto la giri, se chiedi
  l'aiuto, se cambi risposta prima di confermare, quanto leggi del retro,
  se l'avevi già letta e come la lasci (`card advanced`, `card closed`).
  Ogni scaffale di Esplora visto davvero: per quanto, quante carte mostrate
  e aperte, se scorso di lato (`explore shelf seen`). Ogni sessione: durata,
  come è iniziata, quante schermate e carte, se il telefono era fluido
  (`app paused`). La velocità: prima carta sullo schermo, giornata pronta.
- **Dove va.** Tutto a PostHog (server UE). Una parte, in forma corta,
  anche nella *traccia* del lettore su Firestore, che il server usa per
  scegliere le carte del giorno e gli scaffali.
- **Cosa non va mai da nessuna parte:** quello che il lettore scrive o
  cerca, il nome, l'email, i codici amico. Nelle registrazioni di PostHog
  tutto il testo è nascosto. L'interruttore *Profilo → Dati di utilizzo*
  spegne tutto PostHog, eventi nuovi compresi.
- **Quanto pesa.** Un lettore assiduo (6 aperture al giorno, le 5 carte,
  3 visite in Esplora con 8 carte aperte e una storia vista fino in fondo)
  passa da circa **100 a circa 140 eventi al giorno**. Il piano gratuito di
  PostHog (1 milione al mese) regge circa 235 lettori così, ogni giorno, o
  circa 800 lettori tipici. Una storia di *Storie vere* dice quando si apre,
  quando arriva in fondo e quando si chiude, con quante delle sue parti sono
  state viste: tre eventi a storia, mai uno per parte.
- **Telefoni di prova.** Ogni evento e ogni profilo dicono da dove viene
  l'installazione (`install_channel`: `app_store`, `testflight`, `play`,
  `sideload`, `test_lab`, `debug`, `web`). I robot di Google Play e le build
  di sviluppo sono segnati come utenti di test (`$internal_or_test_user`),
  e il filtro di PostHog per gli utenti interni li toglie dai grafici.
- **Coorti.** Sul profilo: `is_plus`, `is_trial`, `plan_period`, `plan`,
  `reminders_on`, `widgets_placed`, `install_channel`, le tre materie più
  lette, quanto il lettore si dice sicuro e quanto indovina.
- **Dove vivi.** Con il consenso del lettore, il profilo PostHog ha paese,
  regione e città (`place_country`, `place_region`, `place_city`) e il suo
  sì o no (`location_permission`). Mai le coordinate: nessun evento, nessun
  profilo, nessuna traccia, e un test lo controlla. Gli eventi sono cinque
  (`place asked`, `place answered`, `location permission answered`, `place
  set`, `place removed`) e pesano pochi eventi per lettore, in tutto.
- **Cambiato:** `card flipped` non va più a PostHog (resta nella traccia):
  le girate ora sono dentro `card advanced` e `card closed`. Il profilo
  PostHog si scrive in un colpo solo, e solo dove è cambiato.
- **Aggiungere un evento:** sezione [9](#9-adding-an-event-or-a-screen).

## 1. Rules

These hold at every call site, old and new.

- **It never throws and never blocks.** `Analytics` swallows its own
  failures; nothing on a frame's path waits for it.
- **No prose.** Ids, counts, durations and short enums go out. The text of
  an answer, a reason typed beside it, a search, a report's note, a name,
  an email and a friend code do not. A search is described by its length and
  how many cards it found; a typed answer by whether it was right. A test
  types a sentence into a card and fails if it appears in anything sent.
- **Nothing before a yes.** The intro asks whether Astute may measure how
  the app is used, with two answers of one size (`ConsentChoice`); a reader
  who starts without answering is asked once more, as a sheet, after their
  first finished day (`showConsentSheet`). PostHog is not set up until the
  answer is yes, so nothing below is captured, queued or sent before it, and
  nothing at all after a no; what is stamped on every event and who the
  reader is are kept on the phone and said when a yes starts it. Kept as
  `knowit.analytics` with `knowit.analytics.asked`; an old switch turned off
  counts as a no, an old default of on as no answer. *Profile → Usage data*
  is the same answer, and survives a sign-out. The trace is not
  measurement: it is the personalisation the reader uses the app for, and
  the privacy policy says so.
- **No replays.** Session replay is off (`kSessionReplay`, `REPLAY` at build
  time, set by no build); a build that turns it on records only after a
  yes, with every word and every picture hidden.
- **Names.** Events are lowercase phrases with spaces, in the past tense
  where they can be (`card advanced`). Properties are `snake_case`. Durations
  are whole milliseconds named `ms_*`. Counts are integers; percentages are
  0–100 integers named `*_pct`.
- **No key, no measurement.** A build without `POSTHOG_KEY` sends nothing.
  The tests run without one; those that read what was sent install a
  recording sink (`Analytics.useForTest`).

## 2. Where an event goes: PostHog and the trace

Every event goes through `Analytics.capture` (`lib/analytics.dart`), which
does two things:

1. **The trace.** If the event is one the trace keeps (`Trace.kept` in
   `lib/sync/trace.dart`), a compact copy — a short code, a timestamp, and
   the few fields the dealer reads under short names — is queued and written
   to `readers/{uid}/activity/{day}` in Firestore. It is written whether or
   not usage data is on, because it is how the server deals the reader's
   day. The server reads three weeks of it (`functions/src/profile.ts`,
   `serve.ts`, `scorecard.ts`); its type is open (`[key: string]: unknown`)
   and the rules only cap a day at 2,000 events, so a new field needs no
   server change.
2. **PostHog.** The full event, with every non-null property, the super
   properties below, `$screen_name` (the screen in front, see
   [Screens](#62-screens)) and PostHog's own device facts.

Three events are trace-only and never reach PostHog: `card flipped`,
`card shown` (a card a shelf of Explore put on screen) and `explore
scrolled` (how far down Explore went, in tenths).

## 3. On every event: super properties

Registered once and re-registered only when they change
(`AppState._syncAnalytics`, `Subscription._noteEntitlement`, `main.dart`).
They are stamped on every later event, so a funnel can be cut by them
without a join.

| Property | Values | Set by |
| --- | --- | --- |
| `install_channel` | `app_store`, `testflight`, `play`, `sideload`, `test_lab`, `debug`, `web`, `other` | launch, before the first event (§5) |
| `is_plus` | bool | profile sync, entitlement |
| `plan` | `free`, `year`, `month`, `plus` (a product the app cannot place) | entitlement |
| `is_trial` | bool: a free trial is running, cancelled or not | entitlement |
| `plan_period` | RevenueCat's period: `trial`, `intro`, `normal`, `prepaid`; `none` without an entitlement | entitlement |
| `rung`, `streak_days`, `days_completed`, `topics_count` | ints | profile sync |
| `reminders_on` | bool: the app's own reminder is set | profile sync |
| `theme` | `dark`, `light`, `system` | profile sync |
| `app_language` | the app's language, e.g. `it` | profile sync |
| `days_since_install` | int, from the first day the app was opened on this phone | profile sync |
| `streak_bucket` | `0`, `1-2`, `3-6`, `7-13`, `14-29`, `30+` | profile sync |
| `notifications` | `granted`, `denied`, `not asked` | profile sync |
| `dark_mode` | bool: what the reader actually sees, the system's choice resolved | profile sync |
| `widgets_placed`, `widget_on_home` | int, bool | launch and every return |
| `text_scale_bucket` | `smaller`, `default`, `large` (≤1.3×), `larger` (≤1.6×), `largest` | first frame and every return |
| `reduce_motion` | bool | first frame and every return |

There is no A/B slot: the app has no experiments. The day one is added, its
variant belongs here, registered before the first event.

## 4. On the reader: person properties

The profile is a description, not a stream. `Analytics.person(set:,
setOnce:)` only hands values over; they are written together, as one `$set`
event carrying both `$set` and `$set_once`, and only where they differ from
what was last written for this reader (remembered on the phone, said again
in full after seven days):

- when the reader is identified (every launch, and a sign-in);
- at once (`now: true`) for what a cohort cannot wait for: the plan, and
  where the install came from;
- when the app leaves the screen, at most every six hours.

That replaced a `$set` at every change of the profile — 7.3 a day per active
reader in the first weeks — with about three.

| Property | How | What |
| --- | --- | --- |
| `is_plus`, `is_trial`, `plan_period`, `plan` | `$set`, at once | the plan, as in §3 |
| `install_channel` | `$set`, at once | §5 |
| `$internal_or_test_user` | `$set`, at once | `true` for `test_lab` and `debug` installs only |
| `rung`, `streak_days`, `best_streak`, `days_completed`, `weeks_kept`, `freezes` | `$set` | the habit |
| `topics_count`, `genres_off`, `strands_off` | `$set` | what the mix leaves out, as counts |
| `saved_count`, `liked_count`, `disliked_count` | `$set` | what the reader keeps |
| `reminders_on`, `reminder_hour`, `theme`, `app_language`, `onboarded` | `$set` | settings |
| `widgets_placed`, `widgets` | `$set` | how many widgets are placed, and which, comma-separated |
| `last_day_completed` | `$set` | date key, `2026-10-11` |
| `top_subjects`, `top_subject` | `$set`, on leaving the screen | the three subjects with the most cards read, comma-separated, and the first |
| `answers_count` | `$set`, on leaving the screen | cards answered, ever |
| `avg_sure`, `pct_right`, `calibration_gap` | `$set`, on leaving the screen | how sure the reader says they are, how often they are right, and the gap (sure − right), 0–100; absent below the journey's floor of answers |
| `last_active_local_hour` | `$set`, on leaving the screen | 0–23, the phone's own clock |
| `location_permission` | `$set` | the reader's word on their location: `not_asked`, `granted`, `denied` (the system's prompt said no, or the permission was taken back in the phone's settings), `off` (the place removed in Profile) |
| `place_country`, `place_region`, `place_city` | `$set`; `$unset` on `place removed` | where the reader lives, once they allowed it: the ISO country (`IT`), the region's ISO 3166-2 code where the app knows the country's regions (`IT-45`) or else its English name as the phone gave it, and the city in English (`Modena`). Never a coordinate (see §6.12) |
| `install_date` | `$set_once` | the first day the app was opened on this phone |
| `first_day_completed` | `$set_once` | the earliest finished day the phone remembers |
| `anonymous`, `sign_in_method` | `$identify` | whether the account is anonymous, and Apple or Google |

The person is the Firebase uid; the email and the name are never sent.
Person profiles are made only for identified readers (`identifiedOnly`).

## 5. Where the install came from

`lib/measure/install.dart` asks the phone at launch, in parallel with
Firebase starting, and stamps the answer before the first event:

| Channel | When |
| --- | --- |
| `debug` | a debug build, on any platform |
| `testflight` | iPhone with a sandbox receipt: TestFlight, and the copy App Review installs (the same `astut/install` → `isTestFlight` question the developer tools ask, asked once) |
| `app_store` | any other iPhone install |
| `test_lab` | Android, `Settings.System` `firebase.test.lab` is `"true"`: Firebase Test Lab, where Google Play's pre-launch robots run |
| `play` | Android, installed by `com.android.vending` (`getInstallSourceInfo` on Android 11+, `getInstallerPackageName` before) |
| `sideload` | Android, any other installer, none, or a phone that did not answer |
| `web` | the web app |

The Android question is `astut/install` → `installSource` in
`MainActivity.kt`. Both platforms wait at most 300 ms and fall back
(`sideload`, `app_store`); the question is asked while Firebase starts, so
it does not lengthen launch. `test_lab` and `debug` also set
`$internal_or_test_user: true` on the profile, which PostHog's *Filter out
internal and test users* honours. A reviewer's TestFlight copy is not marked
that way, because a beta tester is a reader; filter by the event property
`install_channel` to leave them out, which also works on events sent before
a profile existed.

## 6. Events

**P** = sent to PostHog. **T:`code`** = also kept in the trace under that
code. *Card facts* are the properties every card event carries
(`AppState.cardFacts`): `pill_id`, `topic`, `genre`, `strand`, `principle`,
`difficulty`, `challenge` (`fact`, `pick_one`, `type_number`, `estimate`,
`take_a_side`), `interaction` (the scene played on the card — `slider`,
`count`, `draw`… — or else its `challenge`, or `read`), `graded`, `era`,
`region`, `hook`, `mood`, `numeracy`, `abstraction`, `shelf_life`,
`has_figure`, `place_fit` **new** (on a card about a place only: `city`,
`region` or `country` — how near it is to where the reader lives — or
`none` for one that reached them some other way; never the place itself),
and, for one of today's cards, `position` and `of` (its place in the five),
`slot` (`own`, `random`, `review`, or `local` **new** for the day's card
about where the reader lives) and `edition`.

New in October 2026: `screen left`, `card closed`, `explore shelf seen`,
`first card shown`, the read facts on `card advanced`, the session on
`app paused`, `ms_to_deal` on `day started`, `interaction` on card facts;
and, later in the month, a true story played on Explore (`explore story
opened`, `finished`, `closed`) and how a year was gone to (`by` on
`explore year`).

### 6.1 Launch and the sitting

| Event | When | Properties | Why | Where |
| --- | --- | --- | --- | --- |
| `app started` | first frame of a cold start | `ms_to_first_frame`, `locale`, `text_scale`, `system_dark`, `reduce_motion`, `bold_text`, `screen_width` | launch speed, and the phone as it changes what the reader sees | P, T:`app` |
| `cloud started` | Firebase has started, or given up | `ok`, `ms`, `failure` (the error, cut to 140 characters) | half of all bug reports start here | P |
| `cards refreshed` | the bank was fetched from the site, once a launch | `outcome`, `ms`, `version_in_use`, `version_fetched`, `cards_fetched` | the cards reaching the phone | P |
| `first card shown` **new** | the first card of the day stands on Today with the reader looking, once per cold start — not after the first run, the come-back screen or a widget's card | `ms_to_first_card` (from `main()` starting), `ms_to_deal`, `dealt_by`, `position` | the wait a reader actually feels | P |
| `app paused` **extended** | the app leaves the screen: the end of a sitting | `ms_in_app` (this sitting, no longer the process's life), `entry` (`cold start`, `warm resume`, `notification`, `widget`), `screens` (visits begun), `cards_seen` (distinct cards that stood in front of the reader), `cards_answered`, `explore_visits`, `explore_opens` (cards opened from Explore), `hour_local`, `weekday` (1 = Monday), `frames`, `janky_frames`, `ms_worst_frame` | the session summary: length, depth, how it began, and whether the phone kept up. Every open screen visit, card and shelf is said just before it | P, T:`pause` |

Janky frames are the engine's own frame timings (`SchedulerBinding.addTimingsCallback`):
a frame is janky when its build or its raster took longer than the display's
refresh allows (16.7 ms at 60 Hz, 8.3 ms at 120 Hz). Only release builds'
numbers mean anything.

### 6.2 Screens

A screen is named where it is built, by wrapping it in `ScreenView`
(`lib/measure/screens.dart`), never taken from the route: the three tabs and
the steps of the first run are one route. A `ScreenObserver` on the
navigator only tells each screen whether something was pushed over it.

A **visit** runs from arriving on a screen to leaving it. A full screen
pushed over it *pauses* the visit (its clock stops) and coming back resumes
the same visit, so the time under a card opened from Explore is Explore's
visit, not a new one. Sheets and dialogs are not screens. Going to the
background ends every visit; coming back starts a new one.

| Event | When | Properties | Why | Where |
| --- | --- | --- | --- | --- |
| `$screen` | a visit begins | `$screen_name` | PostHog's screen views and paths | P |
| `screen left` **new** | a visit ends | `screen`, `ms_on_screen` (in front only), `max_scroll_pct` (how far down its main list was seen, 0–100; absent when nothing scrolls), `scrolls` (finger drags that moved it), `taps`, `screens_opened` (full screens pushed over it), `from` (the screen before, `background` after a return, absent at launch), `left_to` (the next screen, or `background`) | dwell, depth and attention per screen, and the path between them | P |
| `tab opened` | a tab is chosen | `tab`, `by` (`bar`, `swipe`, `widget`) | how the tabs are reached | P, T:`tab` |

Every PostHog event carries `$screen_name`: the screen in front when it was
sent, which after a return from a pushed screen is the screen returned to.

Screen names: `today`, `explore`, `profile` (tabs); `intro`, `onboarding
subjects`, `onboarding genres`, `comeback` (first run and come-back; the
first run has had no paywall since October 2026, so `onboarding offer` is
gone); `deck viewer`, `pill detail`, `archive`, `saved`, `liked`,
`journey`, `path`, `week`, `topics`, `how`, `paywall`, `purchase success`,
`story` (a true story played from Explore).

### 6.3 The day on Today

| Event | When | Properties | Why | Where |
| --- | --- | --- | --- | --- |
| `day started` | a fresh day is dealt | `cards`, `dealt_by` (`server`, `server-cached`, `phone`), `ms_to_deal` **new**, `own`, `reviews`, `local` **new** (bool: the day holds a card about where the reader lives), `sunday` **new** (bool: the reader's Sunday, with one more of their own than the day would have had; never on Astute+), `topics`, `streak_days`, `rung`, `is_plus`, `slots`, `challenges` | who dealt the day and how fast; whether the cards about home and Sunday's extra card reach readers | P, T:`day` |
| `card viewed` | a card of the day comes up | card facts, `resumed` | the funnel inside a day | P, T:`view` |
| `hint shown` | a card's hint is opened | `pill_id`, `topic` | | P, T:`hint` |
| `card answered` | a card is answered | card facts, `graded`, `ms_to_answer`, `correct`, `confidence`, `gave_reason` (bool, never the reason), `review`, `review_stage`, `response_index`, `response_value`, `hint_available` | right, wrong, how sure | P, T:`ans` |
| `card advanced` **extended** | a card of the day is thrown on | card facts, `review`, `ms_on_card` (from the card coming up, background included), and the read facts of its last stint (§6.4) | drop-off by place in the day, and how each card was read | P, T:`next` |
| `card flipped` | a card is turned to its back | `pill_id`, `ms_to_flip` | the scorecard counts turns | T:`flip` only |
| `day completed` | the fifth card is done | `streak_days`, `best_streak`, `cards`, `days_completed`, `rung`, `score_gained`, `rungs_climbed`, `is_plus`, `answered_right`, `answered_wrong`, `reviews`, `own` | | P, T:`done` |
| `rung reached` | a new rung of the ladder | `rung`, `rung_index`, `days_in`, `pills_read` | | P |
| `streak milestone`, `best streak beaten` | the streak hits a milestone, or the best | `streak_days`, `is_plus`, `previous_best` | | P |
| `streak broken` | the streak is found broken | `streak_lost`, `best_streak`, `days_missed`, `freezes_left`, `is_plus` | | P |
| `streak frozen`, `freeze earned` | a freeze covers a missed day; one is earned | `days_covered`, `freezes_left`, `freezes`, `streak_days` | | P |
| `plus gate reached`, `plus gate left` | a reader on the free plan meets something of Astute+ | `source`, `is_plus`, `unlocked` | | P |

### 6.4 How a card was read: `card closed` and the read facts

A card's **stint** is one continuous stretch of it standing on top of a deck
with the reader looking (`lib/measure/card_read.dart`). Its clocks stop when
its screen goes out of sight, so a phone left on the table is not a card
read for an hour. Each stint is said once, by the event that ended it:
`card advanced` when a card of the day is thrown on, `card closed` for every
other ending.

| Event | When | Properties | Why | Where |
| --- | --- | --- | --- | --- |
| `card closed` **new** | a stint ends without the day moving on: a card of the day left for a tab, a pushed screen or the background; every card read in the deck viewer, however it left | `ms_on_card` (in sight, this stint), card facts, `where` (`today`, or the screen the viewer was opened from: `explore`, `journey`, `came back`, `widget`, `story` — the card opened from a story's last screen; `viewer` when none was given), read facts | dwell and depth on cards read outside the day, and on cards of the day left half-read | P, T:`close` |

**Read facts**, on `card advanced` and `card closed`:

| Property | What |
| --- | --- |
| `ms_front`, `ms_back` | time in sight on each side, this stint |
| `ms_to_flip` | time to the first turn to the back |
| `ms_to_first_touch` | time to the first finger on the card |
| `flips` | turns, either way |
| `hint_opened`, `ms_to_hint` | on a card that offers a hint before it is answered |
| `options_changed` | on a card whose answer can be changed before it is committed (a ruler, typed digits): how often it was taken back. Absent on one-tap cards, which commit on the tap |
| `back_scroll_pct` | how much of the back was in sight: 100 for a back that fits, else how far it was scrolled |
| `extras_opened` | which tucked parts of the back were opened, comma-separated: `working`, `picture`, `scene`, `simply` (the simpler telling), `counter` (the other side's case) |
| `reread` | the card was in front of the reader before: an earlier day, or an earlier stint |
| `exit` | `thrown`, `swiped`, `thrown down` (less like this), `tab`, `push`, `background`, `closed` (its screen closed), `gone` (replaced under the reader) |

`confidence_changes` was asked for and left out: confidence is a single tap
that commits the answer, so it can never change. The `interaction` of a card
is in its card facts.

### 6.5 Explore

| Event | When | Properties | Why | Where |
| --- | --- | --- | --- | --- |
| `explore shelf seen` **new** | leaving Explore (another tab, the background), once per shelf that was on screen for at least a second in all during the stay | `shelf`, `position` (1 = top), `ms_visible`, `tiles_seen` (cards the shelf built while Explore was in sight), `tiles_opened`, `scrolled_sideways` (absent for a shelf that does not turn) | what Explore put in front of the reader, not only what was opened: interest and position bias per shelf | P, T:`shelf` |
| `card shown` | a shelf builds a card while Explore is in sight (fixed: it used to count Explore built off screen beside Today) | `pill_id`, `shelf` | what was offered and passed over | T:`seen` only |
| `explore scrolled` | Explore goes a tenth further down | `depth` | | T:`xd` only |
| `card read elsewhere` | a card is read for the first time outside the day | card facts | it is never dealt again | P, T:`read` |
| `explore filtered` | a subject chip | `subject` | | P, T:`xf` |
| `explore search opened`, `explore search closed` | the search field | `had_query` | | P |
| `explore searched` | a search returns | `query_length`, `words`, `results` — never the text | | P, T:`xs` |
| `explore top window`, `explore top opened`, `explore loved opened` | the readers' top list | `window`, `month`, `subject`, `rank`, `readers` | | P, T:`xo` (opens) |
| `explore answered`, `explore leaned` | a card answered on a shelf | `pill_id`, `right`, `side`, `confidence` | | P |
| `explore did you know`, `explore surprise`, `explore spot`, `explore chart unmasked`, `explore slide checked`, `explore range bet`, `explore stake bet`, `explore bigger picked` | the shelf games | `pill_id`, `right`, `new`, `trick`, `off`, `width`, `hit`, `stake`, `won` | | P |
| `explore mood`, `explore minutes`, `explore year`, `explore sixty started`, `explore sixty finished` | the shelf pickers and the sixty-second round | `tone`, `minutes`, `era`, `year`, `by` (on `explore year`: `typed`, or `random` for a year picked by chance), `right`, `answered`, `seconds` | `explore era` went with the ruler and its arrows: an age is only gone to through a year now | P |
| `explore story opened` **new** | a true story starts playing, from its tile on Explore | card facts, `beats` (how many it has), `authored` (true for a story written to be played, its scenes and its question), `rank` (its place on the shelf, from 1) | which stories are opened, and from where on the shelf | P |
| `explore story finished` **new** | a story reaches its last screen, once per opening | `pill_id`, `beats`, `authored`, `ms_to_finish` (from opening), `picked_right` (on a story written to be played: whether the outcome picked came true; absent when nothing was picked) | how many stories are told to the end, and how long one takes | P |
| `explore story closed` **new** | a story is closed, however | `pill_id`, `beats`, `beats_seen` (how many of its beats were on screen), `finished`, `ms_in_story`, `taps_back` (taps on the left to go back), `holds` (fingers held down to stop it), `exit` (`closed` with its button, `swiped down`, `card` — the card opened in its place, `back` — the phone's back) | where readers leave a story, and how: the beats seen are counted on the phone and said once, never an event per beat | P |

### 6.6 Keeping, saying, sharing

| Event | When | Properties | Where |
| --- | --- | --- | --- |
| `pill liked`, `pill unliked`, `pill unlike undone` | like | card facts, `shelf_size` | P, T:`like`/`unlike` |
| `pill saved`, `pill unsaved`, `pill unsave undone` | save | card facts, `shelf_size` | P, T:`save`/`unsave` |
| `pill disliked`, `pill dislike undone` | less like this | card facts, `disliked_total` | P, T:`skip`/`unskip` |
| `pill said` | the reader said a card to someone | card facts, `said_total` | P, T:`said` |
| `pill opened` | a card opened on a page of its own: from Saved, Liked, the archive or a week of the journey (no deck, so no `card closed`) | card facts, `saved`, `liked`, `answered` | P, T:`open` |
| `card reported` | a report is sent | `pill_id`, `topic`, `report_reason`, `with_note` (bool, never the note) | P, T:`rep` |
| `share sheet opened`, `pill shared`, `day shared`, `record shared` | sharing | `kind`, `pill_id`, `topic`, `as`, `image`, `streak_days`, `edition`, `sheet`, `from` | P, T:`share` (cards) |
| `shelf filtered`, `archive filtered` | a subject on Saved, Liked or the archive | `subject` | P |

### 6.7 First run and coming back

| Event | When | Properties | Where |
| --- | --- | --- | --- |
| `intro scene changed`, `intro skipped` | the intro's scenes | `from`, `to`, `by`, `ms_on_scene`, `at_scene` | P |
| `onboarding started`, `onboarding step done`, `onboarding step skipped`, `onboarding completed` | the first run | `step`, `next`, `ms_on_step`, `topics`, `shape`, `claimed`, `solid_start`, `hand_picked` | P, T:`onb` (completed) |
| `genres shown`, `genres set`, `mix set`, `levels set` | the mix | `subjects_in_mix`, `genres_off`, `strands_off`, `genres_on`, `topics`, `leaned_to`, `subjects_rated` | P, T:`genres`/`mix` |
| `sign in started`, `sign in ended`, `account merged` | signing in | `method`, `outcome` (`signedIn`, `cancelled`, `unavailable`, `failed`, `busy`), `from` (`intro`, `profile`, `day done`), `ms`, `no_sheet` (a cancel that came back too fast for a sheet to have shown), `error` (every outcome but `signedIn`), `route`, `account_had_backup`, `days_on_phone`, `days_in_account`, `days_after`, `saved_after`, `cards_seen_after` | P |
| `sign in ignored` | a press while another sign-in is still waiting | `method`, `from`, `busy_with`, `busy_since_ms` | P |
| `sign in sheet shown`, `sign in sheet closed` | the sheet with Apple and Google, by its door | `from`, `signed_in` | P |
| `comeback shown` | the come-back screen after missed days | `days_missed`, `streak_lost` | P |
| `rating prompt requested` | the system's rating sheet is asked for | `streak_days`, `is_plus` | P |

### 6.8 Astute+: paywall, store and plan

| Event | When | Properties | Where |
| --- | --- | --- | --- |
| `paywall shown`, `paywall plan selected`, `paywall link opened`, `paywall closed` | the paywall, by the door that opened it (`sixth card`, `journey`, `archive`, `see the plans`, `manage plan`, the locked features' own; no longer `onboarding`) | `source`, `variant`, `has_number`, `plan_shown`, `store_answered`, `store` (`ready`, `asking`, `unreachable`), `plan`, `from`, `link`, `left_by` (`close`, `back`, `bought`, `pending`, `review access`, `unlocked without a store` in a debug build), `ms_open`, `plan_changes`, `is_plus` | P |
| `purchase started`, `purchase ended`, `purchase success shown`, `purchases restored` | buying | `source`, `plan`, `has_package`, `outcome` (`bought`, `cancelled`, `pending`, `failed`; for a restore `restored`, `nothing`, `unreachable`), `product`, `price`, `currency`, `trial`, `found` | P |
| `store answered` | each time RevenueCat is asked for the offerings: at launch, then after 3 s, 10 s, 30 s and 2 min while nothing is on sale, on the paywall opening, on Try again and on a return to the app | `ms`, `try`, `offering`, `yearly_product`, `yearly_price`, `yearly_trial`, `monthly_product`, `monthly_price`, `currency`, `is_plus`, `error` | P |
| `entitlement read`, `entitlement changed` | the subscription as the store holds it, at launch and on every change | `active`, `product`, `period_type`, `will_renew`, `store`, `sandbox`, `expires`, `unsubscribed`, `billing_issue` | P |
| `trial started`, `plan changed` | the app's own plan | `is_plus` | P, T:`plan` (changed) |
| `manage subscription opened` | the store's management page | `is_plus`, `from`, `days_left` | P |
| `review access granted`, `review code refused` | App Review's code | — | P |

### 6.9 Reminders, widgets, notifications

| Event | When | Properties | Where |
| --- | --- | --- | --- |
| `reminder opened` | a reminder's tap opened or brought the app forward (also sets the sitting's `entry` to `notification`) | `slot`, `planned_for`, `launched_app` | P |
| `reminder switched`, `reminder time set` | the reminder settings | `on`, `at` | P |
| `push preprompt shown`, `push preprompt answered`, `push permission asked`, `push permission answered` | asking for notifications | `reason`, `choice`, `granted` | P |
| `app opened from widget` | a widget's tap (sets `entry` to `widget`) | `widget`, `pill_id`, `where` | P |
| `widgets placed` | the set of placed widgets changed | `count`, `widgets`, `kinds` | P |

### 6.10 Settings and account

| Event | When | Properties | Where |
| --- | --- | --- | --- |
| `theme set` | | `theme` | P |
| `music sound switched` | the music cards' sound, off until turned on: Profile's switch, or Turn on after a card's Listen | `on`, `from` (`profile`, `card`) | P |
| `usage sharing switched` | the reader's switch | `on` | P |
| `usage sharing answered` | the first event after a yes: the intro's question or the sheet's (a no sends nothing) | `on`, `from` (`intro`, `sheet`) | P |
| `signed out` | | `streak_days`, `days_completed`, `pills_read` | P |
| `account deletion asked`, `…cancelled`, `…started`, `…ended` | deleting the account | `signed_in`, `is_plus`, `account`, `outcome`, `error` | P |

Friends came out before the launch, and with them `friend added`, `friend
removed`, `friend code copied`, `friend board read`, the `friends` screen and
the `friends_count` on the profile. Readers profiled before keep the last
`friends_count` they were sent; nothing updates it.

### 6.11 Errors and PostHog's own

`$exception` for every uncaught error and for the caught ones
(`Analytics.error`, with `where`); `$identify` at launch and sign-in; `$set`
for the profile (§4); `$screen` (§6.2). Session replay is off.

### 6.12 Where you live

The place a reader lives, asked for with their consent (docs/PLACES.md,
`lib/widgets/place_ask.dart`): the app's own sheet after the second finished
day, once more after the seventh for a reader who said "Not now", and from
Explore's "Where you live" shelf and Profile whenever the reader asks. Only
a yes on the sheet leads to the system's prompt.

| Event | When | Properties | Where |
| --- | --- | --- | --- |
| `place asked` | the app's sheet is put | `from` (`day done`, `explore`, `profile`), `nth` (which sheet this is for the reader, counting every one) | P |
| `place answered` | the sheet is answered, or swiped away | `choice` (`yes`, `not_now`) | P |
| `location permission answered` | the system's prompt, put after a yes | `granted`, `precise` (iOS: the precise position or the approximate one; Android: always `false`, since only the approximate one is asked for; absent when not granted) | P |
| `place set` | a place is read and kept: after a yes, from Profile's "Use my location now", by the weekly read when the reader has moved, or after the permission was given in the phone's settings | `country`, `region` (as `place_region`, §4), `city`, `changed` (the place kept is not the one kept before; none before counts as a change), `from` (`day done`, `explore`, `profile`, `refresh`, `settings`) | P, T:`place` |
| `place removed` | Profile → Where you live → Remove, and the account deleted | `$unset`: `place_country`, `place_region`, `place_city`, which PostHog takes off the profile | P, T:`unplace` |

The weekly read (`AppState.refreshPlaceIfDue`) that finds the reader where
they were says nothing. **No event, property, profile field or trace field
ever carries a latitude or a longitude**, raw or rounded: the point stays in
the backup's `place`, rounded to a tenth of a degree, and
`test/place_capture_test.dart` fails if one reaches the sink or the trace.
Like every event, all five stop with *Profile → Usage data*.

## 7. The trace: codes and fields

The trace keeps numbers, booleans and strings of up to 64 characters (enums,
ids), under short names. A duration shares `ms`; an event that carries two
keeps the first it lists, which is why `card advanced` and `card closed` list
`ms_on_card` first.

New codes: `close` (`card closed`) and `shelf` (`explore shelf seen`).

New fields:

| Field | Short | On |
| --- | --- | --- |
| `ms_front`, `ms_back` | `mf`, `mb` | `next`, `close` |
| `flips` | `fl` | `next`, `close` |
| `options_changed` | `oc` | `next`, `close` |
| `back_scroll_pct` | `bs` | `next`, `close` |
| `extras_opened` | `xt` | `next`, `close` |
| `reread` | `re` | `next`, `close` |
| `exit` | `x` | `next`, `close` |
| `position` | `p` | `shelf` (the shelf's place); on card events, the card's place in the day |
| `tiles_seen`, `tiles_opened` | `ts`, `tk` | `shelf` |
| `scrolled_sideways` | `sw` | `shelf` |
| `ms_visible` | `ms` | `shelf` |

Codes for where the reader lives: `place` (`place set`) and `unplace`
(`place removed`). `place` keeps three fields of its own and nothing else —
`co` (country), `rg` (region), `ci` (city) — through `Trace._fieldsOf`, a
map per event: `region` on a card event is the card's tag, which the trace
leaves to the bank, and the point is in no map at all. The dealer reads the
place itself from the backup (`readers/{uid}.place`); these say when it
moved.

What the server could do with them, none of which it does yet:

- **Time in sight instead of time up.** `next`'s `ms` counts from the card
  coming up, background included; `mf + mb` is the card actually in front
  of the reader, a cleaner signal for the scorecard's "how long it holds".
- **Hesitation as difficulty.** `oc` on ruler and number cards, with `ok`
  and `cf`, separates a confident miss from a struggle.
- **Read depth.** `bs`, `mb` and `xt` say whether the back was read, which
  is what a card is for; a card whose back is never finished is too long or
  not interesting enough.
- **Rereads.** `re` on a `close` from Explore or the journey is a card the
  reader came back to: a like that was never tapped.
- **Shelves.** `shelf` with `ts`/`tk` gives each shelf an opened-per-seen
  rate, and `p` its position bias; a `close`'s `ms`, joined by card to the
  `seen` that showed it (`sh`), says how long the cards opened from a shelf
  held the reader.
- **Exits.** `x` tells a card thrown on fast from one left for another tab
  or the background, which today look alike.

## 8. Volume

PostHog's free plan is one million events a month. Measured in the
project's first weeks (mostly testers and the first run): per person and
day, median 22 events, 90th percentile 170, 99th about 500; `$set` 7.3 and
`$screen` 12.4 per active reader-day.

A **heavy reader's day**, modelled: two cold starts and four returns (one
from the reminder), all five cards (four graded, one hint, one card left
mid-read for Explore and one for the background), three visits to Explore
seeing five shelves each and opening eight cards in the viewer, one true
story played to its last screen, a filter and a top-list open, two shelf
games, three likes or saves and one card said, Profile, Journey and Saved
once each, one paywall.

| Events | Before | After | Note |
| --- | ---: | ---: | --- |
| Launch: `app started`, `cloud started`, `cards refreshed`, `store answered`, `$identify` | 10 | 10 | |
| `first card shown` | – | 1 | one cold start lands on a card |
| `app paused` | 6 | 6 | now carries the session |
| `$screen` | 19 | 23 | +4: a return now starts a visit |
| `screen left` | – | 23 | one per visit |
| `tab opened` | 6 | 6 | |
| Today: `day started`, `card viewed` ×6, `hint shown`, `card answered` ×4, `card advanced` ×5, `day completed` | 18 | 18 | |
| `card flipped` | 13 | 0 | trace only now; turns are on the card's summary |
| `card closed` | – | 10 | 8 in the viewer, 2 on Today |
| `explore shelf seen` | – | 15 | 3 visits × 5 shelves |
| Explore: `card read elsewhere` ×8, filter, top list, games ×2 | 12 | 12 | |
| A true story: `explore story opened`, `finished`, `closed`, its `$screen` and `screen left`, its `card read elsewhere` | – | 6 | one story, to its last screen |
| Keeping and saying | 4 | 4 | |
| Paywall, reminder, other | 4 | 4 | |
| `$set` | 7 | 3 | coalesced, written only where changed |
| **Total** | **99** | **141** | +42% |

Where the reader lives adds nothing to a day: a handful of events per reader
in all — at most two sheets of the app's own and their answers, one system
prompt, one `place set` — then one `place set` per move and one `place
removed` if it comes to that. The weekly read is silent unless the reader
moved.

A typical reader (one cold start, one return, the five cards, one short
visit to Explore) goes from about 37 to about 40. The free plan then holds
about 235 heavy readers, or about 800 typical ones, every day of a month.

The levers, if it ever needs to come down: `tab opened` is redundant with
`screen left` (`from`, `left_to`) and `$screen` except for its `by` (−6);
`card viewed` could be read off `card advanced` and `card closed` (−6); the
shelf threshold (`ShelfSight.seenMs`) could rise from one second to two.

## 9. Adding an event, or a screen

**An event.**

1. Name it as a lowercase phrase in the past tense (`thing happened`). Look
   for an existing event first: a property on one is cheaper than a new
   one, and a funnel across two names is a join.
2. Call `Analytics.capture('thing happened', {...})`. Properties in
   `snake_case`; durations in whole milliseconds as `ms_*`; counts as ints;
   enums as short lowercase strings; null values are dropped, so pass
   `x == null ? null : ...` rather than branching. About a card, spread
   `app.cardFacts(pill.id)`. Never await it on a frame's path.
3. Nothing the reader wrote: no text field's content, no search, no name,
   email or friend code. If a length or a count tells you what you need,
   send that.
4. If it fires per frame, per scroll or per card shown, aggregate it on the
   phone and send one event when the thing ends (see `screen left`,
   `explore shelf seen`). Update the volume table above.
5. If the dealer should learn from it, add it to `Trace.kept` with a short
   code and its fields to `Trace._fields`. The server's ingestion is open; a
   field it should read goes into `functions/src` with a test.
6. Test it in `test/tracking_test.dart` with the recording sink
   (`Analytics.useForTest`), including that it respects the reader's switch
   if it bypasses `capture`.
7. Add its row here. If it sends a new kind of data, say so in
   `site/privacy.html` (English and Italian) and, for a new data type,
   `ios/Runner/PrivacyInfo.xcprivacy`.

**A screen.** Wrap what it builds in `ScreenView(name: 'thing', child: ...)`
(exported from `lib/widgets/ui.dart`). That is all: `$screen`, `screen
left`, scroll depth, taps and the pause under pushed screens come with it.
A screen that lives beside others on one route (a tab, a step) passes
`showing: false` while it is not the one in front. A pushed screen must be a
`PageRoute` (a `MaterialPageRoute` or `PageRouteBuilder`); sheets and
dialogs are not screens and need nothing. Add its name to §6.2.

**A person property.** `Analytics.person(set: {...})`, or `setOnce:` for a
fact that never changes. Pass `now: true` only for what a cohort cannot wait
six hours for.

**A super property.** Add the key to `AppState._everyEvent` if it is on the
profile, or to `everyEventFacts` if it is not; it is re-registered only when
it changes.
