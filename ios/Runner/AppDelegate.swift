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
      guard call.method == "update" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let data = call.arguments as? [String: Any],
            let shared = UserDefaults(suiteName: AppDelegate.appGroup) else {
        result(FlutterError(code: "bad_args", message: "expected a map", details: nil))
        return
      }
      shared.set(data["edition"] as? Int ?? 0, forKey: "edition")
      shared.set(data["date"] as? String ?? "", forKey: "date")
      shared.set(data["question"] as? String ?? "", forKey: "question")
      shared.set(data["topic"] as? String ?? "", forKey: "topic")
      shared.set(data["color"] as? String ?? "", forKey: "color")
      shared.set(data["ink"] as? String ?? "", forKey: "ink")
      shared.set(data["streak"] as? Int ?? 0, forKey: "streak")
      shared.set(data["done"] as? Bool ?? false, forKey: "done")
      shared.set(data["ahead"] as? [String: String] ?? [:], forKey: "ahead")
      shared.set(data["aheadTopic"] as? [String: String] ?? [:], forKey: "aheadTopic")
      shared.set(data["aheadColor"] as? [String: String] ?? [:], forKey: "aheadColor")
      shared.set(data["aheadInk"] as? [String: String] ?? [:], forKey: "aheadInk")
      // The foot's three lines, in the reader's language: the app has the
      // translations and the widget does not.
      shared.set(data["footPlain"] as? String ?? "", forKey: "footPlain")
      shared.set(data["footStreak"] as? String ?? "", forKey: "footStreak")
      shared.set(data["footDone"] as? String ?? "", forKey: "footDone")
      if #available(iOS 14.0, *) {
        WidgetCenter.shared.reloadAllTimelines()
      }
      result(nil)
    }
  }
}
