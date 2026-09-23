import SwiftUI
import WidgetKit

/// The card the morning opens on, on the home screen — drawn the way the
/// app draws a card: the subject's colour for a ground, the subject as an
/// eyebrow, the question set large, and a foot with the streak.
///
/// Everything it shows was written down by the app the last time it ran,
/// into the shared group: today's card, the streak, and one card for each
/// of the next fourteen mornings, with the colour and the subject of each.
/// The timeline turns a new entry over at each midnight, so the widget
/// changes whether or not the app is opened — and if it goes a fortnight
/// unopened, the widget goes quiet rather than lying.
struct AstutEntry: TimelineEntry {
  let date: Date
  let edition: Int
  let topic: String
  let question: String
  let color: Color
  let ink: Color
  let foot: String
  let streak: Int
  let done: Bool
}

extension Color {
  /// "#RRGGBB" as the app writes it, or the fallback when it did not.
  init(hex: String, fallback: Color) {
    var s = hex.trimmingCharacters(in: .whitespaces)
    if s.hasPrefix("#") { s.removeFirst() }
    guard s.count == 6, let v = UInt64(s, radix: 16) else {
      self = fallback
      return
    }
    self.init(
      red: Double((v >> 16) & 0xFF) / 255,
      green: Double((v >> 8) & 0xFF) / 255,
      blue: Double(v & 0xFF) / 255
    )
  }
}

/// The app's dark paper, for a widget that has not been told a colour yet.
let astutPaper = Color(red: 20 / 255, green: 20 / 255, blue: 22 / 255)

struct AstutProvider: TimelineProvider {
  static let appGroup = "group.com.astuto.app"
  static let key: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
  }()

  func placeholder(in context: Context) -> AstutEntry {
    AstutEntry(
      date: Date(), edition: 0, topic: "Astute",
      question: "Five cards a day, two minutes.",
      color: astutPaper, ink: .white, foot: "", streak: 0, done: false)
  }

  func getSnapshot(in context: Context, completion: @escaping (AstutEntry) -> Void) {
    completion(entries(from: Date()).first ?? placeholder(in: context))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<AstutEntry>) -> Void) {
    let entries = self.entries(from: Date())
    completion(Timeline(entries: entries.isEmpty ? [placeholder(in: context)] : entries, policy: .atEnd))
  }

  /// One entry for today and one per midnight after it, as far as the app
  /// handed over.
  private func entries(from now: Date) -> [AstutEntry] {
    let shared = UserDefaults(suiteName: AstutProvider.appGroup)
    let storedDate = shared?.string(forKey: "date") ?? ""
    let storedQuestion = shared?.string(forKey: "question") ?? ""
    let storedTopic = shared?.string(forKey: "topic") ?? ""
    let storedColor = shared?.string(forKey: "color") ?? ""
    let storedInk = shared?.string(forKey: "ink") ?? ""
    let ahead = shared?.dictionary(forKey: "ahead") as? [String: String] ?? [:]
    let aheadTopic = shared?.dictionary(forKey: "aheadTopic") as? [String: String] ?? [:]
    let aheadColor = shared?.dictionary(forKey: "aheadColor") as? [String: String] ?? [:]
    let aheadInk = shared?.dictionary(forKey: "aheadInk") as? [String: String] ?? [:]
    let streak = shared?.integer(forKey: "streak") ?? 0
    let done = shared?.bool(forKey: "done") ?? false
    let baseEdition = shared?.integer(forKey: "edition") ?? 0
    let footPlain = shared?.string(forKey: "footPlain") ?? ""
    let footStreak = shared?.string(forKey: "footStreak") ?? footPlain
    let footDone = shared?.string(forKey: "footDone") ?? footPlain
    let base = AstutProvider.key.date(from: storedDate)

    let calendar = Calendar.current
    var out: [AstutEntry] = []
    for i in 0...14 {
      guard let day = calendar.date(byAdding: .day, value: i, to: calendar.startOfDay(for: now)) else { continue }
      let key = AstutProvider.key.string(from: day)
      let sameDay = key == storedDate
      let question = sameDay ? storedQuestion : (ahead[key] ?? (i == 0 ? storedQuestion : ""))
      if question.isEmpty { continue }
      let topic = sameDay ? storedTopic : (aheadTopic[key] ?? storedTopic)
      let color = Color(hex: sameDay ? storedColor : (aheadColor[key] ?? storedColor), fallback: astutPaper)
      let ink = Color(hex: sameDay ? storedInk : (aheadInk[key] ?? storedInk), fallback: .white)
      var edition = baseEdition
      if let base = base {
        edition += calendar.dateComponents([.day], from: base, to: day).day ?? 0
      }
      // The streak is only known for the day the app last saw; a later
      // morning says what the day is, not what it did.
      let today = sameDay || (i == 0 && storedDate.isEmpty)
      let foot = today ? (done ? footDone : (streak > 0 ? footStreak : footPlain)) : footPlain
      out.append(AstutEntry(
        date: i == 0 ? now : day,
        edition: edition,
        topic: topic,
        question: question,
        color: color,
        ink: ink,
        foot: foot,
        streak: today ? streak : 0,
        done: today && done
      ))
    }
    return out
  }
}

