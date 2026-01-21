import Foundation
import Combine

struct Profile: Codable, Identifiable {
    let id: UUID
    var name: String
    let dateCreated: Date
    var dateModified: Date
    var results: [String: Int]
}

protocol DataStore {
    func save<T: Codable>(_ value: T, forKey key: String) async throws
    func load<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async throws -> T?
    func delete(forKey key: String) async throws
    func clearAll() async throws
    func getStorageInfo() async -> StorageInfo
}

struct StorageInfo {
    let totalSpace: Int64
    let availableSpace: Int64
    let usedSpace: Int64

    var usagePercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace)
    }

    var isLowSpace: Bool {
        usagePercentage > 0.9
    }
}

class UserDefaultsDataStore: DataStore {
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let errorRecoveryManager: ErrorRecoveryManager

    init(errorRecoveryManager: ErrorRecoveryManager) {
        self.errorRecoveryManager = errorRecoveryManager
    }

    func save<T: Codable>(_ value: T, forKey key: String) async throws {
        do {
            let data = try encoder.encode(value)
            defaults.set(data, forKey: key)
        } catch {
            throw AppError.storageUnavailable
        }
    }

    func load<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async throws -> T? {
        do {
            guard let data = defaults.data(forKey: key) else { return nil }
            let decoded = try decoder.decode(type, from: data)
            return decoded
        } catch {
            throw AppError.corruptedData
        }
    }

    func delete(forKey key: String) async throws {
        defaults.removeObject(forKey: key)
    }

    func clearAll() async throws {
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
    }

    func getStorageInfo() async -> StorageInfo {
        // UserDefaults doesn't provide detailed storage info
        return StorageInfo(
            totalSpace: 0,
            availableSpace: 0,
            usedSpace: 0
        )
    }
}

class FileSystemDataStore: DataStore {
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let errorRecoveryManager: ErrorRecoveryManager
    private let cache = NSCache<NSString, NSData>()

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    init(errorRecoveryManager: ErrorRecoveryManager) {
        self.errorRecoveryManager = errorRecoveryManager
        setupCache()
    }

    private func setupCache() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    func save<T: Codable>(_ value: T, forKey key: String) async throws {
        let url = documentsDirectory.appendingPathComponent(key)

        // Check storage space
        let storageInfo = await getStorageInfo()
        if storageInfo.isLowSpace {
            throw AppError.storageUnavailable
        }

        do {
            let data = try encoder.encode(value)

            // Create backup if file exists
            if fileManager.fileExists(atPath: url.path) {
                let backupURL = url.appendingPathExtension("backup")
                try? fileManager.removeItem(at: backupURL)
                try fileManager.copyItem(at: url, to: backupURL)
            }

            try data.write(to: url)

            // Cache the data
            cache.setObject(data as NSData, forKey: key as NSString)

            // Remove backup file after successful save
            let backupURL = url.appendingPathExtension("backup")
            try? fileManager.removeItem(at: backupURL)

        } catch {
            // Attempt to restore from backup
            let backupURL = url.appendingPathExtension("backup")
            if fileManager.fileExists(atPath: backupURL.path) {
                try? fileManager.moveItem(at: backupURL, to: url)
            }
            throw AppError.storageUnavailable
        }
    }

    func load<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async throws -> T? {
        let url = documentsDirectory.appendingPathComponent(key)

        // Try cache first
        if let cachedData = cache.object(forKey: key as NSString) {
            do {
                return try decoder.decode(type, from: cachedData as Data)
            } catch {
                // Cache corrupted, remove it
                cache.removeObject(forKey: key as NSString)
            }
        }

        do {
            guard let data = try? Data(contentsOf: url) else { return nil }
            let decoded = try decoder.decode(type, from: data)

            // Cache the decoded data
            cache.setObject(data as NSData, forKey: key as NSString)

            return decoded
        } catch {
            // Try to restore from backup
            let backupURL = url.appendingPathExtension("backup")
            if fileManager.fileExists(atPath: backupURL.path) {
                do {
                    let backupData = try Data(contentsOf: backupURL)
                    let decoded = try decoder.decode(type, from: backupData)

                    // Restore from backup
                    try fileManager.moveItem(at: backupURL, to: url)
                    cache.setObject(backupData as NSData, forKey: key as NSString)

                    return decoded
                } catch {
                    throw AppError.corruptedData
                }
            }
            throw AppError.corruptedData
        }
    }

    func delete(forKey key: String) async throws {
        let url = documentsDirectory.appendingPathComponent(key)

        do {
            try fileManager.removeItem(at: url)
            cache.removeObject(forKey: key as NSString)
        } catch {
            throw AppError.storageUnavailable
        }
    }

    func clearAll() async throws {
        do {
            let contents = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            for url in contents {
                try fileManager.removeItem(at: url)
            }
            cache.removeAllObjects()
        } catch {
            throw AppError.storageUnavailable
        }
    }

    func getStorageInfo() async -> StorageInfo {
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: documentsDirectory.path)
            let totalSpace = attributes[.systemSize] as? Int64 ?? 0
            let freeSpace = attributes[.systemFreeSize] as? Int64 ?? 0
            let usedSpace = totalSpace - freeSpace

            return StorageInfo(
                totalSpace: totalSpace,
                availableSpace: freeSpace,
                usedSpace: usedSpace
            )
        } catch {
            return StorageInfo(
                totalSpace: 0,
                availableSpace: 0,
                usedSpace: 0
            )
        }
    }
}

// MARK: - Data Store Manager

class DataStoreManager: ObservableObject {
    private let dataStore: DataStore
    private let errorRecoveryManager: ErrorRecoveryManager

    @Published var isLoading = false
    @Published var lastError: AppError?
    @Published var storageInfo: StorageInfo?

    init(dataStore: DataStore, errorRecoveryManager: ErrorRecoveryManager) {
        self.dataStore = dataStore
        self.errorRecoveryManager = errorRecoveryManager
        Task {
            await updateStorageInfo()
        }
    }

    func save<T: Codable>(_ value: T, forKey key: String) async {
        isLoading = true
        lastError = nil

        do {
            try await dataStore.save(value, forKey: key)
            await updateStorageInfo()
        } catch {
            if let appError = error as? AppError {
                lastError = appError

                // Schedule retry if retryable
                if appError.isRetryable {
                    errorRecoveryManager.scheduleOperation({
                        try await self.dataStore.save(value, forKey: key)
                    }, description: "Save \(key)")
                }
            } else {
                lastError = AppError.storageUnavailable
            }
        }

        isLoading = false
    }

    func load<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async -> T? {
        isLoading = true
        lastError = nil

        do {
            let result = try await dataStore.load(type, forKey: key)
            isLoading = false
            return result
        } catch {
            isLoading = false
            if let appError = error as? AppError {
                lastError = appError
            } else {
                lastError = AppError.corruptedData
            }
            return nil
        }
    }

    func delete(forKey key: String) async {
        isLoading = true
        lastError = nil

        do {
            try await dataStore.delete(forKey: key)
            await updateStorageInfo()
        } catch {
            if let appError = error as? AppError {
                lastError = appError
            } else {
                lastError = AppError.storageUnavailable
            }
        }

        isLoading = false
    }

    func clearAll() async {
        isLoading = true
        lastError = nil

        do {
            try await dataStore.clearAll()
            await updateStorageInfo()
        } catch {
            if let appError = error as? AppError {
                lastError = appError
            } else {
                lastError = AppError.storageUnavailable
            }
        }

        isLoading = false
    }

    @MainActor
    private func updateStorageInfo() async {
        storageInfo = await dataStore.getStorageInfo()
    }
}
