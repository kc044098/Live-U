// ios/Runner/CallManager.swift
import Foundation
import CallKit
#if canImport(AVFAudio)
import AVFAudio        // iOS 15+ 的模組名
#else
import AVFoundation    // 舊版 SDK 用這個（也包含 AVAudioSession）
#endif

final class CallManager: NSObject, CXProviderDelegate {
    static let shared = CallManager()

    private let provider: CXProvider
    private let controller = CXCallController()

    // 方便把原始 payload 帶回 Flutter：uuid -> payload
    private var pendingPayload: [UUID: [String: Any]] = [:]

    override init() {
        let cfg = CXProviderConfiguration(localizedName: "lu live")
        cfg.supportsVideo = true
        cfg.maximumCallsPerCallGroup = 1
        cfg.includesCallsInRecents = false
        cfg.iconTemplateImageData = nil        // 可放 app icon 的黑白模板
        cfg.ringtoneSound = nil                // ⚠️ iOS CallKit鈴聲不能自訂檔案，只能系統鈴聲
        provider = CXProvider(configuration: cfg)
        super.init()
        provider.setDelegate(self, queue: nil)
    }

    // 來電進來：一定要在數秒內呼叫
    func reportNewIncomingCall(uuid: UUID,
                               displayName: String,
                               hasVideo: Bool,
                               payload: [String: Any],
                               completion: ((Error?) -> Void)? = nil) {
        pendingPayload[uuid] = payload
        let upd = CXCallUpdate()
        upd.localizedCallerName = displayName
        upd.hasVideo = hasVideo
        provider.reportNewIncomingCall(with: uuid, update: upd) { err in
            completion?(err)
        }
    }

    // App 主動結束（如超時、掛斷）
    func end(uuid: UUID) {
        let action = CXEndCallAction(call: uuid)
        let txn = CXTransaction(action: action)
        controller.request(txn) { _ in }
    }

    // === CXProviderDelegate ===
    func providerDidReset(_ provider: CXProvider) {}

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        let uuid = action.callUUID
        action.fulfill()
        let payload = pendingPayload[uuid] ?? [:]
        CallKitChannel.shared.emitAnswer(uuid: uuid, payload: payload)
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        let uuid = action.callUUID
        action.fulfill()
        let payload = pendingPayload.removeValue(forKey: uuid) ?? [:]
        CallKitChannel.shared.emitEnd(uuid: uuid, payload: payload)
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        // 這裡可以喚起你們 Agora/音訊設定
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        // 清理音訊
    }
}
