import XCTest

@testable import APGI_Explorer

final class ResearchExportTests: XCTestCase {
  var researchExportManager: ResearchExportManager?
  var testProfile: ProfileExport?

  override func setUpWithError() throws {
    continueAfterFailure = false
    self.researchExportManager = ResearchExportManager.shared

    // Create test profile
    let quizProfile = QuizProfile(
      id: UUID(),
      name: "Test Profile",
      dateCreated: Date(),
      dateModified: Date(),
      results: [
        "epsilon": 75,
        "precision": 60,
        "threshold": 45,
        "somatic": 30
      ]
    )

    let apgiScores = APGIProfile(
      epsilon: 75.0,
      precision: 60.0,
      threshold: 45.0,
      somaticBias: 30.0,
      interactionScore: 70.0,
      temporalStability: 80.0,
      environmentalFit: 75.0
    )

    self.testProfile = ProfileExport(
      version: "1.0",
      timestamp: Date(),
      profile: quizProfile,
      apgiScores: apgiScores
    )
  }

  override func tearDownWithError() throws {
    self.researchExportManager = nil
    self.testProfile = nil
  }

  private func getManager() throws -> ResearchExportManager {
    try XCTUnwrap(researchExportManager)
  }

  private func getProfile() throws -> ProfileExport {
    try XCTUnwrap(testProfile)
  }

  func testResearchExportManagerInitialization() {
    XCTAssertNotNil(self.researchExportManager)
    XCTAssertNotNil(self.testProfile)
  }

  func testJSONExport() throws {
    let manager = try getManager()
    let profile = try getProfile()
    let exportData = try manager.exportProfile(profile, format: .json)

    XCTAssertFalse(exportData.isEmpty)

    // Verify it's valid JSON
    let jsonObject = try JSONSerialization.jsonObject(with: exportData)
    XCTAssertNotNil(jsonObject)

    if let dict = jsonObject as? [String: Any] {
      XCTAssertEqual(dict["version"] as? String, "1.0")
      XCTAssertNotNil(dict["profile"])
      XCTAssertNotNil(dict["apgiScores"])
    }
  }

  func testCSVExport() throws {
    let manager = try getManager()
    let profile = try getProfile()
    let exportData = try manager.exportProfile(profile, format: .csv)

    XCTAssertFalse(exportData.isEmpty)

    let csvString = String(data: exportData, encoding: .utf8)
    XCTAssertNotNil(csvString)

    // Verify CSV headers
    XCTAssertTrue(csvString?.contains("Metric,Value,Category,Description") ?? false)
    XCTAssertTrue(csvString?.contains("APGI_Total") ?? false)
    XCTAssertTrue(csvString?.contains("APGI_Autonomy") ?? false)
    XCTAssertTrue(csvString?.contains("Profile_Name") ?? false)
  }

  func testXMLExport() throws {
    let manager = try getManager()
    let profile = try getProfile()
    let exportData = try manager.exportProfile(profile, format: .xml)

    XCTAssertFalse(exportData.isEmpty)

    let xmlString = String(data: exportData, encoding: .utf8)
    XCTAssertNotNil(xmlString)

    // Verify XML structure
    XCTAssertTrue(xmlString?.contains("<?xml version=\"1.0\"") ?? false)
    XCTAssertTrue(xmlString?.contains("<APGIProfileExport>") ?? false)
    XCTAssertTrue(xmlString?.contains("<Metadata>") ?? false)
    XCTAssertTrue(xmlString?.contains("<APGIScores>") ?? false)
  }

  func testSPSSExport() throws {
    let manager = try getManager()
    let profile = try getProfile()
    let exportData = try manager.exportProfile(profile, format: .spss)

    XCTAssertFalse(exportData.isEmpty)
    XCTAssertGreaterThanOrEqual(exportData.count, 100)  // SPSS files have binary headers
  }

  func testStataExport() throws {
    let manager = try getManager()
    let profile = try getProfile()
    let exportData = try manager.exportProfile(profile, format: .stata)

    XCTAssertFalse(exportData.isEmpty)
    XCTAssertGreaterThanOrEqual(exportData.count, 100)  // Stata files have binary headers
  }

