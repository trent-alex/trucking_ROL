import Foundation
import Security

/// Secure Keychain wrapper for storing premium unlock state
/// Uses kSecClassGenericPassword for simple key-value storage
enum KeychainHelper {

    private static let service = "com.pivotallift.rol"
    private static let lifetimeUnlockedKey = "isLifetimeUnlocked"

    // MARK: - Lifetime Unlock State

    static var isLifetimeUnlocked: Bool {
        get {
            guard let data = read(key: lifetimeUnlockedKey),
                  let value = String(data: data, encoding: .utf8) else {
                return false
            }
            return value == "true"
        }
        set {
            let data = Data((newValue ? "true" : "false").utf8)
            if read(key: lifetimeUnlockedKey) != nil {
                update(key: lifetimeUnlockedKey, data: data)
            } else {
                save(key: lifetimeUnlockedKey, data: data)
            }
        }
    }

    // MARK: - Private Keychain Operations

    private static func save(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemDelete(query as CFDictionary) // Remove existing if any
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func read(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private static func update(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }

    /// Clears all keychain data for this app (useful for testing)
    static func clearAll() {
        delete(key: lifetimeUnlockedKey)
    }
}
