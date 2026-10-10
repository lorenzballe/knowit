import SwiftUI
import WidgetKit

// Four widgets from one extension: today's card, the streak, today's five
// and today's shelf. The drawing is in AstutWidgetViews.swift; this is where
// the data comes from, when each widget turns over, and where a tap goes.
//
// Every widget is cards, and every card on one opens that very card: a card
// of today's five opens on Today, a card of today's shelf in Explore. The
// link names the widget, the card and where the card lives —
// astute://widget?from=card.systemSmall&card=<id>&in=today — and the app
// lands on it.
//
// The app writes everything down in the shared App Group each time it
// runs: today's next card and the one each of the next fourteen mornings
// opens on, the streak and the week, today's five and tomorrow's, today's
// shelf and the next fortnight's, and every line already in the reader's
// language. Until that group exists on the Apple account the extension
// cannot read any of it, so today's card and the shelf fall back on today's
// shelf as the site publishes it — the same for everybody — and the other
// two say where their data will come from.

// MARK: - What the app wrote down

enum Shared {
  static let group = "group.com.astuto.app"

  static let dayKey: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
  }()

  static func key(_ date: Date) -> String { dayKey.string(from: date) }

  static func days(from: String, to: Date) -> Int {
    guard let start = dayKey.date(from: from) else { return 0 }
    let calendar = Calendar.current
    return calendar.dateComponents(
      [.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: to)
    ).day ?? 0
  }

  /// Everything the app handed over, or nil when it never has.
  static func snapshot() -> Snapshot? {
    guard let d = UserDefaults(suiteName: group),
      let date = d.string(forKey: "date"), !date.isEmpty
    else { return nil }
    return Snapshot(d, date: date)
  }
}

/// Where a card lives in the app, as the links say it.
enum CardPlace {
  /// One of today's five, opened on Today.
  static let today = "today"
  /// A card of today's shelf, opened in Explore.
  static let shelf = "shelf"
}

struct Snapshot {
  let date: String
  let edition: Int
  let cardId: String
  let question: String
  let topic: String
  let color: String
  let ink: String
  let streak: Int
  let done: Bool
  let footPlain: String
  let footStreak: String
  let footDone: String
  let ahead: [String: String]
  let aheadId: [String: String]
  let aheadTopic: [String: String]
  let aheadColor: [String: String]
  let aheadInk: [String: String]
  let streakCaption: String
  let streakText: String
  let streakStart: String
  let weekDone: String
  let weekLabels: [String]
  let five: [FiveCard]
  let fiveTomorrow: [FiveCard]
  let fiveTitle: String
  let fiveReadText: String
  let fiveDone: String
  let fiveWaiting: String
  /// Today's shelf and the next fortnight's, by date, each a JSON list.
  let shelves: [String: String]
  let shelfTitle: String
  let shelfFrom: String
  let shelfLine: String

  init(_ d: UserDefaults, date: String) {
    func text(_ key: String) -> String { d.string(forKey: key) ?? "" }
    func map(_ key: String) -> [String: String] {
      d.dictionary(forKey: key) as? [String: String] ?? [:]
    }
    self.date = date
    edition = d.integer(forKey: "edition")
    cardId = text("cardId")
    question = text("question")
    topic = text("topic")
    color = text("color")
    ink = text("ink")
    streak = d.integer(forKey: "streak")
    done = d.bool(forKey: "done")
    footPlain = text("footPlain")
    footStreak = text("footStreak")
    footDone = text("footDone")
    ahead = map("ahead")
    aheadId = map("aheadId")
    aheadTopic = map("aheadTopic")
    aheadColor = map("aheadColor")
    aheadInk = map("aheadInk")
    streakCaption = text("streakCaption")
    streakText = text("streakText")
    streakStart = text("streakStart")
    weekDone = text("weekDone")
    weekLabels =
      (try? JSONSerialization.jsonObject(with: Data(text("weekLabels").utf8)) as? [String]) ?? []
    five = Snapshot.cards(text("fiveJson"))
    fiveTomorrow = Snapshot.cards(text("fiveTomorrowJson"))
    fiveTitle = text("fiveTitle")
    fiveReadText = text("fiveReadText")
    fiveDone = text("fiveDone")
    fiveWaiting = text("fiveWaiting")
    shelves = map("shelf")
    shelfTitle = text("shelfTitle")
    shelfFrom = text("shelfFrom")
    shelfLine = text("shelfLine")
  }

