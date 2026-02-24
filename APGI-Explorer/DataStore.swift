import Combine
import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    var name: String
    let dateCreated: Date
    var dateModified: Date
    var results: [String: Int]
}

protocol DataStore {
    func save(_ value: some Codable, forKey key: String) async throws
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
        guard self.totalSpace > 0 else { return 0 }
        return Double(self.usedSpace) / Double(self.totalSpace)
    }

    var isLowSpace: Bool {
        self.usagePercentage > 0.9
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

    func save(_ value: some Codable, forKey key: String) async throws {
        do {
            let data = try encoder.encode(value)
            self.defaults.set(data, forKey: key)
        } catch {
            throw AppError.storageUnavailable
        }
    }

    func load<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async throws -> T? {
        do {
            guard let data = defaults.data(forKey: key) else { return nil }
            return try self.decoder.decode(type, from: data)
        } catch {
            throw AppError.corruptedData
        }
    }

    func delete(forKey key: String) async throws {
        self.defaults.removeObject(forKey: key)
    }

    func clearAll() async throws {
        guard let domain = Bundle.main.bundleIdentifier else {
            throw NSError(domain: "DataStore", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Unable to get bundle identifier"])
        }
        self.defaults.removePersistentDomain(forName: domain)
    }

    func getStorageInfo() async -> StorageInfo {
        // UserDefaults doesn't provide detailed storage info
        StorageInfo(
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
        self.fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    init(errorRecoveryManager: ErrorRecoveryManager) {
        self.errorRecoveryManager = errorRecoveryManager
        self.setupCache()
    }

    private func setupCache() {
        self.cache.countLimit = 100
        self.cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    func save(_ value: some Codable, forKey key: String) async throws {
        let url = self.documentsDirectory.appendingPathComponent(key)

        // Check storage space
        let storageInfo = await getStorageInfo()
        if storageInfo.isLowSpace {
            throw AppError.storageUnavailable
        }

        do {
            let data = try encoder.encode(value)

            // Create backup if file exists
            if self.fileManager.fileExists(atPath: url.path) {
                let backupURL = url.appendingPathExtension("backup")
                try? self.fileManager.removeItem(at: backupURL)
                try self.fileManager.copyItem(at: url, to: backupURL)
            }

            try data.write(to: url)

            // Cache the data
            self.cache.setObject(data as NSData, forKey: key as NSString)

            // Remove backup file after successful save
            let backupURL = url.appendingPathExtension("backup")
            try? self.fileManager.removeItem(at: backupURL)
        } catch {
            // Attempt to restore from backup
            let backupURL = url.appendingPathExtension("backup")
            if self.fileManager.fileExists(atPath: backupURL.path) {
                try? self.fileManager.moveItem(at: backupURL, to: url)
            }
            throw AppError.storageUnavailable
        }
    }

    func load<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async throws -> T? {
        let url = self.documentsDirectory.appendingPathComponent(key)

        // Try cache first
        if let cachedData = cache.object(forKey: key as NSString) {
            do {
                return try self.decoder.decode(type, from: cachedData as Data)
            } catch {
                // Cache corrupted, remove it
                self.cache.removeObject(forKey: key as NSString)
            }
        }

        do {
            guard let data = try? Data(contentsOf: url) else { return nil }
            let decoded = try decoder.decode(type, from: data)

            // Cache the decoded data
            self.cache.setObject(data as NSData, forKey: key as NSString)

            return decoded
        } catch {
            // Try to restore from backup
            let backupURL = url.appendingPathExtension("backup")
            if self.fileManager.fileExists(atPath: backupURL.path) {
                do {
                    let backupData = try Data(contentsOf: backupURL)
                    let decoded = try decoder.decode(type, from: backupData)

                    // Restore from backup
                    try self.fileManager.moveItem(at: backupURL, to: url)
                    self.cache.setObject(backupData as NSData, forKey: key as NSString)

                    return decoded
                } catch {
                    throw AppError.corruptedData
                }
            }
            throw AppError.corruptedData
        }
    }

    func delete(forKey key: String) async throws {
        let url = self.documentsDirectory.appendingPathComponent(key)

        do {
            try self.fileManager.removeItem(at: url)
            self.cache.removeObject(forKey: key as NSString)
        } catch {
            throw AppError.storageUnavailable
        }
    }

    func clearAll() async throws {
        do {
            let contents = try fileManager.contentsOfDirectory(at: self.documentsDirectory, includingPropertiesForKeys: nil)
            for url in contents {
                try self.fileManager.removeItem(at: url)
            }
            self.cache.removeAllObjects()
        } catch {
            throw AppError.storageUnavailable
        }
    }

    func getStorageInfo() async -> StorageInfo {
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: self.documentsDirectory.path)
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
            await self.updateStorageInfo()
        }
    }

    func save(_ value: some Codable, forKey key: String) async {
        self.isLoading = true
        self.lastError = nil

        do {
            try await self.dataStore.save(value, forKey: key)
            await self.updateStorageInfo()
        } catch {
            if let appError = error as? AppError {
                self.lastError = appError

                // Schedule retry if retryable
                if appError.isRetryable {
                    self.errorRecoveryManager.scheduleOperation({
                        try await self.dataStore.save(value, forKey: key)
                    }, description: "Save \(key)")
                }
            } else {
                self.lastError = AppError.storageUnavailable
            }
        }

        self.isLoading = false
    }

    func load<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async -> T? {
        self.isLoading = true
        self.lastError = nil

        do {
            let result = try await dataStore.load(type, forKey: key)
            self.isLoading = false
            return result
        } catch {
            self.isLoading = false
            if let appError = error as? AppError {
                self.lastError = appError
            } else {
                self.lastError = AppError.corruptedData
            }
            return nil
        }
    }

    func delete(forKey key: String) async {
        self.isLoading = true
        self.lastError = nil

        do {
            try await self.dataStore.delete(forKey: key)
            await self.updateStorageInfo()
        } catch {
            if let appError = error as? AppError {
                self.lastError = appError
            } else {
                self.lastError = AppError.storageUnavailable
            }
        }

        self.isLoading = false
    }

    func clearAll() async {
        self.isLoading = true
        self.lastError = nil

        do {
            try await self.dataStore.clearAll()
            await self.updateStorageInfo()
        } catch {
            if let appError = error as? AppError {
                self.lastError = appError
            } else {
                self.lastError = AppError.storageUnavailable
            }
        }

        self.isLoading = false
    }

    @MainActor
    private func updateStorageInfo() async {
        self.storageInfo = await self.dataStore.getStorageInfo()
    }
}
