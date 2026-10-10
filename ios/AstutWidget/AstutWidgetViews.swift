import CoreText
import SwiftUI

// The widgets' drawing, and nothing else: no WidgetKit, no storage, no
// platform. The extension feeds it what the app wrote down; the preview
// tool on a Mac (tool/widget_previews) feeds it samples and renders it to
// pictures, so the widgets can be seen without a phone.

// MARK: - Type

/// The app's two faces, with the axes set the way the app sets them.
///
/// Both files are variable fonts whose default instance is not the one
/// wanted (Fraunces opens at 9pt Black, Figtree at Light), so every size is
/// asked for with its weight, and Fraunces with its optical size and the
/// same softness the app uses. When the fonts are not there, the system's
/// serif and sans stand in.
enum AstutType {
  static func fraunces(_ size: CGFloat, weight: CGFloat = 600) -> Font {
    variable(
      "Fraunces-9ptBlack", size,
      ["wght": weight, "opsz": min(max(size, 9), 144), "SOFT": 30, "WONK": 0],
      fallback: .system(size: size, weight: .semibold, design: .serif))
  }

  static func figtree(_ size: CGFloat, weight: CGFloat = 600) -> Font {
    variable(
      "Figtree-Light", size, ["wght": weight],
      fallback: .system(size: size, weight: weight >= 650 ? .bold : .semibold))
  }

  private static func tag(_ axis: String) -> Int {
    axis.utf8.reduce(0) { ($0 << 8) | Int($1) }
  }

  private static func variable(
    _ name: String, _ size: CGFloat, _ axes: [String: CGFloat], fallback: Font
  ) -> Font {
    var variation: [NSNumber: NSNumber] = [:]
    for (axis, value) in axes {
      variation[NSNumber(value: tag(axis))] = NSNumber(value: Double(value))
    }
    let attributes: [CFString: Any] = [
      kCTFontNameAttribute: name,
      kCTFontVariationAttribute: variation,
    ]
    let descriptor = CTFontDescriptorCreateWithAttributes(attributes as CFDictionary)
    let font = CTFontCreateWithFontDescriptor(descriptor, size, nil)
    let family = String(name.prefix { $0 != "-" })
    guard (CTFontCopyPostScriptName(font) as String).hasPrefix(family) else {
      return fallback
    }
    return Font(font)
  }
}

// MARK: - Colour

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
      blue: Double(v & 0xFF) / 255)
  }
}

enum AstutPalette {
  /// The app's paper at night, a shade off black so a widget reads as a
  /// thing on the screen rather than a hole in it.
  static let night = Color(red: 20 / 255, green: 20 / 255, blue: 22 / 255)
  /// The app's cream: its ink on the dark ground, and its one accent.
  static let cream = Color(red: 242 / 255, green: 241 / 255, blue: 236 / 255)
}

/// Two of the paywall's lights — violet from the top corner, teal beside
/// it — on the night ground, so the dark widgets belong to the same app as
/// the screen they open. The yellow stays on the paywall: that dim, on a
/// ground this small, reads as a smudge rather than a light.
struct AstutLights: View {
  var body: some View {
    GeometryReader { box in
      let w = box.size.width
      let h = box.size.height
      ZStack {
        // The ground is not blurred with the lights, or its edges would
        // go soft and let the wallpaper through.
        AstutPalette.night
        ZStack {
          Ellipse()
            .fill(Color(red: 45 / 255, green: 224 / 255, blue: 210 / 255).opacity(0.3))
            .frame(width: w * 0.7, height: w * 0.4)
            .position(x: w * 0.2, y: -h * 0.05)
          Ellipse()
            .fill(Color(red: 139 / 255, green: 108 / 255, blue: 1).opacity(0.5))
            .frame(width: w, height: w * 0.7)
            .position(x: w * 0.9, y: h * 0.05)
        }
        .blur(radius: w * 0.18)
      }
    }
  }
}

// MARK: - Links

/// A card on a widget that opens that very card in the app. A medium or a
/// large widget can hold a link for each card on it; a small one is a
/// single tap, named by the widget itself, and the previews have no app to
/// open — both pass nil, and the card is drawn the same either way.
struct CardLink<Content: View>: View {
  let url: URL?
  @ViewBuilder let content: () -> Content

  var body: some View {
    if let url {
      Link(destination: url) { content() }
    } else {
      content()
    }
  }
}

// MARK: - Today's card

struct CardData {
  var edition: Int
  var topic: String
  var question: String
  var color: Color
  var ink: Color
  /// The line at the foot: the streak, the day done, the plain promise, or
  /// that the card is from today's shelf.
  var foot: String
  var footMark: FootMark
  /// Today's five, read or not, for the large card; empty to leave out.
  var dots: [Bool]
  var dotsLine: String
}