  /// Today's shelf on a day, as the app handed it over: the cards at the
  /// top of Explore that the reader has not read.
  func shelf(_ key: String) -> [FiveCard] {
    Snapshot.cards(shelves[key] ?? "")
  }

  static func cards(_ json: String) -> [FiveCard] {
    guard let list = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [[String: Any]]
    else { return [] }
    return list.map { FiveCard.from($0) }
  }
}

extension FiveCard {
  /// A card as the app and the site write one: its id, subject, colour,
  /// ink and question, and whether it has been read.
  static func from(_ c: [String: Any]) -> FiveCard {
    FiveCard(
      topic: c["topic"] as? String ?? "",
      color: Color(hex: c["color"] as? String ?? "", fallback: AstutPalette.night),
      ink: Color(hex: c["ink"] as? String ?? "", fallback: .white),
      read: c["read"] as? Bool ?? false,
      id: c["id"] as? String ?? "",
      question: c["question"] as? String ?? "")
  }
}

// MARK: - Today's shelf and the question of the day, from the site

/// Today's shelf for the weeks ahead, and the question of the day beside
/// it, for a widget the app has not spoken to. Published with every deploy
/// as widget/days.json; every card on it carries its id, so a tap still
/// opens that card.
enum WebDays {
  struct Day {
    let edition: Int
    let id: String
    let question: String
    let topic: String
    let color: String
    let ink: String
    let shelf: [FiveCard]
  }

  static let url = URL(string: "https://astutetheapp.com/widget/days.json")!
  private static let cacheKey = "astut.webDays"

  static func cached() -> [String: Day] {
    parse(UserDefaults.standard.data(forKey: cacheKey))
  }

  static func fetch(_ done: @escaping ([String: Day]) -> Void) {
    let request = URLRequest(
      url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 12)
    URLSession.shared.dataTask(with: request) { data, _, _ in
      let days = WebDays.parse(data)
      if !days.isEmpty {
        UserDefaults.standard.set(data, forKey: WebDays.cacheKey)
        done(days)
      } else {
        done(WebDays.cached())
      }
    }.resume()
  }

  private static func parse(_ data: Data?) -> [String: Day] {
    guard let data,
      let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let days = root["days"] as? [String: [String: Any]]
    else { return [:] }
    var out: [String: Day] = [:]
    for (key, d) in days {
      let shelf = (d["shelf"] as? [[String: Any]] ?? []).map { FiveCard.from($0) }
      out[key] = Day(
        edition: d["edition"] as? Int ?? 0,
        id: d["id"] as? String ?? "",
        question: d["question"] as? String ?? "",
        topic: d["topic"] as? String ?? "",
        color: d["color"] as? String ?? "",
        ink: d["ink"] as? String ?? "",
        shelf: shelf.filter { !$0.question.isEmpty })
    }
    return out
  }
}

// MARK: - Turning over through the day

enum Turns {
  /// The moments a day's shelf turns to its next card: from [start], and
  /// then at every third hour until the day is over, so a widget showing
  /// the shelf is not the same card all day.
  static func times(from start: Date, through day: Date) -> [Date] {
    let calendar = Calendar.current
    var out = [start]
    for hour in stride(from: 3, to: 24, by: 3) {
      if let at = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day),
        at > start
      {
        out.append(at)
      }
    }
    return out
  }

  /// [count] cards of [shelf] for the [turn]th turn of the day, wrapping
  /// round the shelf: the medium widget shows two, the large four.
  static func window(_ shelf: [FiveCard], turn: Int, count: Int) -> [FiveCard] {
    guard !shelf.isEmpty, count > 0 else { return [] }
    let n = min(count, shelf.count)
    let start = (turn * n) % shelf.count
    return (0..<n).map { shelf[(start + $0) % shelf.count] }
  }
}

