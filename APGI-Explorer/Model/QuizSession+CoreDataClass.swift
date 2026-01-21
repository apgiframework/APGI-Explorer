import Foundation
import CoreData
import Combine

/// Core Data entity representing a quiz session
/// 
/// This class tracks user progress through the APGI assessment questionnaire,
/// including completion status, progress tracking, and session timing.
/// Session data is stored as JSON for flexibility and future extensibility.
@objc(QuizSession)
public class QuizSession: NSManagedObject {
    @NSManaged public var completedAt: Date?
    @NSManaged public var createdAt: Date
    @NSManaged public var id: UUID
    @NSManaged public var jsonData: Data?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var progress: Int32
}

extension QuizSession {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuizSession> {
        return NSFetchRequest<QuizSession>(entityName: "QuizSession")
    }
}
