import Combine
import Foundation
import PDFKit
import TabularData
import UniformTypeIdentifiers

#if os(iOS)
  import UIKit
#endif

class ResearchExportManager: ObservableObject {
  static let shared = ResearchExportManager()

  private init() {
  }

  func exportProfile(_ profile: ProfileExport, format: ExportFormat) throws -> Data {
    switch format {
    case .json:
      return try self.exportJSON(profile)
    case .csv:
      return try self.exportCSV(profile)
    case .xml:
      return try self.exportXML(profile)
    case .spss, .stata:
      throw ExportError.unsupportedFormat
    case .rData:
      return try self.exportRData(profile)
    case .excel:
      return try self.exportExcel(profile)
    case .bibTeX:
      return try self.exportBibTeX(profile)
    case .endNote:
      return try self.exportEndNote(profile)
    case .apa:
      return try self.exportAPAReport(profile)
    case .mla:
      return try self.exportMLAReport(profile)
    case .pdf, .png:
      throw ExportError.unsupportedFormat
    }
  }

  private func exportJSON(_ profile: ProfileExport) throws -> Data {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(profile)
    var object = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    object["instrument_id"] = APGIIdentifiers.instrument
    object["analysis_mode"] = APGIIdentifiers.analysisMode
    object["excluded_from_norms"] = true
    return try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
  }

  private func scoreRows(_ profile: ProfileExport) -> [[String]] {
    let scores = profile.apgiScores
    return [
      ["Metric", "Value", "Category", "Description"],
      ["epsilon", String(scores.epsilon), "Self-report", ScoreLabels.reactivity],
      ["precision", String(scores.precision), "Self-report", ScoreLabels.prioritisation],
      ["threshold", String(scores.threshold), "Self-report", ScoreLabels.threshold],
      ["somatic", String(scores.somaticBias), "Self-report", ScoreLabels.bodySignal],
      ["Profile_Name", profile.profile.name, "Local", "Profile name"],
      ["instrument_id", APGIIdentifiers.instrument, "Metadata", "Exploratory instrument"],
      ["analysis_mode", APGIIdentifiers.analysisMode, "Metadata", "Excluded from norms"],
      ["Export_Date", ISO8601DateFormatter().string(from: profile.timestamp), "Metadata", "Export timestamp"]
    ]
  }