// MARK: - Today's card

struct CardEntry: TimelineEntry {
  let date: Date
  let data: CardData
  /// The card shown, by id, and where it lives in the app, so that a tap
  /// opens it. Empty for a card with nothing behind it.
  var card: String = ""
  var place: String = CardPlace.today
}

struct CardProvider: TimelineProvider {
  func placeholder(in context: Context) -> CardEntry {
    CardEntry(date: Date(), data: CardProvider.resting)
  }

  func getSnapshot(in context: Context, completion: @escaping (CardEntry) -> Void) {
    if let snap = Shared.snapshot(), let first = CardProvider.entries(snap, from: Date()).first {
      completion(first)
    } else if let first = CardProvider.entries(WebDays.cached(), from: Date()).first {
      completion(first)
    } else {
      completion(placeholder(in: context))
    }
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<CardEntry>) -> Void) {
    let now = Date()
    if let snap = Shared.snapshot() {
      let entries = CardProvider.entries(snap, from: now)
      if !entries.isEmpty {
        completion(Timeline(entries: entries, policy: .atEnd))
        return
      }
    }
    WebDays.fetch { days in
      let entries = CardProvider.entries(days, from: now)
      if entries.isEmpty {
        // Nothing yet: offline on first run. Try again in half an hour.
        completion(
          Timeline(
            entries: [CardEntry(date: now, data: CardProvider.resting)],
            policy: .after(now.addingTimeInterval(30 * 60))))
      } else {
        completion(Timeline(entries: entries, policy: .atEnd))
      }
    }
  }

  /// A fixed card for a widget with nothing to show yet.
  static let resting = CardData(
    edition: 0, topic: "Astute",
    question: String(localized: "Five cards a day, two minutes."),
    color: AstutPalette.night, ink: AstutPalette.cream,
    foot: "", footMark: .none, dots: [], dotsLine: "")

  /// From the app: today's next card to read, as it wrote it — and once
  /// the five are read, today's shelf, turning over every third hour — and
  /// each morning after it the card that morning opens on, from the
  /// calendar it handed over. The streak and the five are only known for
  /// the day the app last saw; a later morning says what the day is, not
  /// what it did.
  static func entries(_ snap: Snapshot, from now: Date) -> [CardEntry] {
    let calendar = Calendar.current
    let base = Shared.days(from: snap.date, to: now)
    var out: [CardEntry] = []
    for i in 0...14 {
      guard
        let day = calendar.date(byAdding: .day, value: i, to: calendar.startOfDay(for: now))
      else { continue }
      let key = Shared.key(day)
      let sameDay = key == snap.date
      let start = i == 0 ? now : day
      let edition = snap.edition + base + i
      let read = snap.five.filter { $0.read }.count
      if sameDay && snap.done {
        let shelf = snap.shelf(key)
        if !shelf.isEmpty {
          out += shelfEntries(
            shelf, from: start, through: day, edition: edition, foot: snap.shelfFrom,
            dots: snap.five.map { $0.read }, dotsLine: snap.fiveDone)
          continue
        }
      }
      let question = sameDay ? snap.question : (snap.ahead[key] ?? "")
      if question.isEmpty { continue }
      let topic = sameDay ? snap.topic : (snap.aheadTopic[key] ?? snap.topic)
      let color = sameDay ? snap.color : (snap.aheadColor[key] ?? snap.color)
      let ink = sameDay ? snap.ink : (snap.aheadInk[key] ?? snap.ink)
      var foot = snap.footPlain
      var mark = FootMark.none
      if sameDay && snap.done {
        foot = snap.footDone
        mark = .done
      } else if sameDay && snap.streak > 0 {
        foot = snap.footStreak
        mark = .streak
      }
      out.append(
        CardEntry(
          date: start,
          data: CardData(
            edition: edition,
            topic: topic, question: question,
            color: Color(hex: color, fallback: AstutPalette.night),
            ink: Color(hex: ink, fallback: .white),
            foot: foot, footMark: mark,
            dots: sameDay ? snap.five.map { $0.read } : [],
            dotsLine: sameDay
              ? (read == snap.five.count && read > 0 ? snap.fiveDone : snap.fiveReadText)
              : ""),
          card: sameDay ? snap.cardId : (snap.aheadId[key] ?? ""),
          place: CardPlace.today))
    }
    return out
  }

  /// From the site: today's shelf, the same for everybody, turning over
  /// every third hour — or, from a copy kept before the site carried the
  /// shelf, the question of the day. A week of it; the timeline ends there
  /// and the site is asked again.
  static func entries(_ days: [String: WebDays.Day], from now: Date) -> [CardEntry] {
    let calendar = Calendar.current
    var out: [CardEntry] = []
    for i in 0...7 {
      guard
        let day = calendar.date(byAdding: .day, value: i, to: calendar.startOfDay(for: now)),
        let d = days[Shared.key(day)]
      else { continue }
      let start = i == 0 ? now : day
      if !d.shelf.isEmpty {
        out += shelfEntries(
          d.shelf, from: start, through: day, edition: d.edition,
          foot: String(localized: "From today's shelf"), dots: [], dotsLine: "")
      } else if !d.question.isEmpty {
        out.append(
          CardEntry(
            date: start,
            data: CardData(
              edition: d.edition, topic: d.topic, question: d.question,
              color: Color(hex: d.color, fallback: AstutPalette.night),
              ink: Color(hex: d.ink, fallback: .white),
              foot: String(localized: "Five cards a day, two minutes."), footMark: .none,
              dots: [], dotsLine: ""),
            card: d.id, place: CardPlace.shelf))
      }
    }
    return out
  }

  /// Today's shelf across the rest of a day, a card at a time.
  static func shelfEntries(
    _ shelf: [FiveCard], from start: Date, through day: Date, edition: Int, foot: String,
    dots: [Bool], dotsLine: String
  ) -> [CardEntry] {
    var out: [CardEntry] = []
    for (turn, at) in Turns.times(from: start, through: day).enumerated() {
      let card = shelf[turn % shelf.count]
      out.append(
        CardEntry(
          date: at,
          data: CardData(
            edition: edition, topic: card.topic, question: card.question,
            color: card.color, ink: card.ink, foot: foot, footMark: .shelf,
            dots: dots, dotsLine: dotsLine),
          card: card.id, place: CardPlace.shelf))
    }
    return out
  }
}

