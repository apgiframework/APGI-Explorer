import Combine
import CoreData
import Foundation

/// Represents a quiz session with progress tracking and completion status
@objc(QuizSession)
public class QuizSession: NSManagedObject {
  /// The date and time when the quiz was completed
  @NSManaged public var completedAt: Date?
  /// The date and time when the quiz session was created
  @NSManaged public var createdAt: Date
  /// Unique identifier for the quiz session
  @NSManaged public var id: UUID
  /// JSON data containing quiz session state
  @NSManaged public var jsonData: Data?
  /// Indicates whether the quiz session has been completed
  @NSManaged public var isCompleted: Bool
  /// Current progress through the quiz (0-100)
  @NSManaged public var progress: Int32
}

extension QuizSession {
  /// Creates a fetch request for QuizSession entities
  /// - Returns: A configured NSFetchRequest for QuizSession
  @nonobjc public class func fetchRequest() -> NSFetchRequest<QuizSession> {
    NSFetchRequest<QuizSession>(entityName: "QuizSession")
  }
}
