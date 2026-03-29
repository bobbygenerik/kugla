import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let mapsConfigChannelName = "kugla/maps_config"
  private var hasValidGoogleMapsKey = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       isResolvableGoogleMapsApiKey(apiKey) {
      hasValidGoogleMapsKey = true
      GMSServices.provideAPIKey(apiKey)
    }
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: mapsConfigChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "isGoogleMapsAvailable" else {
          result(FlutterMethodNotImplemented)
          return
        }
        result(self?.hasValidGoogleMapsKey ?? false)
      }
    }
    return launched
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func isResolvableGoogleMapsApiKey(_ value: String) -> Bool {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return false
    }

    // Treat unresolved Xcode substitutions like `$(GMS_API_KEY)` as missing.
    if trimmed.hasPrefix("$(") && trimmed.hasSuffix(")") {
      return false
    }

    return true
  }
}