struct CardWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: CardEntry

  /// Lock-screen families exist from iOS 16, so they are asked about
  /// behind the version check, here, rather than in the view's switch.
  private var size: CardSize {
    if #available(iOS 16.0, *), family == .accessoryRectangular { return .rectangular }
    switch family {
    case .systemMedium: return .medium
    case .systemLarge: return .large
    default: return .small
    }
  }

  /// The card on the widget is the whole widget, so the whole widget opens
  /// it.
  private var link: URL? {
    entry.card.isEmpty
      ? AstutLink.from("card", family)
      : AstutLink.card("card", family, id: entry.card, in: entry.place)
  }

  var body: some View {
    switch size {
    case .rectangular:
      CardView(data: entry.data, size: .rectangular)
        .astutBackground(Color.clear)
        .widgetURL(link)
    default:
      CardView(data: entry.data, size: size)
        .astutBackground(entry.data.color)
        .widgetURL(link)
    }
  }
}

struct TodayCardWidget: Widget {
  // The kind the first version shipped with, so a card already on
  // somebody's home screen stays there.
  let kind = "AstutWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: CardProvider()) { entry in
      CardWidgetView(entry: entry)
    }
    .configurationDisplayName("Today's card")
    .description("The next of today's cards, then today's shelf.")
    .supportedFamilies(TodayCardWidget.families)
  }

  static var families: [WidgetFamily] {
    if #available(iOS 16.0, *) {
      return [.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular]
    }
    return [.systemSmall, .systemMedium, .systemLarge]
  }
}

// MARK: - Streak

struct StreakEntry: TimelineEntry {
  let date: Date
  let data: StreakData
  let known: Bool
}

