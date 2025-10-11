// ios/Runner/AppDelegate.swift
import UIKit
import Flutter
import FBSDKCoreKit
import PushKit   // ★
import CallKit   // ★

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {

  override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?
  ) -> Bool {

    // Facebook 初始化
    ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Flutter 插件
    GeneratedPluginRegistrant.register(with: self)

    // 綁定 MethodChannel
    if let controller = window?.rootViewController as? FlutterViewController {
      CallKitChannel.shared.bind(messenger: controller.binaryMessenger)
    }

    // 啟動 PushKit（VoIP）
    VoipPushManager.shared.start()

    print("### Runtime BundleID =", Bundle.main.bundleIdentifier ?? "nil")
    print("### GoogleService-Info path =", Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") ?? "not found")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // iOS 9+ URL 回呼（Facebook）
  override func application(
      _ app: UIApplication,
      open url: URL,
      options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    let handled = ApplicationDelegate.shared.application(app, open: url, options: options)
    return handled || super.application(app, open: url, options: options)
  }
}
