import Foundation

nonisolated enum APIMethod: String, Sendable { case get = "GET", post = "POST", put = "PUT", patch = "PATCH", delete = "DELETE" }
nonisolated enum APIParameterLocation: String, Sendable { case path, query, header, cookie }
nonisolated enum APIBodyRequirement: String, Sendable { case none, optional, required }

nonisolated struct APIParameter: Equatable, Sendable {
  let name: String
  let location: APIParameterLocation
  let required: Bool
}

/// One HTTP operation of a pinned OpenAPI contract. Generated; never hand-written.
nonisolated struct APIOperation: Equatable, Sendable {
  let id: String
  let method: APIMethod
  let path: String
  let parameters: [APIParameter]
  let body: APIBodyRequirement
  let requiresAuthentication: Bool
  let successStatuses: [Int]
}