struct StreakProvider: TimelineProvider {
  func placeholder(in context: Context) -> StreakEntry {
    StreakEntry(date: Date(), data: StreakProvider.sample, known: true)
  }

  func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
    completion(StreakProvider.entries(from: Date()).first ?? placeholder(in: context))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
    completion(Timeline(entries: StreakProvider.entries(from: Date()), policy: .atEnd))
  }

  static let sample = StreakData(
    streak: 12, caption: "DAY STREAK", text: "12 days", start: "",
    week: [true, true, true, false, true, true, true],
    labels: ["M", "T", "W", "T", "F", "S", "S"])

  /// Today, and the next two midnights. A streak survives a day that has
  /// not been read yet, so the morning after the app last ran still shows
  /// it, with today's dot open; two mornings on it cannot be vouched for,
  /// and the widget asks for today's five instead.
  static func entries(from now: Date) -> [StreakEntry] {
    guard let snap = Shared.snapshot() else {
      return [
        StreakEntry(
          date: now,
          data: StreakData(
            streak: 0, caption: "ASTUTE", text: "",
            start: String(localized: "Open Astute to see your streak here."),
            week: [], labels: []),
          known: false)
      ]
    }
    let calendar = Calendar.current
    var out: [StreakEntry] = []
    for i in 0...2 {
      guard
        let day = calendar.date(byAdding: .day, value: i, to: calendar.startOfDay(for: now))
      else { continue }
      let gap = max(0, Shared.days(from: snap.date, to: day))
      var week = snap.weekDone.map { $0 == "1" }
      var labels = snap.weekLabels
      if gap > 0 && week.count == 7 && labels.count == 7 {
        let k = min(gap, 7)
        week = Array(week.dropFirst(k)) + Array(repeating: false, count: k)
        labels = Array(labels.dropFirst(k)) + Array(labels.prefix(k))
      }
      let alive = gap == 0 || (gap == 1 && snap.done)
      out.append(
        StreakEntry(
          date: i == 0 ? now : day,
          data: StreakData(
            streak: alive ? snap.streak : 0,
            caption: snap.streakCaption, text: snap.streakText,
            start: snap.streakStart, week: week, labels: labels),
          known: true))
    }
    return out
  }
}

struct StreakWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: StreakEntry

  private var size: StreakSize {
    if #available(iOS 16.0, *) {
      if family == .accessoryCircular { return .circular }
      if family == .accessoryInline { return .inline }
    }
    return .small
  }

  var body: some View {
    switch size {
    case .circular:
      StreakView(data: entry.data, size: .circular)
        .astutAccessoryBackground()
        .widgetURL(AstutLink.from("streak", family))
    case .inline:
      StreakView(data: entry.data, size: .inline)
        .astutBackground(Color.clear)
        .widgetURL(AstutLink.from("streak", family))
    case .small:
      StreakView(data: entry.data, size: .small)
        .astutBackground { AstutLights() }
        .widgetURL(AstutLink.from("streak", family))
    }
  }
}

struct StreakWidget: Widget {
  let kind = "AstutStreak"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
      StreakWidgetView(entry: entry)
    }
    .configurationDisplayName("Streak")
    .description("Your days in a row, and the week.")
    .supportedFamilies(StreakWidget.families)
  }

  static var families: [WidgetFamily] {
    if #available(iOS 16.0, *) {
      return [.systemSmall, .accessoryCircular, .accessoryInline]
    }
    return [.systemSmall]
  }
}

// MARK: - Today's five

struct FiveEntry: TimelineEntry {
  let date: Date
  let data: FiveData
}

struct FiveProvider: TimelineProvider {
  func placeholder(in context: Context) -> FiveEntry {
    FiveEntry(date: Date(), data: FiveProvider.sample)
  }

