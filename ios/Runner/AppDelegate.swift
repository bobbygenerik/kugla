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
    let rawApiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String
    logGoogleMapsConfiguration(rawApiKey)

    if let apiKey = rawApiKey,
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

  private func logGoogleMapsConfiguration(_ value: String?) {
    #if DEBUG
      guard let value else {
        print("[Kugla][Maps] GMSApiKey is missing from Info.plist at runtime.")
        assertionFailure("Missing GMSApiKey. Create ios/Flutter/Secrets.xcconfig with a valid GMS_API_KEY.")
        return
      }

      let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty {
        print("[Kugla][Maps] GMSApiKey resolved to an empty string.")
        assertionFailure("Empty GMSApiKey. Set GMS_API_KEY in ios/Flutter/Secrets.xcconfig.")
        return
      }

      if trimmed.hasPrefix("$(") && trimmed.hasSuffix(")") {
        print("[Kugla][Maps] GMSApiKey is still unresolved: \(trimmed)")
        assertionFailure("Unresolved GMSApiKey. Confirm ios/Flutter/Secrets.xcconfig exists and is included by the active build configuration.")
        return
      }

      let prefix = String(trimmed.prefix(8))
      print("[Kugla][Maps] GMSApiKey resolved successfully with prefix: \(prefix)…")
    #endif
  }
}
