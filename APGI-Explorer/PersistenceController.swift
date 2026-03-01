import CloudKit
import Combine
import CoreData

enum PersistenceControllerError: Error {
    case directoryAccessFailed
    case storeLoadFailed(Error)
}

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    @Published var lastError: PersistenceControllerError?

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        for index in 0 ..< DataConstants.previewProfileCount {
            let profile = ProfileEntity(context: viewContext)
            profile.id = UUID()
            profile.name = "Sample Profile \(index)"
            profile.dateCreated = Date()
            profile.dateModified = Date()
            profile.epsilon = Double.random(in: ColorConstants.minPositiveValue ... 80)
            profile.precision = Double.random(in: ColorConstants.minPositiveValue ... 80)
            profile.threshold = Double.random(in: ColorConstants.minPositiveValue ... 80)
            profile.somaticBias = Double.random(in: ColorConstants.minPositiveValue ... 80)
            profile.isFavorite = index == 0
        }

        try? viewContext.save()
        return controller
    }()

    init(inMemory: Bool = false) {
        self.container = NSPersistentCloudKitContainer(name: "APGIExplorer")

        if inMemory {
            self.container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            if let appSupportURL = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first {
                let storeURL = appSupportURL.appendingPathComponent("APGIExplorer.sqlite")
                let description = NSPersistentStoreDescription(url: storeURL)
                description.shouldMigrateStoreAutomatically = true
                description.shouldInferMappingModelAutomatically = true
                #if os(iOS)
                    description.setOption(
                        FileProtectionType.complete as NSObject,
                        forKey: NSPersistentStoreFileProtectionKey
                    )
                #endif
                self.container.persistentStoreDescriptions = [description]
            } else {
                self.lastError = .directoryAccessFailed
                guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    self.lastError = .directoryAccessFailed
                    return
                }
                let storeURL = documentsURL.appendingPathComponent("APGIExplorer.sqlite")
                let description = NSPersistentStoreDescription(url: storeURL)
                description.shouldMigrateStoreAutomatically = true
                description.shouldInferMappingModelAutomatically = true
                #if os(iOS)
                    description.setOption(
                        FileProtectionType.complete as NSObject,
                        forKey: NSPersistentStoreFileProtectionKey
                    )
                #endif
                self.container.persistentStoreDescriptions = [description]
            }
        }

        self.container.loadPersistentStores { _, error in
            if let error {
                self.lastError = .storeLoadFailed(error)
            }
        }

        self.container.viewContext.automaticallyMergesChangesFromParent = true
        self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        self.container.viewContext.name = "viewContext"
        self.container.viewContext.transactionAuthor = "app"
    }

    // MARK: - Save Operations

    func saveProfile(_ profile: QuizProfile) async throws {
        let context = self.container.viewContext

        try await context.perform {
            let fetchRequest: NSFetchRequest<ProfileEntity> = ProfileEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", profile.id as CVarArg)

            let entity: ProfileEntity = if let existing = try? context.fetch(fetchRequest).first {
                existing
            } else {
                ProfileEntity(context: context)
            }

            try entity.update(from: profile)

            if context.hasChanges {
                try context.save()
            }
        }
    }

    func saveProfileSync(_ profile: QuizProfile) throws {
        let context = self.container.viewContext

        let fetchRequest: NSFetchRequest<ProfileEntity> = ProfileEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", profile.id as CVarArg)

        let entity: ProfileEntity = if let existing = try? context.fetch(fetchRequest).first {
            existing
        } else {
            ProfileEntity(context: context)
        }

        try entity.update(from: profile)

        if context.hasChanges {
            try context.save()
        }
    }

    // MARK: - Fetch Operations

    func fetchProfiles(
        sortBy: ProfileSortOption = .dateModified,
        ascending: Bool = false
    ) async throws -> [QuizProfile] {
        let context = self.container.viewContext

        return try await context.perform {
            let fetchRequest: NSFetchRequest<ProfileEntity> = ProfileEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortBy.rawValue, ascending: ascending)]

            let entities = try context.fetch(fetchRequest)
            return try entities.map { try $0.toQuizProfile() }
        }
    }

    func fetchProfile(id: UUID) async throws -> QuizProfile? {
        let context = self.container.viewContext

        return try await context.perform {
            let fetchRequest: NSFetchRequest<ProfileEntity> = ProfileEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = DataConstants.fetchLimit

            guard let entity = try context.fetch(fetchRequest).first else {
                return nil
            }

            return try entity.toQuizProfile()
        }
    }

    func searchProfiles(query: String) async throws -> [QuizProfile] {
        let context = self.container.viewContext

        return try await context.perform {
            let fetchRequest: NSFetchRequest<ProfileEntity> = ProfileEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateModified", ascending: false)]

            let entities = try context.fetch(fetchRequest)
            return try entities.map { try $0.toQuizProfile() }
        }
    }

    // MARK: - Delete Operations

    func deleteProfile(_ profile: QuizProfile) async throws {
        let context = self.container.viewContext

        try await context.perform {
            let fetchRequest: NSFetchRequest<ProfileEntity> = ProfileEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", profile.id as CVarArg)

            if let entity = try context.fetch(fetchRequest).first {
                context.delete(entity)
                try context.save()
            }
        }
    }

    func deleteAllProfiles() async throws {
        let context = self.container.viewContext

        try await context.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ProfileEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            try context.execute(deleteRequest)
            try context.save()
        }
    }

    // MARK: - Favorite Management

    func toggleFavorite(_ profile: QuizProfile) async throws {
        let context = self.container.viewContext

        try await context.perform {
            let fetchRequest: NSFetchRequest<ProfileEntity> = ProfileEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", profile.id as CVarArg)

            if let entity = try context.fetch(fetchRequest).first {
                entity.isFavorite.toggle()
                try context.save()
            }
        }
    }
}

enum ProfileSortOption: String, CaseIterable {
    case name
    case dateCreated
    case dateModified
    case epsilon
    case precision
}