  func getSnapshot(in context: Context, completion: @escaping (FiveEntry) -> Void) {
    completion(FiveProvider.entries(from: Date()).first ?? placeholder(in: context))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<FiveEntry>) -> Void) {
    completion(Timeline(entries: FiveProvider.entries(from: Date()), policy: .atEnd))
  }

  static let sample = FiveData(
    title: "TODAY'S FIVE",
    cards: [
      FiveCard(
        topic: "Space", color: Color(hex: "#2B5CFF", fallback: .blue), ink: .white, read: true,
        question: "Why does the catalogue of known planets look so strange?"),
      FiveCard(
        topic: "Economics", color: Color(hex: "#FFE600", fallback: .yellow), ink: .black,
        read: true, question: "Should cities scrap rules requiring parking spaces?"),
      FiveCard(
        topic: "Thinking", color: Color(hex: "#9B5CFF", fallback: .purple), ink: .white,
        read: false, question: "Is three hires from one university a reason to look elsewhere?"),
      FiveCard(
        topic: "Language", color: Color(hex: "#00D9D9", fallback: .teal), ink: .black,
        read: false, question: "Why do so many languages call their mother something like ma?"),
      FiveCard(
        topic: "Nature", color: Color(hex: "#00D451", fallback: .green), ink: .black,
        read: false, question: "How much could an ant scaled up a hundred times lift?"),
    ],
    line: "2 of 5 read")

  /// Today as the app left it, and at midnight the new day's five, all
  /// still to read — dealt by the app the night before.
  static func entries(from now: Date) -> [FiveEntry] {
    guard let snap = Shared.snapshot() else {
      return [
        FiveEntry(
          date: now,
          data: FiveData(
            title: "ASTUTE", cards: [],
            line: String(localized: "Open Astute to see today's five here.")))
      ]
    }
    let calendar = Calendar.current
    var out: [FiveEntry] = []
    let gap = Shared.days(from: snap.date, to: now)
    if gap == 0 {
      let read = snap.five.filter { $0.read }.count
      out.append(
        FiveEntry(
          date: now,
          data: FiveData(
            title: snap.fiveTitle, cards: snap.five,
            line: read == snap.five.count && read > 0 ? snap.fiveDone : snap.fiveReadText)))
    }
    if gap <= 1 {
      let midnight =
        gap == 0
        ? calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        : now
      out.append(
        FiveEntry(
          date: midnight,
          data: FiveData(title: snap.fiveTitle, cards: snap.fiveTomorrow, line: snap.fiveWaiting)))
    } else {
      out.append(
        FiveEntry(
          date: now, data: FiveData(title: snap.fiveTitle, cards: [], line: snap.fiveWaiting)))
    }
    return out
  }
}

struct FiveWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: FiveEntry

  private var large: Bool { family == .systemLarge }

  /// Each card opens itself, on Today.
  private var data: FiveData {
    var out = entry.data
    out.cards = entry.data.cards.map { card -> FiveCard in
      var linked = card
      if !card.id.isEmpty {
        linked.link = AstutLink.card("five", family, id: card.id, in: CardPlace.today)
      }
      return linked
    }
    return out
  }

  /// A tap between the cards goes to the next one to read, which is the
  /// card Today is waiting on.
  private var next: URL? {
    if let card = entry.data.cards.first(where: { !$0.read && !$0.id.isEmpty }) {
      return AstutLink.card("five", family, id: card.id, in: CardPlace.today)
    }
    return AstutLink.from("five", family)
  }

  var body: some View {
    FiveView(data: data, large: large)
      .astutBackground(AstutPalette.night)
      .widgetURL(next)
  }
}

struct FiveWidget: Widget {
  let kind = "AstutFive"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FiveProvider()) { entry in
      FiveWidgetView(entry: entry)
    }
    .configurationDisplayName("Today's five")
    .description("The five cards of the day, and how far you are.")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

// MARK: - Today's shelf

struct ShelfEntry: TimelineEntry {
  let date: Date
  let title: String
  let line: String
  /// The whole shelf for the day; each widget shows its share of it.
  let shelf: [FiveCard]
  /// Which turn of the day this is, so the shelf moves on.
  let turn: Int
}

struct ShelfProvider: TimelineProvider {
  func placeholder(in context: Context) -> ShelfEntry {
    ShelfEntry(
      date: Date(), title: "TODAY'S SHELF", line: "", shelf: ShelfProvider.sample, turn: 0)
  }

