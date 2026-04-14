import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let mapsConfigChannelName = "kugla/maps_config"
  private var hasValidGoogleMapsKey = false
  private var googleMapsConfigMessage =
    "Google Maps is not configured for this iOS build yet. Add a valid GMS_API_KEY in ios/Flutter/Secrets.xcconfig."

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       isResolvableGoogleMapsApiKey(apiKey) {
      hasValidGoogleMapsKey = true
      googleMapsConfigMessage = "Google Maps is configured."
      GMSServices.provideAPIKey(apiKey)
    } else {
      googleMapsConfigMessage =
        "Google Maps is unavailable because GMS_API_KEY is missing or unresolved in ios/Flutter/Secrets.xcconfig."
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: mapsConfigChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "isGoogleMapsAvailable":
        result(self?.hasValidGoogleMapsKey ?? false)
      case "getGoogleMapsConfig":
        result([
          "available": self?.hasValidGoogleMapsKey ?? false,
          "message": self?.googleMapsConfigMessage ?? "",
        ])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
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
