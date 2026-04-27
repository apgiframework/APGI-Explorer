import CloudKit
import Combine
import CoreData
import Foundation
import OSLog

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
  private let log = OSLog(subsystem: "com.lesoto.APGI-Explorer", category: "CloudSync")

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
      case .unknown(let error):
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
      // Use .utility QoS for background sync operations
      try await Task(priority: .utility) { try await work() }.value
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

    let createZoneOperation = CKModifyRecordZonesOperation(
      recordZonesToSave: [zone], recordZoneIDsToDelete: [])

    return try await withCheckedThrowingContinuation { continuation in
      createZoneOperation.modifyRecordZonesResultBlock = { result in
        switch result {
        case .success:
          continuation.resume()
        case .failure(let error):
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
    let context = PersistenceController.shared.container.newBackgroundContext()
    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    context.automaticallyMergesChangesFromParent = true

    let localProfiles = try context.performAndWait {
      try context.fetch(ProfileEntity.fetchRequest())
    }

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
      !localProfiles.contains { $0.id.uuidString == cloudProfile.id }
        || (localProfiles.first(where: { $0.id.uuidString == cloudProfile.id })?.dateModified
          ?? Date()) < cloudProfile.updatedAt
    }

    try await self.uploadProfiles(profilesToUpload + profilesToUpdate)

    for cloudProfile in profilesToDownload {
      try await self.downloadProfile(cloudProfile, in: context)
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
        case .success(let record):
          if let profile = CloudProfile(from: record) {
            profiles.append(profile)
          }
        case .failure(let error):
          os_log(
            "Error fetching record: %@", log: self.log, type: .error, error.localizedDescription)
        }
      }

      queryOperation.queryResultBlock = { result in
        switch result {
        case .success:
          continuation.resume(returning: profiles)
        case .failure(let error):
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
        if case .failure(let error) = result,
          let ckError = error as? CKError,
          ckError.code == .serverRecordChanged,
          let serverRecord = ckError.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord,
          let record = records.first(where: { $0.recordID == recordID }),
          let localUpdated = record["updatedAt"] as? Date,
          let serverUpdated = serverRecord["updatedAt"] as? Date,
          localUpdated > serverUpdated {
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
                os_log(
                  "Transaction verification failed: %@", log: self.log, type: .error,
                  error.localizedDescription)
                continuation.resume(throwing: error)
              }
            }
          }
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
      self.privateDatabase.add(saveOperation)
    }
  }

  private func downloadProfile(_ cloudProfile: CloudProfile, in context: NSManagedObjectContext)
    async throws {
    guard let profileDict = cloudProfile.profileData,
      let idStr = profileDict["id"] as? String,
      let id = UUID(uuidString: idStr),
      let name = profileDict["name"] as? String,
      let createdAt = profileDict["createdAt"] as? Date,
      let updatedAt = profileDict["updatedAt"] as? Date
    else {
      return
    }

    try context.performAndWait {
      let profile = ProfileEntity(context: context)
      profile.id = id
      profile.name = name
      profile.dateCreated = createdAt
      profile.dateModified = updatedAt
      profile.epsilon = profileDict["epsilon"] as? Double ?? 0.0
      profile.precision = profileDict["precision"] as? Double ?? 0.0
      profile.threshold = profileDict["threshold"] as? Double ?? 0.0
      profile.somaticBias = profileDict["somaticBias"] as? Double ?? 0.0
      profile.resultsData = profileDict["resultsData"] as? Data
      profile.profileType = profileDict["profileType"] as? String ?? ""
      profile.isFavorite = profileDict["isFavorite"] as? Bool ?? false
      profile.tags = profileDict["tags"] as? String

      try context.save()
    }
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

    let deleteOperation = CKModifyRecordsOperation(
      recordsToSave: nil, recordIDsToDelete: [recordID])

    return try await withCheckedThrowingContinuation { continuation in
      deleteOperation.modifyRecordsResultBlock = { result in
        switch result {
        case .success:
          continuation.resume()
        case .failure(let error):
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
          let deleteOperation = CKModifyRecordsOperation(
            recordsToSave: nil, recordIDsToDelete: recordIDs)
          deleteOperation.modifyRecordsResultBlock = { result in
            switch result {
            case .success:
              continuation.resume()
            case .failure(let error):
              continuation.resume(throwing: error)
            }
          }
          self.privateDatabase.add(deleteOperation)
        case .failure(let error):
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
