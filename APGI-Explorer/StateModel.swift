import Combine
import Foundation

// MARK: - State Model Cache

class StateModelCache {
  private var similarityCache: [String: Double] = [:]
  private let queue = DispatchQueue(label: "com.app.cache", attributes: .concurrent)

  func getCachedSimilarity(state1: Int, state2: Int) -> Double? {
    let key = "\(min(state1, state2))-\(max(state1, state2))"
    return self.queue.sync { self.similarityCache[key] }
  }

  func cacheSimilarity(state1: Int, state2: Int, value: Double) {
    let key = "\(min(state1, state2))-\(max(state1, state2))"
    self.queue.async(flags: .barrier) { [weak self] in
      self?.similarityCache[key] = value
    }
  }

  func clearCache() {
    self.queue.async(flags: .barrier) { [weak self] in
      self?.similarityCache.removeAll()
    }
  }
}

// MARK: - State Model

@MainActor
class StateModel: ObservableObject {
  @Published var states: [PsychologicalState] = PsychologicalState.exampleStates
  @Published var isLoadingStates = false
  @Published var error: AppError?
  @Published var isLoadingSimilarStates = false
  private let cache = StateModelCache()

  // MARK: - Data Loading

  func loadStates() async {
    self.isLoadingStates = true
    self.error = nil

    do {
      self.states = try await self.loadStatesFromSource()
    } catch {
      self.error = .dataLoadingFailed(underlying: error)
    }

    self.isLoadingStates = false
  }

  private func loadStatesFromSource() async throws -> [PsychologicalState] {
    // For now, return example states. In a real app, this would load from a data source
    PsychologicalState.exampleStates
  }

  // MARK: - Async Operations

  func findSimilarStates(to state: PsychologicalState, limit: Int = 5) async -> [PsychologicalState] {
    self.isLoadingSimilarStates = true
    defer { isLoadingSimilarStates = false }

    return await withTaskGroup(of: (PsychologicalState, Double).self) { group in
      for candidateState in self.states where candidateState.id != state.id {
        group.addTask {
          let similarity = await self.calculateSimilarity(between: state, and: candidateState)
          return (candidateState, similarity)
        }
      }

      var results: [(PsychologicalState, Double)] = []
      for await result in group {
        results.append(result)
      }

      return
        results
        .sorted { $0.1 > $1.1 }
        .prefix(limit)
        .map(\.0)
    }
  }

  func calculateSimilarity(between state1: PsychologicalState, and state2: PsychologicalState) async
    -> Double {
    // Check cache first
    if let cachedSimilarity = cache.getCachedSimilarity(state1: state1.id, state2: state2.id) {
      return cachedSimilarity
    }

    // Calculate similarity
    let similarity = await Task.detached {
      await self.performSimilarityCalculation(state1: state1, state2: state2)
    }.value

    // Cache the result
    self.cache.cacheSimilarity(state1: state1.id, state2: state2.id, value: similarity)

    return similarity
  }

  private func performSimilarityCalculation(state1: PsychologicalState, state2: PsychologicalState)
    async -> Double {
    // Use the built-in similarity method from PsychologicalState
    state1.similarity(to: state2)
  }

  func clearCache() {
    self.cache.clearCache()
  }

  /// Refreshes state data - used by auto-refresh feature
  func refreshIfNeeded() async {
    // In a real app with a backend, this would check for new data
    // For now, we just reload from the local source
    await self.loadStates()
  }
}
