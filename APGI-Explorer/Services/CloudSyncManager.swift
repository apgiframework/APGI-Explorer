import CloudKit
import Combine
import CoreData
import Foundation

class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()

    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: CloudSyncError?
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine

    private let syncCoordinator = SyncCoordinator()

    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.container = CKContainer(identifier: "iCloud.com.lesoto.APGI-Explorer")
        self.privateDatabase = self.container.privateCloudDatabase
        self.publicDatabase = self.container.publicCloudDatabase

        self.checkAccountStatus()
    }

    enum CloudSyncError: Error, LocalizedError {
        case accountNotAvailable
        case accountRestricted
        case accountNoiCloud
        case networkUnavailable
        case quotaExceeded
        case zoneNotFound
        case recordNotFound
        case invalidData
        case syncInProgress
        case unknown(Error)

        var errorDescription: String? {
            switch self {
            case .accountNotAvailable:
                "iCloud account is not available"
            case .accountRestricted:
                "iCloud account is restricted"
            case .accountNoiCloud:
                "No iCloud account configured"
            case .networkUnavailable:
                "Network connection is unavailable"
            case .quotaExceeded:
                "iCloud storage quota exceeded"
            case .zoneNotFound:
                "CloudKit zone not found"
            case .recordNotFound:
                "Record not found in iCloud"
            case .invalidData:
                "Invalid data format"
            case .syncInProgress:
                "Sync operation already in progress"
            case let .unknown(error):
                "Unknown error: \(error.localizedDescription)"
            }
        }
    }

    actor SyncCoordinator {
        private var isSyncing = false
        func performSync(_ work: @escaping () async throws -> Void) async throws {
            guard !self.isSyncing else { throw CloudSyncError.syncInProgress }
            self.isSyncing = true
            defer { isSyncing = false }
            try await work()
        }
    }

    func checkAccountStatus() {
        self.container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.accountStatus = status
                if let error {
                    self?.syncError = .unknown(error)
                }
            }
        }
    }

    func syncProfiles() async throws {
        try await self.syncCoordinator.performSync {
            await MainActor.run {
                self.isSyncing = true
                self.syncError = nil
            }
            defer {
                Task { await MainActor.run { self.isSyncing = false } }
            }
            do {
                try await self.ensureCustomZoneExists()
                try await self.performProfileSync()
                await MainActor.run {
                    self.lastSyncDate = Date()
                }
            } catch {
                await MainActor.run {
                    self.syncError = self.mapCloudKitError(error)
                }
                throw error
            }
        }
    }

    private func ensureCustomZoneExists() async throws {
        let zoneID = CKRecordZone.ID(zoneName: "APGIProfiles")
        let zone = CKRecordZone(zoneID: zoneID)

        let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: [])

        return try await withCheckedThrowingContinuation { continuation in
            createZoneOperation.modifyRecordZonesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case let .failure(error):
                    let ckError = error as NSError
                    if ckError.code == CKError.serverRecordChanged.rawValue {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error)
                    }
                }
            }

            self.privateDatabase.add(createZoneOperation)
        }
    }

    private func performProfileSync() async throws {
        let context = PersistenceController.shared.container.viewContext
        let localProfiles = try context.fetch(ProfileEntity.fetchRequest())

        let cloudProfiles = try await fetchCloudProfiles()

        let profilesToUpload = localProfiles.filter { localProfile in
            !cloudProfiles.contains { $0.id == localProfile.id.uuidString }
        }

        let profilesToUpdate = localProfiles.compactMap { localProfile in
            if let cloudProfile = cloudProfiles.first(where: { $0.id == localProfile.id.uuidString }) {
                return localProfile.dateModified > cloudProfile.updatedAt ? localProfile : nil
            }
            return nil
        }

        let profilesToDownload = cloudProfiles.filter { cloudProfile in
            !localProfiles.contains { $0.id.uuidString == cloudProfile.id } ||
                (localProfiles.first(where: { $0.id.uuidString == cloudProfile.id })?.dateModified ?? Date()) < cloudProfile.updatedAt
        }

        try await self.uploadProfiles(profilesToUpload + profilesToUpdate)

        for cloudProfile in profilesToDownload {
            try await self.downloadProfile(cloudProfile)
        }
    }

    private func fetchCloudProfiles() async throws -> [CloudProfile] {
        let zoneID = CKRecordZone.ID(zoneName: "APGIProfiles")
        let query = CKQuery(recordType: "Profile", predicate: NSPredicate(value: true))

        return try await withCheckedThrowingContinuation { continuation in
            let queryOperation = CKQueryOperation(query: query)
            queryOperation.zoneID = zoneID

            var profiles: [CloudProfile] = []

            queryOperation.recordMatchedBlock = { _, result in
                switch result {
                case let .success(record):
                    if let profile = CloudProfile(from: record) {
                        profiles.append(profile)
                    }
                case let .failure(error):
                    print("Error fetching record: \(error)")
                }
            }

            queryOperation.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: profiles)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }

            self.privateDatabase.add(queryOperation)
        }
    }

    private func uploadProfiles(_ profiles: [ProfileEntity]) async throws {
        let zoneID = CKRecordZone.ID(zoneName: "APGIProfiles")
        let records = profiles.compactMap { profile -> CKRecord? in
            let recordID = CKRecord.ID(recordName: profile.id.uuidString, zoneID: zoneID)
            let record = CKRecord(recordType: "Profile", recordID: recordID)

            record["id"] = profile.id.uuidString
            record["name"] = profile.name
            record["createdAt"] = profile.dateCreated
            record["updatedAt"] = profile.dateModified

            if let profileData = try? JSONEncoder().encode(profile) {
                record["profileData"] = profileData
            }

            return record
        }

        try await self.saveRecords(records)
    }

    private func saveRecords(_ records: [CKRecord]) async throws {
        let saveOperation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: [])
        saveOperation.savePolicy = .changedKeys

        return try await withCheckedThrowingContinuation { continuation in
            var recordsToReSave: [CKRecord] = []
            saveOperation.perRecordSaveBlock = { recordID, result in
                if case let .failure(error) = result,
                   let ckError = error as? CKError,
                   ckError.code == .serverRecordChanged,
                   let serverRecord = ckError.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord,
                   let record = records.first(where: { $0.recordID == recordID }),
                   let localUpdated = record["updatedAt"] as? Date,
                   let serverUpdated = serverRecord["updatedAt"] as? Date,
                   localUpdated > serverUpdated
                {
                    recordsToReSave.append(record)
                }
            }
            saveOperation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    if recordsToReSave.isEmpty {
                        continuation.resume()
                    } else {
                        Task {
                            do {
                                try await self.saveRecords(recordsToReSave)
                                continuation.resume()
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
            self.privateDatabase.add(saveOperation)
        }
    }

    private func downloadProfile(_ cloudProfile: CloudProfile) async throws {
        let context = PersistenceController.shared.container.viewContext

        guard let profileDict = cloudProfile.profileData,
              let idStr = profileDict["id"] as? String,
              let id = UUID(uuidString: idStr),
              let name = profileDict["name"] as? String,
              let createdAt = profileDict["createdAt"] as? Date,
              let updatedAt = profileDict["updatedAt"] as? Date
        else {
            return
        }

        let profile = ProfileEntity(context: context)
        profile.id = id
        profile.name = name
        profile.dateCreated = createdAt
        profile.dateModified = updatedAt
        // Other properties are set via Codable if needed

        try context.save()
    }

    private func mapCloudKitError(_ error: Error) -> CloudSyncError {
        guard let ckError = error as? CKError else {
            return .unknown(error)
        }

        switch ckError.code {
        case .notAuthenticated:
            return .accountNotAvailable
        case .managedAccountRestricted:
            return .accountRestricted
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .quotaExceeded:
            return .quotaExceeded
        case .zoneNotFound:
            return .zoneNotFound
        case .unknownItem:
            return .recordNotFound
        case .invalidArguments, .serverRecordChanged, .assetFileNotFound:
            return .invalidData
        default:
            return .unknown(error)
        }
    }

    func deleteProfileFromCloud(_ profileId: UUID) async throws {
        let zoneID = CKRecordZone.ID(zoneName: "APGIProfiles")
        let recordID = CKRecord.ID(recordName: profileId.uuidString, zoneID: zoneID)

        let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [recordID])

        return try await withCheckedThrowingContinuation { continuation in
            deleteOperation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }

            self.privateDatabase.add(deleteOperation)
        }
    }

    func resetCloudData() async throws {
        let zoneID = CKRecordZone.ID(zoneName: "APGIProfiles")
        let query = CKQuery(recordType: "Profile", predicate: NSPredicate(value: true))

        let queryOperation = CKQueryOperation(query: query)
        queryOperation.zoneID = zoneID

        var recordIDs: [CKRecord.ID] = []

        queryOperation.recordMatchedBlock = { recordID, _ in
            recordIDs.append(recordID)
        }

        return try await withCheckedThrowingContinuation { continuation in
            queryOperation.queryResultBlock = { result in
                switch result {
                case .success:
                    // Continue with delete operation
                    let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
                    deleteOperation.modifyRecordsResultBlock = { result in
                        switch result {
                        case .success:
                            continuation.resume()
                        case let .failure(error):
                            continuation.resume(throwing: error)
                        }
                    }
                    self.privateDatabase.add(deleteOperation)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }

            self.privateDatabase.add(queryOperation)
        }
    }
}

struct CloudProfile {
    let id: String
    let name: String
    let createdAt: Date
    let updatedAt: Date
    let profileData: [String: Any]?

    init?(from record: CKRecord) {
        guard let id = record["id"] as? String,
              let name = record["name"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }

        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt

        if let data = record["profileData"] as? Data {
            self.profileData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        } else {
            self.profileData = nil
        }
    }
}
