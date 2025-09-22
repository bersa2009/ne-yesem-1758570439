import UIKit
import Flutter
import Intents

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let assistantChannel = FlutterMethodChannel(name: "ne_yesem/assistant",
                                                binaryMessenger: controller.binaryMessenger)
    
    assistantChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "handleSiriIntent":
        self.handleSiriIntent(call: call, result: result)
      case "setupAppShortcuts":
        self.setupAppShortcuts(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func handleSiriIntent(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let intentName = args["intentName"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
      return
    }
    
    let parameters = args["parameters"] as? [String: Any] ?? [:]
    
    let response: [String: Any] = [
      "type": "success",
      "message": "Siri intent handled: \(intentName)",
      "data": parameters
    ]
    
    result(response)
  }
  
  private func setupAppShortcuts(call: FlutterMethodCall, result: @escaping FlutterResult) {
    // Setup iOS app shortcuts
    let shortcut1 = UIApplicationShortcutItem(
      type: "add_ingredients",
      localizedTitle: "Malzeme Ekle",
      localizedSubtitle: "Sesle malzeme ekle",
      icon: UIApplicationShortcutIcon(systemImageName: "mic.fill")
    )
    
    let shortcut2 = UIApplicationShortcutItem(
      type: "find_recipes",
      localizedTitle: "Tarif Bul",
      localizedSubtitle: "Hızlı tarif bul",
      icon: UIApplicationShortcutIcon(systemImageName: "magnifyingglass")
    )
    
    let shortcut3 = UIApplicationShortcutItem(
      type: "camera_scan",
      localizedTitle: "Kamera ile Tara",
      localizedSubtitle: "Malzemeleri kamera ile ekle",
      icon: UIApplicationShortcutIcon(systemImageName: "camera.fill")
    )
    
    UIApplication.shared.shortcutItems = [shortcut1, shortcut2, shortcut3]
    result(true)
  }
  
  override func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
    let controller = window?.rootViewController as! FlutterViewController
    let assistantChannel = FlutterMethodChannel(name: "ne_yesem/assistant",
                                                binaryMessenger: controller.binaryMessenger)
    
    let args: [String: Any] = [
      "shortcutId": shortcutItem.type,
      "title": shortcutItem.localizedTitle
    ]
    
    assistantChannel.invokeMethod("handleAppShortcut", arguments: args)
    completionHandler(true)
  }
  
  // Handle Siri Intents
  override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if userActivity.activityType == "AddIngredientsIntent" {
      let controller = window?.rootViewController as! FlutterViewController
      let assistantChannel = FlutterMethodChannel(name: "ne_yesem/assistant",
                                                  binaryMessenger: controller.binaryMessenger)
      
      let args: [String: Any] = [
        "intentName": "AddIngredientsIntent",
        "parameters": userActivity.userInfo ?? [:]
      ]
      
      assistantChannel.invokeMethod("handleSiriIntent", arguments: args)
      return true
    }
    
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}