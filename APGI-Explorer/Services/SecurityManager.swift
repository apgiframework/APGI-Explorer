import Combine
import CoreData
import Foundation
import OSLog

extension CodingUserInfoKey {
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")
}

enum SecurityManagerError: Error {
    case persistenceLoadFailed(Error)
}

@MainActor class SecurityManager: ObservableObject {
    static func shared() async -> SecurityManager {
        let manager = SecurityManager()
        await manager.configure()
        return manager
    }

    private let keychain = KeychainManager.shared
    private var persistentContainer: NSPersistentContainer?

    private init() {
    }

    func configure() async {
        let pc = NSPersistentContainer(name: "APGISignature")
        await withCheckedContinuation { cont in
            pc.loadPersistentStores { _, error in
                if let error {
                    os_log(OSLogType.fault, "Core Data load failed: %@", error.localizedDescription)
                    let mem = NSPersistentContainer(name: "APGISignature")
                    mem.persistentStoreDescriptions.first?.type = NSInMemoryStoreType
                    mem.loadPersistentStores { _, _ in cont.resume() }
                    self.persistentContainer = mem
                } else {
                    self.persistentContainer = pc
                    cont.resume()
                }
            }
        }
    }

    enum SecurityKeys {
        static let userProfile = "com.lesoto.APGI-Explorer.userProfile"
        static let appSettings = "com.lesoto.APGI-Explorer.appSettings"
        static let sessionToken = "com.lesoto.APGI-Explorer.sessionToken"
        static let analyticsConsent = "com.lesoto.APGI-Explorer.analyticsConsent"
        static let lastBackupDate = "com.lesoto.APGI-Explorer.lastBackupDate"
    }

    private func storeData(_ data: Data, forKey key: String) throws {
        try self.keychain.store(data, forKey: key)
    }

    private func retrieveData(forKey key: String) throws -> Data {
        try self.keychain.retrieve(forKey: key)
    }

    private func containsKey(_ key: String) throws -> Bool {
        self.keychain.contains(forKey: key)
    }

    private func deleteKey(_ key: String) throws {
        try self.keychain.delete(forKey: key)
    }

    private func storeString(_ string: String, forKey key: String) throws {
        try self.keychain.storeString(string, forKey: key)
    }

    private func retrieveString(forKey key: String) throws -> String {
        try self.keychain.retrieveString(forKey: key)
    }

    private func storeCodable(_ value: some Codable, forKey key: String) throws {
        try self.keychain.storeCodable(value, forKey: key)
    }

    private func retrieveCodable<T: Codable>(_ type: T.Type, forKey key: String) throws -> T {
        try self.keychain.retrieveCodable(type, forKey: key)
    }

    func storeUserProfile(_ profile: ProfileEntity) async throws {
        let profileData = try JSONEncoder().encode(profile)
        try self.storeData(profileData, forKey: SecurityKeys.userProfile)
    }

    func retrieveUserProfile() async throws -> ProfileEntity? {
        guard try self.containsKey(SecurityKeys.userProfile) else {
            return nil
        }
        let data = try self.retrieveData(forKey: SecurityKeys.userProfile)
        let decoder = JSONDecoder()
        if let contextKey = CodingUserInfoKey.managedObjectContext,
           let context = self.persistentContainer?.viewContext
        {
            decoder.userInfo[contextKey] = context
        }
        return try decoder.decode(ProfileEntity.self, from: data)
    }

    func storeAppSettings(_ settings: [String: Any]) async throws {
        let jsonData = try JSONSerialization.data(withJSONObject: settings, options: [])
        try self.storeData(jsonData, forKey: SecurityKeys.appSettings)
    }

    func retrieveAppSettings() async throws -> [String: Any]? {
        guard try self.containsKey(SecurityKeys.appSettings) else {
            return nil
        }
        let jsonData = try self.retrieveData(forKey: SecurityKeys.appSettings)
        return try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
    }

    func storeSessionToken(_ token: String) async throws {
        try self.storeString(token, forKey: SecurityKeys.sessionToken)
    }

    func retrieveSessionToken() async throws -> String? {
        guard try self.containsKey(SecurityKeys.sessionToken) else {
            return nil
        }
        return try self.retrieveString(forKey: SecurityKeys.sessionToken)
    }

    func storeAnalyticsConsent(_ consent: Bool) async throws {
        let consentString = consent ? "true" : "false"
        try self.storeString(consentString, forKey: SecurityKeys.analyticsConsent)
    }

    func retrieveAnalyticsConsent() async throws -> Bool? {
        guard try self.containsKey(SecurityKeys.analyticsConsent) else {
            return nil
        }
        let consentString = try self.retrieveString(forKey: SecurityKeys.analyticsConsent)
        return consentString == "true"
    }

    func storeLastBackupDate(_ date: Date) async throws {
        try self.storeCodable(date, forKey: SecurityKeys.lastBackupDate)
    }

    func retrieveLastBackupDate() async throws -> Date? {
        guard try self.containsKey(SecurityKeys.lastBackupDate) else {
            return nil
        }
        return try self.retrieveCodable(Date.self, forKey: SecurityKeys.lastBackupDate)
    }

    func clearAllSecureData() async throws {
        let keys = [
            SecurityKeys.userProfile,
            SecurityKeys.appSettings,
            SecurityKeys.sessionToken,
            SecurityKeys.analyticsConsent,
            SecurityKeys.lastBackupDate,
        ]
        for key in keys {
            try self.deleteKey(key)
        }
    }

    func validateDataIntegrity() async throws -> SecurityValidationResult {
        var issues: [String] = []

        do {
            if try self.containsKey(SecurityKeys.userProfile) {
                _ = try await self.retrieveUserProfile()
            }
        } catch {
            issues.append("User profile data corrupted")
        }

        do {
            if try self.containsKey(SecurityKeys.appSettings) {
                _ = try await self.retrieveAppSettings()
            }
        } catch {
            issues.append("App settings data corrupted")
        }

        return SecurityValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }
}

struct SecurityValidationResult {
    let isValid: Bool
    let issues: [String]
}

extension SecurityManager {
    func exportSecureData() async throws -> [String: Any] {
        var exportData: [String: Any] = [:]

        if let profile = try await retrieveUserProfile() {
            exportData["userProfile"] = try JSONEncoder().encode(profile)
        }

        if let settings = try await retrieveAppSettings() {
            exportData["appSettings"] = settings
        }

        if let consent = try await retrieveAnalyticsConsent() {
            exportData["analyticsConsent"] = consent
        }

        if let backupDate = try await retrieveLastBackupDate() {
            exportData["lastBackupDate"] = backupDate
        }

        return exportData
    }

    func importSecureData(_ data: [String: Any]) async throws {
        if let profileData = data["userProfile"] as? Data {
            let decoder = JSONDecoder()
            if let contextKey = CodingUserInfoKey.managedObjectContext,
               let context = self.persistentContainer?.viewContext
            {
                decoder.userInfo[contextKey] = context
            }
            let profile = try decoder.decode(ProfileEntity.self, from: profileData)
            try await self.storeUserProfile(profile)
        }

        if let settings = data["appSettings"] as? [String: Any] {
            try await self.storeAppSettings(settings)
        }

        if let consent = data["analyticsConsent"] as? Bool {
            try await self.storeAnalyticsConsent(consent)
        }

        if let backupDate = data["lastBackupDate"] as? Date {
            try await self.storeLastBackupDate(backupDate)
        }
    }
}
