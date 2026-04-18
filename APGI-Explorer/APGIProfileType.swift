import Foundation

enum APGIProfileType: String, CaseIterable {
  case sensitiveIntegrator = "Sensitive Integrator"
  case analyticalGuard = "Analytical Guard"
  case adaptiveBalancer = "Adaptive Balancer"
  case openExplorer = "Open Explorer"
  case contemplativeAnchor = "Contemplative Anchor"
  case somaticNavigator = "Somatic Navigator"
  case cognitiveArchitect = "Cognitive Architect"
  case dynamicResponder = "Dynamic Responder"

  var description: String {
    switch self {
    case .sensitiveIntegrator:
      "High ε, high β and a lowered θₜ make you exquisitely aware of prediction errors and their bodily echoes."
    case .analyticalGuard:
      "Low ε, high π and elevated θₜ equip you to keep a tight inner model and defend against uncertainty."
    case .adaptiveBalancer:
      "Balanced ε, π, θₜ and β let you shift between exploration and stability with relative ease."
    case .openExplorer:
      "Very high ε, low π and a loose θₜ keep you curious, ready to approach novelty without overthinking."
    case .contemplativeAnchor:
      "Low ε paired with high π and θₜ fosters calm, reflective presence even in novel contexts."
    case .somaticNavigator:
      "Moderate ε, elevated β and grounded π keep you oriented in the body while remaining attentive to new inputs."
    case .cognitiveArchitect:
      "Moderate-to-high ε, very high π and high θₜ build a mind that theorizes, plans and protects clarity."
    case .dynamicResponder:
      "High ε, high β, strong interaction signals and a flexible θₜ let you respond quickly to emotionally salient situations."
    }
  }

  var strengths: [String] {
    switch self {
    case .sensitiveIntegrator:
      [
        "Detects subtle patterns earlier than most",
        "Embodied emotional richness that fuels empathy",
        "Learns quickly from embodied feedback",
      ]
    case .analyticalGuard:
      [
        "Creates airtight mental models",
        "Anticipates risks with precise vigilance",
        "Keeps others grounded through structure",
      ]
    case .adaptiveBalancer:
      [
        "Pivot between data and feeling with ease",
        "Recovers quickly when expectations shift",
        "Acts as a translator between extremes",
      ]
    case .openExplorer:
      [
        "Scans vast possibility space without fear",
        "Generates novel hypotheses on a whim",
        "Perceives the unknown as invitation",
      ]
    case .contemplativeAnchor:
      [
        "Carries steadiness into chaos",
        "Models futures patiently and deeply",
        "Keeps emotional rhythms slow and intentional",
      ]
    case .somaticNavigator:
      [
        "Knows what the body is trying to tell the mind",
        "Embodies safety even when predictions waver",
        "Calms others through resonant presence",
      ]
    case .cognitiveArchitect:
      [
        "Designs intricate systems and plans",
        "Maintains razor-sharp focus, even under pressure",
        "Triangulates information across domains",
      ]
    case .dynamicResponder:
      [
        "Responds to social-emotional cues in real time",
        "Rebalances quickly after surprises",
        "Infuses transition moments with energy",
      ]
    }
  }

  var challenges: [String] {
    switch self {
    case .sensitiveIntegrator:
      [
        "Easily overwhelmed in high-stimulation situations",
        "Anxiety flares when predictions pile up",
        "Needs frequent recovery space to avoid emotional flooding",
      ]
    case .analyticalGuard:
      [
        "Rigidity when models encounter ambiguity",
        "Disconnect from the body's wisdom",
        "Difficulty letting others in emotionally",
      ]
    case .adaptiveBalancer:
      [
        "Can drift into indecision when extremes collide",
        "Tends to self-critique instead of trusting adaptability",
        "Requires more energy to champion a single path",
      ]
    case .openExplorer:
      [
        "Scattered focus and unfinished experiments",
        "Burnout from too many surprises at once",
        "Struggle to honor structure or routine",
      ]
    case .contemplativeAnchor:
      [
        "Might stagnate when novelty is missing",
        "Resists change even when it is needed",
        "Suppresses drive in favor of calm",
      ]
    case .somaticNavigator:
      [
        "Somatic alarms can feel overwhelming",
        "May cling to physical intuition even when data shifts",
        "Struggles when forced to ignore bodily cues",
      ]
    case .cognitiveArchitect:
      [
        "Feels detached from body/feeling",
        "Analysis paralysis when data is messy",
        "Holds tight control and can feel inflexible",
      ]
    case .dynamicResponder:
      [
        "Impulsivity when surprise hits",
        "Overstimulated by sustained high-intensity input",
        "May skip detail in favor of the emotional arc",
      ]
    }
  }

