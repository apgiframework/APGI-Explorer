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
