import Foundation

// MARK: - User Data Export Model

struct UserDataExport: Codable {
  let profiles: [QuizProfile]
  let exportDate: Date
  let appVersion: String
  let deviceInfo: [String: String]
  let exportFormat: String = "APGI UserData Export v1.0"

  enum CodingKeys: String, CodingKey {
    case profiles
    case exportDate
    case appVersion
    case deviceInfo
    case exportFormat
  }
}

// MARK: - Quiz Profile Extension for Export

extension QuizProfile {
  enum ExportCodingKeys: String, CodingKey {
    case id
    case name
    case dateCreated
    case dateModified
    case results
  }
}
