import AVFoundation
import Flutter

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {

  override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "recorder.audio.session",
                                       binaryMessenger: controller.binaryMessenger)

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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

final class RecorderAudioSession {
  static let shared = RecorderAudioSession()

  func configure(frontMic: Bool) throws {
    let session = AVAudioSession.sharedInstance()

    // 建議用錄影模式，避免語音處理壓縮掉響度
    try session.setCategory(.playAndRecord,
                            mode: .videoRecording,
                            options: [.defaultToSpeaker, .allowBluetoothA2DP, .mixWithOthers])
    try session.setActive(true, options: [])

    // 優先使用內建麥克風，並嘗試選擇資料源（前/後）
    if let builtIn = session.availableInputs?.first(where: { $0.portType == .builtInMic }) {
      var targetDS: AVAudioSessionDataSourceDescription?
      if let dsList = builtIn.dataSources {
        // .front / .back 二選一，沒有對應就用預設
        targetDS = dsList.first(where: { $0.location == (frontMic ? .front : .back) }) ?? builtIn.preferredDataSource
      }
      if let ds = targetDS {
        try builtIn.setPreferredDataSource(ds)
      } else {
        try session.setPreferredInput(builtIn)
      }
    }
  }

  func deactivate() {
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}