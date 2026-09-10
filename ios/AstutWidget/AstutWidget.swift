import SwiftUI
import WidgetKit

/// The question of the day, on the home screen.
///
/// Everything it shows was written down by the app the last time it ran,
/// into the shared group: today's question, the streak, and one question
/// for each of the next fourteen mornings. The timeline turns a new entry
/// over at each midnight, so the widget changes whether or not the app is
/// opened — and if it goes a fortnight unopened, the widget goes quiet
/// rather than lying.
struct AstutEntry: TimelineEntry {
  let date: Date
  let edition: Int
  let question: String
  let streak: Int
  let done: Bool
}

struct AstutProvider: TimelineProvider {
  static let appGroup = "group.com.astuto.app"
  static let key: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
  }()

  func placeholder(in context: Context) -> AstutEntry {
    AstutEntry(date: Date(), edition: 0, question: "Five cards a day.", streak: 0, done: false)
  }

  func getSnapshot(in context: Context, completion: @escaping (AstutEntry) -> Void) {
    completion(entries(from: Date()).first ?? placeholder(in: context))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<AstutEntry>) -> Void) {
    completion(Timeline(entries: entries(from: Date()), policy: .atEnd))
  }

  /// One entry for today and one per midnight after it, as far as the app
  /// handed over.
  private func entries(from now: Date) -> [AstutEntry] {
    let shared = UserDefaults(suiteName: AstutProvider.appGroup)
    let storedDate = shared?.string(forKey: "date") ?? ""
    let storedQuestion = shared?.string(forKey: "question") ?? ""
    let ahead = shared?.dictionary(forKey: "ahead") as? [String: String] ?? [:]
    let streak = shared?.integer(forKey: "streak") ?? 0
    let done = shared?.bool(forKey: "done") ?? false
    let baseEdition = shared?.integer(forKey: "edition") ?? 0
    let base = AstutProvider.key.date(from: storedDate)

    let calendar = Calendar.current
    var out: [AstutEntry] = []
    for i in 0...14 {
      guard let day = calendar.date(byAdding: .day, value: i, to: calendar.startOfDay(for: now)) else { continue }
      let key = AstutProvider.key.string(from: day)
      let sameDay = key == storedDate
      let question = sameDay ? storedQuestion : (ahead[key] ?? (i == 0 ? storedQuestion : ""))
      if question.isEmpty { continue }
      var edition = baseEdition
      if let base = base {
        edition += calendar.dateComponents([.day], from: base, to: day).day ?? 0
      }
      out.append(AstutEntry(
        date: i == 0 ? now : day,
        edition: edition,
        question: question,
        streak: streak,
        done: sameDay && done
      ))
    }
    return out
  }
}

struct AstutWidgetView: View {
  var entry: AstutEntry

  var foot: String {
    if entry.done { return "Done for today · 🔥\(entry.streak)" }
    if entry.streak > 0 { return "🔥\(entry.streak) · five cards, two minutes" }
    return "Five cards, two minutes"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(entry.edition > 0 ? "ASTUT · #\(entry.edition)" : "ASTUT")
        .font(.system(size: 10, weight: .bold))
        .tracking(1.4)
        .foregroundColor(.white.opacity(0.6))
      Text(entry.question)
        .font(.system(size: 17, weight: .semibold, design: .serif))
        .foregroundColor(.white)
        .lineLimit(4)
        .minimumScaleFactor(0.8)
      Spacer(minLength: 0)
      Text(foot)
        .font(.system(size: 12))
        .foregroundColor(.white.opacity(0.6))
        .lineLimit(1)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color(red: 20 / 255, green: 20 / 255, blue: 22 / 255))
  }
}

@main
struct AstutWidget: Widget {
  let kind: String = "AstutWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: AstutProvider()) { entry in
      if #available(iOS 17.0, *) {
        AstutWidgetView(entry: entry)
          .containerBackground(for: .widget) {
            Color(red: 20 / 255, green: 20 / 255, blue: 22 / 255)
          }
      } else {
        AstutWidgetView(entry: entry)
      }
    }
    .configurationDisplayName("Today's question")
    .description("The question of the day, and your streak.")
    .supportedFamilies([.systemMedium, .systemSmall])
  }
}
