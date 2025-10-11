import Foundation
import PushKit
import CallKit

final class VoipPushManager: NSObject, PKPushRegistryDelegate {
    static let shared = VoipPushManager()

    private var registry: PKPushRegistry?
    var lastToken: String?

    func start() {
        let r = PKPushRegistry(queue: .main)
        r.delegate = self
        r.desiredPushTypes = [.voIP]
        self.registry = r
    }

    // Token 變更
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else { return }
        let tokenHex = credentials.token.map { String(format: "%02x", $0) }.joined()
        lastToken = tokenHex
        CallKitChannel.shared.emitVoipToken(tokenHex)
    }

    // iOS 13+
    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      completion: @escaping () -> Void) {
        handle(payload: payload.dictionaryPayload)
        completion()
    }

    // iOS 11~12
    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType) {
        handle(payload: payload.dictionaryPayload)
    }

    // ========= 核心處理 =========
    private func handle(payload: [AnyHashable: Any]) {
        guard var dict = payload as? [String: Any] else { return }

        // 1) 攤平 data/Data
        if let d = dict["data"] as? [String: Any] { dict.merge(d) { _, new in new } }
        else if let d = dict["Data"] as? [String: Any] { dict.merge(d) { _, new in new } }

        // 2) 事件推導
        let event = deriveEvent(from: dict) ?? "invite"

        // 3) 取/造 UUID（穩定 fallback）
        let uuid: UUID = {
            if let s = (dict["uuid"] as? String) ?? (dict["UUID"] as? String) { return UUID(uuidString: s) ?? fallbackUUID(dict) }
            return fallbackUUID(dict)
        }()

        switch event {
        case "invite":
            let name = (dict["nick_name"] as? String) ?? "Incoming"
            let flag = Int("\(dict["flag"] ?? "1")") ?? 1
            let hasVideo = (flag == 1)

            let isActive = UIApplication.shared.applicationState == .active
            if isActive {
                print("### [VOIP] invite while foreground → skip CallKit & skip Dart emit")
                // 前景：什麼都不做（不顯示 CallKit、不 emit 到 Flutter）
                return
            }

            // 背景：顯示系統來電 UI；完成後不必再 emit 到 Flutter（看需求）
            CallManager.shared.reportNewIncomingCall(
                uuid: uuid,
                displayName: name,
                hasVideo: hasVideo,
                payload: dict
            )

        case "cancel", "timeout", "busy", "end":
            CallManager.shared.end(uuid: uuid)
            CallKitChannel.shared.emitEnd(uuid: uuid, payload: dict)

            // 來電裝置通常不需要處理 accept/reject（給呼叫方用），這裡保守忽略
        case "accept", "reject":
            break
        default:
            break
        }
    }

    // --- 工具方法 ---

    private func deriveEvent(from m: [String: Any]) -> String? {
        // 1) 直接給 event
        if let e = (m["event"] as? String)?.lowercased(), !e.isEmpty { return e }

        // 2) 從 status 對應（同 Dart 的 _mapCallStateToEventDynamic）
        func asString(_ v: Any?) -> String { v.map { "\($0)" } ?? "" }
        let s = asString(m["status"] ?? (m["Status"] ?? m["data_status"])).lowercased()
        if !s.isEmpty {
            switch s {
            case "1", "accept", "accepted": return "accept"
            case "invite", "ringing": return "invite"
            case "2", "reject": return "reject"
            case "cancel": return "cancel"
            case "timeout": return "timeout"
            case "end", "hangup": return "end"
            case "busy": return "busy"
            default: break
            }
        }

        // 3) 只有 type=6（call）時，預設 invite
        let t = asString(m["type"]).lowercased()
        if t == "6" || t == "call" { return "invite" }

        return nil
    }

    private func fallbackUUID(_ m: [String: Any]) -> UUID {
        let ch = (m["channel_id"] as? String) ?? ""
        let unix = (m["unix"] as? String) ?? (m["ts"] as? String) ?? ""
        let seed = !ch.isEmpty ? "\(ch)#\(unix)" : (m.description)
        return SeenStore.uuid(fromSeed: seed)
    }
}
