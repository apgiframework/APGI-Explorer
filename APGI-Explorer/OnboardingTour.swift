import SwiftUI

struct OnboardingStep: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let imageType: ImageType
    let tips: [String]
    let highlightColor: Color
    
    enum ImageType {
        case system
        case asset
    }
}

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

let steps: [OnboardingStep] = [
    OnboardingStep(
        title: "Welcome to APGI Explorer",
        subtitle: "Your Cognitive Profile Navigator",
        description: "Discover how your mind works through the APGI framework. Explore psychological states, take assessments, and track your cognitive journey with precision and insight.",
        imageName: "brain.head.profile",
        imageType: .system,
        tips: [
            "Take the assessment to discover your cognitive profile",
            "Explore how different psychological states are mapped",
            "Compare your results with various cognitive patterns",
            "Track changes in your profile over time"
        ],
        highlightColor: .blue
    ),
    OnboardingStep(
        title: "Interactive Assessment",
        subtitle: "Map Your Cognitive Profile",
        description: "Our comprehensive quiz evaluates your cognitive patterns across key APGI dimensions. Answer naturally—there are no right or wrong answers, just insights waiting to be discovered.",
        imageName: "doc.text.magnifyingglass",
        imageType: .system,
        tips: [
            "Takes about 15-20 minutes to complete",
            "Save and resume your progress anytime",
            "Questions adapt based on your responses",
            "Get immediate results upon completion"
        ],
        highlightColor: .teal
    ),
    OnboardingStep(
        title: "APGI Framework",
        subtitle: "The Science Behind Your Mind",
        description: "The APGI model breaks down cognition into four key parameters that shape your experience. Understanding these helps explain how you perceive and interact with the world.",
        imageName: "atom",
        imageType: .system,
        tips: [
            "ε (Prediction Error): Your sensitivity to unexpected events",
            "π (Precision): How you weigh sensory vs. prior information",
            "θₜ (Threshold): Your awareness threshold for stimuli",
            "β (Somatic Bias): How bodily states influence your perception"
        ],
        highlightColor: .indigo
    ),
    OnboardingStep(
        title: "State Explorer",
        subtitle: "Understand Psychological Patterns",
        description: "Browse our comprehensive library of psychological states, each mapped to the APGI framework. See how different cognitive patterns manifest in thoughts, emotions, and behaviors.",
        imageName: "square.grid.3x3",
        imageType: .system,
        tips: [
            "Search by state name or description",
            "Filter by APGI parameters",
            "View detailed parameter breakdowns",
            "Save favorite states for quick reference"
        ],
        highlightColor: .purple
    ),
    OnboardingStep(
        title: "Profile Insights",
        subtitle: "Your Cognitive Blueprint",
        description: "After completing the assessment, receive a detailed analysis of your cognitive profile. See how your scores compare to population averages and understand what they mean for your daily experience.",
        imageName: "chart.bar.fill",
        imageType: .system,
        tips: [
            "Visual representation of your cognitive patterns",
            "Personalized insights and observations",
            "Actionable recommendations",
            "Exportable reports for professional review"
        ],
        highlightColor: .orange
    ),
    OnboardingStep(
        title: "Track & Compare",
        subtitle: "Your Cognitive Journey",
        description: "Save multiple assessment results to track how your cognitive patterns evolve. Compare different profiles to understand changes in your mental landscape over time.",
        imageName: "chart.line.uptrend.xyaxis",
        imageType: .system,
        tips: [
            "Save unlimited profiles",
            "Visual timeline of your progress",
            "Detailed comparison tools",
            "Set reminders for follow-up assessments"
        ],
        highlightColor: .green
    ),
    OnboardingStep(
        title: "Personalized Strategies",
        subtitle: "Optimize Your Mind",
        description: "Based on your profile, discover tailored strategies and exercises to enhance your cognitive flexibility, emotional regulation, and overall mental well-being.",
        imageName: "sparkles",
        imageType: .system,
        tips: [
            "Daily cognitive exercises",
            "Mindfulness practices",
            "Coping strategies",
            "Growth opportunities"
        ],
        highlightColor: .pink
    ),
    OnboardingStep(
        title: "Ready to Begin?",
        subtitle: "Your Cognitive Adventure Awaits",
        description: "You're all set to explore the fascinating landscape of your mind. Start with the assessment or browse psychological states to begin your journey of self-discovery.",
        imageName: "checkmark.seal.fill",
        imageType: .system,
        tips: [
            "Take the assessment first for personalized insights",
            "Bookmark interesting states to explore later",
            "Check back regularly for new content",
            "Your data is private and secure"
        ],
        highlightColor: .blue
    )
]

let tourSteps: [TourStep] = [
    TourStep(
        target: .navigation,
        title: "Main Navigation",
        description: "Easily switch between key sections: take the assessment, explore psychological states, view your saved profiles, and access settings.",
        position: .below,
        highlightColor: .blue
    ),
    TourStep(
        target: .search,
        title: "Advanced Search",
        description: "Quickly find specific psychological states by name, description, or APGI parameters. Use filters to narrow down results based on your interests.",
        position: .below,
        highlightColor: .purple
    ),
    TourStep(
        target: .sidebar,
        title: "State Explorer",
        description: "Browse through our comprehensive library of psychological states. Each card shows key APGI parameters at a glance—tap for detailed analysis.",
        position: .right,
        highlightColor: .teal
    ),
    TourStep(
        target: .glossary,
        title: "APGI Parameters",
        description: "Access detailed explanations of all APGI parameters, including how they interact and influence different psychological states.",
        position: .above,
        highlightColor: .indigo
    ),
    TourStep(
        target: .settings,
        title: "Your Profile Hub",
        description: "Manage your assessment history, saved states, comparison tools, and app preferences—all in one convenient location.",
        position: .below,
        highlightColor: .green
    ),
    TourStep(
        target: .settings,
        title: "Comparison Tools",
        description: "Compare multiple profiles side-by-side to track changes in your cognitive patterns over time or understand differences between states.",
        position: .left,
        highlightColor: .orange
    )
]