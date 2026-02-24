@testable import APGI_Explorer
import XCTest

final class ResearchExportTests: XCTestCase {
    var researchExportManager: ResearchExportManager!
    var testProfile: ProfileExport!

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
                "epsilon": 75.0,
                "precision": 60.0,
                "threshold": 45.0,
                "somatic": 30.0,
            ]
        )

        let apgiScores = APGIProfile(
            overall: 75.0,
            autonomy: 80.0,
            purposefulness: 70.0,
            selfAcceptance: 75.0,
            personalGrowth: 76.0
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

    func testResearchExportManagerInitialization() {
        XCTAssertNotNil(self.researchExportManager)
    }

    func testJSONExport() throws {
        let exportData = try researchExportManager.exportProfile(self.testProfile, format: .json)

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
        let exportData = try researchExportManager.exportProfile(self.testProfile, format: .csv)

        XCTAssertFalse(exportData.isEmpty)

        let csvString = String(data: exportData, encoding: .utf8)
        XCTAssertNotNil(csvString)

        // Verify CSV headers
        XCTAssertTrue(try XCTUnwrap(csvString?.contains("Metric,Value,Category,Description")))
        XCTAssertTrue(try XCTUnwrap(csvString?.contains("APGI_Total")))
        XCTAssertTrue(try XCTUnwrap(csvString?.contains("APGI_Autonomy")))
        XCTAssertTrue(try XCTUnwrap(csvString?.contains("Profile_Name")))
    }

    func testXMLExport() throws {
        let exportData = try researchExportManager.exportProfile(self.testProfile, format: .xml)

        XCTAssertFalse(exportData.isEmpty)

        let xmlString = String(data: exportData, encoding: .utf8)
        XCTAssertNotNil(xmlString)

        // Verify XML structure
        XCTAssertTrue(try XCTUnwrap(xmlString?.contains("<?xml version=\"1.0\"")))
        XCTAssertTrue(try XCTUnwrap(xmlString?.contains("<APGIProfileExport>")))
        XCTAssertTrue(try XCTUnwrap(xmlString?.contains("<Metadata>")))
        XCTAssertTrue(try XCTUnwrap(xmlString?.contains("<APGIScores>")))
    }

    func testSPSSExport() throws {
        let exportData = try researchExportManager.exportProfile(self.testProfile, format: .spss)

        XCTAssertFalse(exportData.isEmpty)
        XCTAssertGreaterThanOrEqual(exportData.count, 100) // SPSS files have binary headers
    }

    func testStataExport() throws {
        let exportData = try researchExportManager.exportProfile(self.testProfile, format: .stata)

        XCTAssertFalse(exportData.isEmpty)
        XCTAssertGreaterThanOrEqual(exportData.count, 100) // Stata files have binary headers
    }

    func testRDataExport() throws {
        let exportData = try researchExportManager.exportProfile(self.testProfile, format: .rData)

        XCTAssertFalse(exportData.isEmpty)

        let rScript = String(data: exportData, encoding: .utf8)
        XCTAssertNotNil(rScript)

        // Verify R script content
        XCTAssertTrue(try XCTUnwrap(rScript?.contains("# APGI Profile Data Export")))
        XCTAssertTrue(try XCTUnwrap(rScript?.contains("apgi_data <- data.frame(")))
        XCTAssertTrue(try XCTUnwrap(rScript?.contains("save(apgi_data")))
    }

    func testExcelExport() throws {
        let exportData = try researchExportManager.exportProfile(self.testProfile, format: .excel)

        XCTAssertFalse(exportData.isEmpty)

        // Excel export currently uses CSV format internally
        let csvString = String(data: exportData, encoding: .utf8)
        XCTAssertNotNil(csvString)
        XCTAssertTrue(try XCTUnwrap(csvString?.contains("Metric,Value,Category,Description")))
    }

    func testBibTeXExport() throws {
        let exportData = try researchExportManager.exportProfile(self.testProfile, format: .bibTeX)

        XCTAssertFalse(exportData.isEmpty)

        let bibtexString = String(data: exportData, encoding: .utf8)
        XCTAssertNotNil(bibtexString)

        // Verify BibTeX structure
        XCTAssertTrue(try XCTUnwrap(bibtexString?.contains("@misc{")))
        XCTAssertTrue(try XCTUnwrap(bibtexString?.contains("title = {")))
        XCTAssertTrue(try XCTUnwrap(bibtexString?.contains("author = {")))
        XCTAssertTrue(try XCTUnwrap(bibtexString?.contains("year = {")))
    }

    func testEndNoteExport() throws {
        let exportData = try researchExportManager.exportProfile(self.testProfile, format: .endNote)

        XCTAssertFalse(exportData.isEmpty)

        let endNoteString = String(data: exportData, encoding: .utf8)
        XCTAssertNotNil(endNoteString)

        // Verify EndNote structure
        XCTAssertTrue(try XCTUnwrap(endNoteString?.contains("%0 Generic")))
        XCTAssertTrue(try XCTUnwrap(endNoteString?.contains("%T")))
        XCTAssertTrue(try XCTUnwrap(endNoteString?.contains("%A")))
        XCTAssertTrue(try XCTUnwrap(endNoteString?.contains("%D")))
    }

    func testAPAReportExport() throws {
        let exportData = try researchExportManager.exportProfile(self.testProfile, format: .apa)

        XCTAssertFalse(exportData.isEmpty)

        // APA reports are generated as PDF
        XCTAssertGreaterThanOrEqual(exportData.count, 1000) // PDF files are larger
    }

    func testMLAReportExport() throws {
        let exportData = try researchExportManager.exportProfile(self.testProfile, format: .mla)

        XCTAssertFalse(exportData.isEmpty)

        // MLA reports are generated as PDF
        XCTAssertGreaterThanOrEqual(exportData.count, 1000) // PDF files are larger
    }

    func testExportFormatProperties() {
        let formats: [ExportFormat] = [
            .json, .csv, .pdf, .png, .spss, .stata, .rData,
            .excel, .xml, .bibTeX, .endNote, .apa, .mla,
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

    func testExportUtilities() {
        let filename = ExportUtilities.generateExportFilename(profile: self.testProfile.profile, format: .json)

        XCTAssertFalse(filename.isEmpty)
        XCTAssertTrue(filename.hasPrefix("Test_Profile_"))
        XCTAssertTrue(filename.hasSuffix(".json"))

        let tempDir = ExportUtilities.getTemporaryDirectory()
        XCTAssertNotNil(tempDir)
        XCTAssertTrue(tempDir.lastPathComponent == "tmp")
    }
}
