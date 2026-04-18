import SwiftUI

enum TourTarget {
  case navigation
  case search
  case sidebar
  case glossary
  case settings
}

struct TourStep: Identifiable {
  let id = UUID()
  let target: TourTarget
  let title: String
  let description: String
  let position: Position
  let highlightColor: Color

  enum Position {
    case above
    case below
    case left
    case right
  }
}

let tourSteps: [TourStep] = [
  TourStep(
    target: .navigation,
    title: "Main Navigation",
    description: "Easily switch between key sections: take the assessment, "
      + "explore psychological states, view your saved profiles, and access settings.",
    position: .below,
    highlightColor: .blue
  ),
  TourStep(
    target: .search,
    title: "Advanced Search",
    description: "Quickly find specific psychological states by name, description, "
      + "or APGI parameters. Use filters to narrow down results based on your interests.",
    position: .below,
    highlightColor: .purple
  ),
  TourStep(
    target: .sidebar,
    title: "State Explorer",
    description: "Browse through our comprehensive library of psychological states. "
      + "Each card shows key APGI parameters at a glance—tap for detailed analysis.",
    position: .right,
    highlightColor: .teal
  ),
  TourStep(
    target: .glossary,
    title: "APGI Parameters",
    description: "Access detailed explanations of all APGI parameters, including "
      + "how they interact and influence different psychological states.",
    position: .above,
    highlightColor: .indigo
  ),
  TourStep(
    target: .settings,
    title: "Your Profile Hub",
    description: "Manage your assessment history, saved states, comparison tools, "
      + "and app preferences—all in one convenient location.",
    position: .below,
    highlightColor: .green
  ),
  TourStep(
    target: .settings,
    title: "Comparison Tools",
    description:
      "Compare multiple profiles side-by-side to track changes in your cognitive patterns over time or understand differences between states.",
    position: .left,
    highlightColor: .orange
  ),
]
