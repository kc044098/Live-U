import UIKit
import Flutter
import FirebaseCore
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {

  override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?
  ) -> Bool {

    // Facebook 初始化
    ApplicationDelegate.shared.application(
        application,
        didFinishLaunchingWithOptions: launchOptions
    )

    // Flutter 插件
    GeneratedPluginRegistrant.register(with: self)

    print("### Runtime BundleID =", Bundle.main.bundleIdentifier ?? "nil")
    print("### GoogleService-Info path =", Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") ?? "not found")


    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // iOS 9+ URL 回呼（新版簽名）
  override func application(
      _ app: UIApplication,
      open url: URL,
      options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    print("FB openURL => \(url.absoluteString)")
    let handled = ApplicationDelegate.shared.application(app, open: url, options: options)
    print("FB handled: \(handled)")
    return handled || super.application(app, open: url, options: options)
  }
}
