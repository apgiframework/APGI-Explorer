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
        csvContent += "APGI_Purposefulness,\(apgiScores.purposefulness),Purposefulness,Sense of purpose and direction\n"
        csvContent += "APGI_SelfAcceptance,\(apgiScores.selfAcceptance),Self-Acceptance,Level of self-acceptance\n"
        csvContent += "APGI_PersonalGrowth,\(apgiScores.personalGrowth),Personal Growth,Orientation toward growth\n"

        let quizProfile = profile.profile
        csvContent += "Profile_Name,\(quizProfile.name),Demographic,Profile identifier\n"
        csvContent += "Profile_Age,\(quizProfile.age),Demographic,Participant age\n"
        csvContent += "Profile_Gender,\(quizProfile.gender),Demographic,Participant gender\n"
        csvContent += "Profile_Education,\(quizProfile.education),Demographic,Education level\n"
        csvContent += "Profile_Occupation,\(quizProfile.occupation),Demographic,Occupation\n"

        csvContent += "Export_Date,\(ISO8601DateFormatter().string(from: profile.timestamp)),Metadata,Export timestamp\n"
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
        var spssData = Data()

        let header: [UInt8] = [
            0x24, 0x46, 0x4c, 0x32, 0x02, 0x00, 0x01, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        ]
        spssData.append(contentsOf: header)

        let variableRecords = [
            ("APGI_Total", 8, 0),
            ("APGI_Autonomy", 12, 0),
            ("APGI_Purpose", 14, 0),
            ("APGI_SelfAcc", 11, 0),
            ("APGI_Growth", 11, 0),
            ("Age", 3, 0),
            ("Export_Date", 11, 0),
        ]

        for (name, length, type) in variableRecords {
            var record = Data(count: 32)
            let nameData = name.data(using: .ascii) ?? Data()
            record.replaceSubrange(0 ..< min(nameData.count, 8), with: nameData)
            record[8] = UInt8(length)
            record[9] = UInt8(type)
            spssData.append(record)
        }

        let values = [
            profile.apgiScores.overall,
            profile.apgiScores.autonomy,
            profile.apgiScores.purposefulness,
            profile.apgiScores.selfAcceptance,
            profile.apgiScores.personalGrowth,
            Double(profile.profile.age),
            profile.timestamp.timeIntervalSince1970,
        ]

        for value in values {
            var floatValue = Float(value)
            let data = Data(bytes: &floatValue, count: MemoryLayout<Float>.size)
            spssData.append(data)
        }

        return spssData
    }

    private func exportStata(_ profile: ProfileExport) throws -> Data {
        var stataData = Data()

        let header = Data([
            0x73, 0x74, 0x61, 0x74, 0x61, 0x00, 0x00, 0x00,
            0x01, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00,
        ])
        stataData.append(header)

        let variableNames = [
            "apgi_total", "apgi_autonomy", "apgi_purpose",
            "apgi_selfacc", "apgi_growth", "age", "export_date",
        ]

        for name in variableNames {
            var nameData = name.data(using: .ascii) ?? Data()
            nameData.append(contentsOf: Data(count: 33 - nameData.count))
            stataData.append(nameData)
        }

        let values = [
            profile.apgiScores.overall,
            profile.apgiScores.autonomy,
            profile.apgiScores.purposefulness,
            profile.apgiScores.selfAcceptance,
            profile.apgiScores.personalGrowth,
            Double(profile.profile.age),
            profile.timestamp.timeIntervalSince1970,
        ]

        for value in values {
            var doubleValue = value
            let data = Data(bytes: &doubleValue, count: MemoryLayout<Double>.size)
            stataData.append(data)
        }

        return stataData
    }

    private func exportRData(_ profile: ProfileExport) throws -> Data {
        let rScript = """
        # APGI Profile Data Export
        # Generated: \(Date())
        # Version: \(profile.version)

        # Create data frame
        apgi_data <- data.frame(
            apgi_total = c(\(profile.apgiScores.overall)),
            apgi_autonomy = c(\(profile.apgiScores.autonomy)),
            apgi_purposefulness = c(\(profile.apgiScores.purposefulness)),
            apgi_self_acceptance = c(\(profile.apgiScores.selfAcceptance)),
            apgi_personal_growth = c(\(profile.apgiScores.personalGrowth)),
            age = c(\(profile.profile.age)),
            gender = c("\(profile.profile.gender)"),
            education = c("\(profile.profile.education)"),
            occupation = c("\(profile.profile.occupation)"),
            profile_type = c("\(profile.profileType)"),
            export_date = c(as.POSIXct("\(profile.timestamp)"))
        )

        # Variable labels
        attr(apgi_data$apgi_total, "label") <- "Total APGI Score"
        attr(apgi_data$apgi_autonomy, "label") <- "Autonomy Subscale"
        attr(apgi_data$apgi_purposefulness, "label") <- "Purposefulness Subscale"
        attr(apgi_data$apgi_self_acceptance, "label") <- "Self-Acceptance Subscale"
        attr(apgi_data$apgi_personal_growth, "label") <- "Personal Growth Subscale"

        # Save to RData format
        save(apgi_data, file = "apgi_profile.RData")
        """

        return rScript.data(using: String.Encoding.utf8) ?? Data()
    }

    private func exportExcel(_ profile: ProfileExport) throws -> Data {
        try self.exportCSV(profile)
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
            interpretation += "The individual shows stronger autonomy compared to personal growth orientation. "
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
            recommendations = "Continue current growth practices and consider advanced development opportunities."
        }

        return recommendations
    }

    private func generatePDFReport(content: String, title: String) throws -> Data {
        #if os(iOS)
            let pdfMetaData = [
                kCGPDFContextCreator: "APGI Explorer",
                kCGPDFContextAuthor: "APGI Explorer",
                kCGPDFContextTitle: title,
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
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
            ]

            let textRect = CGRect(x: 50, y: 50, width: 512, height: 692)
            content.draw(in: textRect, withAttributes: attributes)

            UIGraphicsEndPDFContext()

            return pdfData as Data
        #else
            // PDF generation not implemented for macOS
            return Data()
        #endif
    }
}

extension ExportError {
    static let unsupportedFormat = ExportError.unknown
}
