// Renders the home-screen and lock-screen widgets to pictures, on a Mac,
// from the very SwiftUI the widget extension draws with
// (ios/AstutWidget/AstutWidgetViews.swift) — so they can be seen and
// checked without a phone, a simulator or the App Group.
//
//   swiftc -O -parse-as-library -target arm64-apple-macos14.0 \
//     ios/AstutWidget/AstutWidgetViews.swift tool/widget_previews/Render.swift -o render
//   ./render assets/fonts/Fraunces.ttf assets/fonts/Figtree.ttf out/
//
// .github/workflows/widget-previews.yml runs it on every change to the
// widgets and publishes the pictures on the widget-previews branch.

import AppKit
import CoreText
import SwiftUI

struct Strings {
  let home: String
  let lock: String
  let footStreak: String
  let footDone: String
  let streakCaption: String
  let streakText: String
  let fiveTitle: String
  let fiveRead: String
  let week: [String]
}

let italian = Strings(
  home: "Schermata Home", lock: "Blocco schermo",
  footStreak: "Serie di 12 giorni", footDone: "Fatto per oggi",
  streakCaption: "GIORNI DI SERIE", streakText: "12 giorni",
  fiveTitle: "LE CINQUE DI OGGI", fiveRead: "2 su 5 lette",
  week: ["V", "S", "D", "L", "M", "M", "G"])

let english = Strings(
  home: "Home Screen", lock: "Lock Screen",
  footStreak: "12-day streak", footDone: "Done for today",
  streakCaption: "DAY STREAK", streakText: "12 days",
  fiveTitle: "TODAY'S FIVE", fiveRead: "2 of 5 read",
  week: ["F", "S", "S", "M", "T", "W", "T"])

let dark = Color(red: 16 / 255, green: 16 / 255, blue: 12 / 255)
let space = Color(hex: "#2B5CFF", fallback: .blue)
let economics = Color(hex: "#FFE600", fallback: .yellow)
let psychology = Color(hex: "#9B5CFF", fallback: .purple)
let language = Color(hex: "#00D9D9", fallback: .teal)
let nature = Color(hex: "#00D451", fallback: .green)

/// A widget as the home screen frames it: its ground, the system's margin,
/// and the rounded corner.
struct Framed<Content: View, Ground: View>: View {
  let width: CGFloat
  let height: CGFloat
  @ViewBuilder let ground: () -> Ground
  @ViewBuilder let content: () -> Content

  var body: some View {
    content()
      .padding(16)
      .frame(width: width, height: height)
      .background(ground())
      .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
      .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
  }
}

struct Gallery: View {
  let s: Strings

  var body: some View {
    let five = FiveData(
      title: s.fiveTitle,
      cards: [
        FiveCard(topic: "Space", color: space, ink: .white, read: true),
        FiveCard(topic: "Economics", color: economics, ink: dark, read: true),
        FiveCard(topic: "Psychology", color: psychology, ink: .white, read: false),
        FiveCard(topic: "Language", color: language, ink: dark, read: false),
        FiveCard(topic: "Nature", color: nature, ink: dark, read: false),
      ],
      line: s.fiveRead)
    let streak = StreakData(
      streak: 12, caption: s.streakCaption, text: s.streakText, start: "",
      week: [true, true, true, true, true, true, false], labels: s.week)

    VStack(alignment: .leading, spacing: 18) {
      heading(s.home)
      HStack(spacing: 24) {
        Framed(width: 170, height: 170, ground: { space }) {
          CardView(
            data: CardData(
              edition: 24, topic: "Space",
              question: "Why does the catalogue of known planets look so strange?",
              color: space, ink: .white, foot: s.footStreak, footMark: .streak,
              dots: [], dotsLine: ""),
            size: .small)
        }
        Framed(width: 170, height: 170, ground: { AstutLights() }) {
          StreakView(data: streak, size: .small)
        }
      }
      Framed(width: 364, height: 170, ground: { economics }) {
        CardView(
          data: CardData(
            edition: 24, topic: "Economics",
            question: "Should cities scrap rules requiring parking spaces?",
            color: economics, ink: dark, foot: s.footDone, footMark: .done,
            dots: [], dotsLine: ""),
          size: .medium)
      }
      Framed(width: 364, height: 170, ground: { AstutPalette.night }) {
        FiveView(data: five)
      }
      Framed(width: 364, height: 382, ground: { psychology }) {
        CardView(
          data: CardData(
            edition: 24, topic: "Psychology",
            question:
              "A manager has hired three people from the same university and now feels they should pick elsewhere. Is that reasoning sound?",
            color: psychology, ink: .white, foot: s.footStreak, footMark: .streak,
            dots: five.cards.map { $0.read }, dotsLine: s.fiveRead),
          size: .large)
      }
      heading(s.lock).padding(.top, 10)
      lockScreen(streak: streak)
    }
    .padding(20)
    .background(
      LinearGradient(
        colors: [
          Color(red: 0.16, green: 0.2, blue: 0.36), Color(red: 0.31, green: 0.2, blue: 0.4),
          Color(red: 0.12, green: 0.1, blue: 0.2),
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing))
  }

  private func heading(_ text: String) -> some View {
    Text(text)
      .font(AstutType.figtree(13, weight: 700))
      .tracking(1)
      .foregroundStyle(.white.opacity(0.75))
  }

  /// The lock screen tints what it shows in one colour of its own; white
  /// over the wallpaper is what most of them look like.
  private func lockScreen(streak: StreakData) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      StreakView(data: streak, size: .inline)
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(.white)
      HStack(spacing: 14) {
        CardView(
          data: CardData(
            edition: 24, topic: "Space",
            question: "Why does the catalogue of known planets look so strange?",
            color: space, ink: .white, foot: "", footMark: .none, dots: [], dotsLine: ""),
          size: .rectangular
        )
        .foregroundStyle(.white)
        .frame(width: 172, height: 76)
        StreakView(data: streak, size: .circular)
          .foregroundStyle(.white)
          .frame(width: 76, height: 76)
          .background(Circle().fill(.white.opacity(0.14)))
      }
    }
    .padding(18)
    .frame(width: 364, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(Color.black.opacity(0.35)))
    // The lock screen is dark whatever the phone's setting.
    .environment(\.colorScheme, .dark)
  }
}

@MainActor
func render<V: View>(_ view: V, to url: URL) {
  let renderer = ImageRenderer(content: view)
  renderer.scale = 3
  guard let image = renderer.cgImage else {
    print("could not render \(url.lastPathComponent)")
    exit(1)
  }
  let bitmap = NSBitmapImageRep(cgImage: image)
  guard let png = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
  try! png.write(to: url)
  print("wrote \(url.path) \(image.width)x\(image.height)")
}

@main
struct Render {
  @MainActor
  static func main() {
    let args = Array(CommandLine.arguments.dropFirst())
    for path in args where path.hasSuffix(".ttf") {
      var error: Unmanaged<CFError>?
      if !CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: path) as CFURL, .process, &error) {
        print("font not registered: \(path)")
      }
    }
    let out = URL(fileURLWithPath: args.last ?? ".")
    render(Gallery(s: italian), to: out.appendingPathComponent("widgets-it.png"))
    render(Gallery(s: english), to: out.appendingPathComponent("widgets-en.png"))
  }
}
