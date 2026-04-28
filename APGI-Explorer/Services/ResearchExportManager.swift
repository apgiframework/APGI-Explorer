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
    case .spss:
      return try self.exportSPSS(profile)
    case .stata:
      return try self.exportStata(profile)
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
    return try encoder.encode(profile)
  }

  private func exportCSV(_ profile: ProfileExport) throws -> Data {
    var csvContent = "Metric,Value,Category,Description\n"

    let apgiScores = profile.apgiScores
    csvContent += "APGI_Total,\(apgiScores.overall),Overall,Total APGI Score\n"
    csvContent += "APGI_Autonomy,\(apgiScores.autonomy),Autonomy,Level of autonomous functioning\n"
    csvContent +=
      "APGI_Purposefulness,\(apgiScores.purposefulness),Purposefulness,Sense of purpose and direction\n"
    csvContent +=
      "APGI_SelfAcceptance,\(apgiScores.selfAcceptance),Self-Acceptance,Level of self-acceptance\n"
    csvContent +=
      "APGI_PersonalGrowth,\(apgiScores.personalGrowth),Personal Growth,Orientation toward growth\n"

    let quizProfile = profile.profile
    csvContent += "Profile_Name,\(quizProfile.name),Demographic,Profile identifier\n"
    csvContent += "Profile_Age,\(quizProfile.age),Demographic,Participant age\n"
    csvContent += "Profile_Gender,\(quizProfile.gender),Demographic,Participant gender\n"
    csvContent += "Profile_Education,\(quizProfile.education),Demographic,Education level\n"
    csvContent += "Profile_Occupation,\(quizProfile.occupation),Demographic,Occupation\n"

    csvContent +=
      "Export_Date,\(ISO8601DateFormatter().string(from: profile.timestamp)),Metadata,Export timestamp\n"
    csvContent += "Export_Version,\(profile.version),Metadata,Export format version\n"
    csvContent += "Profile_Type,\(profile.profileType),Metadata,APGI profile classification\n"

    return csvContent.data(using: String.Encoding.utf8) ?? Data()
  }

  private func exportXML(_ profile: ProfileExport) throws -> Data {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

    let xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <APGIProfileExport>
          <Metadata>
              <Version>\(profile.version)</Version>
              <ExportDate>\(formatter.string(from: profile.timestamp))</ExportDate>
              <ProfileType>\(profile.profileType)</ProfileType>
          </Metadata>
          <Demographics>
              <Name>\(profile.profile.name)</Name>
              <Age>\(profile.profile.age)</Age>
              <Gender>\(profile.profile.gender)</Gender>
              <Education>\(profile.profile.education)</Education>
              <Occupation>\(profile.profile.occupation)</Occupation>
          </Demographics>
          <APGIScores>
              <Overall>\(profile.apgiScores.overall)</Overall>
              <Autonomy>\(profile.apgiScores.autonomy)</Autonomy>
              <Purposefulness>\(profile.apgiScores.purposefulness)</Purposefulness>
              <SelfAcceptance>\(profile.apgiScores.selfAcceptance)</SelfAcceptance>
              <PersonalGrowth>\(profile.apgiScores.personalGrowth)</PersonalGrowth>
          </APGIScores>
      </APGIProfileExport>
      """

    return xml.data(using: String.Encoding.utf8) ?? Data()
  }

  private func exportSPSS(_ profile: ProfileExport) throws -> Data {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let dateString = dateFormatter.string(from: Date())
    var portable = "SPSSPORT APGI_Profile \(dateString)\n"

    let variables = [
      ("APGI_Total", "Total APGI Score"),
      ("APGI_Autonomy", "Autonomy"),
      ("APGI_Purposefulness", "Purposefulness"),
      ("APGI_SelfAcceptance", "Self-Acceptance"),
      ("APGI_PersonalGrowth", "Personal Growth"),
      ("Age", "Participant Age"),
      ("Export_Date", "Export Timestamp")
    ]

    for (name, label) in variables {
      portable += "\(name) 0 8 \"\(label)\"\n"
    }

    portable += "*\n"

    let values = [
      profile.apgiScores.overall,
      profile.apgiScores.autonomy,
      profile.apgiScores.purposefulness,
      profile.apgiScores.selfAcceptance,
      profile.apgiScores.personalGrowth,
      Double(profile.profile.age),
      profile.timestamp.timeIntervalSince1970
    ]

    let valueStrings = values.map { String(format: "%.2f", $0) }
    portable += valueStrings.joined(separator: " ") + "\n"

    return portable.data(using: .ascii) ?? Data()
  }

  private func exportStata(_ profile: ProfileExport) throws -> Data {
    var data = Data()
    // Byte order: little endian
    data.append(0x01)
    data.append(0x01)
    // File type: data
    data.append(0x01)
    // Unused
    data.append(0x00)
    // Number of variables: 7
    data.append(contentsOf: withUnsafeBytes(of: UInt16(7).littleEndian) { Data($0) })
    // Number of observations: 1
    data.append(contentsOf: withUnsafeBytes(of: UInt32(1).littleEndian) { Data($0) })
    // Data label: empty
    data.append(0x00)
    // Time stamp: empty
    data.append(0x00)
    // Variable names
    let names = [
      "apgi_total", "apgi_autonomy", "apgi_purpose", "apgi_selfacc", "apgi_growth", "age",
      "export_date"
    ]
    for name in names {
      guard let nameData = name.data(using: .ascii) else {
        throw ExportError.invalidData
      }
      data.append(contentsOf: nameData)
      data.append(0x00)
    }
    // Data
    let values: [Double] = [
      profile.apgiScores.overall,
      profile.apgiScores.autonomy,
      profile.apgiScores.purposefulness,
      profile.apgiScores.selfAcceptance,
      profile.apgiScores.personalGrowth,
      Double(profile.profile.age),
      profile.timestamp.timeIntervalSince1970
    ]
    for value in values {
      data.append(contentsOf: withUnsafeBytes(of: value.bitPattern.littleEndian) { Data($0) })
    }
    return data
  }

  private func exportRData(_ profile: ProfileExport) throws -> Data {
    // Generate R script that creates and saves the data
    let dateFormatter = ISO8601DateFormatter()
    let dateString = dateFormatter.string(from: profile.timestamp)

    let rScript = """
      # APGI Profile Data Export
      # Generated by APGI Explorer
      # Export Date: \(dateString)

      # Create data frame with APGI profile data
      apgi_data <- data.frame(
        apgi_total = \(profile.apgiScores.overall),
        apgi_autonomy = \(profile.apgiScores.autonomy),
        apgi_purposefulness = \(profile.apgiScores.purposefulness),
        apgi_self_acceptance = \(profile.apgiScores.selfAcceptance),
        apgi_personal_growth = \(profile.apgiScores.personalGrowth),
        age = \(profile.profile.age),
        gender = "\(profile.profile.gender)",
        education = "\(profile.profile.education)",
        occupation = "\(profile.profile.occupation)",
        profile_type = "\(profile.profileType)",
        export_date = "\(dateString)",
        stringsAsFactors = FALSE
      )

      # Save to RDS file
      saveRDS(apgi_data, file = "apgi_profile.rds")

      # Also save as RData workspace
      save(apgi_data, file = "apgi_profile.RData")
      """

    return rScript.data(using: .utf8) ?? Data()
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

    let rows: [[String]] = [
      ["Metric", "Value", "Category", "Description"],
      ["APGI_Total", String(profile.apgiScores.overall), "Overall", "Total APGI Score"],
      [
        "APGI_Autonomy", String(profile.apgiScores.autonomy), "Autonomy",
        "Level of autonomous functioning"
      ],
      [
        "APGI_Purposefulness", String(profile.apgiScores.purposefulness), "Purposefulness",
        "Sense of purpose and direction"
      ],
      [
        "APGI_SelfAcceptance", String(profile.apgiScores.selfAcceptance), "Self-Acceptance",
        "Level of self-acceptance"
      ],
      [
        "APGI_PersonalGrowth", String(profile.apgiScores.personalGrowth), "Personal Growth",
        "Orientation toward growth"
      ],
      ["Profile_Name", profile.profile.name, "Demographic", "Profile identifier"],
      ["Profile_Age", String(profile.profile.age), "Demographic", "Participant age"],
      ["Profile_Gender", profile.profile.gender, "Demographic", "Participant gender"],
      ["Profile_Education", profile.profile.education, "Demographic", "Education level"],
      ["Profile_Occupation", profile.profile.occupation, "Demographic", "Occupation"],
      [
        "Export_Date", ISO8601DateFormatter().string(from: profile.timestamp), "Metadata",
        "Export timestamp"
      ],
      ["Export_Version", profile.version, "Metadata", "Export format version"],
      ["Profile_Type", profile.profileType, "Metadata", "APGI profile classification"]
    ]

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
    let bibtex = """
      @misc{apgi_profile_\(profile.profile.name.replacingOccurrences(of: " ", with: "_").lowercased()),
          title = {APGI Psychological Profile: \\(profile.profile.name)},
          author = {APGI Explorer},
          year = {\(Calendar.current.component(.year, from: profile.timestamp))},
          month = {\(Calendar.current.monthSymbols[Calendar.current.component(.month, from: profile.timestamp) - 1])},
          note = {APGI Total Score: \\(profile.apgiScores.overall); Profile Type: \\(profile.profileType)},
          type = {Psychological Assessment},
          howpublished = {APGI Explorer Application}
      }
      """

    return bibtex.data(using: .utf8) ?? Data()
  }

  private func exportEndNote(_ profile: ProfileExport) throws -> Data {
    let endNote = """
      %0 Generic
      %T APGI Psychological Profile: \(profile.profile.name)
      %A APGI Explorer
      %D \(Calendar.current.component(.year, from: profile.timestamp))
      %8 \(Calendar.current.monthSymbols[Calendar.current.component(.month, from: profile.timestamp) - 1])
      %X APGI Total Score: \(profile.apgiScores.overall)
      %X Profile Type: \(profile.profileType)
      %X Autonomy: \(profile.apgiScores.autonomy)
      %X Purposefulness: \(profile.apgiScores.purposefulness)
      %X Self-Acceptance: \(profile.apgiScores.selfAcceptance)
      %X Personal Growth: \(profile.apgiScores.personalGrowth)
      %9 Psychological Assessment
      %Z Generated by APGI Explorer Application
      %@ APGI Explorer
      """

    return endNote.data(using: String.Encoding.utf8) ?? Data()
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
    let formatter = DateFormatter()
    formatter.dateStyle = .long

    return """
      APGI Psychological Assessment Report
      ====================================

      Client Information
      -----------------
      Name: \(profile.profile.name)
      Age: \(profile.profile.age)
      Gender: \(profile.profile.gender)
      Education: \(profile.profile.education)
      Occupation: \(profile.profile.occupation)

      Assessment Information
      ---------------------
      Date of Assessment: \(formatter.string(from: profile.timestamp))
      Assessment Instrument: Adult Psychological Growth Inventory (APGI)
      Profile Type: \(profile.profileType)

      Assessment Results
      -----------------

      Total APGI Score: \(profile.apgiScores.overall)

      Subscale Scores:
      - Autonomy: \(profile.apgiScores.autonomy)
      - Purposefulness: \(profile.apgiScores.purposefulness)
      - Self-Acceptance: \(profile.apgiScores.selfAcceptance)
      - Personal Growth: \(profile.apgiScores.personalGrowth)

      Interpretation
      -------------
      \(self.generateInterpretation(profile: profile))

      Recommendations
      ---------------
      \(self.generateRecommendations(profile: profile))

      Report Generated: \(formatter.string(from: Date()))
      Generated by: APGI Explorer v\(profile.version)

      References
      ----------
      APGI Explorer. (2025). Adult Psychological Growth Inventory [Computer software].
      Retrieved from https://github.com/lesoto/APGI-Explorer
      """
  }

  private func generateMLAReport(profile: ProfileExport) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .long

    return """
      \(profile.profile.name) - APGI Assessment Report

      Client Information
      Name: \(profile.profile.name)
      Age: \(profile.profile.age)
      Gender: \(profile.profile.gender)
      Education: \(profile.profile.education)
      Occupation: \(profile.profile.occupation)

      Assessment Details
      Date: \(formatter.string(from: profile.timestamp))
      Instrument: Adult Psychological Growth Inventory (APGI)
      Classification: \(profile.profileType)

      Results Summary
      Total Score: \(profile.apgiScores.overall)

      Detailed Scores:
      Autonomy: \(profile.apgiScores.autonomy)
      Purposefulness: \(profile.apgiScores.purposefulness)
      Self-Acceptance: \(profile.apgiScores.selfAcceptance)
      Personal Growth: \(profile.apgiScores.personalGrowth)

      Analysis
      \(self.generateInterpretation(profile: profile))

      Suggestions
      \(self.generateRecommendations(profile: profile))

      Works Cited
      APGI Explorer. "Adult Psychological Growth Inventory." 2025. Computer software.
      """
  }

  private func generateInterpretation(profile: ProfileExport) -> String {
    let scores = profile.apgiScores

    var interpretation = "The APGI assessment reveals "

    if scores.overall >= 80 {
      interpretation += "high levels of psychological growth across all domains. "
    } else if scores.overall >= 60 {
      interpretation += "moderate levels of psychological growth with room for development. "
    } else {
      interpretation += "areas for potential growth and development. "
    }

    if scores.autonomy > scores.personalGrowth {
      interpretation +=
        "The individual shows stronger autonomy compared to personal growth orientation. "
    } else {
      interpretation += "Personal growth orientation appears more developed than autonomy. "
    }

    return interpretation
  }

  private func generateRecommendations(profile: ProfileExport) -> String {
    let scores = profile.apgiScores
    var recommendations = ""

    if scores.autonomy < 60 {
      recommendations += "• Focus on developing independent decision-making skills\n"
    }

    if scores.purposefulness < 60 {
      recommendations += "• Explore personal values and life goals\n"
    }

    if scores.selfAcceptance < 60 {
      recommendations += "• Practice self-compassion and acceptance exercises\n"
    }

    if scores.personalGrowth < 60 {
      recommendations += "• Engage in new learning experiences and challenges\n"
    }

    if recommendations.isEmpty {
      recommendations =
        "Continue current growth practices and consider advanced development opportunities."
    }

    return recommendations
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
