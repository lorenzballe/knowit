import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Where the widget reads from. The app and its widget extension share
  /// this group; both targets must carry it in their entitlements.
  static let appGroup = "group.com.astuto.app"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // A tap on a widget opens the app on an astute://widget link that says
    // which widget it was and which card; this is where the link arrives.
    // Registered before every plugin: the launch's links are shown to one
    // listener only, the first to claim them, and a plugin that answers for
    // every launch would otherwise keep a widget's tap from the app that
    // started from it.
    engineBridge.pluginRegistry.registrar(forPlugin: "AstutWidgetOpens")?
      .addSceneDelegate(WidgetOpens.shared)

    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // The home-screen widgets cannot run Dart, so the app hands them what
    // they will need — today's cards and today's shelf, the streak, and the
    // same for each of the next fourteen mornings — and asks WidgetKit to
    // redraw.
    let channel = FlutterMethodChannel(
      name: "astut/widget",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "update":
        AppDelegate.update(call.arguments, result: result)
      case "installed":
        AppDelegate.installed(result: result)
      case "takeOpenedFrom":
        result(WidgetOpens.take())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    WidgetOpens.channel = channel
  }

  /// Everything the app handed over, under the key it came with: text,
  /// numbers and flags, and the calendar maps of the mornings ahead. The
  /// widgets read the keys they know, so a new one on either side costs
  /// nothing here.
  static func update(_ arguments: Any?, result: FlutterResult) {
    guard let data = arguments as? [String: Any],
      let shared = UserDefaults(suiteName: AppDelegate.appGroup)
    else {
      result(FlutterError(code: "bad_args", message: "expected a map", details: nil))
      return
    }
    for (key, value) in data {
      switch value {
      case let text as String:
        shared.set(text, forKey: key)
      case let number as NSNumber:
        shared.set(number, forKey: key)
      case let map as [String: String]:
        shared.set(map, forKey: key)
      default:
        continue
      }
    }
    WidgetCenter.shared.reloadAllTimelines()
    result(nil)
  }

  /// The widgets the reader has placed, as "kind.family", for measurement.
  static func installed(result: @escaping FlutterResult) {
    WidgetCenter.shared.getCurrentConfigurations { found in
      var names: [String] = []
      if case .success(let widgets) = found {
        names = widgets.map { "\(AppDelegate.shortKind($0.kind)).\($0.family)" }
      }
      DispatchQueue.main.async { result(names) }
    }
  }

  /// The widget kinds by the names the events use.
  static func shortKind(_ kind: String) -> String {
    switch kind {
    case "AstutWidget": return "card"
    case "AstutStreak": return "streak"
    case "AstutFive": return "five"
    case "AstutShelf": return "shelf"
    default: return kind
    }
  }
}

/// Which widget's tap opened the app, and the card it named, held until
/// Dart asks for it.
final class WidgetOpens: NSObject, FlutterSceneLifeCycleDelegate {
  static let shared = WidgetOpens()

  /// The channel the app listens on, to be told a tap has come in.
  static var channel: FlutterMethodChannel?

  /// "from", and for a card "card" and "in": the link's own words.
  private static var pending: [String: String]?

  /// The tap, once: asking clears it.
  static func take() -> [String: String]? {
    defer { pending = nil }
    return pending
  }

  /// Keeps what an astute://widget link says: which widget, which card,
  /// and where the card lives. Every other link is left to whoever else is
  /// listening.
  @discardableResult
  static func note(_ url: URL) -> Bool {
    guard url.scheme == "astute", url.host == "widget" else { return false }
    var open = ["from": "unknown"]
    for item in URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? [] {
      guard ["from", "card", "in"].contains(item.name), let value = item.value, !value.isEmpty
      else { continue }
      open[item.name] = value
    }
    pending = open
    return true
  }

  /// The app started from a widget's tap. Claimed, so that Flutter does not
  /// also try the link as a route of its own, which it is not.
  @objc(scene:willConnectToSession:options:)
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    var handled = false
    for context in connectionOptions?.urlContexts ?? [] where WidgetOpens.note(context.url) {
      handled = true
    }
    return handled
  }

  /// The app, already running, brought forward by a widget's tap. The app
  /// is told at once: it also asks on coming back to the foreground, and
  /// the phone does not promise which of the two happens first.
  @objc(scene:openURLContexts:)
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    var handled = false
    for context in URLContexts where WidgetOpens.note(context.url) {
      handled = true
    }
    if handled {
      WidgetOpens.channel?.invokeMethod("opened", arguments: nil)
    }
    return handled
  }
}
