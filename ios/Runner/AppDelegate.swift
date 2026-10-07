import Flutter
import StoreKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // In-app review, called by ReviewService. StoreKit decides whether the
    // sheet shows and never says, so this always answers true.
    if let reviewRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "ReviewChannel") {
      FlutterMethodChannel(name: "com.neteru.tixtat/review", binaryMessenger: reviewRegistrar.messenger())
        .setMethodCallHandler { call, result in
          guard call.method == "requestReview" else {
            result(FlutterMethodNotImplemented)
            return
          }
          if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
          }
          result(true)
        }
    }
  }
}