  func testRDataExport() throws {
    let manager = try getManager()
    let profile = try getProfile()
    let exportData = try manager.exportProfile(profile, format: .rData)

    XCTAssertFalse(exportData.isEmpty)

    guard let rScript = String(data: exportData, encoding: .utf8) else {
      XCTFail("Failed to convert export data to string")
      return
    }

    // Verify R script content
    XCTAssertTrue(rScript.contains("# APGI Profile Data Export"))
    XCTAssertTrue(rScript.contains("apgi_data <- data.frame("))
    XCTAssertTrue(rScript.contains("save(apgi_data)"))
  }

  func testExcelExport() throws {
    let manager = try getManager()
    let profile = try getProfile()
    let exportData = try manager.exportProfile(profile, format: .excel)

    XCTAssertFalse(exportData.isEmpty)
    // Excel export is a binary ZIP/XLSX file
    XCTAssertGreaterThan(exportData.count, 100)
    // Check for ZIP magic number (PK..)
    XCTAssertEqual(exportData[0], 0x50) // 'P'
    XCTAssertEqual(exportData[1], 0x4B) // 'K'
  }

  func testBibTeXExport() throws {
    let manager = try getManager()
    let profile = try getProfile()
    let exportData = try manager.exportProfile(profile, format: .bibTeX)

    XCTAssertFalse(exportData.isEmpty)

    let bibtexString = String(data: exportData, encoding: .utf8)
    XCTAssertNotNil(bibtexString)

    // Verify BibTeX structure
    XCTAssertTrue(bibtexString?.contains("@misc{") ?? false)
    XCTAssertTrue(bibtexString?.contains("title = {") ?? false)
    XCTAssertTrue(bibtexString?.contains("author = {") ?? false)
    XCTAssertTrue(bibtexString?.contains("year = {") ?? false)
  }

  func testEndNoteExport() throws {
    let manager = try getManager()
    let profile = try getProfile()
    let exportData = try manager.exportProfile(profile, format: .endNote)

    XCTAssertFalse(exportData.isEmpty)

    let endNoteString = String(data: exportData, encoding: .utf8)
    XCTAssertNotNil(endNoteString)

    // Verify EndNote structure
    XCTAssertTrue(endNoteString?.contains("%0 Generic") ?? false)
    XCTAssertTrue(endNoteString?.contains("%T") ?? false)
    XCTAssertTrue(endNoteString?.contains("%A") ?? false)
    XCTAssertTrue(endNoteString?.contains("%D") ?? false)
  }

  func testAPAReportExport() throws {
    let manager = try getManager()
    let profile = try getProfile()
    let exportData = try manager.exportProfile(profile, format: .apa)

    XCTAssertFalse(exportData.isEmpty)

    // APA reports are generated as PDF
    XCTAssertGreaterThanOrEqual(exportData.count, 500)  // PDF files are larger
  }

  func testMLAReportExport() throws {
    let manager = try getManager()
    let profile = try getProfile()
    let exportData = try manager.exportProfile(profile, format: .mla)

    XCTAssertFalse(exportData.isEmpty)

    // MLA reports are generated as PDF
    XCTAssertGreaterThanOrEqual(exportData.count, 500)  // PDF files are larger
  }

  func testExportFormatProperties() {
    let formats: [ExportFormat] = [
      .json, .csv, .pdf, .png, .spss, .stata, .rData,
      .excel, .xml, .bibTeX, .endNote, .apa, .mla
    ]

    for format in formats {
      XCTAssertFalse(format.fileExtension.isEmpty)
      XCTAssertFalse(format.contentType.isEmpty)
      XCTAssertFalse(format.description.isEmpty)

      // Test category assignment
      let category = format.category
      XCTAssertTrue(ExportCategory.allCases.contains(category))
    }
  }

  func testExportCategoryFormats() {
    for category in ExportCategory.allCases {
      let formats = category.formats
      XCTAssertFalse(formats.isEmpty)

      for format in formats {
        XCTAssertEqual(format.category, category)
      }
    }
  }

  func testExportUtilities() throws {
    let profile = try getProfile()
    let filename = ExportUtilities.generateExportFilename(
      profile: profile.profile, format: .json)

    XCTAssertFalse(filename.isEmpty)
    XCTAssertTrue(filename.hasPrefix("Test_Profile_"))
    XCTAssertTrue(filename.hasSuffix(".json"))

    let tempDir = ExportUtilities.getTemporaryDirectory()
    XCTAssertNotNil(tempDir)
    XCTAssertTrue(tempDir.lastPathComponent == "tmp")
  }
}
