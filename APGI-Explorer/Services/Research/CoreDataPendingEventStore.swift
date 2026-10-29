import CoreData
import Foundation

/// Core Data persistence for the research outbox (`PendingEvent` entity, model version 2).
/// Personal journals live in `QuizSession` and are never read into this store.
///
/// Rows are never deleted: after a verified acknowledgement the payload is cleared and the
/// row stays as a tombstone so an acknowledged entry cannot be enqueued again.
nonisolated final class CoreDataPendingEventStore: PendingEventStoring, @unchecked Sendable {
  private let container: NSPersistentContainer

  init(container: NSPersistentContainer) { self.container = container }

  private func context() -> NSManagedObjectContext {
    let context = container.newBackgroundContext()
    // Never let a constraint conflict silently overwrite a tombstone.
    context.mergePolicy = NSErrorMergePolicy
    context.name = "research-outbox"
    return context
  }

  private static func record(_ object: NSManagedObject) -> PendingEventRecord? {
    guard let key = object.value(forKey: "eventKey") as? String,
          let session = object.value(forKey: "sessionID") as? String,
          let digest = object.value(forKey: "payloadDigest") as? String,
          let created = object.value(forKey: "createdAt") as? Date,
          let raw = object.value(forKey: "stateRaw") as? String,
          let state = PendingEventState(rawValue: raw) else { return nil }
    return PendingEventRecord(
      eventKey: key, sessionID: session, seqNo: (object.value(forKey: "seqNo") as? Int64).map(Int.init) ?? 0,
      payload: object.value(forKey: "payload") as? Data, payloadDigest: digest, state: state,
      attemptCount: (object.value(forKey: "attemptCount") as? Int32).map(Int.init) ?? 0,
      nextAttemptAt: object.value(forKey: "nextAttemptAt") as? Date, createdAt: created,
      verifiedAt: object.value(forKey: "verifiedAt") as? Date)
  }

  private static func fetch(_ predicate: NSPredicate, in context: NSManagedObjectContext,
                            sorted: Bool = false) throws -> [NSManagedObject] {
    let request = NSFetchRequest<NSManagedObject>(entityName: "PendingEvent")
    request.predicate = predicate
    if sorted { request.sortDescriptors = [NSSortDescriptor(key: "seqNo", ascending: true)] }
    return try context.fetch(request)
  }

  func insertIfAbsent(_ record: PendingEventRecord) async throws -> EnqueueResult {
    let context = context()
    return try await context.perform {
      let existing = try Self.fetch(NSPredicate(format: "sessionID == %@ AND seqNo == %lld",
                                                record.sessionID, Int64(record.seqNo)), in: context)
      if let found = existing.first, let stored = Self.record(found) {
        guard stored.payloadDigest == record.payloadDigest else { throw OutboxError.conflictingPayload(seqNo: record.seqNo) }
        return stored.state == .verified ? .alreadyAcknowledged(eventKey: stored.eventKey)
                                         : .alreadyQueued(eventKey: stored.eventKey)
      }
      let object = NSEntityDescription.insertNewObject(forEntityName: "PendingEvent", into: context)
      object.setValue(record.eventKey, forKey: "eventKey")
      object.setValue(record.sessionID, forKey: "sessionID")
      object.setValue(Int64(record.seqNo), forKey: "seqNo")
      object.setValue(record.payload, forKey: "payload")
      object.setValue(record.payloadDigest, forKey: "payloadDigest")
      object.setValue(record.state.rawValue, forKey: "stateRaw")
      object.setValue(Int32(record.attemptCount), forKey: "attemptCount")
      object.setValue(record.nextAttemptAt, forKey: "nextAttemptAt")
      object.setValue(record.createdAt, forKey: "createdAt")
      try context.save()
      return .enqueued(eventKey: record.eventKey)
    }
  }

  func dueEvents(sessionID: String, now: Date, limit: Int) async throws -> [PendingEventRecord] {
    let context = context()
    return try await context.perform {
      let open = try Self.fetch(NSPredicate(format: "sessionID == %@ AND stateRaw != %@", sessionID,
                                            PendingEventState.verified.rawValue), in: context, sorted: true)
        .compactMap(Self.record)
      guard let first = open.first, first.state == .pending,
            first.nextAttemptAt.map({ $0 <= now }) ?? true else { return [] }
      var due: [PendingEventRecord] = []
      for record in open.prefix(limit) {
        guard record.state == .pending else { break }
        due.append(record)
      }
      return due
    }
  }

  private func update(_ keys: [String], _ change: @escaping (NSManagedObject) -> Void) async throws {
    let context = context()
    try await context.perform {
      for object in try Self.fetch(NSPredicate(format: "eventKey IN %@", keys), in: context) { change(object) }
      if context.hasChanges { try context.save() }
    }
  }

  func markUploading(eventKeys: [String]) async throws {
    try await update(eventKeys) { $0.setValue(PendingEventState.uploading.rawValue, forKey: "stateRaw") }
  }

  func markVerified(eventKey: String, at date: Date) async throws {
    try await update([eventKey]) { object in
      object.setValue(nil, forKey: "payload")
      object.setValue(PendingEventState.verified.rawValue, forKey: "stateRaw")
      object.setValue(date, forKey: "verifiedAt")
      object.setValue(nil, forKey: "nextAttemptAt")
    }
  }

  func recordFailure(eventKey: String, nextAttemptAt: Date) async throws {
    try await update([eventKey]) { object in
      guard (object.value(forKey: "stateRaw") as? String) != PendingEventState.verified.rawValue else { return }
      let attempts = (object.value(forKey: "attemptCount") as? Int32) ?? 0
      object.setValue(PendingEventState.pending.rawValue, forKey: "stateRaw")
      object.setValue(attempts + 1, forKey: "attemptCount")
      object.setValue(nextAttemptAt, forKey: "nextAttemptAt")
    }
  }

  func resetInFlight() async throws {
    let context = context()
    try await context.perform {
      for object in try Self.fetch(NSPredicate(format: "stateRaw == %@", PendingEventState.uploading.rawValue), in: context) {
        object.setValue(PendingEventState.pending.rawValue, forKey: "stateRaw")
      }
      if context.hasChanges { try context.save() }
    }
  }

  func sessionsWithWork() async throws -> [String] {
    let context = context()
    return try await context.perform {
      let open = try Self.fetch(NSPredicate(format: "stateRaw != %@", PendingEventState.verified.rawValue), in: context)
      return Array(Set(open.compactMap { $0.value(forKey: "sessionID") as? String })).sorted()
    }
  }

  func record(eventKey: String) async throws -> PendingEventRecord? {
    let context = context()
    return try await context.perform {
      try Self.fetch(NSPredicate(format: "eventKey == %@", eventKey), in: context).first.flatMap(Self.record)
    }
  }

  func openCount(sessionID: String) async throws -> Int {
    let context = context()
    return try await context.perform {
      try Self.fetch(NSPredicate(format: "sessionID == %@ AND stateRaw != %@", sessionID,
                                 PendingEventState.verified.rawValue), in: context).count
    }
  }

  func purgeSession(_ sessionID: String) async throws {
    let context = context()
    try await context.perform {
      for object in try Self.fetch(NSPredicate(format: "sessionID == %@", sessionID), in: context) { context.delete(object) }
      if context.hasChanges { try context.save() }
    }
  }
}
