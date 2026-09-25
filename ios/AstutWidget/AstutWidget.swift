import SwiftUI
import WidgetKit

// Three widgets from one extension: today's card, the streak, and today's
// five. The drawing is in AstutWidgetViews.swift; this is where the data
// comes from and when each widget turns over.
//
// The app writes everything down in the shared App Group each time it
// runs: today's card and one for each of the next fourteen mornings, the
// streak and the week, today's five and tomorrow's, and every line already
// in the reader's language. Until that group exists on the Apple account
// the extension cannot read any of it, so the card falls back to the
// question of the day, which is the same for everybody and published on
// the site, and the other two say where their data will come from.

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

struct Snapshot {
  let date: String
  let edition: Int
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

  init(_ d: UserDefaults, date: String) {
    func text(_ key: String) -> String { d.string(forKey: key) ?? "" }
    func map(_ key: String) -> [String: String] {
      d.dictionary(forKey: key) as? [String: String] ?? [:]
    }
    self.date = date
    edition = d.integer(forKey: "edition")
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
  }

  static func cards(_ json: String) -> [FiveCard] {
    guard let list = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [[String: Any]]
    else { return [] }
    return list.map {
      FiveCard(
        topic: $0["topic"] as? String ?? "",
        color: Color(hex: $0["color"] as? String ?? "", fallback: AstutPalette.night),
        ink: Color(hex: $0["ink"] as? String ?? "", fallback: .white),
        read: $0["read"] as? Bool ?? false)
    }
  }
}

// MARK: - The question of the day, from the site

/// Today's question and the next weeks', for a widget the app has not
/// spoken to. Published with every deploy as widget/days.json.
enum WebDays {
  struct Day {
    let edition: Int
    let question: String
    let topic: String
    let color: String
    let ink: String
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
      out[key] = Day(
        edition: d["edition"] as? Int ?? 0,
        question: d["question"] as? String ?? "",
        topic: d["topic"] as? String ?? "",
        color: d["color"] as? String ?? "",
        ink: d["ink"] as? String ?? "")
    }
    return out
  }
}

// MARK: - Today's card

struct CardEntry: TimelineEntry {
  let date: Date
  let data: CardData
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

  /// From the app: today's card as it wrote it, and each morning after it
  /// from the calendar it handed over. The streak and the five are only
  /// known for the day the app last saw; a later morning says what the day
  /// is, not what it did.
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
      let read = snap.five.filter { $0.read }.count
      out.append(
        CardEntry(
          date: i == 0 ? now : day,
          data: CardData(
            edition: snap.edition + base + i,
            topic: topic, question: question,
            color: Color(hex: color, fallback: AstutPalette.night),
            ink: Color(hex: ink, fallback: .white),
            foot: foot, footMark: mark,
            dots: sameDay ? snap.five.map { $0.read } : [],
            dotsLine: sameDay
              ? (read == snap.five.count && read > 0 ? snap.fiveDone : snap.fiveReadText)
              : "")))
    }
    return out
  }

  /// From the site: the question of the day, for each morning it lists.
  static func entries(_ days: [String: WebDays.Day], from now: Date) -> [CardEntry] {
    let calendar = Calendar.current
    var out: [CardEntry] = []
    for i in 0...14 {
      guard
        let day = calendar.date(byAdding: .day, value: i, to: calendar.startOfDay(for: now)),
        let d = days[Shared.key(day)], !d.question.isEmpty
      else { continue }
      out.append(
        CardEntry(
          date: i == 0 ? now : day,
          data: CardData(
            edition: d.edition, topic: d.topic, question: d.question,
            color: Color(hex: d.color, fallback: AstutPalette.night),
            ink: Color(hex: d.ink, fallback: .white),
            foot: String(localized: "Five cards a day, two minutes."), footMark: .none,
            dots: [], dotsLine: "")))
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

  var body: some View {
    switch size {
    case .rectangular:
      CardView(data: entry.data, size: .rectangular)
        .astutBackground(Color.clear)
        .widgetURL(AstutLink.from("card", family))
    default:
      CardView(data: entry.data, size: size)
        .astutBackground(entry.data.color)
        .widgetURL(AstutLink.from("card", family))
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
    .description("The card the morning opens on, and your streak.")
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
      FiveCard(topic: "Space", color: Color(hex: "#2B5CFF", fallback: .blue), ink: .white, read: true),
      FiveCard(topic: "Economics", color: Color(hex: "#FFE600", fallback: .yellow), ink: .black, read: true),
      FiveCard(topic: "Thinking", color: Color(hex: "#9B5CFF", fallback: .purple), ink: .white, read: false),
      FiveCard(topic: "Language", color: Color(hex: "#00D9D9", fallback: .teal), ink: .black, read: false),
      FiveCard(topic: "Nature", color: Color(hex: "#00D451", fallback: .green), ink: .black, read: false),
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

struct FiveWidget: Widget {
  let kind = "AstutFive"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FiveProvider()) { entry in
      FiveView(data: entry.data)
        .astutBackground(AstutPalette.night)
        .widgetURL(AstutLink.from("five", .systemMedium))
    }
    .configurationDisplayName("Today's five")
    .description("The five cards of the day, and how far you are.")
    .supportedFamilies([.systemMedium])
  }
}

// MARK: - The bundle

@main
struct AstutWidgets: WidgetBundle {
  var body: some Widget {
    TodayCardWidget()
    StreakWidget()
    FiveWidget()
  }
}

// MARK: - Which widget opened the app

/// The link a widget opens the app on, naming itself — "card.systemSmall",
/// "streak.accessoryCircular" — so the app can say which widgets bring
/// readers in.
enum AstutLink {
  static func from(_ kind: String, _ family: WidgetFamily) -> URL? {
    URL(string: "astute://widget?from=\(kind).\(family)")
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
