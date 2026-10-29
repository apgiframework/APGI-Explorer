import Foundation
import Security

/// Device-local Keychain storage for one Codable value under its own service and account.
/// Unlike `KeychainManager` there is deliberately NO simulator or preference-store fallback, and
/// the item is `ThisDeviceOnly` and non-synchronizable, so it never leaves this device.
nonisolated final class ResearchKeychainBox<Value: Codable & Sendable>: @unchecked Sendable {
  enum StoreError: Error, Equatable { case osStatus(OSStatus), corrupt }

  private let service: String
  private let account: String

  init(service: String, account: String) {
    self.service = service
    self.account = account
  }

  private var query: [String: Any] {
    [kSecClass as String: kSecClassGenericPassword,
     kSecAttrService as String: service,
     kSecAttrAccount as String: account]
  }

  func load() throws -> Value? {
    var request = query
    request[kSecReturnData as String] = true
    request[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: AnyObject?
    let status = SecItemCopyMatching(request as CFDictionary, &result)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess else { throw StoreError.osStatus(status) }
    guard let data = result as? Data, let value = try? JSONDecoder().decode(Value.self, from: data) else {
      throw StoreError.corrupt
    }
    return value
  }

  func save(_ value: Value) throws {
    let data = try JSONEncoder().encode(value)
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

nonisolated final class ResearchKeychainCredentialStore: ResearchCredentialStoring, @unchecked Sendable {
  typealias StoreError = ResearchKeychainBox<ResearchCredentials>.StoreError
  private let box: ResearchKeychainBox<ResearchCredentials>
  init(service: String = "org.apgiframework.APGI-Explorer.research") {
    box = ResearchKeychainBox(service: service, account: "research-credentials")
  }
  func load() throws -> ResearchCredentials? { try box.load() }
  func save(_ credentials: ResearchCredentials) throws { try box.save(credentials) }
  func clear() throws { try box.clear() }
}

nonisolated final class ResearchKeychainProgressStore: ResearchProgressStoring, @unchecked Sendable {
  private let box: ResearchKeychainBox<ResearchProgress>
  init(service: String = "org.apgiframework.APGI-Explorer.research") {
    box = ResearchKeychainBox(service: service, account: "research-progress")
  }
  func load() throws -> ResearchProgress? { try box.load() }
  func save(_ progress: ResearchProgress) throws { try box.save(progress) }
  func clear() throws { try box.clear() }
}
