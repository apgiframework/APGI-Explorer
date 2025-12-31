import Foundation
import PDFKit
import SwiftUI

// MARK: - Export Models

/// Represents a profile export with metadata
struct ProfileExport: Codable {
    let version: String
    let timestamp: Date
    let profile: QuizProfile
    let apgiScores: APGIProfile
    let profileType: String
    
    enum CodingKeys: String, CodingKey {
        case version, timestamp, profile, apgiScores, profileType
    }
    
    init(version: String, timestamp: Date, profile: QuizProfile, apgiScores: APGIProfile) {
        self.version = version
        self.timestamp = timestamp
        self.profile = profile
        self.apgiScores = apgiScores
        self.profileType = ProfileManager().determineProfileType(for: apgiScores).rawValue
    }
}

// MARK: - Export Format

enum ExportFormat: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"
    case pdf = "PDF"
    case png = "PNG"
    case html = "HTML"
    
    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .json: return "json"
        case .csv: return "csv"
        case .png: return "png"
        case .html: return "html"
        }
    }
    
    var contentType: String {
        switch self {
        case .pdf: return "application/pdf"
        case .json: return "application/json"
        case .csv: return "text/csv"
        case .png: return "image/png"
        case .html: return "text/html"
        }
    }
}

// MARK: - Export Error

enum ExportError: Error {
    case invalidData
    case pdfGenerationFailed
    case fileCreationFailed
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidData: return "Invalid data for export"
        case .pdfGenerationFailed: return "Failed to generate PDF"
        case .fileCreationFailed: return "Failed to create export file"
        case .unknown: return "An unknown error occurred"
        }
    }
}

// MARK: - Export Utilities

struct ExportUtilities {
    static func generateExportFilename(profile: QuizProfile, format: ExportFormat) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return "\(profile.name.replacingOccurrences(of: " ", with: "_"))_\(timestamp).\(format.fileExtension)"
    }
    
    static func getTemporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
    }
}
