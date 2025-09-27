import AVFoundation
import Flutter
import FirebaseCore

import AVFoundation
import Flutter
import FirebaseCore

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {

  override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ 先註冊所有 Flutter 插件（非常重要）
    GeneratedPluginRegistrant.register(with: self)

    // ✅ 若尚未配置 Firebase，就在原生端配置一次（可與 Dart 並存）
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    // 你的 MethodChannel 維持不變
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
          name: "recorder.audio.session",
          binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "configure":
          guard let args = call.arguments as? [String: Any],
                let front = args["front"] as? Bool else {
            result(FlutterError(code: "BAD_ARGS", message: "missing 'front'", details: nil))
            return
          }
          do {
            try RecorderAudioSession.shared.configure(frontMic: front)
            result(true)
          } catch {
            result(FlutterError(code: "AUDIO_CFG_FAIL", message: error.localizedDescription, details: nil))
          }
        case "deactivate":
          RecorderAudioSession.shared.deactivate()
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

import AVFoundation

final class RecorderAudioSession {
  static let shared = RecorderAudioSession()

  func configure(frontMic: Bool) throws {
    let session = AVAudioSession.sharedInstance()

    // 錄放同時 + 外放 +（可選）藍牙
    try session.setCategory(
      .playAndRecord,
      mode: .videoRecording,
      options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP, .mixWithOthers]
    )

    try session.setActive(true, options: [])

    // （可選）把偏好輸入設為內建麥克風；不處理資料來源(front/back)
    if let builtIn = session.availableInputs?.first(where: { $0.portType == .builtInMic }) {
      try session.setPreferredInput(builtIn)
    }
  }

  func deactivate() {
    try? AVAudioSession.sharedInstance()
      .setActive(false, options: .notifyOthersOnDeactivation)
  }
}
