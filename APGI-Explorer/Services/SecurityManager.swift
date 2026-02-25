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

class SecurityManager: ObservableObject {
    static let shared = SecurityManager()
    private let keychain = KeychainManager.shared
    private var persistentContainer: NSPersistentContainer

    private init() {
        self.persistentContainer = NSPersistentContainer(name: "APGISignature")
        let semaphore = DispatchSemaphore(value: 0)
        self.persistentContainer.loadPersistentStores { _, error in
            if let error {
                os_log(OSLogType.fault, "Core Data load failed: %@", error.localizedDescription)
                self.persistentContainer = NSPersistentContainer(name: "APGISignature")
                self.persistentContainer.persistentStoreDescriptions.first!.type = NSInMemoryStoreType
                self.persistentContainer.loadPersistentStores { _, _ in
                    semaphore.signal()
                }
            } else {
                semaphore.signal()
            }
        }
        semaphore.wait()
    }

    enum SecurityKeys {
        static let userProfile = "com.lesoto.APGI-Explorer.userProfile"
        static let appSettings = "com.lesoto.APGI-Explorer.appSettings"
        static let sessionToken = "com.lesoto.APGI-Explorer.sessionToken"
        static let analyticsConsent = "com.lesoto.APGI-Explorer.analyticsConsent"
        static let lastBackupDate = "com.lesoto.APGI-Explorer.lastBackupDate"
    }

    func storeUserProfile(_ profile: ProfileEntity) throws {
        let profileData = try JSONEncoder().encode(profile)
        try self.keychain.store(profileData, forKey: SecurityKeys.userProfile)
    }

    func retrieveUserProfile() throws -> ProfileEntity? {
        guard self.keychain.contains(forKey: SecurityKeys.userProfile) else {
            return nil
        }
        let data = try keychain.retrieve(forKey: SecurityKeys.userProfile)
        let decoder = JSONDecoder()
        decoder.userInfo[CodingUserInfoKey.managedObjectContext!] = self.persistentContainer.viewContext
        return try decoder.decode(ProfileEntity.self, from: data)
    }

    func storeAppSettings(_ settings: [String: Any]) throws {
        let settingsData = try JSONSerialization.data(withJSONObject: settings)
        try self.keychain.store(settingsData, forKey: SecurityKeys.appSettings)
    }

    func retrieveAppSettings() throws -> [String: Any]? {
        guard self.keychain.contains(forKey: SecurityKeys.appSettings) else {
            return nil
        }
        let data = try keychain.retrieve(forKey: SecurityKeys.appSettings)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    func storeSessionToken(_ token: String) throws {
        try self.keychain.storeString(token, forKey: SecurityKeys.sessionToken)
    }

    func retrieveSessionToken() throws -> String? {
        guard self.keychain.contains(forKey: SecurityKeys.sessionToken) else {
            return nil
        }
        return try self.keychain.retrieveString(forKey: SecurityKeys.sessionToken)
    }

    func storeAnalyticsConsent(_ consent: Bool) throws {
        try self.keychain.storeString(consent ? "true" : "false", forKey: SecurityKeys.analyticsConsent)
    }

    func retrieveAnalyticsConsent() throws -> Bool? {
        guard self.keychain.contains(forKey: SecurityKeys.analyticsConsent) else {
            return nil
        }
        let consentString = try keychain.retrieveString(forKey: SecurityKeys.analyticsConsent)
        return consentString == "true"
    }

    func storeLastBackupDate(_ date: Date) throws {
        try self.keychain.storeCodable(date, forKey: SecurityKeys.lastBackupDate)
    }

    func retrieveLastBackupDate() throws -> Date? {
        guard self.keychain.contains(forKey: SecurityKeys.lastBackupDate) else {
            return nil
        }
        return try self.keychain.retrieveCodable(Date.self, forKey: SecurityKeys.lastBackupDate)
    }

    func clearAllSecureData() throws {
        let keys = [
            SecurityKeys.userProfile,
            SecurityKeys.appSettings,
            SecurityKeys.sessionToken,
            SecurityKeys.analyticsConsent,
            SecurityKeys.lastBackupDate,
        ]

        for key in keys {
            try? self.keychain.delete(forKey: key)
        }
    }

    func validateDataIntegrity() -> SecurityValidationResult {
        var issues: [String] = []

        do {
            if self.keychain.contains(forKey: SecurityKeys.userProfile) {
                _ = try self.retrieveUserProfile()
            }
        } catch {
            issues.append("User profile data corrupted")
        }

        do {
            if self.keychain.contains(forKey: SecurityKeys.appSettings) {
                _ = try self.retrieveAppSettings()
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
    func exportSecureData() throws -> [String: Any] {
        var exportData: [String: Any] = [:]

        if let profile = try? retrieveUserProfile() {
            exportData["userProfile"] = try JSONEncoder().encode(profile)
        }

        if let settings = try? retrieveAppSettings() {
            exportData["appSettings"] = settings
        }

        if let consent = try? retrieveAnalyticsConsent() {
            exportData["analyticsConsent"] = consent
        }

        if let backupDate = try? retrieveLastBackupDate() {
            exportData["lastBackupDate"] = backupDate
        }

        return exportData
    }

    func importSecureData(_ data: [String: Any]) throws {
        if let profileData = data["userProfile"] as? Data {
            let decoder = JSONDecoder()
            decoder.userInfo[CodingUserInfoKey.managedObjectContext!] = self.persistentContainer.viewContext
            let profile = try decoder.decode(ProfileEntity.self, from: profileData)
            try self.storeUserProfile(profile)
        }

        if let settings = data["appSettings"] as? [String: Any] {
            try self.storeAppSettings(settings)
        }

        if let consent = data["analyticsConsent"] as? Bool {
            try self.storeAnalyticsConsent(consent)
        }

        if let backupDate = data["lastBackupDate"] as? Date {
            try self.storeLastBackupDate(backupDate)
        }
    }
}
