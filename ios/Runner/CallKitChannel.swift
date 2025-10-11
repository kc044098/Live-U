// ios/Runner/CallKitChannel.swift
import Foundation
import Flutter

final class CallKitChannel {
    static let shared = CallKitChannel()
    private init() {}

    private var channel: FlutterMethodChannel?
    private var seen = Set<UUID>() // 基本去重（10分鐘 TTL 可自行擴充成 LRU）

    func bind(messenger: FlutterBinaryMessenger) {
        let ch = FlutterMethodChannel(name: "app.callkit", binaryMessenger: messenger)
        ch.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            switch call.method {
            case "voip.requestToken":
                if let t = VoipPushManager.shared.lastToken {
                    self.emitVoipToken(t)
                }
                result(nil)
            case "call.end":
                if let args = call.arguments as? [String: Any],
                   let id = args["uuid"] as? String,
                   let uuid = UUID(uuidString: id) {
                    CallManager.shared.end(uuid: uuid)
                }
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
        self.channel = ch

        // ★ 綁定當下若本地已有 token，直接推一次（解決冷啟動 race）
        if let t = VoipPushManager.shared.lastToken {
            emitVoipToken(t)
        }
    }

    // === 往 Flutter 發事件 ===
    func emitVoipToken(_ token: String) {
        channel?.invokeMethod("voipToken", arguments: ["token": token])
    }

    func emitIncoming(uuid: UUID, payload: [String: Any]) {
        SeenStore.remember(uuid)
        let args: [String: Any] = ["uuid": uuid.uuidString, "payload": payload]
        channel?.invokeMethod("incoming", arguments: args)
    }

    func emitAnswer(uuid: UUID, payload: [String: Any]) {
        let args: [String: Any] = ["uuid": uuid.uuidString, "payload": payload]
        channel?.invokeMethod("answer", arguments: args)
    }

    func emitEnd(uuid: UUID, payload: [String: Any]) {
        let args: [String: Any] = ["uuid": uuid.uuidString, "payload": payload]
        channel?.invokeMethod("end", arguments: args)
    }

    // === 去重（簡易版）===
    func remember(uuid: UUID) { seen.insert(uuid) }
    func isDuplicate(uuid: UUID) -> Bool { return seen.contains(uuid) }
}
