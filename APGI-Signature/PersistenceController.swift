// PersistenceController.swift

import CoreData
import Combine

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    @Published var lastError: PersistenceError?
    
    // Preview instance for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // Create sample data for previews
        for i in 0..<5 {
            let profile = ProfileEntity(context: viewContext)
            profile.id = UUID()
            profile.name = "Sample Profile \(i)"
            profile.dateCreated = Date()
            profile.dateModified = Date()
            profile.epsilon = Double.random(in: 20...80)
            profile.precision = Double.random(in: 20...80)
            profile.threshold = Double.random(in: 20...80)
            profile.somaticBias = Double.random(in: 20...80)
            profile.isFavorite = i == 0
        }
        
        try? viewContext.save()
        return controller
    }()
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "APGISignature")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Set up store location in Application Support
            let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let storeURL = appSupportURL.appendingPathComponent("APGISignature.sqlite")
            
            let description = NSPersistentStoreDescription(url: storeURL)
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            
            container.persistentStoreDescriptions = [description]
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Enable persistent history tracking
        container.viewContext.name = "viewContext"
        container.viewContext.transactionAuthor = "app"
    }
    
    // MARK: - Save Operations
    
    func saveProfile(_ profile: QuizProfile) async throws {
        let context = container.viewContext
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<ProfileEntity> = ProfileEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", profile.id as CVarArg)
            
            let entity: ProfileEntity
            if let existing = try? context.fetch(fetchRequest).first {
                entity = existing
            } else {
                entity = ProfileEntity(context: context)
            }
            
            try entity.update(from: profile)
            
            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    func saveProfileSync(_ profile: QuizProfile) throws {
        let context = container.viewContext
        
        let fetchRequest: NSFetchRequest<ProfileEntity> = ProfileEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", profile.id as CVarArg)
        
        let entity: ProfileEntity
        if let existing = try? context.fetch(fetchRequest).first {
            entity = existing
        } else {
            entity = ProfileEntity(context: context)
        }
        
        try entity.update(from: profile)
        
        if context.hasChanges {
            try context.save()
        }
    }
    
    // MARK: - Fetch Operations
    
    func fetchProfiles(sortBy: ProfileSortOption = .dateModified, ascending: Bool = false) async throws -> [QuizProfile] {
        let context = container.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<ProfileEntity> = ProfileEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortBy.rawValue, ascending: ascending)]
            
            let entities = try context.fetch(fetchRequest)
            return try entities.map { try $0.toQuizProfile() }
        }
    }
    
    func fetchProfile(id: UUID) async throws -> QuizProfile? {
        let context = container.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<ProfileEntity> = ProfileEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            guard let entity = try context.fetch(fetchRequest).first else {
                return nil
            }
            
            return try entity.toQuizProfile()
        }
    }
    
    func searchProfiles(query: String) async throws -> [QuizProfile] {
        let context = container.viewContext
        
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
        let context = container.viewContext
        
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
        let context = container.viewContext
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ProfileEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            try context.execute(deleteRequest)
            try context.save()
        }
    }
    
    // MARK: - Favorite Management
    
    func toggleFavorite(_ profile: QuizProfile) async throws {
        let context = container.viewContext
        
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

enum ProfileSortOption: String {
    case name = "name"
    case dateCreated = "dateCreated"
    case dateModified = "dateModified"
    case epsilon = "epsilon"
    case precision = "precision"
}