import Combine
import CoreData
import Foundation

@objc(ProfileEntity)
public class ProfileEntity: NSManagedObject, Codable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var dateCreated: Date
    @NSManaged public var dateModified: Date
    @NSManaged public var epsilon: Double
    @NSManaged public var precision: Double
    @NSManaged public var threshold: Double
    @NSManaged public var somaticBias: Double
    @NSManaged public var resultsData: Data?
    @NSManaged public var profileType: String
    @NSManaged public var isFavorite: Bool
    @NSManaged public var tags: String?

    enum CodingKeys: String, CodingKey {
        case id, name, dateCreated, dateModified
        case epsilon, precision, threshold, somaticBias
        case resultsData, profileType, isFavorite, tags
    }

    public required convenience init(from decoder: Decoder) throws {
        guard let contextKey = CodingUserInfoKey.managedObjectContext,
              let context = decoder.userInfo[contextKey] as? NSManagedObjectContext
        else {
            throw DecodingError.missingContext
        }
        self.init(context: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.dateCreated = try container.decode(Date.self, forKey: .dateCreated)
        self.dateModified = try container.decode(Date.self, forKey: .dateModified)
        self.epsilon = try container.decode(Double.self, forKey: .epsilon)
        self.precision = try container.decode(Double.self, forKey: .precision)
        self.threshold = try container.decode(Double.self, forKey: .threshold)
        self.somaticBias = try container.decode(Double.self, forKey: .somaticBias)
        self.resultsData = try container.decode(Data?.self, forKey: .resultsData)
        self.profileType = try container.decode(String.self, forKey: .profileType)
        self.isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        self.tags = try container.decode(String?.self, forKey: .tags)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.dateCreated, forKey: .dateCreated)
        try container.encode(self.dateModified, forKey: .dateModified)
        try container.encode(self.epsilon, forKey: .epsilon)
        try container.encode(self.precision, forKey: .precision)
        try container.encode(self.threshold, forKey: .threshold)
        try container.encode(self.somaticBias, forKey: .somaticBias)
        try container.encode(self.resultsData, forKey: .resultsData)
        try container.encode(self.profileType, forKey: .profileType)
        try container.encode(self.isFavorite, forKey: .isFavorite)
        try container.encode(self.tags, forKey: .tags)
    }
}

public extension ProfileEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ProfileEntity> {
        NSFetchRequest<ProfileEntity>(entityName: "ProfileEntity")
    }
}

enum DecodingError: LocalizedError {
    case missingContext

    var errorDescription: String? {
        switch self {
        case .missingContext:
            "Missing NSManagedObjectContext in decoder userInfo"
        }
    }
}
