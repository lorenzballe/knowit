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
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // The home-screen widget cannot run Dart, so the app hands it what it
    // will need — today's question, the streak, and the question for each
    // of the next fourteen mornings — and asks WidgetKit to redraw.
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

    // A tap on a widget opens the app on an astute://widget link that says
    // which widget it was; this is where the link arrives.
    engineBridge.pluginRegistry.registrar(forPlugin: "AstutWidgetOpens")?
      .addSceneDelegate(WidgetOpens.shared)
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
    default: return kind
    }
  }
}

/// Which widget's tap opened the app, held until Dart asks for it.
final class WidgetOpens: NSObject, FlutterSceneLifeCycleDelegate {
  static let shared = WidgetOpens()
  private static var pending: String?

  /// The widget a tap came from, once: asking clears it.
  static func take() -> String? {
    defer { pending = nil }
    return pending
  }

  /// Keeps the widget named by an astute://widget?from=… link. Every other
  /// link is left to whoever else is listening.
  @discardableResult
  static func note(_ url: URL) -> Bool {
    guard url.scheme == "astute", url.host == "widget" else { return false }
    pending =
      URLComponents(url: url, resolvingAgainstBaseURL: false)?
      .queryItems?.first(where: { $0.name == "from" })?.value ?? "unknown"
    return true
  }

  /// The app started from a widget's tap.
  @objc(scene:willConnectToSession:options:)
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    for context in connectionOptions?.urlContexts ?? [] {
      WidgetOpens.note(context.url)
    }
    return false
  }

  /// The app, already running, brought forward by a widget's tap.
  @objc(scene:openURLContexts:)
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    var handled = false
    for context in URLContexts where WidgetOpens.note(context.url) {
      handled = true
    }
    return handled
  }
}
