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
    case spss = "SPSS"
    case stata = "Stata"
    case rData = "R Data"
    case excel = "Excel"
    case xml = "XML"
    case bibTeX = "BibTeX"
    case endNote = "EndNote"
    case apa = "APA Report"
    case mla = "MLA Report"

    var fileExtension: String {
        switch self {
        case .pdf: "pdf"
        case .json: "json"
        case .csv: "csv"
        case .png: "png"
        case .spss: "sav"
        case .stata: "dta"
        case .rData: "RData"
        case .excel: "xlsx"
        case .xml: "xml"
        case .bibTeX: "bib"
        case .endNote: "enw"
        case .apa: "pdf"
        case .mla: "pdf"
        }
    }

    var contentType: String {
        switch self {
        case .pdf: "application/pdf"
        case .json: "application/json"
        case .csv: "text/csv"
        case .png: "image/png"
        case .spss: "application/octet-stream"
        case .stata: "application/octet-stream"
        case .rData: "application/octet-stream"
        case .excel: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case .xml: "application/xml"
        case .bibTeX: "application/x-bibtex"
        case .endNote: "application/x-endnote-refer"
        case .apa: "application/pdf"
        case .mla: "application/pdf"
        }
    }

    var description: String {
        switch self {
        case .json: "Standard JSON format for data interchange"
        case .csv: "Comma-separated values for spreadsheet applications"
        case .pdf: "Portable Document Format with visual charts"
        case .png: "PNG image of profile visualization"
        case .spss: "SPSS .sav file for statistical analysis"
        case .stata: "Stata .dta file for econometric analysis"
        case .rData: "R data frame for statistical computing"
        case .excel: "Excel spreadsheet with multiple worksheets"
        case .xml: "XML format for structured data exchange"
        case .bibTeX: "BibTeX bibliography format for academic papers"
        case .endNote: "EndNote reference format for citation management"
        case .apa: "APA-formatted research report"
        case .mla: "MLA-formatted research report"
        }
    }

    var category: ExportCategory {
        switch self {
        case .json, .csv, .xml:
            .data
        case .pdf, .png:
            .visual
        case .spss, .stata, .rData, .excel:
            .statistical
        case .bibTeX, .endNote:
            .bibliography
        case .apa, .mla:
            .academic
        }
    }
}

enum ExportCategory: String, CaseIterable {
    case data = "Data Formats"
    case visual = "Visual Formats"
    case statistical = "Statistical Software"
    case bibliography = "Bibliography"
    case academic = "Academic Reports"

    var formats: [ExportFormat] {
        switch self {
        case .data:
            [.json, .csv, .xml]
        case .visual:
            [.pdf, .png]
        case .statistical:
            [.spss, .stata, .rData, .excel]
        case .bibliography:
            [.bibTeX, .endNote]
        case .academic:
            [.apa, .mla]
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
        case .invalidData: "Invalid data for export"
        case .pdfGenerationFailed: "Failed to generate PDF"
        case .fileCreationFailed: "Failed to create export file"
        case .unknown: "An unknown error occurred"
        }
    }
}

// MARK: - Export Utilities

enum ExportUtilities {
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
