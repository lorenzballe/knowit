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
      // Everything the app handed over, under the key it came with: text,
      // numbers and flags, and the calendar maps of the mornings ahead.
      // The widgets read the keys they know, so a new one on either side
      // costs nothing here.
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
      if #available(iOS 14.0, *) {
        WidgetCenter.shared.reloadAllTimelines()
      }
      result(nil)
    }
  }
}