  private func exportCSV(_ profile: ProfileExport) throws -> Data {
    let text = scoreRows(profile).map { row in
      row.map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }.joined(separator: ",")
    }.joined(separator: "\n")
    return Data(text.utf8)
  }

  private func xmlEscape(_ value: String) -> String {
    value.replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
      .replacingOccurrences(of: "'", with: "&apos;")
  }

  private func exportXML(_ profile: ProfileExport) throws -> Data {
    let rows = scoreRows(profile).dropFirst().map {
      "<Metric name=\"\(xmlEscape($0[0]))\" label=\"\(xmlEscape($0[3]))\">\(xmlEscape($0[1]))</Metric>"
    }.joined()
    return Data("<?xml version=\"1.0\" encoding=\"UTF-8\"?><APGIProfileExport><Metadata><Instrument>apgi-explorer-35</Instrument><AnalysisMode>exploratory</AnalysisMode><ExcludedFromNorms>true</ExcludedFromNorms></Metadata><APGIScores>\(rows)</APGIScores></APGIProfileExport>".utf8)
  }

  private func exportRData(_ profile: ProfileExport) throws -> Data {
    // An executable R source file, explicitly exported with .R rather than .RData.
    let rows = scoreRows(profile).dropFirst().prefix(4)
    let keys = rows.map { "\"\($0[0])\"" }.joined(separator: ", ")
    let values = rows.map { $0[1] }.joined(separator: ", ")
    return Data("""
    # APGI Profile Data Export
    # Exploratory self-report; excluded from norms. No validated trait interpretation.
    apgi_data <- data.frame(metric = c(\(keys)), value = c(\(values)))
    saveRDS(apgi_data, file = "apgi_profile.rds")
    save(apgi_data, file = "apgi_profile.RData")
    """.utf8)
  }

  private func exportExcel(_ profile: ProfileExport) throws -> Data {
    // Generate XLSX using OOXML format
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    let xlDir = tempDir.appendingPathComponent("xl")
    try FileManager.default.createDirectory(at: xlDir, withIntermediateDirectories: true)

    let worksheetsDir = xlDir.appendingPathComponent("worksheets")
    try FileManager.default.createDirectory(at: worksheetsDir, withIntermediateDirectories: true)

    let relsDir = tempDir.appendingPathComponent("_rels")
    try FileManager.default.createDirectory(at: relsDir, withIntermediateDirectories: true)

    let xlRelsDir = xlDir.appendingPathComponent("_rels")
    try FileManager.default.createDirectory(at: xlRelsDir, withIntermediateDirectories: true)

    // [Content_Types].xml
    let contentTypes = """
      <?xml version="1.0" encoding="UTF-8"?>
      <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
      <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
      <Default Extension="xml" ContentType="application/xml"/>
      <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
      <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
      </Types>
      """
    try contentTypes.write(
      to: tempDir.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)

    // _rels/.rels
    let rels = """
      <?xml version="1.0" encoding="UTF-8"?>
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
      <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
      </Relationships>
      """
    try rels.write(to: relsDir.appendingPathComponent(".rels"), atomically: true, encoding: .utf8)

    // xl/workbook.xml
    let workbook = """
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
      <sheets>
      <sheet name="Sheet1" sheetId="1" r:id="rId1"/>
      </sheets>
      </workbook>
      """
    try workbook.write(
      to: xlDir.appendingPathComponent("workbook.xml"), atomically: true, encoding: .utf8)

    // xl/_rels/workbook.xml.rels
    let workbookRels = """
      <?xml version="1.0" encoding="UTF-8"?>
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
      <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
      </Relationships>
      """
    try workbookRels.write(
      to: xlRelsDir.appendingPathComponent("workbook.xml.rels"), atomically: true, encoding: .utf8)

    // xl/worksheets/sheet1.xml
    var sheetXML = """
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
      <sheetData>
      """

    let rows = scoreRows(profile)

    for (index, row) in rows.enumerated() {
      let rowNum = index + 1
      sheetXML += "<row r=\"\(rowNum)\">"
      for (colIndex, cell) in row.enumerated() {
        let colLetter: Character
        if colIndex < 26, let scalar = UnicodeScalar(65 + colIndex) {
          colLetter = Character(scalar)
        } else {
          colLetter = "A"
        }
        let cellRef = "\(colLetter)\(rowNum)"
        if Double(cell) != nil {
          sheetXML += "<c r=\"\(cellRef)\"><v>\(cell)</v></c>"
        } else {
          sheetXML +=
            "<c r=\"\(cellRef)\" t=\"str\"><v>\(cell.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;"))</v></c>"
        }
      }
      sheetXML += "</row>"
    }

    sheetXML += """
      </sheetData>
      </worksheet>
      """

    try sheetXML.write(
      to: worksheetsDir.appendingPathComponent("sheet1.xml"), atomically: true, encoding: .utf8)

    // Create ZIP archive
    let zipFile = tempDir.appendingPathComponent("temp.xlsx")
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
    process.arguments = ["-r", zipFile.path, ".", "-x", "*.DS_Store"]
    process.currentDirectoryURL = tempDir
    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
      try? FileManager.default.removeItem(at: tempDir)
      throw ExportError.unknown
    }

    let zipData = try Data(contentsOf: zipFile)
    try FileManager.default.removeItem(at: tempDir)
    return zipData
  }

  private func exportBibTeX(_ profile: ProfileExport) throws -> Data {
    let citation = """
    @misc{apgi_exploratory_profile,
      title = {APGI Explorer exploratory self-report},
      author = {APGI Explorer},
      year = {\(Calendar.current.component(.year, from: profile.timestamp))},
      note = {Instrument apgi-explorer-35; exploratory; excluded from norms},
      howpublished = {APGI Explorer Application}
    }
    """
    return Data(citation.utf8)
  }

  private func exportEndNote(_ profile: ProfileExport) throws -> Data {
    let citation = """
    %0 Generic
    %T APGI Explorer exploratory self-report
    %A APGI Explorer
    %D \(Calendar.current.component(.year, from: profile.timestamp))
    %X Instrument apgi-explorer-35; exploratory; excluded from norms
    %9 Local self-report summary
    """
    return Data(citation.utf8)
  }

  private func exportAPAReport(_ profile: ProfileExport) throws -> Data {
    let apaReport = self.generateAPAReport(profile: profile)
    return try self.generatePDFReport(content: apaReport, title: "APGI Assessment Report")
  }

  private func exportMLAReport(_ profile: ProfileExport) throws -> Data {
    let mlaReport = self.generateMLAReport(profile: profile)
    return try self.generatePDFReport(content: mlaReport, title: "APGI Assessment Report")
  }

  private func generateAPAReport(profile: ProfileExport) -> String {
    let rows = scoreRows(profile).dropFirst().map { "\($0[3]): \($0[1])" }.joined(separator: "\n")
    return """
    APGI Explorer — Exploratory Self-Report

    \(rows)

    These local item averages describe responses to the apgi-explorer-35 questionnaire.
    They are not validated psychological measures, diagnoses, predictions or population norms.
    No reliability estimate or confidence interval is available. Items 7 and 9 are nominal
    choices and are excluded from numeric averages. All 35 valid responses are required.

    Reflect on how recent context may have influenced your answers. This report does not
    infer strengths, weaknesses, mental states, or recommendations from these summaries.
    Personal questionnaire answers remain on your device and are excluded from research norms.
    """
  }

  private func generateMLAReport(profile: ProfileExport) -> String {
    generateAPAReport(profile: profile)
  }

  private func generatePDFReport(content: String, title: String) throws -> Data {
    #if os(iOS)
      let pdfMetaData = [
        kCGPDFContextCreator: "APGI Explorer",
        kCGPDFContextAuthor: "APGI Explorer",
        kCGPDFContextTitle: title
      ]

      let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
      let pdfData = NSMutableData()

      UIGraphicsBeginPDFContextToData(pdfData, pageRect, pdfMetaData)
      UIGraphicsBeginPDFPage()

      let context = UIGraphicsGetCurrentContext()
      context?.setFillColor(UIColor.black.cgColor)

      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .left

      let attributes = [
        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
        NSAttributedString.Key.paragraphStyle: paragraphStyle
      ]

      let textRect = CGRect(x: 50, y: 50, width: 512, height: 692)
      content.draw(in: textRect, withAttributes: attributes)

      UIGraphicsEndPDFContext()

      return pdfData as Data
    #else
      let pdfMetaData = [
        kCGPDFContextCreator: "APGI Explorer",
        kCGPDFContextAuthor: "APGI Explorer",
        kCGPDFContextTitle: title
      ]

      let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
      let pdfData = NSMutableData()

      guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else {
        throw ExportError.unknown
      }
      var mediaBox = pageRect
      let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)

      context?.beginPDFPage(NSDictionary())
      context?.setFillColor(NSColor.black.cgColor)

      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .left

      let attributes = [
        NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12),
        NSAttributedString.Key.paragraphStyle: paragraphStyle
      ]

      let textRect = CGRect(x: 50, y: 50, width: 512, height: 692)
      (content as NSString).draw(in: textRect, withAttributes: attributes)

      context?.endPDFPage()
      context?.closePDF()

      return pdfData as Data
    #endif
  }
}

extension ExportError {
  static let unsupportedFormat = ExportError.unknown
}
