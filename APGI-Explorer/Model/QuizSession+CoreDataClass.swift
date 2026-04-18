import Combine
import CoreData
import Foundation

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
    NSFetchRequest<QuizSession>(entityName: "QuizSession")
  }
}
