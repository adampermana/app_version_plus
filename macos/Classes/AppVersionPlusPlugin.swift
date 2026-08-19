import Cocoa
import FlutterMacOS

public class AppVersionPlusPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "app_version_plus/in_app_update", binaryMessenger: registrar.messenger)
    let instance = AppVersionPlusPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "checkUpdateAvailability":
      result(nil)
    case "startImmediateUpdate":
      result("UPDATE_NOT_AVAILABLE")
    case "startFlexibleUpdate":
      result("UPDATE_NOT_AVAILABLE")
    case "completeFlexibleUpdate":
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
