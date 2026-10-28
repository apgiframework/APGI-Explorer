import Foundation

enum APGIProfileType: String, CaseIterable {
  case sensitiveIntegrator = "Reactivity and body attention"
  case analyticalGuard = "Information focus and attention"
  case adaptiveBalancer = "Mixed responses"
  case openExplorer = "Reactivity and open attention"
  case contemplativeAnchor = "Lower reactivity and attention focus"
  case somaticNavigator = "Body attention"
  case cognitiveArchitect = "Information and attention focus"
  case dynamicResponder = "Reactivity and interaction"

  var description: String {
    "An exploratory grouping of self-reported answers, not a validated personality type."
  }
  var strengths: [String] { [] }
  var challenges: [String] { [] }
  var strategies: [String] {
    ["Reflect on which answers fit your recent experience.",
     "Consider how your answers may change with context."]
  }
  var likelyStates: [PsychologicalStateMatch] { [] }
}

struct PsychologicalStateMatch {
  let stateId: Int
  let likelihood: Likelihood
  let reason: String

  enum Likelihood: String {
    case veryHigh = "Very Likely"
    case high = "Likely"
    case moderate = "Moderate"
    case low = "Unlikely"
  }
}