struct AstutWidgetView: View {
  @Environment(\.widgetFamily) var family
  var entry: AstutEntry

  var eyebrow: String {
    entry.topic.isEmpty ? "ASTUTE" : entry.topic.uppercased()
  }

  var body: some View {
    if #available(iOS 16.0, *), family == .accessoryRectangular {
      // The lock screen: no colour of its own, two lines of the question.
      VStack(alignment: .leading, spacing: 2) {
        Text(eyebrow)
          .font(.system(size: 10, weight: .bold))
          .tracking(1)
          .opacity(0.7)
        Text(entry.question)
          .font(.system(size: 13, weight: .semibold, design: .serif))
          .lineLimit(2)
          .minimumScaleFactor(0.85)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    } else {
      card
    }
  }

  /// The card: the subject's colour, the eyebrow, the question, the foot.
  var card: some View {
    let small = family == .systemSmall
    return VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        Image(systemName: "sparkles")
          .font(.system(size: 9, weight: .bold))
        Text(eyebrow)
          .font(.system(size: 10, weight: .bold))
          .tracking(1.4)
          .lineLimit(1)
        Spacer(minLength: 4)
        if entry.edition > 0 && !small {
          Text("#\(entry.edition)")
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.6)
        }
      }
      .foregroundColor(entry.ink.opacity(0.72))
      Spacer(minLength: 2)
      Text(entry.question)
        .font(.system(size: small ? 15 : 19, weight: .semibold, design: .serif))
        .foregroundColor(entry.ink)
        .lineLimit(small ? 4 : 3)
        .minimumScaleFactor(0.72)
        .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 2)
      if !entry.foot.isEmpty {
        HStack(spacing: 5) {
          if entry.done {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 11, weight: .semibold))
          } else if entry.streak > 0 {
            Image(systemName: "flame.fill").font(.system(size: 11, weight: .semibold))
          }
          Text(entry.foot)
            .font(.system(size: 11.5, weight: .medium))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .foregroundColor(entry.ink.opacity(0.78))
      }
    }
    .padding(small ? 14 : 16)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

@main
struct AstutWidget: Widget {
  let kind: String = "AstutWidget"

  var families: [WidgetFamily] {
    if #available(iOS 16.0, *) {
      return [.systemSmall, .systemMedium, .accessoryRectangular]
    }
    return [.systemSmall, .systemMedium]
  }

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: AstutProvider()) { entry in
      if #available(iOS 17.0, *) {
        AstutWidgetView(entry: entry)
          .containerBackground(for: .widget) { entry.color }
      } else {
        AstutWidgetView(entry: entry)
          .background(entry.color)
      }
    }
    .configurationDisplayName("Today's card")
    .description("The card the morning opens on, and your streak.")
    .supportedFamilies(families)
  }
}
