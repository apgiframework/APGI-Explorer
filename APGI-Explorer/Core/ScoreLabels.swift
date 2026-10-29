import Foundation

/// The only user-facing names for score groups. Result, comparison, chart, export and
/// report surfaces must reference these constants rather than repeating the text, and no
/// other `Reported …` literal may appear in runtime sources (enforced by the language gate).
nonisolated enum ScoreLabels {
  static let reactivity = "Reported reactivity to the unexpected"
  static let prioritisation = "Reported information prioritisation"
  static let threshold = "Reported attentional threshold"
  static let bodySignal = "Reported body-signal attention"

  static let approved: [String] = [reactivity, prioritisation, threshold, bodySignal]
}

/// Paid products need BOTH the remote `validation_results` flag and explicit approval
/// compiled into the build. This build's approval is false, so nothing can enable them.
nonisolated enum ExplorerBuildApproval {
  static let paidProductsApproved = false
}

nonisolated struct ProductEligibility: Equatable, Sendable {
  let remoteValidationResults: Bool
  let buildApproved: Bool
  var isEligible: Bool { remoteValidationResults && buildApproved }

  static func current(remoteValidationResults: Bool?) -> ProductEligibility {
    ProductEligibility(remoteValidationResults: remoteValidationResults ?? false,
                       buildApproved: ExplorerBuildApproval.paidProductsApproved)
  }
}

/// Research is available only when this build approves it AND the server turns it on.
/// `researchApproved` stays false until the privacy manifest has been reviewed for real research
/// collection (S3-EXP-01.12); `scripts/check_explorer_contracts.py` enforces that ordering.
nonisolated extension ExplorerBuildApproval {
  static let researchApproved = false
}

nonisolated extension ResearchCapability {
  static func current(serverResearchEnabled: Bool?) -> ResearchCapability {
    ResearchCapability(isEnabled: ExplorerBuildApproval.researchApproved && serverResearchEnabled == true)
  }
}

nonisolated enum ResearchImportSource: Equatable, Sendable {
  case personalProfile, legacyBackup, serverBank
}

/// Only the verified server bank may feed a research session. Personal profiles and legacy
/// (pre-research-mode) backups are never admitted.
nonisolated enum ResearchImportGate {
  static func admits(_ source: ResearchImportSource) -> Bool { source == .serverBank }
}