  func getSnapshot(in context: Context, completion: @escaping (ShelfEntry) -> Void) {
    if let snap = Shared.snapshot(), let first = ShelfProvider.entries(snap, from: Date()).first {
      completion(first)
    } else if let first = ShelfProvider.entries(WebDays.cached(), from: Date()).first {
      completion(first)
    } else {
      completion(placeholder(in: context))
    }
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ShelfEntry>) -> Void) {
    let now = Date()
    if let snap = Shared.snapshot() {
      let entries = ShelfProvider.entries(snap, from: now)
      if !entries.isEmpty {
        completion(Timeline(entries: entries, policy: .atEnd))
        return
      }
    }
    WebDays.fetch { days in
      let entries = ShelfProvider.entries(days, from: now)
      if entries.isEmpty {
        // Nothing yet: offline on first run. Try again in half an hour.
        completion(
          Timeline(
            entries: [
              ShelfEntry(
                date: now, title: ShelfProvider.title, line: "", shelf: [], turn: 0)
            ],
            policy: .after(now.addingTimeInterval(30 * 60))))
      } else {
        completion(Timeline(entries: entries, policy: .atEnd))
      }
    }
  }

  /// "TODAY'S SHELF" in the phone's language, for a widget the app has not
  /// spoken to.
  static var title: String {
    String(localized: "Today's shelf").uppercased(with: Locale.current)
  }

  static let sample = [
    FiveCard(
      topic: "Nature", color: Color(hex: "#00D451", fallback: .green), ink: .black, read: false,
      question: "An ant lifts 20 times its own weight. Scaled up 100 times, how much could it lift?"
    ),
    FiveCard(
      topic: "Technology", color: Color(hex: "#00A6FF", fallback: .blue), ink: .black,
      read: false,
      question: "Two fingers land on a touch screen at once. How many points can it compute?"),
    FiveCard(
      topic: "Food", color: Color(hex: "#FF7A1A", fallback: .orange), ink: .black, read: false,
      question: "Kona coffee grows low, yet rivals mountain coffee. What does altitude stand for?"),
    FiveCard(
      topic: "Space", color: Color(hex: "#2B5CFF", fallback: .blue), ink: .white, read: false,
      question: "Why does the catalogue of known planets look so strange?"),
  ]

  /// From the app: today's shelf and the next fortnight's, a day at a time,
  /// turning over every third hour.
  static func entries(_ snap: Snapshot, from now: Date) -> [ShelfEntry] {
    let calendar = Calendar.current
    var out: [ShelfEntry] = []
    for i in 0...14 {
      guard
        let day = calendar.date(byAdding: .day, value: i, to: calendar.startOfDay(for: now))
      else { continue }
      let shelf = snap.shelf(Shared.key(day))
      if shelf.isEmpty { continue }
      for (turn, at) in Turns.times(from: i == 0 ? now : day, through: day).enumerated() {
        out.append(
          ShelfEntry(
            date: at, title: snap.shelfTitle, line: snap.shelfLine, shelf: shelf, turn: turn))
      }
    }
    return out
  }

  /// From the site, for a widget the app has not spoken to: a week of it,
  /// and then the site is asked again.
  static func entries(_ days: [String: WebDays.Day], from now: Date) -> [ShelfEntry] {
    let calendar = Calendar.current
    var out: [ShelfEntry] = []
    for i in 0...7 {
      guard
        let day = calendar.date(byAdding: .day, value: i, to: calendar.startOfDay(for: now)),
        let d = days[Shared.key(day)], !d.shelf.isEmpty
      else { continue }
      for (turn, at) in Turns.times(from: i == 0 ? now : day, through: day).enumerated() {
        out.append(
          ShelfEntry(
            date: at, title: title,
            line: String(localized: "The same for everyone, and only today"),
            shelf: d.shelf, turn: turn))
      }
    }
    return out
  }
}

