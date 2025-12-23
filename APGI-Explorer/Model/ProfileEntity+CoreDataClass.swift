import Foundation
import CoreData

@objc(ProfileEntity)
public class ProfileEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var dateCreated: Date
    @NSManaged public var dateModified: Date
    @NSManaged public var epsilon: Double
    @NSManaged public var precision: Double
    @NSManaged public var threshold: Double
    @NSManaged public var somaticBias: Double
    @NSManaged public var resultsData: Data? // JSON of full results
    @NSManaged public var profileType: String
    @NSManaged public var isFavorite: Bool
    @NSManaged public var tags: String? // Comma-separated tags
}

extension ProfileEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProfileEntity> {
        return NSFetchRequest<ProfileEntity>(entityName: "ProfileEntity")
    }
}
