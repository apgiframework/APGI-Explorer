import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    private init() {
    }

    private let service = "com.lesoto.APGI-Explorer"

    enum KeychainError: Error, LocalizedError {
        case itemNotFound
        case duplicateItem
        case invalidData
        case osError(OSStatus)

        var errorDescription: String? {
            switch self {
            case .itemNotFound:
                "Item not found in keychain"
            case .duplicateItem:
                "Duplicate item found in keychain"
            case .invalidData:
                "Invalid data format"
            case let .osError(status):
                "Keychain operation failed with status: \(status)"
            }
        }
    }

    func store(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.osError(status)
        }
    }

    func retrieve(forKey key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }

        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.osError(status)
        }

        return data
    }

    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.osError(status)
        }
    }

    func update(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service,
            kSecAttrAccount as String: key,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status == errSecSuccess else {
            throw KeychainError.osError(status)
        }
    }

    func contains(forKey key: String) -> Bool {
        do {
            _ = try self.retrieve(forKey: key)
            return true
        } catch KeychainError.itemNotFound {
            return false
        } catch {
            return false
        }
    }
}

extension KeychainManager {
    func storeString(_ string: String, forKey key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try self.store(data, forKey: key)
    }

    func retrieveString(forKey key: String) throws -> String {
        let data = try retrieve(forKey: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }

    func storeCodable(_ object: some Codable, forKey key: String) throws {
        let data = try JSONEncoder().encode(object)
        try self.store(data, forKey: key)
    }

    func retrieveCodable<T: Codable>(_ type: T.Type, forKey key: String) throws -> T {
        let data = try retrieve(forKey: key)
        return try JSONDecoder().decode(type, from: data)
    }
}
