import Foundation
import Security

/// Research credentials live only in the device-local Keychain under their own service name.
/// Unlike `KeychainManager` there is deliberately NO simulator or preference-store fallback, and the
/// item is `ThisDeviceOnly`, so it never syncs or migrates to another device.
nonisolated final class ResearchKeychainCredentialStore: ResearchCredentialStoring, @unchecked Sendable {
  enum StoreError: Error, Equatable { case osStatus(OSStatus), corrupt }

  private let service: String
  private let account = "research-credentials"

  init(service: String = "org.apgiframework.APGI-Explorer.research") { self.service = service }

  private var query: [String: Any] {
    [kSecClass as String: kSecClassGenericPassword,
     kSecAttrService as String: service,
     kSecAttrAccount as String: account]
  }

  func load() throws -> ResearchCredentials? {
    var request = query
    request[kSecReturnData as String] = true
    request[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: AnyObject?
    let status = SecItemCopyMatching(request as CFDictionary, &result)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess else { throw StoreError.osStatus(status) }
    guard let data = result as? Data, let value = try? JSONDecoder().decode(ResearchCredentials.self, from: data) else {
      throw StoreError.corrupt
    }
    return value
  }

  func save(_ credentials: ResearchCredentials) throws {
    let data = try JSONEncoder().encode(credentials)
    SecItemDelete(query as CFDictionary)
    var item = query
    item[kSecValueData as String] = data
    item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    item[kSecAttrSynchronizable as String] = false
    let status = SecItemAdd(item as CFDictionary, nil)
    guard status == errSecSuccess else { throw StoreError.osStatus(status) }
  }

  func clear() throws {
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else { throw StoreError.osStatus(status) }
  }
}
