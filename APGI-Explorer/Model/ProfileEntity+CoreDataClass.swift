import Foundation
import CoreData
import Combine

/// Core Data entity representing a user's psychological profile
/// 
/// This class stores APGI profile data including the four main parameters:
/// - epsilon: prediction error
/// - precision: precision weighting
/// - threshold: action threshold
/// - somaticBias: somatic bias factor
/// 
/// Also includes metadata like creation date, modification date, and user preferences.
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