  var strategies: [String] {
    switch self {
    case .sensitiveIntegrator:
      [
        "Practice grounding techniques during overloads",
        "Build predictable routines to reduce surprise load",
        "Use interoceptive meditation to regulate β",
      ]
    case .analyticalGuard:
      [
        "Schedule deliberate curiosity breaks",
        "Check in with bodily cues before decisions",
        "Narrate emotions aloud to invite connection",
      ]
    case .adaptiveBalancer:
      [
        "Define a few guiding values to choose between paths",
        "Alternate focused work with playful rest",
        "Journal shifts to make them tangible",
      ]
    case .openExplorer:
      [
        "Batch experiments into time-limited sprints",
        "Lean on accountability partners to finish",
        "Capture insights before moving to the next novelty",
      ]
    case .contemplativeAnchor:
      [
        "Introduce gentle novelty—small rituals that shift the frame",
        "Pair reflective work with light movement",
        "Set playful deadlines to inject momentum",
      ]
    case .somaticNavigator:
      [
        "Honor somatic hygiene between big moments",
        "Ground through breath and posture before deciding",
        "Lean into rest when β spikes high",
      ]
    case .cognitiveArchitect:
      [
        "Check in with the body before signing off",
        "Design micro-experiments instead of debating endlessly",
        "Delegate perception-heavy tasks to trusting collaborators",
      ]
    case .dynamicResponder:
      [
        "Anchor with brief rituals before reacting",
        "Pause to record observations before jumping in",
        "Schedule reflective check-ins after high-energy efforts",
      ]
    }
  }

  var likelyStates: [PsychologicalStateMatch] {
    switch self {
    case .sensitiveIntegrator:
      [
        PsychologicalStateMatch(
          stateId: 20, likelihood: .veryHigh,
          reason: "High ε and β keep anxious alarms easily triggered."),
        PsychologicalStateMatch(
          stateId: 35, likelihood: .high,
          reason: "Low θₜ and rich signals crowd the reservoir, inviting overwhelm."),
        PsychologicalStateMatch(
          stateId: 41, likelihood: .veryHigh,
          reason: "Embodied attunement primes shared-empathy states."),
      ]
    case .analyticalGuard:
      [
        PsychologicalStateMatch(
          stateId: 15, likelihood: .high,
          reason: "Predictive stability and high threshold favor neutral equilibrium."),
        PsychologicalStateMatch(
          stateId: 21, likelihood: .moderate,
          reason: "Stress surfaces when low ε surprises breach high π defenses."),
        PsychologicalStateMatch(
          stateId: 29, likelihood: .moderate,
          reason: "Confusion arrives when rigid models meet ambiguous feedback."),
      ]
    case .adaptiveBalancer:
      [
        PsychologicalStateMatch(
          stateId: 1, likelihood: .high,
          reason: "The blend of parameters smooths into flow when focus aligns."),
        PsychologicalStateMatch(
          stateId: 13, likelihood: .high,
          reason: "Engagement follows from steady attention and gentle surprise handling."),
        PsychologicalStateMatch(
          stateId: 28, likelihood: .moderate,
          reason: "Frustration flares when balanced cues still pull in competing directions."),
      ]
    case .openExplorer:
      [
        PsychologicalStateMatch(
          stateId: 12, likelihood: .veryHigh,
          reason: "High ε and low θₜ keep curiosity mechanisms online."),
        PsychologicalStateMatch(
          stateId: 6, likelihood: .high,
          reason: "Awe ignites when novelty overwhelms previously tight models."),
        PsychologicalStateMatch(
          stateId: 7, likelihood: .high,
          reason: "Inspiration rides the rapid recombination of fresh predictions."),
      ]
    case .contemplativeAnchor:
      [
        PsychologicalStateMatch(
          stateId: 14, likelihood: .veryHigh,
          reason: "High θₜ and low ε invite mindful observation."),
        PsychologicalStateMatch(
          stateId: 8, likelihood: .high, reason: "Steady precision nurtures calm serenity."),
        PsychologicalStateMatch(
          stateId: 5, likelihood: .moderate,
          reason: "Optimism sustains when cautious models consistently succeed."),
      ]
    case .somaticNavigator:
      [
        PsychologicalStateMatch(
          stateId: 41, likelihood: .veryHigh,
          reason: "Rich β prioritizes empathetic somatic mirroring."),
        PsychologicalStateMatch(
          stateId: 20, likelihood: .high,
          reason: "Heightened somatic precision keeps anxiety accessible near the surface."),
        PsychologicalStateMatch(
          stateId: 35, likelihood: .high,
          reason: "When the body floods, overwhelm can cascade quickly."),
      ]
    case .cognitiveArchitect:
      [
        PsychologicalStateMatch(
          stateId: 13, likelihood: .veryHigh,
          reason: "Engagement sustains while π and θₜ stay elevated."),
        PsychologicalStateMatch(
          stateId: 29, likelihood: .moderate,
          reason: "Confusion appears when even elegant plans cannot resolve surprise."),
        PsychologicalStateMatch(
          stateId: 34, likelihood: .moderate,
          reason: "Pessimism settles after repeated model failures."),
      ]
    case .dynamicResponder:
      [
        PsychologicalStateMatch(
          stateId: 2, likelihood: .veryHigh,
          reason: "Joy blooms when energetic response loops land successfully."),
        PsychologicalStateMatch(
          stateId: 6, likelihood: .high,
          reason: "Awe follows from large, sudden prediction errors in positive contexts."),
        PsychologicalStateMatch(
          stateId: 35, likelihood: .moderate,
          reason: "Sustained high arousal can tip into overwhelm without rest."),
      ]
    }
  }
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
