import Foundation
import CryptoKit

struct SeenStore {
    private static let key = "voip.seen.v1"
    private static let cap = 512
    private static let ttl: TimeInterval = 10 * 60 // 10 min

    static func wasSeen(_ uuid: UUID) -> Bool {
        var m = load()
        let now = Date().timeIntervalSince1970
        if let ts = m[uuid.uuidString], now - ts <= ttl { return true }
        // 清理過期
        m = m.filter { now - $0.value <= ttl }
        save(m)
        return false
    }

    static func remember(_ uuid: UUID) {
        var m = load()
        m[uuid.uuidString] = Date().timeIntervalSince1970
        // LRU 壓縮
        if m.count > cap {
            let sorted = m.sorted { $0.value < $1.value }
            for (i, kv) in sorted.enumerated() where i < (sorted.count - cap) {
                m.removeValue(forKey: kv.key)
            }
        }
        save(m)
    }

    private static func load() -> [String: TimeInterval] {
        (UserDefaults.standard.dictionary(forKey: key) as? [String: TimeInterval]) ?? [:]
    }

    private static func save(_ m: [String: TimeInterval]) {
        UserDefaults.standard.set(m, forKey: key)
    }

    /// 以字串種子產生穩定 UUID（32 hex → 8-4-4-4-12）
    static func uuid(fromSeed seed: String) -> UUID {
        let digest = SHA256.hash(data: Data(seed.utf8))
        let hex = digest.compactMap { String(format: "%02x", $0) }.joined()
        let s = String(hex.prefix(32))
        let fmt = "\(s.prefix(8))-\(s.dropFirst(8).prefix(4))-\(s.dropFirst(12).prefix(4))-\(s.dropFirst(16).prefix(4))-\(s.dropFirst(20).prefix(12))"
        return UUID(uuidString: fmt) ?? UUID()
    }
}