enum FootMark { case streak, done, shelf, none }

enum CardSize { case small, medium, large, rectangular }

/// The next card to read today: the subject's colour for a ground, the
/// subject as an eyebrow, the question set large, and the streak at the
/// foot — the app's card, on the home screen. Once the five are read, a
/// card of today's shelf, and the foot says so.
struct CardView: View {
  let data: CardData
  let size: CardSize

  var body: some View {
    switch size {
    case .rectangular: rectangular
    case .small: small
    case .medium: medium
    case .large: large
    }
  }

  private var eyebrow: some View {
    Text(data.topic.isEmpty ? "ASTUTE" : data.topic.uppercased())
      .font(AstutType.figtree(10, weight: 700))
      .tracking(1.5)
      .lineLimit(1)
      .foregroundStyle(data.ink.opacity(0.72))
  }

  private var edition: some View {
    Text(data.edition > 0 ? "#\(data.edition)" : "")
      .font(AstutType.figtree(10.5, weight: 650))
      .tracking(0.4)
      .foregroundStyle(data.ink.opacity(0.6))
  }

  private var foot: some View {
    HStack(spacing: 6) {
      switch data.footMark {
      case .streak:
        Circle().fill(data.ink).frame(width: 6, height: 6)
      case .done:
        Image(systemName: "checkmark").font(.system(size: 9.5, weight: .heavy))
      case .shelf:
        // The compass Explore's tab wears, where today's shelf is.
        Image(systemName: "safari").font(.system(size: 10, weight: .semibold))
      case .none:
        EmptyView()
      }
      Text(data.foot)
        .font(AstutType.figtree(11.5, weight: 600))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .foregroundStyle(data.ink.opacity(0.82))
  }

  private var mark: some View {
    Text("Astute")
      .font(AstutType.fraunces(13.5, weight: 600))
      .foregroundStyle(data.ink.opacity(0.62))
  }

  private func question(_ size: CGFloat, lines: Int) -> some View {
    Text(data.question)
      .font(AstutType.fraunces(size))
      .tracking(-size * 0.02)
      .lineSpacing(-size * 0.06)
      .foregroundStyle(data.ink)
      .lineLimit(lines)
      .minimumScaleFactor(0.62)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var small: some View {
    VStack(alignment: .leading, spacing: 0) {
      eyebrow
      Spacer(minLength: 6)
      question(17.5, lines: 5)
      Spacer(minLength: 6)
      foot
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private var medium: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline) {
        eyebrow
        Spacer(minLength: 8)
        edition
      }
      Spacer(minLength: 6)
      question(22, lines: 3)
      Spacer(minLength: 6)
      HStack(alignment: .lastTextBaseline) {
        foot
        Spacer(minLength: 8)
        mark
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private var large: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline) {
        eyebrow
        Spacer(minLength: 8)
        edition
      }
      Spacer(minLength: 10)
      question(31, lines: 6)
      Spacer(minLength: 12)
      if !data.dots.isEmpty {
        HStack(spacing: 7) {
          ForEach(Array(data.dots.enumerated()), id: \.offset) { _, read in
            Circle()
              .fill(read ? data.ink : Color.clear)
              .overlay(Circle().strokeBorder(data.ink.opacity(read ? 0 : 0.55), lineWidth: 1.5))
              .frame(width: 11, height: 11)
          }
          Text(data.dotsLine)
            .font(AstutType.figtree(12, weight: 600))
            .foregroundStyle(data.ink.opacity(0.78))
            .lineLimit(1)
            .padding(.leading, 4)
        }
        .padding(.bottom, 14)
      }
      HStack(alignment: .lastTextBaseline) {
        foot
        Spacer(minLength: 8)
        mark
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  /// The lock screen draws in one tint of its own choosing, so this is the
  /// words alone: the subject, and the question in two lines.
  private var rectangular: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(data.topic.isEmpty ? "ASTUTE" : data.topic.uppercased())
        .font(AstutType.figtree(10, weight: 700))
        .tracking(1.2)
        .opacity(0.72)
        .lineLimit(1)
      Text(data.question)
        .font(AstutType.fraunces(14.5, weight: 600))
        .lineLimit(2)
        .minimumScaleFactor(0.8)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}

// MARK: - Streak

struct StreakData {
  var streak: Int
  /// "DAY STREAK", in the reader's language.
  var caption: String
  /// "12 days".
  var text: String
  /// What to say while there is no streak.
  var start: String
  /// The last seven days, oldest first.
  var week: [Bool]
  var labels: [String]
}

enum StreakSize { case small, circular, inline }

/// The days in a row, large, and the week under it: seven dots, filled for
/// a day read through, the last one today's.
struct StreakView: View {
  let data: StreakData
  let size: StreakSize

  var body: some View {
    switch size {
    case .small: small
    case .circular: circular
    case .inline: inline
    }
  }

  private var cream: Color { AstutPalette.cream }

  private var small: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(data.caption)
        .font(AstutType.figtree(10, weight: 700))
        .tracking(1.5)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .foregroundStyle(cream.opacity(0.62))
      Spacer(minLength: 2)
      if data.streak > 0 {
        Text("\(data.streak)")
          .font(AstutType.fraunces(58, weight: 600))
          .tracking(-2)
          .foregroundStyle(cream)
          .lineLimit(1)
          .minimumScaleFactor(0.5)
      } else {
        Text(data.start)
          .font(AstutType.fraunces(16.5, weight: 600))
          .foregroundStyle(cream)
          .lineLimit(4)
          .minimumScaleFactor(0.7)
      }
      Spacer(minLength: 6)
      week
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private var week: some View {
    HStack(spacing: 0) {
      ForEach(0..<7, id: \.self) { i in
        let done = i < data.week.count && data.week[i]
        let today = i == 6
        VStack(spacing: 5) {
          ZStack {
            Circle().fill(done ? cream : Color.clear)
            Circle().strokeBorder(
              cream.opacity(done ? 0 : (today ? 0.9 : 0.32)), lineWidth: today ? 1.6 : 1.3)
          }
          .frame(width: 9, height: 9)
          Text(i < data.labels.count ? data.labels[i] : "")
            .font(AstutType.figtree(8.5, weight: 650))
            .foregroundStyle(cream.opacity(today ? 0.92 : 0.42))
        }
        .frame(maxWidth: .infinity)
      }
    }
  }

  /// A ring for the week, and the days in a row inside it.
  private var circular: some View {
    let doneThisWeek = data.week.filter { $0 }.count
    // In the lock screen's own tint: the track a shade of it, the week in
    // full.
    return ZStack {
      Circle().stroke(.tertiary, lineWidth: 4.5)
      Circle()
        .trim(from: 0, to: CGFloat(doneThisWeek) / 7)
        .stroke(.primary, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
        .rotationEffect(.degrees(-90))
      Text("\(data.streak)")
        .font(AstutType.fraunces(data.streak > 99 ? 15 : 20, weight: 600))
        .minimumScaleFactor(0.6)
    }
    .padding(3)
  }

  private var inline: some View {
    Text(data.streak > 0 ? "\(data.text) · Astute" : "Astute")
  }
}

// MARK: - Today's five

struct FiveCard {
  var topic: String
  var color: Color
  var ink: Color
  var read: Bool
  /// The card, by id, which is what a tap on it opens.
  var id: String = ""
  /// Its question, for the widgets with room to show it.
  var question: String = ""
  /// Where a tap on it goes; nil where the widget cannot hold a link.
  var link: URL? = nil
}

struct FiveData {
  /// "TODAY'S FIVE", in the reader's language.
  var title: String
  var cards: [FiveCard]
  /// "3 of 5 read", "All five read", or the new day waiting.
  var line: String
}

/// The day's five in their colours, in the order they are read: a card
/// read is solid with a tick, a card still to read is its colour, faint,
/// with a ring. Medium, the five side by side with their subjects; large,
/// one above the other, each with the start of its question. Every card
/// opens itself.
struct FiveView: View {
  let data: FiveData
  var large = false

  private var cream: Color { AstutPalette.cream }

  var body: some View {
    let read = data.cards.filter { $0.read }.count
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline) {
        Text(data.title)
          .font(AstutType.figtree(10, weight: 700))
          .tracking(1.5)
          .lineLimit(1)
          .foregroundStyle(cream.opacity(0.62))
        Spacer(minLength: 8)
        if !data.cards.isEmpty {
          Text("\(read)/\(data.cards.count)")
            .font(AstutType.fraunces(17, weight: 600))
            .foregroundStyle(cream)
        }
      }
      Spacer(minLength: 8)
      if large {
        VStack(spacing: 6) {
          ForEach(Array(data.cards.enumerated()), id: \.offset) { _, card in
            CardLink(url: card.link) { row(card) }
          }
        }
      } else {
        HStack(spacing: 7) {
          ForEach(Array(data.cards.enumerated()), id: \.offset) { _, card in
            CardLink(url: card.link) { tile(card) }
          }
        }
        .frame(maxHeight: 84)
      }
      Spacer(minLength: 8)
      Text(data.line)
        .font(AstutType.figtree(12, weight: 600))
        .foregroundStyle(cream.opacity(0.78))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  /// A card's ground: solid once read, its colour faint with a ring while
  /// it waits.
  private func ground(_ card: FiveCard) -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 13, style: .continuous)
        .fill(card.read ? card.color : card.color.opacity(0.2))
      RoundedRectangle(cornerRadius: 13, style: .continuous)
        .strokeBorder(card.color.opacity(card.read ? 0 : 0.75), lineWidth: 1.5)
    }
  }

  /// The large widget's card: the subject over the start of the question,
  /// as much of it as the row holds, and the tick at the end once read.
  private func row(_ card: FiveCard) -> some View {
    let ink = card.read ? card.ink : cream
    return ZStack {
      ground(card)
      HStack(alignment: .center, spacing: 10) {
        VStack(alignment: .leading, spacing: 2) {
          Text(card.topic.uppercased())
            .font(AstutType.figtree(8.5, weight: 700))
            .tracking(0.9)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(ink.opacity(0.78))
          Text(card.question)
            .font(AstutType.fraunces(13.5, weight: 600))
            .tracking(-0.2)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        if card.read {
          Image(systemName: "checkmark")
            .font(.system(size: 11, weight: .heavy))
            .foregroundStyle(card.ink)
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func tile(_ card: FiveCard) -> some View {
    ZStack(alignment: .bottomLeading) {
      ground(card)
      if card.read {
        Image(systemName: "checkmark")
          .font(.system(size: 11, weight: .heavy))
          .foregroundStyle(card.ink)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
          .padding(8)
      }
      Text(card.topic.uppercased())
        .font(AstutType.figtree(7.5, weight: 700))
        .tracking(0.5)
        .lineLimit(1)
        .minimumScaleFactor(0.55)
        .foregroundStyle(card.read ? card.ink.opacity(0.85) : cream.opacity(0.88))
        .padding(.horizontal, 7)
        .padding(.bottom, 8)
    }
  }
}

// MARK: - Today's shelf

struct ShelfData {
  /// "TODAY'S SHELF", in the reader's language.
  var title: String
  /// What the shelf is, under the title on the large widget.
  var line: String
  /// The cards on show: two on the medium widget, four on the large.
  var cards: [FiveCard]
  /// What to say while there is no shelf to show.
  var empty: String
}

/// Today's shelf on the home screen: cards from the top of Explore, the
/// same for everybody and only today, two side by side or four, each on
/// its subject's colour with the subject as an eyebrow and the question
/// set in the display face. Every card opens itself, in Explore.
struct ShelfView: View {
  let data: ShelfData
  var large = false

  private var cream: Color { AstutPalette.cream }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(data.title)
        .font(AstutType.figtree(10, weight: 700))
        .tracking(1.5)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .foregroundStyle(cream.opacity(0.62))
      if large && !data.line.isEmpty && !data.cards.isEmpty {
        Text(data.line)
          .font(AstutType.figtree(11.5, weight: 600))
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .foregroundStyle(cream.opacity(0.5))
          .padding(.top, 3)
      }
      Spacer(minLength: large ? 10 : 8)
      if data.cards.isEmpty {
        Text(data.empty)
          .font(AstutType.fraunces(16.5, weight: 600))
          .foregroundStyle(cream)
          .lineLimit(3)
          .minimumScaleFactor(0.7)
        Spacer(minLength: 0)
      } else if large {
        VStack(spacing: 8) {
          HStack(spacing: 8) {
            cell(0)
            cell(1)
          }
          HStack(spacing: 8) {
            cell(2)
            cell(3)
          }
        }
      } else {
        HStack(spacing: 8) {
          cell(0)
          cell(1)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  /// The card at [i], or the room it would take on a shelf that is short.
  @ViewBuilder
  private func cell(_ i: Int) -> some View {
    if i < data.cards.count {
      CardLink(url: data.cards[i].link) { face(data.cards[i]) }
    } else {
      Color.clear
    }
  }

  private func face(_ card: FiveCard) -> some View {
    let size: CGFloat = large ? 15.5 : 14
    return VStack(alignment: .leading, spacing: 0) {
      Text(card.topic.isEmpty ? "ASTUTE" : card.topic.uppercased())
        .font(AstutType.figtree(8.5, weight: 700))
        .tracking(1.1)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .foregroundStyle(card.ink.opacity(0.72))
      Spacer(minLength: 6)
      Text(card.question)
        .font(AstutType.fraunces(size))
        .tracking(-size * 0.02)
        .lineSpacing(-size * 0.06)
        .foregroundStyle(card.ink)
        .lineLimit(large ? 6 : 4)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(large ? 12 : 11)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(
      RoundedRectangle(cornerRadius: 15, style: .continuous).fill(card.color))
  }
}