struct ShelfWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: ShelfEntry

  private var large: Bool { family == .systemLarge }

  /// This turn's share of the shelf, each card opening itself in Explore.
  private var data: ShelfData {
    let shown = Turns.window(entry.shelf, turn: entry.turn, count: large ? 4 : 2)
    let cards = shown.map { card -> FiveCard in
      var linked = card
      if !card.id.isEmpty {
        linked.link = AstutLink.card("shelf", family, id: card.id, in: CardPlace.shelf)
      }
      return linked
    }
    return ShelfData(
      title: entry.title, line: entry.line, cards: cards,
      empty: String(localized: "Open Astute to see today's shelf here."))
  }

  /// A tap between the cards opens Explore, where the shelf is.
  var body: some View {
    ShelfView(data: data, large: large)
      .astutBackground(AstutPalette.night)
      .widgetURL(AstutLink.from("shelf", family, in: CardPlace.shelf))
  }
}

struct ShelfWidget: Widget {
  let kind = "AstutShelf"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ShelfProvider()) { entry in
      ShelfWidgetView(entry: entry)
    }
    .configurationDisplayName("Today's shelf")
    .description("Cards from the top of Explore, the same for everyone, and only today.")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

// MARK: - The bundle

@main
struct AstutWidgets: WidgetBundle {
  var body: some Widget {
    TodayCardWidget()
    StreakWidget()
    FiveWidget()
    ShelfWidget()
  }
}

// MARK: - Where a tap goes

/// The link a widget opens the app on: which widget it was — "card.systemSmall",
/// "streak.accessoryCircular" — so the app can say which widgets bring
/// readers in, and, for a card, which card and where it lives, so the app
/// opens exactly that card.
enum AstutLink {
  /// A tap on no card in particular: the streak, the room between cards.
  static func from(_ kind: String, _ family: WidgetFamily, in place: String? = nil) -> URL? {
    link(kind, family, card: nil, in: place)
  }

  /// A tap on a card: one of today's five ("today") or a card of today's
  /// shelf ("shelf").
  static func card(_ kind: String, _ family: WidgetFamily, id: String, in place: String) -> URL? {
    link(kind, family, card: id.isEmpty ? nil : id, in: place)
  }

  private static func link(
    _ kind: String, _ family: WidgetFamily, card: String?, in place: String?
  ) -> URL? {
    var parts = URLComponents()
    parts.scheme = "astute"
    parts.host = "widget"
    var items = [URLQueryItem(name: "from", value: "\(kind).\(family)")]
    if let card { items.append(URLQueryItem(name: "card", value: card)) }
    if let place { items.append(URLQueryItem(name: "in", value: place)) }
    parts.queryItems = items
    return parts.url
  }
}

// MARK: - Grounds and margins

extension View {
  /// The widget's ground. iOS 17 wants it declared as the container's
  /// background, and pads the content by its own margins; before 17 the
  /// widget pads and paints itself.
  @ViewBuilder
  func astutBackground(_ color: Color) -> some View {
    if #available(iOS 17.0, *) {
      self.containerBackground(for: .widget) { color }
    } else {
      self.padding(16).background(color)
    }
  }

  @ViewBuilder
  func astutBackground<B: View>(@ViewBuilder _ ground: () -> B) -> some View {
    if #available(iOS 17.0, *) {
      self.containerBackground(for: .widget) { ground() }
    } else {
      self.padding(16).background(ground())
    }
  }

  /// The lock screen's round widgets sit on the system's own disc.
  @ViewBuilder
  func astutAccessoryBackground() -> some View {
    if #available(iOS 17.0, *) {
      self.containerBackground(for: .widget) { AccessoryWidgetBackground() }
    } else {
      self.modifier(AccessoryDisc())
    }
  }
}

/// Before iOS 17 the disc is drawn under the widget by hand; before 16
/// there is no lock screen to draw it on.
private struct AccessoryDisc: ViewModifier {
  @ViewBuilder
  func body(content: Content) -> some View {
    if #available(iOS 16.0, *) {
      ZStack {
        AccessoryWidgetBackground()
        content
      }
    } else {
      content
    }
  }
}
